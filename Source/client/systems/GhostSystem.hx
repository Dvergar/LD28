package client.systems;

import enh.Builders;
import enh.Timer;

import Client;
import Common;


class GhostSystem extends System<Client, EntityCreator>
{
    public function init() {}

    public function processEntities()
    {
        var allGhosts = em.getEntitiesWithComponent(CGhost);
        for(ghost in allGhosts)
        {
            // trace("moop");
            var player = em.getComponent(ghost, CGhost).entity;
            var gpos = em.getComponent(ghost, CPosition);
            var ppos = em.getComponent(player, CPosition);

            gpos.x = ppos.x;
            gpos.y = ppos.y;
        }
    }
}