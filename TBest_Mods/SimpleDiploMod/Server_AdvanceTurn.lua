--TODO
--Give players 1 card if they have no cards. Prvent stuck games
--


function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	--[[if (order.proxyType == 'GameOrderAttackTransfer' and order.PlayerID == 4569) then
		print('NumTurns=' .. game.Game.NumberOfTurns .. ' Mod.Settings.NumTurns=' .. tostring(Mod.Settings.NumTurns) .. ' From=' .. game.Map.Territories[order.From].Name .. ' to=' .. game.Map.Territories[order.To].Name .. ' IsAttack=' .. tostring(result.IsAttack) .. ' DestinationOwner=' .. tostring(game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID));
	end ]]--

    if (game.Game.NumberOfTurns < Mod.Settings.NumTurns  -- are we at the start of the game, within our defined range?  (without this check, we'd affect the entire game, not just the start)
		and order.proxyType == 'GameOrderAttackTransfer'  --is this an attack/transfer order?  (without this check, we'd stop deployments or cards)
		and result.IsAttack  --is it an attack? (without this check, transfers wouldn't be allowed within your own territory or to teammates)
		and not IsDestinationNeutral(game, order) or isAtWar) then --is the destination owned by neutral? (without this check we'd stop people from attacking neutrals)
		skipThisOrder(WL.ModOrderControl.Skip);

	end

end

function IsDestinationNeutral(game, order)
	local terrID = order.To; --The order has "To" and "From" which are territory IDs
	local terrOwner = game.ServerGame.LatestTurnStanding.Territories[terrID].OwnerPlayerID; --LatestTurnStanding always shows the current state of the game.
	return terrOwner == WL.PlayerID.Neutral;
end

function isAtWar(game, order)
	local TOterrID = order.To; --The order has "To" and "From" which are territory IDs
	local FromTerrID = order.From; 
	local terrDefender = game.ServerGame.LatestTurnStanding.Territories[TOterrID].OwnerPlayerID; --LatestTurnStanding always shows the current state of the game.
	local terrAttacker = game.ServerGame.LatestTurnStanding.Territories[FromterrID].OwnerPlayerID; --LatestTurnStanding always shows the current state of the game.
	for(WL.CardID.Spy in ActiveCard) do
		if(TargetPlayerID = terrAttacker) then
			return true;
		end
	end
	
	return false;
		
