package common.systems;

import enh.Builders;
import enh.Timer;

import Common;


// Stole from other project
class TimerSystem extends System<Main, EntityCreator>
{
    public function init() {}

    public function processEntities()
    {
        var allTimers = em.getEntitiesWithComponent(CTimer);

        for(entity in allTimers)
        {
            var timer = em.getComponent(entity, CTimer);

            if(Timer.getTime() - timer.creationTime > timer.delay)
            {
                // trace("boom");
                timer.callFunction();
                em.removeComponent(entity, timer);
            }   
        }
    }
}