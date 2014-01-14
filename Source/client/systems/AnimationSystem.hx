package client.systems;

import flash.geom.ColorTransform;
import motion.Actuate;

import enh.Builders;
import enh.Timer;

import Client;
import Common;


class AnimationSystem extends System<Client, EntityCreator>
{
    var hitColor:ColorTransform;
    var nohitColor:ColorTransform;

    public function init()
    {
        nohitColor = new ColorTransform();
        hitColor = new ColorTransform();
        hitColor.redOffset = 100;
    }

    public function getNextFrame(anim:CAnimation)
    {
    	anim.pointer++;
    	if(anim.pointer > 1) anim.pointer = 0;
    	return anim.frames[anim.pointer];
    }

    public function processEntities()
    {
        var allAnims = em.getEntitiesWithComponent(CAnimation);
        for(player in allAnims)
        {
            if(em.hasComponent(player, CDead)) continue;

        	var pos = em.getComponent(player, CPosition);
        	var anim = em.getComponent(player, CAnimation);
            var drawable = em.getComponent(player, CDrawable);
            var dx = pos.x - pos.oldx;
            var dy = pos.y - pos.oldy;

            // if(em.hasComponent(player, CGhost))
            // {
            //     trace("pos " + pos.x + " / " + pos.y + " # old " + pos.oldx + " / " + pos.oldy);
            // }

            if((dx > 1 || dx < -1 || dy > 1 || dy < -1) && Timer.getTime() - anim.frameTime > 0.1)
            {
                var newBitmap = getNextFrame(anim);

                drawable.sprite.removeChild(drawable.bitmap);
                drawable.bitmap = newBitmap;
                drawable.sprite.addChild(drawable.bitmap);

                anim.frameTime = Timer.getTime();
            }

            if(dx < 1 && dx > -1 && dy < 1 && dy > -1)
            {
                if(drawable.bitmap != anim.idle)
                {
                    var newBitmap = anim.idle;

                    drawable.sprite.removeChild(drawable.bitmap);
                    drawable.bitmap = newBitmap;
                    drawable.sprite.addChild(drawable.bitmap);
                }
            }

            if(pos.flipped)
            {
                drawable.sprite.scaleX = -1;
                drawable.bitmap.x = -drawable.bitmap.width;
            }
            else
            {
                drawable.sprite.scaleX = 1;
                drawable.bitmap.x = 0;
            }
        }

        var allHealthBars = em.getEntitiesWithComponent(CHealthBar);
        for(player in allHealthBars)
        {
            var pos = em.getComponent(player, CPosition);
            var hp = em.getComponent(player, CHealth);
            var healthBar = em.getComponent(player, CHealthBar).o;

            if(pos.flipped)
            {
                healthBar.scaleX = -1;
            }
            else
            {
                healthBar.scaleX = 1;
            }

            
            if(hp.future < hp.value)
            {
                var drawable = em.getComponent(player, CDrawable);
                drawable.sprite.transform.colorTransform = hitColor;
                em.addComponent(player, new CTimer(onCollisionEnd.bind(player), 0.1));
            }

            
            // HPBAR
            healthBar.resize(hp.value / 100);
            hp.value = hp.future;
        }

        var stars = em.getEntitiesWithComponent(CStar);
        for(player in stars)
        {
            var pos = em.getComponent(player, CPosition);
            var star = em.getComponent(player, CStar);

            if(pos.flipped)
            {
                star.sprite.scaleX = -1;
            }
            else
            {
                star.sprite.scaleX = 1;
            }
        }
    }

    function onCollisionEnd(entity:String)
    {
        // trace("onCollisionEnd");
        var drawable = em.getComponent(entity, CDrawable);
        drawable.sprite.transform.colorTransform = nohitColor;
    }
}
