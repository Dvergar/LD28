import enh.EntityManager;
import enh.Builders;
import enh.Timer;

import Common;
import common.*;
import common.systems.*;

class Server extends Enh2<Server, EntityCreator>
{
    var netTime:Float;

    public function new()
    {
        super(this, EntityCreator);
    }

    public function init()
    {
        this.netTime = Timer.getTime();
        this.startServer("", 8008);
        // this.startServer("", 1111);

        new World();

        @addSystem CollisionSystem;
        @addSystem MovementSystem;
        @addSystem HealthSystem;
        @addSystem TimerSystem;

        @registerListener "CONNECTION";
        @registerListener "DISCONNECTION";
        @registerListener "BULLET_MAKE";
        @registerListener "NET_HELLO";
        @registerListener "PLAYER_UPDATE";
        @registerListener "PING";

        this.startLoop(loop, 1/60);
    }

    function onPing(entity:Entity, ev:Dynamic)
    {
        // trace("ping");
    }

    @msg('String')
    function onNetHello(entity:Entity, ev:Dynamic)
    {
        trace("onNetHello");
    }

    @left('Bool') @right('Bool') @up('Bool') @down('Bool') @flipped('Bool')
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
            pos.flipped = ev.flipped;
            collisionSystem.move(player);  // WOO CHEAT, workaround
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

        trace("player pos " +  pos);
        return [pos[0] * World.TILE_SIZE, pos[1] * World.TILE_SIZE];
    }

    @x('Short') @y('Short') @vx('Short') @vy('Short')
    function onBulletMake(player:Entity, ev:Dynamic)
    {
        if(em.hasComponent(player, CDead)) return;
        var ownerId = em.getIdFromEntity(player);
        var bullet = ec.bullet([ev.x, ev.y]);
        em.addComponent(bullet, new CMovingObject([ev.vx / 100, ev.vy / 100], 10));
        em.addComponent(bullet, new COwner(player));
        var id = em.setId(bullet);
        // trace("create bullet " + bullet);

        var playerPos = em.getComponent(player, CPosition);
        playerPos.dx -= ev.vx / 100 * 8;
        playerPos.dy -= ev.vy / 100 * 8;

        @RPC("BULLET_MAKE", ev.x, ev.y, ev.vx, ev.vy, ownerId, id)
                {x:Short, y:Short, vx:Short, vy:Short, ownerId:Short, id:Short};
    }

    function onConnection(conn:Entity, ev:Dynamic)
    {
        trace("onConnection " + conn);
        // net.sendWorldStateTo(conn);


        var newPos = getNewPlayerPosition();
        var player = net.createNetworkEntity("player", conn, [100, 100], true);
        net.setConnectionEntityFromTo(conn, player);

        // var player = ec.player([newPos[0], newPos[1]]);
        // em.addComponent(player, new CInput());
        // em.addComponent(player, new CCollidable());
        // var id = em.setId(player);

        // broadCastMyPlayerCreate(player);
        // broadCastPlayerCreate();
        // trace("new player " + newPos + " id " + id);
    }

    // public function broadCastMyPlayerCreate(player:String)
    // {
    //     var connId = net.connectionsByEntity[player].id;
    //     var id = em.getIdFromEntity(player);
    //     var pos = em.getComponent(player, CPosition);
    //     @RPC("PLAYER_CREATE", Std.int(pos.x), Std.int(pos.y), id, 0, connId)
    //             {x:Short, y:Short, id:Short, lvl:Short, connId:Short};

    // }

    public function broadCastPlayerCreate()
    {
        var allPlayers = em.getEntitiesWithComponent(CPlayer);
        for(otherPlayer in allPlayers)
        {
            var connId = net.connectionsByEntity[otherPlayer].id;
            var pos = em.getComponent(otherPlayer, CPosition);
            var lvl = em.getComponent(otherPlayer, CLevel).value;
            var otherId = em.getIdFromEntity(otherPlayer);

            @RPC("OTHER_PLAYER_CREATE", Std.int(pos.x), Std.int(pos.y), otherId, lvl, connId)
                    {x:Short, y:Short, id:Short, lvl:Short, connId:Short};
            trace("other player " + pos.x + " " + pos.y + " id " + otherId);
        }
    }

    function onDisconnection(player:Entity, ev:Dynamic)
    {
        trace("onDisconnection " + player);
        if(player == -1)
        {
            trace("entity hasn't probably entered the game yet, ignoring destruction");
            return;
        }

        var id = em.getIdFromEntity(player);
        em.killEntityNow(player);
        @RPC("PLAYER_DESTROY", id) {id:Short};
    }

    function loop():Void
    {
        timerSystem.processEntities();
        movementSystem.processEntities();
        collisionSystem.processEntities();
        healthSystem.processEntities();

        em.processKills();

        // if(Timer.getTime() - netTime > 1/20)
        // {   
        //     var allPlayers = em.getEntitiesWithComponent(CPlayer);
        //     for(player in allPlayers)
        //     {
        //         var id = em.getIdFromEntity(player);
        //         var pos = em.getComponent(player, CPosition);
        //         var hp = em.getComponent(player, CHealth);

        //         @RPC("PLAYER_UPDATE", Std.int(pos.x), Std.int(pos.y), Std.int(hp.value), id, pos.flipped)
        //                 {x:Short, y:Short, hp:Short, id:Short, flipped:Bool};
        //     }

        //     netTime = Timer.getTime();
        // }
    }

    static function main() {new Server();}
}