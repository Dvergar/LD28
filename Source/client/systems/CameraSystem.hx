package client.systems;

import motion.Actuate;
import flash.Lib;

import enh.Builders;
import enh.Timer;

import Client;
import Common;


class CameraSystem extends System<Client, EntityCreator>
{
    public function init() {}

    public function processEntities()
    {
        var allCams = em.getEntitiesWithComponent(CCamera);
        for(player in allCams)
        {
        	var pos = em.getComponent(player, CPosition);
        	var cam = em.getComponent(player, CCamera);

        	if(em.hasComponent(player, CScreenShake))
        	{
        		var ss = em.getComponent(player, CScreenShake);
	            if(Timer.getTime() - ss.shakeTime > 0.05)
	            {
	            	var warp = if(Std.random(2) == 0) -1 else 1;
	                cam.dx += Std.random(10) * warp;
	                cam.dy += Std.random(10) * warp;
	                ss.shakeTime = Timer.getTime();
	            }

	            if(Timer.getTime() - ss.startTime > 0.1)
	                em.removeComponentOfType(player, CScreenShake);
        	}

        	cam.dx += (pos.x - cam.x) * 0.1;
        	cam.dy += (pos.y - cam.y) * 0.1;

        	cam.x += cam.dx;
        	cam.y += cam.dy;

        	Client.viewport.x = Std.int(-cam.x + Lib.current.stage.stageWidth / 2);
        	Client.viewport.y = Std.int(-cam.y + Lib.current.stage.stageHeight / 2);

        	cam.dx = 0;
        	cam.dy = 0;
        }
    }
}