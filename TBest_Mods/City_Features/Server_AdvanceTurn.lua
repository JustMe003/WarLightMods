function Server_AdvanceTurn_Start (game, addNewOrder)	
	local cityCap = 10;
	local cityGrowth = 1;

	--Have to check for nil, as this setting was added in an update
	if (Mod.Settings.CityGrowth ~= nil)then
		if (Mod.Settings.CityGrowth == false)then return end; --City growth is off
		cityCap = Mod.Settings.CityGrowthCap;
		cityGrowth = Mod.Settings.CityGrowthPower;
	end;
	
	--The turns cities can grow.
	if ((game.Game.NumberOfTurns+1) %5 == 0) then
		local standing = game.ServerGame.LatestTurnStanding; --todo use standing instead of game. etc.
		local CurrentIndex=1;
		local NewOrders={};
		
		--As of now WarZone only has one type of structure.
		local structure = {}
		local Cities = WL.StructureType.City
		for _, territory in pairs(standing.Territories) do
			--Can be 0, if a territory has been bombed. We don't want that city to grow.
			if not(territory.Structures == nil or territory.Structures[WL.StructureType.City] == 0) then
				local terrMod = WL.TerritoryModification.Create(territory.ID);		
				structure[Cities] = territory.Structures[WL.StructureType.City] +cityGrowth;
				--A hard-coded cap on how big cities can grow.
				--TODO make this not be hardcoded
				if (structure[Cities] <= cityCap) then
					terrMod.SetStructuresOpt   = structure
					NewOrders[CurrentIndex]=terrMod;
					CurrentIndex=CurrentIndex+1;
				end
			end
		end					
		addNewOrder(WL.GameOrderEvent.Create(WL.PlayerID.Neutral,"Smaller cities have grown",nil,NewOrders));
	end
end

