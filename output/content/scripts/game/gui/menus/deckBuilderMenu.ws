/***********************************************************************/
/** Witcher Script file - gwint deck builder
/***********************************************************************/
/** Copyright © 2014 CDProjektRed
/** Author : Jason Slama
/***********************************************************************/

class CR4DeckBuilderMenu extends CR4GwintBaseMenu
{
	private var m_fxSetSelectedDeck	: CScriptedFlashFunction;
	private var m_fxSetGwintGamePending : CScriptedFlashFunction;
	private var m_fxShowTutorial : CScriptedFlashFunction;
	private var m_fxContinueTutorial : CScriptedFlashFunction;
	private var m_fxSetPassiveAbilString : CScriptedFlashFunction;
	
	function EnableJournalTutorialEnries()
	{
		var tutSystem : CR4TutorialSystem;
		// Journal - Enable Gwent tutorial entries
		tutSystem = theGame.GetTutorialSystem();
		tutSystem.ActivateJournalEntry('deckpanelMERGEDNEW');
		tutSystem.ActivateJournalEntry('deckcompositionNEW');
		//tutSystem.ActivateJournalEntry('leadercardsMERGED'); // uncommenting this will lead to 2x almost the same entry in journal	
	}
	
	event /*flash*/ OnConfigUI()
	{
		var selectedDeckIndex : eGwintFaction;
		var tutSystem : CR4TutorialSystem;		
		super.OnConfigUI();
		
		m_fxSetSelectedDeck = m_flashModule.GetMemberFlashFunction("setSelectedDeck");
		m_fxSetGwintGamePending = m_flashModule.GetMemberFlashFunction("setGwintGamePending");
		m_fxShowTutorial = m_flashModule.GetMemberFlashFunction("showTutorial");
		m_fxContinueTutorial = m_flashModule.GetMemberFlashFunction("continueTutorial");
		m_fxSetPassiveAbilString = m_flashModule.GetMemberFlashFunction("setPassiveAbilityString");
		
		m_fxSetPassiveAbilString.InvokeSelfOneArg(FlashArgString(GetLocStringByKeyExt("gwint_passive_ability")));	
		
		selectedDeckIndex = gwintManager.GetSelectedPlayerDeck();
		m_fxSetSelectedDeck.InvokeSelfOneArg(FlashArgInt(selectedDeckIndex));
		m_fxSetGwintGamePending.InvokeSelfOneArg(FlashArgBool(gwintManager.gameRequested));
		
		SendDeckInformation();
		SendCollectionInformation();
		SendLeaderCollectionInformation();
		theSound.EnterGameState( ESGS_Gwent );
		
		theGame.GetGuiManager().RequestMouseCursor(true);
		theGame.CenterMouse();
		
		if (!gwintManager.GetHasDoneDeckTutorial())
		{
			EnableJournalTutorialEnries();
			if (!theGame.GetTutorialSystem().AreMessagesEnabled() || FactsQuerySum("NewGamePlus") > 0)
			{
				gwintManager.SetHasDoneDeckTutorial(true);
			}
			else
			{
				sendTutorialStrings();
				m_fxShowTutorial.InvokeSelf();
			}
		}
	}
	
	event /* C++ */ OnClosingMenu()
	{
		super.OnClosingMenu();
		
		theGame.GetGuiManager().RequestMouseCursor(false);
		
		gwintManager.SetHasDoneDeckTutorial(true);
		
		if (gwintManager.gameRequested)
		{
			gwintManager.gameRequested = false;
			theGame.RequestMenu( 'GwintGame' );
		}
		else
		{
			theSound.LeaveGameState( ESGS_Gwent );
		}
	}
	
	public function OnQuitGameConfirmed()
	{
		if (gwintManager.gameRequested)
		{
			gwintManager.gameRequested = false;
			thePlayer.SetGwintMinigameState( EMS_End_PlayerLost );
		}
		super.OnQuitGameConfirmed();
		CardKill();
	}
	
