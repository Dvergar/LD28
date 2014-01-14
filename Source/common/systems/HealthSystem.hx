package common.systems;

import enh.Builders;

import Common;


class HealthSystem extends System<Main, EntityCreator>
{
    public function init()
    {
        @registerListener "COLLISION";
    }

    function onCollision(entity:String, ev:Dynamic)
    {
        var health = em.getComponent(entity, CHealth);
        health.value -= 8;

        if(health.value <= 0)
        {
            em.addComponent(entity, new CDead());
            // em.removeComponentOfType(entity, CPlayer);
            em.removeComponentOfType(entity, CInput);
            em.removeComponentOfType(entity, CCollidable);
            var pos = em.getComponent(entity, CPosition);
            pos.x = 9000;
            pos.y = 9000;
            trace("dead");

            // OWNER LEVEL UP
            var deadlvl = em.getComponent(entity, CLevel);
            var lvl = em.getComponent(ev.owner, CLevel);
            lvl.value++;
            lvl.value+= Std.int(deadlvl.value / 2);
            if(lvl.value > 4) lvl.value = 4;

            // HP REGEN UPDATE
            var hp = em.getComponent(ev.owner, CHealth);
            hp.regen = 0.03 + lvl.value * 0.01;

            var ownerId = em.getIdFromEntity(ev.owner);
            var id = em.getIdFromEntity(entity);
            @RPC("PLAYER_KILL", id, ownerId, lvl.value) {id:Short, ownerId:Short, lvl:Short};
        }

    }

    public function processEntities()
    {
        var allPlayers = em.getEntitiesWithComponent(CHealth);
        for(player in allPlayers)
        {
            var hp = em.getComponent(player, CHealth);
            hp.value += hp.regen;

            if(hp.value > 100) hp.value = 100;
        }

        // DEATH UGGGGLYYYY
        var allPlayers = em.getAllComponentsOfType(CPlayer);
        var nbPlayers = 0;
        for(player in allPlayers) nbPlayers++;
        if(nbPlayers > 1)
        {
            var allInputs = em.getAllComponentsOfType(CInput);
            var nbInputs = 0;
            for(input in allInputs) nbInputs++;
            if(nbInputs == 1)
            {
                @RPC("NEW_ROUND") {};

                // RESET
                var allPlayers = em.getEntitiesWithComponent(CPlayer);
                for(player in allPlayers)
                {
                    var pos = em.getComponent(player, CPosition);
                    var newPos = Main.getNewPlayerPosition();
                    pos.x = newPos[0];
                    pos.y = newPos[1];

                    var hp = em.getComponent(player, CHealth);
                    hp.value = 100;

                    if(em.hasComponent(player, CDead))
                    {
                        em.addComponent(player, new CLevel(0));
                        em.addComponent(player, new CHealth(100));
                        em.removeComponentOfType(player, CDead);
                    }

                    em.addComponent(player, new CInput());
                    em.addComponent(player, new CCollidable());
                }

                // enh.broadCastMyPlayerCreate();
                enh.broadCastPlayerCreate();
            }

        }
    }
}
