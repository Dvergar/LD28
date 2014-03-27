import enh.Builders;
import enh.Timer;

#if (flash || openfl)
import flash.display.Shape;
import flash.display.Bitmap;
import flash.display.Sprite;
import openfl.Assets;
import Client;
#end

import common.World;


class CTimer extends Component {
    public var creationTime:Float;
    public var callFunction:Void -> Void;
    public var delay:Float;

    public function new(f:Void -> Void, delay:Float) {
        super();
        this.creationTime = Timer.getTime();
        this.callFunction = f;
        this.delay = delay;
    }
}


class CDead extends Component
{
    public function new()
    {
        super();
    }
}


class CLevel extends Component
{
    public var value:Int;

    public function new(value:Int)
    {
        super();
        this.value = value;
    }
}


class COwner extends Component
{
    public var entity:Entity;

    public function new(entity:Entity)
    {
        super();
        this.entity = entity;
    }
}


class CPlayer extends Component
{
    public function new() {
        super();
    }
}


class CBullet extends Component
{
    public function new() {
        super();
    }
}


class CCollidable extends Component
{
    public function new() {
        super();
    }
}


class CBulletRate extends Component
{
    public var value:Float;

    public function new(value:Float) {
        super();
        this.value = value;
    }
}


@networked
class CHealth extends Component
{
    @int public var value:Float;
    public var past:Float;
    public var regen:Float;

    public function new(value:Int) {
        super();
        this.value = value;
        this.past = value;
        this.regen = 0.03;
    }
}

@networked
class CMovingObject extends Component
{
    @float public var vx:Float;
    @float public var vy:Float;
    @short public var speed:Int;

    public function new(?vx:Float, ?vy:Float, ?speed:Int)
    {
        super();
        this.vx = vx;
        this.vy = vy;
        this.speed = speed;
    }
}

@networked
class CPosition extends Component
{
    @short("netx") public var x:Float;
    @short("nety") public var y:Float;
    @bool("netFlipped") public var flipped:Bool;
    public var dx:Float;
    public var dy:Float;
    public var oldx:Float;
    public var oldy:Float;
    public var netx:Float;
    public var nety:Float;
    public var netFlipped:Bool;
    public var lastMove:Float;

    public function new(x:Float, y:Float)
    {
        super();
        this.x = x;
        this.y = y;
        this.flipped = false;
        this.dx = 0;
        this.dy = 0;
        this.oldx = x;
        this.oldy = y;
        this.netx = x;
        this.nety = y;
        this.lastMove = Timer.getTime();
    }
}


class CInput extends Component 
{
    public var keyIsDown:Bool;
    public var keyLeftIsDown:Bool;
    public var keyRightIsDown:Bool;
    public var keyUpIsDown:Bool;
    public var keyDownIsDown:Bool;
    public var keyAction:Bool;
    public var mouseIsDown:Bool;
    public var lastActionTime:Float;
    public var updated:Bool;
    public var mouseX:Short;
    public var mouseY:Short;

    public function new()
    {
        super();
        this.keyIsDown = false;
        this.keyLeftIsDown = false;
        this.keyRightIsDown = false;
        this.keyUpIsDown = false;
        this.keyDownIsDown = false;
        this.keyAction = false;
        this.mouseIsDown = false;
        this.lastActionTime = Timer.getTime();
        this.updated = false;
        this.mouseX = 0;
        this.mouseY = 0;
    }
}


class Upgrade
{
    static public function level(em, entity:Entity, lvl:Int)
    {
        em.getComponent(entity, CBulletRate).value = 0.3 - lvl * 0.05;
        trace("LEVEL UP " +  em.getComponent(entity, CBulletRate).value);
    }
}


class EntityCreator extends EntityCreatowr
{
    public function new() {
        super();
    }

    @networked
    public function player(args:Array<Int>):Entity
    {
        var x = args[0];
        var y = args[1];

        var player = em.createEntity();
        trace("player spawn at : " + args + " # " + player);
        @sync em.addComponent(player, new CPosition(x, y));
        @sync em.addComponent(player, new CHealth(100));
        em.addComponent(player, new CPlayer());
        em.addComponent(player, new CLevel(0));
        em.addComponent(player, new CBulletRate(0.3));
        #if server
        em.addComponent(player, new CInput());
        #end

        #if client
        // ANIMATION FRAMES
        var bitmapFrames = [];
        bitmapFrames.push(new Bitmap(
                            Assets.getBitmapData("assets/soldier_anim1.png")));
        bitmapFrames.push(new Bitmap(
                            Assets.getBitmapData("assets/soldier_anim2.png")));
        var bitmapIdle = new Bitmap(
                            Assets.getBitmapData("assets/soldier_idle.png"));

        var anim = em.addComponent(player, new CAnimation());
        anim.idle = bitmapIdle;
        anim.frames = bitmapFrames;

        var sprite = new Sprite();
        sprite.addChild(bitmapIdle);

        var drawable = em.addComponent(player, new CDrawable(sprite));
        drawable.bitmap = bitmapIdle;

        // HEALTHBAR
        var healthBar = new Bar(0xE32424, 16 * 4, 6);
        healthBar.y -= 10;
        drawable.sprite.addChild(healthBar);
        em.addComponent(player, new CHealthBar(healthBar));
        #end

        return player;
    }

    @networked
    public function bullet(args:Array<Int>):Entity
    {
        trace("bullet " + args);
        var x = args[0];
        var y = args[1];

        var bullet = em.createEntity();
        em.addComponent(bullet, new CPosition(x, y));
        em.addComponent(bullet, new CBullet());

        #if client
        var bitmap = new Bitmap(Assets.getBitmapData("assets/bullet.png"));
        var sprite = new Sprite();
        sprite.addChild(bitmap);
        var drawable = em.addComponent(bullet, new CDrawable(sprite));
        #end

        return bullet;
    }

    #if client
    public function deadBody(args:Array<Int>):Entity
    {
        var x = args[0];
        var y = args[1];

        var deadBody = em.createEntity();
        em.addComponent(deadBody, new CPosition(x, y));

        var sprite = new Sprite();
        var bitmap = new Bitmap(
                        Assets.getBitmapData("assets/soldier_dead.png"));
        sprite.addChild(bitmap);
        var drawable = em.addComponent(deadBody, new CDrawable(sprite));

        return deadBody;
    }
    #end
}


