package common.systems;

import enh.Builders;
import enh.Timer;

import Common;
#if client
import Client;
#end


class CollisionSystem extends System<Main, EntityCreator>
{
    public function init() {}

    static inline function corners() {
        var margin = 2;
        return [[margin, margin],
                [World.TILE_SIZE - margin, margin],
                [World.TILE_SIZE - margin, World.TILE_SIZE - margin],
                [margin, World.TILE_SIZE - margin]];
    }

    static inline function getTilePosition(x:Float, y:Float)
    {
        var posx = Std.int(x / World.TILE_SIZE);
        var posy = Std.int(y / World.TILE_SIZE);

        return [posx, posy];
    }

    static inline function collides(x:Float, y:Float)
    {
        var collision = false;
        for(corner in corners())
        {
            var tpos = getTilePosition(x + corner[0], y + corner[1]);

            if(outsideMap(tpos[0], tpos[1])) continue;

            if(World.map[tpos[0]][tpos[1]] != -1)
            {
                collision = true;
                break;
            }
        }

        return collision;
    }

    static inline function outsideMap(posx:Int, posy:Int)
    {
        var outside = false;
        if(posx >= PyxelMapImporter.TILES_WIDE ||
           posy >= PyxelMapImporter.TILES_HIGH ||
           posx < 0 ||
           posy < 0)
        {
            outside = true;
        }
        return outside;
    }

    public function move(player:Entity)
    {
        var pos = em.getComponent(player, CPosition);
        var input = em.getComponent(player, CInput);

        // COLLISION X
        if(input.keyLeftIsDown) pos.dx -= 5;
        if(input.keyRightIsDown) pos.dx += 5;
        var newx = pos.x + pos.dx;

        if(collides(newx, pos.y))
        {
            var tpos = getTilePosition(newx, pos.y);

            if(pos.dx > 0)
            {
                newx = ((tpos[0] + 1) * World.TILE_SIZE) - World.TILE_SIZE;
            }
            if(pos.dx < 0)
            {
                newx = (tpos[0] + 1) * World.TILE_SIZE;
            }
        }

        // COLLISION Y
        if(input.keyUpIsDown) pos.dy -= 5;
        if(input.keyDownIsDown) pos.dy += 5;
        var newy = pos.y + pos.dy;

        if(collides(pos.x, newy))
        {
            var tpos = getTilePosition(pos.x, newy);

            if(pos.dy > 0)
            {
                newy = ((tpos[1] + 1) * World.TILE_SIZE) - World.TILE_SIZE;
            }
            else
            {
                newy = (tpos[1] + 1) * World.TILE_SIZE;
            }
        }

        if(newx != pos.x || newy != pos.y)
            pos.lastMove = Timer.getTime();

        pos.x = newx;
        pos.y = newy;
        pos.dx = 0;
        pos.dy = 0;
    }

    public function processEntities()
    {
        #if client
        var allInputs = em.getEntitiesWithComponent(CInput);
        for(player in allInputs)
        {
            move(player);
        }
        #end

        #if server
        var allMovingObjects = em.getEntitiesWithComponent(CMovingObject);
        for(object in allMovingObjects)
        {
            var pos = em.getComponent(object, CPosition);
            var tpos = getTilePosition(pos.x, pos.y);

            // BULLETS TO WORLD
            if(outsideMap(tpos[0], tpos[1]))
            {
                net.killEntityNow(object);
                continue;
            }

            if(World.map[tpos[0]][tpos[1]] != -1)
            {
                net.killEntityNow(object);
                continue;
            }

            // BULLETS TO PLAYERS
            // Mhhhhhhhhhh U_U
            var owner = em.getComponent(object, COwner).entity;
            var allPlayers = em.getEntitiesWithComponent(CPlayer);
            for(player in allPlayers)
            {
                if(owner == player) continue;

                var ppos = em.getComponent(player, CPosition);
                if(ppos.x < pos.x && pos.x < ppos.x + World.TILE_SIZE &&
                   ppos.y < pos.y && pos.y < ppos.y + World.TILE_SIZE)
                {
                    em.pushEvent("COLLISION", player, {owner:owner});
                    net.killEntityNow(object);
                    break;
                }
            }
        }
        #end
    }
}