	protected function SendDeckInformation():void
	{
		var deckListArray : CScriptedFlashArray;
		var deckInfo : CScriptedFlashObject;
		var currentDeckInfo : SDeckDefinition;
		var i : int;
		
		deckListArray = m_flashValueStorage.CreateTempFlashArray();
		
		if (gwintManager.GetFactionDeck(GwintFaction_NothernKingdom, currentDeckInfo) && currentDeckInfo.unlocked)
		{
			deckInfo = CreateDeckDefinitionFlash(currentDeckInfo);
			deckListArray.PushBackFlashObject(deckInfo);
		}
		
		if (gwintManager.GetFactionDeck(GwintFaction_Nilfgaard, currentDeckInfo) && currentDeckInfo.unlocked)
		{
			deckInfo = CreateDeckDefinitionFlash(currentDeckInfo);
			deckListArray.PushBackFlashObject(deckInfo);
		}
		
		if (gwintManager.GetFactionDeck(GwintFaction_Scoiatael, currentDeckInfo) && currentDeckInfo.unlocked)
		{
			deckInfo = CreateDeckDefinitionFlash(currentDeckInfo);
			deckListArray.PushBackFlashObject(deckInfo);
		}
		
		if (gwintManager.GetFactionDeck(GwintFaction_NoMansLand, currentDeckInfo) && currentDeckInfo.unlocked)
		{
			deckInfo = CreateDeckDefinitionFlash(currentDeckInfo);
			deckListArray.PushBackFlashObject(deckInfo);
		}
		
		m_flashValueStorage.SetFlashArray("gwint.deckbuilder.decks", deckListArray);
	}
	
	protected function SendCollectionInformation():void
	{
		var colList : CScriptedFlashArray;
		
		colList = m_flashValueStorage.CreateTempFlashArray();
		FillArrayWithCardList(gwintManager.GetPlayerCollection(), colList);
		
		m_flashValueStorage.SetFlashArray("gwint.deckbuilder.collection", colList);
	}
	
	protected function SendLeaderCollectionInformation():void
	{
		var colList : CScriptedFlashArray;
		
		colList = m_flashValueStorage.CreateTempFlashArray();
		FillArrayWithCardList(gwintManager.GetPlayerLeaderCollection(), colList);
		
		m_flashValueStorage.SetFlashArray("gwint.deckbuilder.leaderList", colList);
	}
	
	event /*flash*/ OnTabChanged(tabIndex:int)
	{
	}
	
	event /*flash*/ OnCardAddedToDeck(factionID:int, cardId:int)
	{
		gwintManager.AddCardToDeck(factionID, cardId);
	}
	
	event /*flash*/ OnCardRemovedFromDeck(factionID:int, cardId:int)
	{
		gwintManager.RemoveCardFromDeck(factionID, cardId);
	}
	
	event /*flash*/ OnSelectedDeckChanged(factionID:int)
	{
		gwintManager.SetSelectedPlayerDeck(factionID);
	}
	
	event /*flash*/ OnLeaderChanged(factionID:int, leaderID:int)
	{
		var deckDefinition : SDeckDefinition;
		
		if (gwintManager.GetFactionDeck(factionID, deckDefinition) && deckDefinition.leaderIndex != leaderID)
		{
			OnPlaySoundEvent("gui_gwint_leader_change");
			deckDefinition.leaderIndex = leaderID;
			gwintManager.SetFactionDeck(factionID, deckDefinition);
		}
	}
	
	event /*flash*/ OnLackOfUnitsError(numCards:int)
	{
		var errorString:string;
		var argsInt : array<int>;
		
		argsInt.PushBack(22 - numCards);
		
		errorString = GetLocStringByKeyExtWithParams("gwint_more_units", argsInt);
		
		showNotification(errorString);
		OnPlaySoundEvent("gui_global_denied");
	}
	
	event /*flash*/ OnTooManySpecialCards()
	{
		showNotification(GetLocStringByKeyExt("gwint_special_card_limit"));
		OnPlaySoundEvent("gui_global_denied");
	}
	
	protected function sendTutorialStrings():void
	{
		var l_flashArray : CScriptedFlashArray;
		var maString:string;
		
		l_flashArray = m_flashValueStorage.CreateTempFlashArray();
		
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_welcome_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_factions_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_leaders_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_leaders_2_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_collection_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_in_deck_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_composition_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_full_deck_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_full_deck_2_desc")));
		l_flashArray.PushBackFlashString(ReplaceTagsToIcons(GetLocStringByKeyExt("gwint_deck_tut_exit_builder_desc")));
		
		m_flashValueStorage.SetFlashArray( "gwint.tutorial.strings", l_flashArray );
	}
}
