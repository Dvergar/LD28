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
import enh.Constants;

import client.systems.*;
import Common;
import common.PyxelMapImporter;
import common.World;
import common.systems.*;


class Text extends TextField
{
    public function new(text:String, ?x:Float, ?y:Float,
                        ?size:Float, ?color:Int, ?fontPath:String)
    {
        super();

        if(fontPath == null) fontPath = "assets/small_hollows.ttf";
        if(color == null) color = 0x000000;
        if(size == null) size = 10;

        var font = Assets.getFont(fontPath);
        var format = new TextFormat();
        format.font = font.fontName;
        format.size = size;

        this.defaultTextFormat = format;
        this.embedFonts = true;
        this.selectable = false;
        this.textColor = color;
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

            drawable.sprite.x = pos.x;
            drawable.sprite.y = pos.y;
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
    var tilesheet:Tilesheet;
    var myPlayer:Entity = -1;
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
        Client.msn = new Messenger();
        Client.viewport = new Sprite();
        new SoundManager();

        connect("192.168.1.4", 8008);
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

        @registerListener "CONNECTION";
        @registerListener "PLAYER_CREATE";
        @registerListener "PLAYER_KILL";
        @registerListener "NEW_ROUND";

        this.tilesheet = loadMapTilesheet();
        this.pingTime = Timer.getTime();

        Lib.current.graphics.clear();
        Lib.current.stage.addChild(Client.viewport);
        Lib.current.stage.addChild(Client.msn);

        tilesheet.drawTiles(Client.viewport.graphics, World.tileSheetArray);
        startLoop(loop, 1/60);
    }

    function onNewRound(entity:Entity, ev:Dynamic)
    {
        msn.say("NEW ROUND");

        // REMOVE CAMERA
        var focusedEntity = em.getEntitiesWithComponent(CCamera).next();
        em.removeComponentOfType(focusedEntity, CCamera);

        // RESET PLAYER PROPERTIES
        var allPlayers = em.getEntitiesWithComponent(CPlayer);
        for(player in allPlayers)
        {
            // REMOVE DEAD STATE
            if(em.hasComponent(player, CDead))
            {
                em.removeComponentOfType(player, CDead);
                em.addComponent(player, new CLevel(0));
                starSystem.attachStarTo(player);
            }

            // RESET MY PLAYER STATE
            if(em.hasComponent(player, CMyPlayer))
            {
                em.addComponent(player, new CCamera());
                em.addComponent(player, new CInput());
            }

            em.addComponent(player, new CPlayer());
        }
    }

    @killerId('Short') @lvl('Short')
    function onPlayerKill(dead:Entity, ev:Dynamic)
    {
        trace("onPlayerKill");
        
        function switchCamera()
        {
            var playerObserved = em.getEntitiesWithComponent(CCamera).next();
            em.removeComponentOfType(playerObserved, CCamera);

            var allPlayers = em.getEntitiesWithComponent(CPlayer);
            for(player in allPlayers)
            {
                if(!em.hasComponent(player, CDead) &&
                   !em.hasComponent(player, CGhost))
                {
                    em.addComponent(player, new CCamera());
                    break;
                }
            }

            msn.say("SPECTATING", true);
        }

        // DEAD PLAYER
        em.addComponent(dead, new CDead());

        // SPAWN BODY
        var pos = em.getComponent(dead, CPosition);
        ec.deadBody([Std.int(pos.x), Std.int(pos.y)]);

        // CAMERA
        if(dead == myPlayer)
        {
            trace("myplayer delete");
            em.removeComponentOfType(dead, CInput);
            pos.x = 9000;
            pos.y = 9000;

            switchCamera();
        }
        else
        {
            if(em.hasComponent(dead, CCamera)) switchCamera();
        }

        // LEVEL UP
        var killer = em.getEntityFromId(ev.killerId);
        em.addComponent(killer, new CLevel(ev.lvl));
        starSystem.attachStarTo(killer);

        if(killer == myPlayer)
            Upgrade.level(myPlayer, ev.lvl);
            gotoFail();
    }

    function onPlayerCreate(player:Entity, ev:Dynamic)
    {
        trace("player create " + player + " / " +
              ev.id + " xy " + ev.x + " / " + ev.y);

        if(myPlayer == -1)
        {
            trace("myPlayer spawn");
            myPlayer = player;

            em.addComponent(player, new CCamera());
            em.addComponent(player, new CMyPlayer());
            em.addComponent(player, new CLevel(ev.lvl));
            em.addComponent(player, new CInput());
            starSystem.attachStarTo(player);

            // GHOST
            var ghost = ec.player([ev.x, ev.y]);
            em.addComponent(ghost, new CGhost(player));
            em.addComponent(ghost, new CInterpolation(0, 0));
            var drawable = em.getComponent(ghost, CDrawable);
            drawable.sprite.alpha = 0.5;

            // drawable.sprite.alpha = 0;
            // drawable.sprite.visible = false;
        }
        else
        {
            em.addComponent(player, new CInterpolation(ev.x, ev.y));
        }
    }

    function loadMapTilesheet()
    {
        new World();
        var bd = Assets.getBitmapData("assets/tileset.png");
        return makeTilesheet(bd);
    }

    function makeTilesheet(bd:BitmapData) {
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

    function onConnection(entity:Entity, ev:Dynamic)
    {
        trace("onConnection");
    }

    function loop()
    {
        timerSystem.processEntities();
        inputSystem.processEntities();
        movementSystem.processEntities();
        collisionSystem.processEntities();
        ghostSystem.processEntities();
        interpolationSystem.processEntities();
        drawableSystem.processEntities();
        animationSystem.processEntities();
        cameraSystem.processEntities();

        em.processKills();

        var allInputs = this.em.getEntitiesWithComponent(CInput);
        for(player in allInputs)
        {
            var pos = em.getComponent(player, CPosition);
            var input = em.getComponent(player, CInput);

            @RPC("PLAYER_UPDATE", myPlayer,
                                  input.keyLeftIsDown,
                                  input.keyRightIsDown,
                                  input.keyUpIsDown,
                                  input.keyDownIsDown,
                                  input.mouseIsDown,
                                  input.mouseX,
                                  input.mouseY,
                                  pos.flipped)
                    {left:Bool,
                     right:Bool,
                     up:Bool,
                     down:Bool,
                     mouse:Bool,
                     mouseX:Short,
                     mouseY:Short,
                     flipped:Bool};
        }

        // WORKAROUND
        if(Timer.getTime() - pingTime > 1)
        {
            @RPC("PING", CONST.DUMMY) {};
            pingTime = Timer.getTime();
        }
    }

    function gotoFail(){};
}