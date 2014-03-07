package common.systems;

import enh.Builders;
import enh.Timer;

import Common;
import common.World;

#if client
import Client;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import flash.Lib;
#end


class InputSystem extends System<Main, EntityCreator>
{
    public function init()
    {
        #if client
        Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        #end
    }

    #if client
    private function onMouseMove(event:MouseEvent)
    {
        var allInputs = this.em.getEntitiesWithComponent(CInput);
        for(player in allInputs)
        {
            var pos = em.getComponent(player, CPosition);
            var input = em.getComponent(player, CInput);
            var drawable = em.getComponent(player, CDrawable);
            var sprite = drawable.sprite;
            var bitmap = drawable.bitmap;

            var dx = event.stageX - pos.x - Client.viewport.x;

            if(dx < 0 && !pos.flipped)
                pos.flipped = true;
        
            if(dx > 0 && pos.flipped)
                pos.flipped = false;

            input.mouseX = Std.int(event.stageX - Client.viewport.x);
            input.mouseY = Std.int(event.stageY - Client.viewport.y);
        }
    }

    private function onMouseDown(ev:MouseEvent)
    {
        var allInputs = this.em.getAllComponentsOfType(CInput);
        for(input in allInputs)
            input.mouseIsDown = true;
    }

    private function onMouseUp(event:MouseEvent)
    {
        var allInputs = this.em.getAllComponentsOfType(CInput);
        for(input in allInputs)
            input.mouseIsDown = false;
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
    #end

    public function processEntities()
    {
        var allInputs = this.em.getEntitiesWithComponent(CInput);
        for(player in allInputs)
        {
            var input = em.getComponent(player, CInput);
            var bulletRate = em.getComponent(player, CBulletRate);

            if(input.mouseIsDown &&
               Timer.getTime() - input.lastActionTime > bulletRate.value)
            {
                trace("hit " + (Timer.getTime() - input.lastActionTime));

                var playerPos = em.getComponent(player, CPosition);

                var playerCenterX = Std.int(playerPos.x + World.TILE_SIZE / 2);
                var playerCenterY = Std.int(playerPos.y + World.TILE_SIZE / 2);

                var v:Array<Float> = [input.mouseX - playerCenterX,
                                      input.mouseY - playerCenterY];
                var d = Math.sqrt(Math.pow(v[0], 2) + Math.pow(v[1], 2));
                v = [v[0] / d, v[1] / d];

                playerPos.dx -= v[0] * 8;
                playerPos.dy -= v[1] * 8;
                input.lastActionTime = Timer.getTime();

                #if server
                trace("player bullet " + player);
                var bullet = net.createNetworkEntity("bullet", player,
                                                     [playerCenterX,
                                                      playerCenterY]);
                var mo = new CMovingObject(v[0], v[1], 10);
                net.addComponent2(bullet, mo);
                em.addComponent(bullet, new COwner(player));
                #end

                #if client
                em.addComponent(player, new CScreenShake());
                SoundManager.pew.play();
                #end

                trace("bullet " + v + " ppos " + playerCenterX + " / "
                                               + playerCenterY);
                trace("mouse " + input.mouseX + " / " + input.mouseY);
            }
        }
    }
}