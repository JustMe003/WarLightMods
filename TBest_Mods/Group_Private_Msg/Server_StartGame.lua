function Server_StartGame(game, standing)		
	--Set the mod boolean flag to be enabled
	local publicGameData = Mod.PublicGameData
	publicGameData.GameFinalized = false;
	publicGameData.Diplo = {};
	publicGameData.Chat = {};
	Mod.PublicGameData = publicGameData;

	--TODO set up all playergamedata


	if (Mod.Settings.ModBetterCitiesEnabled)then StartGameBetterCities(game, standing) end;
	--NOTE: We are setting up PlayerGameData.Chat in StartGameWinCon too
	if (Mod.Settings.ModWinningConditionsEnabled)then StartGameWinCon(game, standing) end;
end


function StartGameBetterCities( game, standing )
		--If we are not doing anything, return
		if (Mod.Settings.StartingCitiesActive == false and Mod.Settings.WastlandCities == false and Mod.Settings.CustomSenarioCapitals == false)then
			return;
		end
		
		--Make a city on all starting territories
		local structure = {}
		Cities = WL.StructureType.City
		structure[Cities] = Mod.Settings.NumberOfStartingCities;
		
		for _, territory in pairs(standing.Territories) do
			if (territory.IsNeutral == false and Mod.Settings.StartingCitiesActive == true) then
				--Players starts with a city
				territory.Structures  = structure
				
				elseif (territory.NumArmies.NumArmies == game.Settings.WastelandSize and Mod.Settings.WastlandCities == true
				and territory.IsNeutral == true) then
				--Wastelands starts with a city.
				structure[Cities] = 1;
				territory.Structures  = structure
				structure[Cities] = Mod.Settings.NumberOfStartingCities;	
				end
			
			--Capitals results in bigger city
			--Useful for Custom scenario, where players can start with a lot of territories
			if (territory.NumArmies.NumArmies == Mod.Settings.CustomSenarioCapitals and territory.IsNeutral == false) then
				structure[Cities] = Mod.Settings.CapitalExtraStartingCities;
				territory.Structures = structure;
				--Reset to 1, as we loop back to the next territory.
				structure[Cities] = Mod.Settings.NumberOfStartingCities;
			end
		end
end

function StartGameWinCon(game, standing) 
	local playerGameData = Mod.PlayerGameData;
	for _,pid in pairs(game.ServerGame.Game.Players)do
		if(pid.IsAI == false)then
			playerGameData[pid.ID] = {};
			playerGameData[pid.ID].WinCon = {};

			playerGameData[pid.ID].Chat = {}; -- For the chat function

			playerGameData[pid.ID].WinCon.Capturedterritories = 0;
			playerGameData[pid.ID].WinCon.Lostterritories = 0;
			playerGameData[pid.ID].WinCon.Ownedterritories = 0;
			playerGameData[pid.ID].WinCon.Capturedbonuses = 0;
			playerGameData[pid.ID].WinCon.Lostbonuses = 0;
			playerGameData[pid.ID].WinCon.Ownedbonuses = 0;
			playerGameData[pid.ID].WinCon.Killedarmies = 0;
			playerGameData[pid.ID].WinCon.Lostarmies = 0;
			playerGameData[pid.ID].WinCon.Ownedarmies = 0;
			playerGameData[pid.ID].WinCon.Eleminateais = 0;
			playerGameData[pid.ID].WinCon.Eleminateplayers = 0;
			playerGameData[pid.ID].WinCon.Eleminateaisandplayers = 0;
		end
	end
	for _,terr in pairs(standing.Territories)do
		if(terr.OwnerPlayerID ~= WL.PlayerID.Neutral)then
			if(game.ServerGame.Game.PlayingPlayers[terr.OwnerPlayerID].IsAI == false)then
				playerGameData[terr.OwnerPlayerID].WinCon.Ownedterritories = playerGameData[terr.OwnerPlayerID].WinCon.Ownedterritories+1;
				playerGameData[terr.OwnerPlayerID].WinCon.Ownedarmies = playerGameData[terr.OwnerPlayerID].WinCon.Ownedarmies+terr.NumArmies.NumArmies;
			end
		end
	end
	for _,boni in pairs(game.Map.Bonuses)do
		local Match = true;
		for _,terrid in pairs(boni.Territories)do
			if(pid == nil)then
				pid = standing.Territories[terrid].OwnerPlayerID;
			end
			if(pid ~= standing.Territories[terrid].OwnerPlayerID)then
				Match = false;
			end
		end
		if(Match == true)then
			if(pid ~= WL.PlayerID.Neutral and game.ServerGame.Game.PlayingPlayers[pid].IsAI == false)then
				playerGameData[pid].WinCon.Ownedbonuses = playerGameData[pid].WinCon.Ownedbonuses+1;
			end
		end
		pid = nil;
	end
	Mod.PlayerGameData = playerGameData;
end