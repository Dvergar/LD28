package;

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.geom.Rectangle;
import flash.display.DisplayObjectContainer;
import flash.net.Socket;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;
import flash.utils.ByteArray;
import flash.Lib;
import openfl.Assets;
import openfl.display.Tilesheet;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.media.Sound;

import motion.Actuate;

import enh.Builders;
import enh.Timer;
import enh.ClientManager;

import client.systems.*;
import Common;
import common.PyxelMapImporter;
import common.World;
import common.systems.*;


// Stole from another project
class Text extends TextField
{
    public function new(text:String, x:Float, y:Float,
                        ?size:Float, ?rawFont:Bool)
    {
        super();

        if(size == null) size = 10;

        var format = new TextFormat();
        // format.font = Assets.getFont("assets/Kirsty.ttf").fontName;
        if(!rawFont)
        {            
            var font = Assets.getFont("assets/small_hollows.ttf");
            format.font = font.fontName;
        }
        format.size = size;

        this.defaultTextFormat = format;
        this.embedFonts = true;
        this.selectable = false;
        this.textColor = 0x000000;
        this.text = text;
        this.autoSize = flash.text.TextFieldAutoSize.CENTER;
        this.x = x;
        this.y = y;
        
        this.mouseEnabled = false;
        this.cacheAsBitmap = true;
    }
}


class Messenger extends Text
{
    public function new()
    {
        super("Nope",
              Lib.current.stage.stageWidth / 2 - 20,
              Lib.current.stage.stageHeight - 80,
              30);
        this.visible = false;
    }

    public function say(txt:String, ?stay=false)
    {
        trace("say " + txt);
        Actuate.stop(this);
        this.alpha = 1;
        this.visible = true;
        this.text = txt;

        if(!stay)
            Actuate.tween(this, 10, {alpha: 0});
    }

    public function clear()
    {
        Actuate.stop(this);
        this.visible = false;
    }
}


// Stole from another project
class Bar extends Sprite
{
    public var content:Sprite;

    public function new(color:Int, width:Int, height:Int, border:Bool=true,
                                                         center:Bool=false)
    {
        super();
        var bsize:Int = 2;
        var marginX = 0.0;
        var marginY = 0.0;

        if(center)
        {
            marginX = width / 2;
            marginY = height / 2;
        }

        // DRAW BAR
        if(border) {
            this.graphics.lineStyle(bsize, 0xE8E8E8);
            this.graphics.beginFill(0xD1D1D1);
            this.graphics.drawRect(0, 0, width, height);
            this.graphics.endFill();
        }

        // BACKGROUND
        this.content = new Sprite();
        this.content.graphics.beginFill(color);
        this.content.graphics.drawRect(-marginX, -marginY,
                    width - bsize, height - bsize);
        this.content.graphics.endFill();
        this.content.x = bsize / 2;
        this.content.y = bsize / 2;
        this.addChild(this.content);
    }

    public function resize(size)
    {
        this.content.scaleX = size;
    }
}


class CHealthBar extends Component
{
    public var o:Bar;

    public function new(bar:Bar)
    {
        super();
        this.o = bar;
    }
}


// Workaround
class CMyBullet extends Component
{
    public function new()
    {
        super();
    }
}


class CMyPlayer extends Component
{
    public function new()
    {
        super();
    }
}


class CScreenShake extends Component
{
    public var startTime:Float;
    public var shakeTime:Float;

    public function new()
    {
        super();
        this.shakeTime = Timer.getTime();
        this.startTime = Timer.getTime();
    }
}


class CCamera extends Component
{
    public var x:Float;
    public var y:Float;
    public var dx:Float;
    public var dy:Float;

    public function new()
    {
        super();
        this.x = 0;
        this.y = 0;
        this.dx = 0;
        this.dy = 0;
    }
}


class CInterpolation extends Component
{
    public var x:Float;
    public var y:Float;

    public function new(x:Float, y:Float)
    {
        super();
        this.x = x;
        this.y = y;
    }
}

class CGhost extends Component
{
    public var entity:Entity;

    public function new(entity:Entity)
    {
        super();
        this.entity = entity;
    }
}


class CStar extends Component
{
    public var sprite:Sprite;

    public function new(sprite:Sprite)
    {
        super();
        this.sprite = sprite;
    }

    public override function _detach()
    {
        this.sprite.parent.removeChild(this.sprite);
    }
}


class CAnimation extends Component
{
    public var idle:Bitmap;
    public var frames:Array<Bitmap>;
    public var frameTime:Float;
    public var pointer:Int;

    public function new()
    {
        super();

        this.frameTime = enh.Timer.getTime();
        this.pointer = 0;
    }
}


