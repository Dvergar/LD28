package common.systems;

import enh.Builders;
import enh.Constants;

import Common;


class HealthSystem extends System<Main, EntityCreator>
{
    public function init()
    {
        #if server
        @registerListener "COLLISION";
        #end
    }

    #if server
    function onCollision(damaged:Entity, ev:Dynamic)
    {
        var health = em.getComponent(damaged, CHealth);
        health.value -= 8;

        trace("health " + health.value);

        if(health.value <= 0)
        {
            var killer:Entity = ev.owner;
            trace("Dead player " + killer);

            em.addComponent(damaged, new CDead());
            em.removeComponentOfType(damaged, CInput);
            var pos = em.getComponent(damaged, CPosition);
            pos.x = 9000;
            pos.y = 9000;

            // OWNER LEVEL UP
            var deadlvl = em.getComponent(damaged, CLevel);
            var lvl = em.getComponent(killer, CLevel);
            lvl.value++;
            lvl.value+= Std.int(deadlvl.value / 2);
            if(lvl.value > 4) lvl.value = 4;
            Upgrade.level(killer, lvl.value);

            // HP REGEN UPDATE
            var hp = em.getComponent(killer, CHealth);
            hp.regen = 0.03 + lvl.value * 0.01;

            var killerId = em.getIdFromEntity(killer);
            @RPC("PLAYER_KILL", damaged, killerId, lvl.value) {killerId:Short, lvl:Short};
        }
    }
    #end

    public function processEntities()
    {
        var allPlayers = em.getEntitiesWithComponent(CHealth);
        for(player in allPlayers)
        {
            var hp = em.getComponent(player, CHealth);
            hp.value += hp.regen;

            if(hp.value > 100) hp.value = 100;
        }

        // DEATH U_U
        var allPlayers = em.getAllComponentsOfType(CPlayer);
        var nbPlayers = 0; for(player in allPlayers) nbPlayers++;

        if(nbPlayers > 1)
        {
            var allInputs = em.getAllComponentsOfType(CInput);
            var nbInputs = 0; for(input in allInputs) nbInputs++;

            if(nbInputs == 1)
            {
                // RESET
                var allPlayers = em.getEntitiesWithComponent(CPlayer);
                for(player in allPlayers)
                {
                    var pos = em.getComponent(player, CPosition);
                    var newPos = Main.getNewPlayerPosition();
                    pos.x = newPos[0];
                    pos.y = newPos[1];

                    em.getComponent(player, CHealth).value = 100;

                    if(em.hasComponent(player, CDead))
                    {
                        em.getComponent(player, CLevel).value = 0;
                        em.removeComponentOfType(player, CDead);
                    }

                    em.addComponent(player, new CInput());
                }

                @RPC("NEW_ROUND", CONST.DUMMY) {};
            }
        }
    }
}
