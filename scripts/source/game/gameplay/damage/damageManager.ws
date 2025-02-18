/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/





class W3DamageManager
{
	public function ProcessAction(act : W3DamageAction)
	{
		var proc : W3DamageManagerProcessor;
		var wasAlive : bool;
		var npcAttacker : CNewNPC;
		var npcVictim : CNewNPC;
		var playerAttacker : CR4Player;
		var playerVictim : CR4Player;
		var gwintManager : CR4GwintManager;
		var maxLevel : int;
		var i : int;
		var lvl5 : array < int >;
		var lvl10 : array < int >;
		var lvl20 : array < int >;
		var npc : CNewNPC;
		var actors : array<CActor>;
		
		//easy
		lvl5.PushBack(20);
		lvl5.PushBack(23);
		lvl5.PushBack(26);
		lvl5.PushBack(29);
		//easy = new array < int > {20, 23, 26, 29};
		
		//normal
		lvl10.PushBack(21);
		lvl10.PushBack(24);
		lvl10.PushBack(27);
		lvl10.PushBack(30);
		
		//hard
		lvl20.PushBack(22);
		lvl20.PushBack(25);
		lvl20.PushBack(28);
		lvl20.PushBack(31);
		
		if(!act || !act.victim)
			return;
			
		wasAlive = act.victim.IsAlive();
		
		//if victim dead and no buffs in action -> nothing to do here...
		if(!wasAlive && act.GetEffectsCount() == 0)
			return;
		
		playerAttacker = (CR4Player)act.attacker;
		npcVictim = (CNewNPC)act.victim;
		
		//victim is npc, player attacks and npc is not attackable by player
		if ( playerAttacker && npcVictim && !npcVictim.isAttackableByPlayer )
			return;
			
		npcAttacker = (CNewNPC)act.attacker;
		playerVictim = (CR4Player)act.victim;
		
		if ( playerAttacker || playerVictim )
		{
			if ((npcAttacker && npcAttacker.GetAttitude(thePlayer) == AIA_Hostile) || (npcVictim && npcVictim.GetAttitude(thePlayer) == AIA_Hostile))
			{
				actors = GetActorsInRange(thePlayer, 30.0f, 1000000, '', true);
				maxLevel = 0;
				for (i = 0; i < actors.Size(); i += 1)
				{
					npc = (CNewNPC)actors[i];
					if (npc && npc.GetAttitude(thePlayer) == AIA_Hostile)
					{
						if (npc.GetLevel() > maxLevel)
						{
							maxLevel = npc.GetLevel();
						}
					}
				} 
			
				gwintManager = theGame.GetGwintManager();
				gwintManager.setDoubleAIEnabled(false);
				if (maxLevel < 5)
				{
					gwintManager.SetEnemyDeckIndex(lvl5[RandRange(lvl5.Size())]);
				}
				else if (maxLevel < 10)
				{
					gwintManager.SetEnemyDeckIndex(lvl10[RandRange(lvl10.Size())]);
				}
				else if (maxLevel < 20)
				{
					gwintManager.SetEnemyDeckIndex(lvl20[RandRange(lvl20.Size())]);
				}
				else
				{
					gwintManager.SetEnemyDeckIndex(RandRange(42));
				}
				
				gwintManager.testMatch = true;
				gwintManager.gameRequested = true;
				theGame.RequestMenu( 'DeckBuilder' );
			}
		}
		else
		{
			//need one processing object per action as processed action can create new action to process (returned damage)
			proc = new W3DamageManagerProcessor in this;
			proc.ProcessAction(act);
			delete proc;
		}
	}
}
