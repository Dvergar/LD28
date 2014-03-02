import enh.EntityManager;
import enh.Builders;
import enh.Timer;
import enh.Constants;

import Common;
import common.*;
import common.systems.*;


class Server extends Enh2<Server, EntityCreator>
{
    public function new()
    {
        super(this, EntityCreator);
    }

    public function init()
    {
        this.startServer("", 8008);

        new World();

        @addSystem CollisionSystem;
        @addSystem MovementSystem;
        @addSystem HealthSystem;
        @addSystem TimerSystem;
        @addSystem InputSystem;

        @registerListener "CONNECTION";
        @registerListener "DISCONNECTION";
        @registerListener "PLAYER_UPDATE";
        @registerListener "PING";

        this.startLoop(loop, 1/60);
    }

    function onPing(entity:Entity, ev:Dynamic) {}

    @left('Bool') @right('Bool') @up('Bool') @down('Bool') @mouse('Bool') @mouseX('Short') @mouseY('Short') @flipped('Bool')
    function onPlayerUpdate(player:Entity, ev:Dynamic)
    {
        var id = em.getIdFromEntity(player);
        var hp = em.getComponent(player, CHealth);
        var pos = em.getComponent(player, CPosition);

        if(!em.hasComponent(player, CDead))
        {
            var input = em.getComponent(player, CInput);

            input.keyLeftIsDown = ev.left;
            input.keyRightIsDown = ev.right;
            input.keyUpIsDown = ev.up;
            input.keyDownIsDown = ev.down;
            input.mouseIsDown = ev.mouse;
            input.mouseX = ev.mouseX;
            input.mouseY = ev.mouseY;

            pos.flipped = ev.flipped;
            collisionSystem.move(player);  // Not speedhack-proof
        }
    }

    public static inline function getNewPlayerPosition()
    {
        function getPos()
        {
            var x = Std.random(PyxelMapImporter.TILES_WIDE - 4) + 1; // ?
            var y = Std.random(PyxelMapImporter.TILES_HIGH - 4) + 1;
            
            return [x, y];
        }

        var pos = getPos();

        while(World.map[pos[0]][pos[1]] == 0)
            pos = getPos();

        trace("New player position " +  pos);
        return [pos[0] * World.TILE_SIZE, pos[1] * World.TILE_SIZE];
    }

    function onConnection(connectionEntity:Entity, ev:Dynamic)
    {
        trace("onConnection " + connectionEntity);

        var newPos = getNewPlayerPosition();
        var player = net.createNetworkEntity("player",
                                             null,
                                             [100, 100],
                                             true);
        net.setConnectionEntityFromTo(connectionEntity, player);
        net.sendWorldStateTo(player);
    }


    function onDisconnection(player:Entity, ev:Dynamic)
    {
        trace("onDisconnection " + player);
        if(player == -1)
        {
            trace("entity hasn't probably entered the game yet,
                   ignoring destruction");
            return;
        }

        net.killEntityNow(player);
    }

    function loop():Void
    {
        timerSystem.processEntities();
        inputSystem.processEntities();
        movementSystem.processEntities();
        collisionSystem.processEntities();
        healthSystem.processEntities();

        em.processKills();
    }

    static function main() {new Server();}
}