class CDrawable extends Component
{
    public var sprite:Sprite;
    public var parent:DisplayObjectContainer;
    public var bitmap:Bitmap;

    public function new(sprite:Sprite, ?parent:DisplayObjectContainer)
    {
        super();

        this.sprite = sprite;

        if(parent == null) parent = Client.viewport;
        parent.addChild(sprite);

        this.parent = parent;
    }

    public override function _detach()
    {
        // this.parent.removeChild(this.sprite);
        this.sprite.parent.removeChild(this.sprite);
    }
}


class DrawableSystem extends System<Client, EntityCreator>
{
    public function init() {}

    public function processEntities()
    {
        var allDrawables = em.getEntitiesWithComponent(CDrawable);
        for(entity in allDrawables)
        {
            var drawable = em.getComponent(entity, CDrawable);
            var pos = em.getComponent(entity, CPosition);

            if(em.hasComponent(entity, CInterpolation))
            {
                // trace("pos " + pos.x + " / " + pos.y);
                drawable.sprite.x += (pos.x - drawable.sprite.x) * 0.3;
                drawable.sprite.y += (pos.y - drawable.sprite.y) * 0.3;
            }
            else
            {
                drawable.sprite.x = pos.x;
                drawable.sprite.y = pos.y;
            }
        }
    }
}


class SoundManager
{
    public static var poc:Sound;
    public static var flop:Sound;
    public static var pew:Sound;

    public function new()
    {
        SoundManager.poc = Assets.getSound("assets/poc.wav");
        SoundManager.flop = Assets.getSound("assets/poc.wav");
        SoundManager.pew = Assets.getSound("assets/pew.wav");
    }
}


class Client extends Enh2<Client, EntityCreator>
{
    public static var emm:enh.EntityManager;
    var tilesheet:Tilesheet;
    var myPlayer:String;
    var myGhost:String;
    var myId:Int;
    var pingTime:Float;
    public static var msn:Messenger;
    public static var viewport:Sprite;

    public function new()
    {
        super(this, EntityCreator);
    }

    public function init()
    {
        trace("myplayer " + myPlayer);
        // connect("192.168.1.4", 1111);
        connect("192.168.1.4", 8008);
        // connect("90.51.4.31", 8008);
        Client.msn = new Messenger();
        Client.viewport = new Sprite();
        Client.emm = em; // damn workaround
        new SoundManager();
        msn.say("HELLO");

        @addSystem DrawableSystem;
        @addSystem CollisionSystem;
        @addSystem InputSystem;
        @addSystem AnimationSystem;
        @addSystem MovementSystem;
        @addSystem TimerSystem;
        @addSystem CameraSystem;
        @addSystem InterpolationSystem;
        @addSystem StarSystem;
        @addSystem GhostSystem;
        #if standalone
        @addSystem HealthSystem;
        #end

        @registerListener "NET_ACTION_LOL";
        @registerListener "OTHER_PLAYER_CREATE";
        // @registerListener "PLAYER_UPDATE";
        @registerListener "BULLET_MAKE";
        @registerListener "CONNECTION";
        @registerListener "PLAYER_CREATE";
        @registerListener "PLAYER_DESTROY";
        @registerListener "BULLET_DESTROY";
        @registerListener "PLAYER_KILL";
        @registerListener "NEW_ROUND";

        this.em.registerListener("CONNECTION", onConnection);
        this.tilesheet = loadMapTilesheet();
        this.pingTime = Timer.getTime();

        #if standalone
        myPlayer = ec.player([70, 70]);
        em.addComponent(myPlayer, new CInput());

        ec.player([70, 70]);
        #end

        // Lib.current.stage.addChild(new openfl.display.FPS());
        Lib.current.graphics.clear();
        Lib.current.stage.addChild(Client.viewport);
        tilesheet.drawTiles(Client.viewport.graphics, World.tileSheetArray);
        Lib.current.stage.addChild(Client.msn);

        startLoop(loop, 1/60);
    }

    function onNewRound(entity:Entity, ev:Dynamic)
    {
        trace("new round");

        msn.say("NEW ROUND");

        var allPlayers = em.getEntitiesWithComponent(CPlayer);
        for(player in allPlayers)
        {
            em.killEntityNow(player);
        }

        // Workaround, should handle components a bit better
        var deadPlayers = em.getEntitiesWithComponent(CDead);
        for(player in deadPlayers)
        {
            em.killEntityNow(player);
        }
        
        var ghost = em.getEntitiesWithComponent(CGhost).next();
        em.killEntityNow(ghost);

        myPlayer = null;
    }

