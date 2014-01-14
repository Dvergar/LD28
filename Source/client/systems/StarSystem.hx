package client.systems;

import motion.Actuate;
import flash.Lib;
import flash.display.Sprite;
import flash.display.Bitmap;
import openfl.Assets;

import enh.Builders;
import enh.Timer;

import Client;
import Common;


class StarSystem extends System<Client, EntityCreator>
{
    public function init() {}

    public function attachStarTo(entity:String)
    {
        // TODO : removecomponent when addcomponent in enh, to autdetach when overwriting component
        if(em.hasComponent(entity, CStar))
            em.removeComponentOfType(entity, CStar);

        var lvl = em.getComponent(entity, CLevel);
        trace("attachStarTo " + lvl.value);
        if(lvl.value == 0) return;
        trace("attach checked");

        var sprite = new Sprite();
        sprite.y -= 30;
        generateStars(lvl.value, sprite);

        var drawable = em.getComponent(entity, CDrawable);
        drawable.sprite.addChild(sprite);

        em.addComponent(entity, new CStar(sprite));
    }

    function generateStars(nb:Int, sprite:Sprite)
    {
        var x = 0;
        for(i in 0...nb)
        {
            trace("pouf");
            var bitmap = new Bitmap(Assets.getBitmapData("assets/star.png"));
            bitmap.x = x;

            sprite.addChild(bitmap);
            x += 16;
        }
    }

    public function processEntities()
    {
        // var allCams = em.getEntitiesWithComponent(CS);
        // for(player in allCams)
        // {

        // }
    }
}