--As of now WarZone only has one type of structure. If this changes in the future, this code may break.
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)	
	if (order.proxyType == 'GameOrderDeploy') then
		--if city is already destroyed or is not present (nil), return or skip according to Mod.Settings	
		if (game.ServerGame.LatestTurnStanding.Territories[order.DeployOn].Structures == nil) then
			--If mod settings say city deploy only, skip. Else return
			--TODO we might want to give a skip msg here
			if (Mod.Settings.CityDeployOnly)then skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage); end;	
			
			return;
			else if (game.ServerGame.LatestTurnStanding.Territories[order.DeployOn].Structures[WL.StructureType.City] == 0) then	
				--TODO we might want to give a skip msg here
				
				if (Mod.Settings.CityDeployOnly)then skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage); end;	
				
				return;
			end;
		end;	
		
		--Extra armies when deploying in city, but a city is reduced. 
		if (Mod.Settings.CommerceFreeCityDeploy == true) then
			local NewOrders={};	
			local terrMod = WL.TerritoryModification.Create(order.DeployOn);	
			--Reduce structure/cities by 1.
			local structure = {}
			local Cities = WL.StructureType.City
			structure[Cities] = game.ServerGame.LatestTurnStanding.Territories[order.DeployOn].Structures[WL.StructureType.City] -1;
			terrMod.SetStructuresOpt = structure;
			--Add the deploy
			terrMod.SetArmiesTo  = game.ServerGame.LatestTurnStanding.Territories[order.DeployOn].NumArmies.NumArmies + (order.NumArmies *2);
			NewOrders[1]=terrMod;
			--TODO make this not be free in commerce games
			--Add the deploy order to the game and skip the original order.
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID,"Deploy " .. terrMod.SetArmiesTo .. " in " .. game.Map.Territories[order.DeployOn].Name .. " using local workers. The city now has less resources.", {}, NewOrders));
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);			
			return;	
		end	
		return;
	end
	--Give a X% def. bonus per city on defending territory 
	if (order.proxyType == 'GameOrderAttackTransfer' and Mod.Settings.CityWallsActive == true)  then
		if (result.IsAttack) then
			if not (game.ServerGame.LatestTurnStanding.Territories[order.To].Structures == nil) then	
				if (game.ServerGame.LatestTurnStanding.Territories[order.To].Structures[WL.StructureType.City] > 0) then
					local DefBonus = game.ServerGame.LatestTurnStanding.Territories[order.To].Structures[WL.StructureType.City] * Mod.Settings.DefPower;
					local attackersKilled = result.AttackingArmiesKilled.NumArmies +  result.AttackingArmiesKilled.NumArmies * DefBonus
					
					--Minimum kill 1 attacking army
					if(attackersKilled == 0) then
						attackersKilled = 1					
						--Max armies lost is equal to actualArmies
						elseif (result.ActualArmies.NumArmies - attackersKilled < 0) then
						attackersKilled = result.ActualArmies.NumArmies;
						--Note : At the moment we don't dmg special units
						--That would be a very rare edge case, we might want to handle in the future
						else
						--round up, always
						attackersKilled = math.ceil(attackersKilled);
					end
					
					--Write to GameOrderResult	 (result)
					local NewAttackingArmiesKilled = WL.Armies.Create(attackersKilled) 
					result.AttackingArmiesKilled = NewAttackingArmiesKilled
					local msg = "The city has " .. tostring(DefBonus*100) .. "% fortification bonus";
					addNewOrder(WL.GameOrderEvent.Create(game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID,msg,{order.PlayerID}));
					return;
				end
			end
		end
		return;
	end;
		
	--Bomb cards reduces cities by the given X strength.
	if(order.proxyType == 'GameOrderPlayCardBomb' and Mod.Settings.BombcardActive == true) then
		if not(game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].Structures == nil) then
			--if city is already destroyed, return
			if (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].Structures[WL.StructureType.City] == 0) then
				return;
			end
			
			local structure = {}
			local NewOrders={};
			local Cities = WL.StructureType.City
			structure[Cities] = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].Structures[WL.StructureType.City] -Mod.Settings.BombcardPower;
			local msg = "City was bombed";
			if (structure[Cities] < 1) then
				--We can't set to nil, so we set to zero
				structure[Cities] = 0;
				msg = "The City is destroyed! It is now a ruin and won't grow before it's been rebuilt."
			end
			local terrMod = WL.TerritoryModification.Create(order.TargetTerritoryID);	
			terrMod.SetStructuresOpt   = structure
			NewOrders[1]=terrMod;
			
			--Add the new order event. Discard the card played. Skip the normal card effect.		
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID,msg,{},NewOrders));
			addNewOrder(WL.GameOrderDiscard.Create(order.PlayerID, order.CardInstanceID));			
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
			return;
		end
		return;
	end;
		
	--If we blockade or emergency blockade on a city we own. We build on that city
	if(order.proxyType == 'GameOrderPlayCardBlockade' or order.proxyType == 'GameOrderPlayCardAbandon') then
		if (Mod.Settings.BlockadeBuildCityActive == false) then return end;
		--If there is a structure present
		if not(game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].Structures == nil) then
			--Check that the player controls the territory
			if (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID ~= order.PlayerID) then
				return;
			end;
			
			local structure = {}
			local NewOrders={};
			local Cities = WL.StructureType.City
			structure[Cities] = game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].Structures[WL.StructureType.City] +Mod.Settings.BlockadePower;
			local msg = "The City's defenses have been increased!";
			local terrMod = WL.TerritoryModification.Create(order.TargetTerritoryID);	
			terrMod.SetStructuresOpt   = structure
			NewOrders[1]=terrMod;
			
			--Add the new order event. Discard the card played. This skips the normal card effect.
			addNewOrder(WL.GameOrderEvent.Create(order.PlayerID,msg,{},NewOrders));
			addNewOrder(WL.GameOrderDiscard.Create(order.PlayerID, order.CardInstanceID));			
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);		
			return;
		end		
	end
	
	--EMB card setting
	if(order.proxyType == 'GameOrderPlayCardAbandon' and Mod.Settings.EMBActive == true) then
		--This check should not be needed for EMB, but we have it anyway as it may increase mod compatibility
		--Check if we own the territory, else return
		if (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID ~= order.PlayerID) then
			return;
		end;
		--Check for nil on latestTurnStanding. This is for founding a new city, so has to be nil
		if (game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].Structures ~= nil)then return;end;
		
		local structure = {}
		local NewOrders={};
		local Cities = WL.StructureType.City 
		structure[Cities] = Mod.Settings.EMBPower
			
		local msg = "A new city has been founded!";
		local terrMod = WL.TerritoryModification.Create(order.TargetTerritoryID);	
		terrMod.SetStructuresOpt   = structure
		NewOrders[1]=terrMod;	
		
		--Add the new order event. Discard the card played. This skips the normal card effect.
		addNewOrder(WL.GameOrderEvent.Create(order.PlayerID,msg,{},NewOrders));
		addNewOrder(WL.GameOrderDiscard.Create(order.PlayerID, order.CardInstanceID));			
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);		
		return;
	end	
end