    @id('Short') @ownerId('Short') @lvl('Short')
    function onPlayerKill(entity:Entity, ev:Dynamic)
    {
        function switchCamera()
        {
            var playerObserved = em.getEntitiesWithComponent(CCamera).next();
            em.removeComponentOfType(playerObserved, CCamera);

            var allPlayers = em.getEntitiesWithComponent(CPlayer);
            for(player in allPlayers)
            {
                if(!em.hasComponent(player, CDead))
                {
                    em.addComponent(player, new CCamera());
                    break;
                }
            }

            msn.say("SPECTATING", true);
        }

        // DEAD PLAYER
        var player = em.getEntityFromId(ev.id);
        em.addComponent(player, new CDead());
        em.removeComponentOfType(player, CPlayer);

        // SPAWN BODY
        var pos = em.getComponent(player, CPosition);
        ec.deadBody([Std.int(pos.x), Std.int(pos.y)]);

        // CAMERA
        if(ev.id == myId)
        {
            em.removeComponentOfType(player, CInput);
            pos.x = 9000;
            pos.y = 9000;

            switchCamera();
        }
        else
        {
            if(em.hasComponent(player, CCamera)) switchCamera();
        }

        // LEVEL UP
        var owner = em.getEntityFromId(ev.ownerId);
        em.addComponent(owner, new CLevel(ev.lvl));
        starSystem.attachStarTo(owner);

        if(ev.ownerId == myId)
            setBulletRateForLevel(ev.lvl);

        trace("playerkill");
    }

    function setBulletRateForLevel(lvl:Int)
    {
        inputSystem.bulletRate = 0.3 - lvl * 0.05;  // CLIENT SIDE THIS SUCKS I KNOW
    }

    @x('Short') @y('Short') @id('Short') @lvl('Short') @connId('Short')
    function onOtherPlayerCreate(entity:Entity, ev:Dynamic)
    {
        onPlayerCreate(entity, ev);
    }

    function onPlayerCreate(player:Entity, ev:Dynamic)
    {
        trace("player create " + player + " ./ " + ev.id);
        if(ev.id == ClientManager.myId)
        {
            trace("myplayer");
            // myId = ev.id;
            // em.setId(player, ev.id);
            // em.addComponent(player, new CInput());
            em.addComponent(player, new CCamera());
            em.addComponent(player, new CMyPlayer());
            em.addComponent(player, new CLevel(ev.lvl));
            starSystem.attachStarTo(player);
            setBulletRateForLevel(ev.lvl);

            // GHOST
            var ghost = ec.player([ev.x, ev.y]);
            em.addComponent(ghost, new CGhost(player));
            em.addComponent(ghost, new CInterpolation(0, 0));
            var drawable = em.getComponent(ghost, CDrawable);
            drawable.sprite.alpha = 0.5;
            // drawable.sprite.alpha = 0;
            // drawable.sprite.visible = false;
        }
    }

    // @x('Short') @y('Short') @id('Short') @lvl('Short') @connId('Short')
    // function onPlayerCreate(entity:Entity, ev:Dynamic)
    // {
    //     trace("onPlayerCreate " + ev.connId);
    //     if(ClientManager.myId == ev.connId)
    //     {
    //         if(myPlayer != null) return;
    //         trace("new player");

    //         // GHOST
    //         myGhost = ec.player([ev.x, ev.y]);
    //         em.addComponent(myGhost, new CGhost());
    //         em.addComponent(myGhost, new CInterpolation(ev.x, ev.y));
    //         em.removeComponentOfType(myGhost, CPlayer);
    //         var drawable = em.getComponent(myGhost, CDrawable);
    //         // drawable.sprite.alpha = 0.5;
    //         drawable.sprite.alpha = 0;
    //         drawable.sprite.visible = false;

    //         // ME
    //         myPlayer = ec.player([ev.x, ev.y]);
    //         myId = ev.id;
    //         em.setId(myPlayer, ev.id);
    //         em.addComponent(myPlayer, new CInput());
    //         em.addComponent(myPlayer, new CCamera());
    //         em.addComponent(myPlayer, new CMyPlayer());
    //         em.addComponent(myPlayer, new CLevel(ev.lvl));
    //         starSystem.attachStarTo(myPlayer);
    //         setBulletRateForLevel(ev.lvl);

    //         return;
    //     }
    //     // trace("humpf " + em.getEntityFromId(ev.id));
    //     else if(em.getEntityFromId(ev.id) == null)
    //     {
    //         trace("other player " + ev.lvl);
    //         var player = ec.player([ev.x, ev.y]);
    //         em.addComponent(player, new CLevel(ev.lvl));
    //         em.addComponent(player, new CCollidable());
    //         em.addComponent(player, new CInterpolation(ev.x, ev.y));
    //         em.setId(player, ev.id);
    //         starSystem.attachStarTo(player);
    //     }
    //     else
    //     {
    //         trace("NOPE CREATION " + em.getEntityFromId(ev.id));
    //     }

