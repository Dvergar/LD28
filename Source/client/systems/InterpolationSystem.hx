package client.systems;

import enh.Builders;
import enh.Timer;

import Client;
import Common;


class InterpolationSystem extends System<Client, EntityCreator>
{
    public function init() {}

    public function processEntities()
    {
        var allInterp = em.getEntitiesWithComponent(CInterpolation);
        for(player in allInterp)
        {
            var pos = em.getComponent(player, CPosition);
            var interp = em.getComponent(player, CInterpolation);

            // SUPER NAIVE INTERPOLATION
            pos.x += (pos.netx - pos.x) * 0.3;
            pos.y += (pos.nety - pos.y) * 0.3;
            pos.flipped = pos.netFlipped;

            if(em.hasComponent(player, CGhost))
            {
                var myPlayer = em.getComponent(player, CGhost).entity;
                var myPos = em.getComponent(myPlayer, CPosition);

                pos.x = myPos.netx;
                pos.y = myPos.nety;
            }
        }

        var nonsense = em.getEntitiesWithComponent(CMyPlayer);
        for(myPlayer in nonsense)
        {
            var pos = em.getComponent(myPlayer, CPosition);
            var ghost = em.getEntitiesWithComponent(CGhost).next();

            if(Timer.getTime() - pos.lastMove > 0.5)
            {
                pos.x += (pos.netx - pos.x) * 0.3;
                pos.y += (pos.nety - pos.y) * 0.3;
            }

            var dx = Math.abs(pos.x - pos.netx);
            var dy = Math.abs(pos.y - pos.nety);

            if(dx > 100 || dy > 100)
            {
                pos.x = pos.netx;
                pos.y = pos.nety;
            }
        }
    }
}