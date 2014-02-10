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

            pos.x += (interp.x - pos.x) * 0.3;
            pos.y += (interp.y - pos.y) * 0.3;
        }

        // var nonsense = em.getEntitiesWithComponent(CMyPlayer);
        // for(myPlayer in nonsense)
        // {
        //     var pos = em.getComponent(myPlayer, CPosition);
        //     var ghost = em.getEntitiesWithComponent(CGhost).next();
        //     var interp = em.getComponent(ghost, CInterpolation);
        //     if(Timer.getTime() - pos.lastMove > 0.5)
        //     {
        //         pos.x += (interp.x - pos.x) * 0.3;
        //         pos.y += (interp.y - pos.y) * 0.3;
        //     }

        //     var dx = Math.abs(pos.x - interp.x);
        //     var dy = Math.abs(pos.y - interp.y);

        //     if(dx > 100 || dy > 100)
        //     {
        //         pos.x = interp.x;
        //         pos.y = interp.y;
        //     }
        // }
    }
}