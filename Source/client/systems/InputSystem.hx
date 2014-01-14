package client.systems;

import enh.Builders;
import enh.Timer;

import Common;
import Client;
import common.World;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import flash.Lib;


class InputSystem extends System<Client, EntityCreator>
{
    public var bulletRate:Float;

    public function init()
    {
        this.bulletRate = 0.3;

        Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    }

    private function onMouseMove(event:MouseEvent)
    {
        var allInputs = this.em.getEntitiesWithComponent(CInput);
        for(input in allInputs)
        {
        	var pos = em.getComponent(input, CPosition);
        	var drawable = em.getComponent(input, CDrawable);
        	var sprite = drawable.sprite;
        	var bitmap = drawable.bitmap;

        	var dx = event.stageX - pos.x - Client.viewport.x;

        	if(dx < 0 && !pos.flipped)
        	{
        		pos.flipped = true;
        		// sprite.scaleX = -1;
        		// bitmap.x = -bitmap.width;
        	}
        
        	if(dx > 0 && pos.flipped)
        	{
        		pos.flipped = false;
        		// sprite.scaleX = 1;
        		// bitmap.x = 0;
        	}
    	}
    }

    private function onMouseDown(ev:MouseEvent)
    {
        var allInputs = this.em.getAllComponentsOfType(CInput);
        for(input in allInputs)
        {
        	input.mouseIsDown = true;
    	}
    }

    private function onMouseUp(event:MouseEvent)
    {
        var allInputs = this.em.getAllComponentsOfType(CInput);
        for(input in allInputs)
        {
        	input.mouseIsDown = false;
    	}
    }


    private function onKeyDown(event:KeyboardEvent)
    {
        var allInputs = this.em.getAllComponentsOfType(CInput);
        for(input in allInputs)
        {
	        switch(event.keyCode)
	        {
	            // case Keyboard.Q:
	            case Keyboard.A:
	                input.keyLeftIsDown = true;
	            case Keyboard.D:
	                input.keyRightIsDown = true;
	            case Keyboard.W:
	            // case Keyboard.Z:
	                input.keyUpIsDown = true;
	            case Keyboard.S:
	                input.keyDownIsDown = true;
	        }
	    }
    }

    private function onKeyUp(event:KeyboardEvent)
    {
        var allInputs = this.em.getAllComponentsOfType(CInput);
        for(input in allInputs)
        {
	        switch(event.keyCode)
	        {
	            // case Keyboard.Q:
	            case Keyboard.A:
	                input.keyLeftIsDown = false;
	            case Keyboard.D:
	                input.keyRightIsDown = false;
	            case Keyboard.W:
	            // case Keyboard.Z:
	                input.keyUpIsDown = false;
	            case Keyboard.S:
	                input.keyDownIsDown = false;
	        }
	    }
    }

    public function processEntities()
    {
        var allInputs = this.em.getEntitiesWithComponent(CInput);
        for(player in allInputs)
        {
        	var input = em.getComponent(player, CInput);

        	if(input.mouseIsDown && Timer.getTime() - input.lastActionTime > bulletRate)
        	{
        		var playerPos = em.getComponent(player, CPosition);

                var playerCenterX = Std.int(playerPos.x + World.TILE_SIZE / 2);
                var playerCenterY = Std.int(playerPos.y + World.TILE_SIZE / 2);

        		var v = [Lib.current.stage.mouseX - playerCenterX - Client.viewport.x,
        				 Lib.current.stage.mouseY - playerCenterY - Client.viewport.y];
        		var d = Math.sqrt(Math.pow(v[0], 2) + Math.pow(v[1], 2));
        		v = [v[0] / d, v[1] / d];

        		var bullet = ec.bullet([playerCenterX, playerCenterY]);
                em.addComponent(bullet, new CMovingObject(v, 10));
                em.addComponent(bullet, new COwner(player));
                em.addComponent(bullet, new CMyBullet());

        		em.addComponent(player, new CScreenShake());

        		playerPos.dx -= v[0] * 8;
        		playerPos.dy -= v[1] * 8;
        		// enh.screenshake();
        		input.lastActionTime = Timer.getTime();

                SoundManager.pew.play();
                // trace("local bulletmake");

                @RPC("BULLET_MAKE", playerCenterX, playerCenterY,
                                    Std.int(v[0] * 100), Std.int(v[1] * 100))
                                        {x:Short, y:Short, vx:Short, vy:Short};
        	}
    	}
	}
}