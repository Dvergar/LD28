package common.systems;

import enh.Builders;

import Common;


class MovementSystem extends System<Main, EntityCreator>
{
    public function init() {}


    public function processEntities()
    {
        var allMovingObjects = em.getEntitiesWithComponent(CMovingObject);
        for(object in allMovingObjects)
        {
            var mov = em.getComponent(object, CMovingObject);
            var pos = em.getComponent(object, CPosition);

            pos.x += mov.v[0] * mov.speed;
            pos.y += mov.v[1] * mov.speed;
        }

        var allPositions = em.getAllComponentsOfType(CPosition);
        for(pos in allPositions)
        {
            pos.oldx = pos.x;
            pos.oldy = pos.y;
        }
    }
}