    //     // var allPlayers = em.getAllComponentsOfType(CPlayer);
    //     // var nbPlayers = 0;
    //     // for(player in allPlayers) nbPlayers++;
    //     // trace("players nb " + nbPlayers);
    // }

    // @x('Short') @y('Short') @hp('Short') @id('Short') @flipped('Bool')
    // function onPlayerUpdate(connection:String, ev:Dynamic)
    // {
    //     var entity = em.getEntityFromId(ev.id);
    //     // trace("entity update " + entity);

    //     if(ev.id == myId)
    //     {
    //         var pos = em.getComponent(myGhost, CPosition);
    //         var hp = em.getComponent(myGhost, CHealth);
    //         var interp = em.getComponent(myGhost, CInterpolation);

    //         pos.flipped = ev.flipped;
    //         interp.x = ev.x;
    //         interp.y = ev.y;
    //         hp.future = ev.hp;
    //     }
    //     else
    //     {
    //         var interp = em.getComponent(entity, CInterpolation);
    //         interp.x = ev.x;
    //         interp.y = ev.y;
    //     }
        
    //     var pos = em.getComponent(entity, CPosition);
    //     var hp = em.getComponent(entity, CHealth);

    //     pos.flipped = ev.flipped;
    //     hp.future = ev.hp;
    // }

    @x('Short') @y('Short') @vx('Short') @vy('Short') @ownerId('Short') @id('Short')
    function onBulletMake(entity:Entity, ev:Dynamic)
    {
        if(myId == ev.ownerId) return;

        // trace("bulletmake");
        var bullet = ec.bullet([ev.x, ev.y]);
        em.addComponent(bullet, new CMovingObject([ev.vx / 100, ev.vy / 100], 10));
        em.setId(bullet, ev.id);

        SoundManager.flop.play();
    }

    @id('Short')
    function onBulletDestroy(entity:Entity, ev:Dynamic)
    {
        // if(myId == ev.ownerId) return;
        // trace("onBulletDestroy");
        SoundManager.flop.play();
        var bullet:Null<Entity> = em.getEntityFromId(ev.id);
        if(bullet == null) return;
        em.killEntity(bullet);

    }

    @id('Short')
    function onPlayerDestroy(entity:Entity, ev:Dynamic)
    {
        // trace("onPlayerDestroy");
        var player = em.getEntityFromId(ev.id);
        em.killEntity(player);
    }

    function loadMapTilesheet()
    {
        new World();
        var bd = Assets.getBitmapData("assets/tileset.png");
        return makeTilesheet(bd);
    }

    private function makeTilesheet(bd:BitmapData) {
        var tilesheet = new Tilesheet(bd);
        var tilesWide = Std.int(bd.width / World.TILE_SIZE);
        var tilesHigh = Std.int(bd.height / World.TILE_SIZE);

        for(posy in 0...tilesHigh) {
            for(posx in 0...tilesWide) {
                var rect = new Rectangle(posx * World.TILE_SIZE,
                                         posy * World.TILE_SIZE,
                                         World.TILE_SIZE,
                                         World.TILE_SIZE);
                tilesheet.addTileRect(rect);
            }
        }

        return tilesheet;
    }

    @hp('Int') @msg('String')
    private function onNetActionLol(entity:Entity, ev:Dynamic)
    {
        trace("onNetActionLol");
    }

    private function onConnection(entity:Entity, ev:Dynamic)
    {
        trace("connected " + ClientManager.myId);
        @RPC("NET_HELLO", "Hoy") {msg:String};

    }


    private function loop()
    {
        timerSystem.processEntities();
        inputSystem.processEntities();
        movementSystem.processEntities();
        collisionSystem.processEntities();
        ghostSystem.processEntities();
        // interpolationSystem.processEntities();
        drawableSystem.processEntities();
        animationSystem.processEntities();
        cameraSystem.processEntities();

        em.processKills();

        var allInputs = this.em.getEntitiesWithComponent(CMyPlayer);
        for(player in allInputs)
        {
            var pos = em.getComponent(player, CPosition);
            var input = em.getComponent(player, CInput);
            @RPC("PLAYER_UPDATE", input.keyLeftIsDown,
                                  input.keyRightIsDown,
                                  input.keyUpIsDown,
                                  input.keyDownIsDown,
                                  pos.flipped)
                    {left:Bool, right:Bool, up:Bool, down:Bool, flipped:Bool};
        }

        // WORKAROUND
        if(Timer.getTime() - pingTime > 1)
        {
            @RPC("PING") {};
            pingTime = Timer.getTime();
        }
    }
}