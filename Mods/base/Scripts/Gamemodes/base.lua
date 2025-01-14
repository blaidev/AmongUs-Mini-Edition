function InitializeGamemode()
	CE_AddRole({
		internal_name = "crewmate",
		name = "Crewmate",
		role_text = "There are impostors Among Us.",
		specials = {RS_Report},
		has_tasks = true,
		layer = 255, --special layer that shows everyone regardless of layer
		team = 0,
		role_vis = RV_None,
		color = {r=140,g=255,b=255},
		name_color = {r=255,g=255,b=255}
	})
	
	CE_AddRole({
		internal_name = "impostor",
		name = "Impostor",
		role_text = "Kill the crewmates.",
		task_text = "Sabotage and kill everyone.",
		specials = {RS_Primary,RS_Sabotage,RS_Vent,RS_Report},
		has_tasks = false,
		role_vis = RV_SameLayer,
		layer = 1,
		team = 1,
		primary_valid_targets = VPT_Others,
		immune_to_light_affectors = true,
		color = {r=255,g=25,b=25},
		name_color = {r=255,g=25,b=25}
	})
	
	CE_AddRole({
		internal_name = "witch",
		name = "Witch",
		role_text = "There are crewmates to posion.",
		task_text = "Your useless",
		specials = {RS_Primary,RS_Vent},
		has_tasks = false,
		role_vis = RV_SameLayer,
		layer = 1,
		team = 1,
		primary_valid_targets = VPT_Others,
		immune_to_light_affectors = true,
		color = {r=1,g=100,b=0},
		name_color = {r=1,g=100,b=1}
	})
	
	
	CE_AddHook("CanVent", function(player, usual)
		local vent_set = CE_GetNumberSetting("vent_setting")
		if (vent_set == 1) then
			return usual
		elseif (vent_set == 2) then
			return true
		else
			return false
		end
		return usual
	end)
	
	CE_AddHook("GetRemainText", function(ejected)
		local imp_sub = 0
		if (ejected.Role == "impostor") then
			imp_sub = 1
		end
		return (#CE_GetAllPlayersOnTeam(1,true) - imp_sub) .. " impostors remain!"
	end)
	
	CE_AddStringSetting("vent_setting","Who Can Vent", 1, {"Impostors Only","Everybody","Nobody"})
	CE_AddToggleSetting("end_on_zero_only","Game Only ends on 0 Crew", false, {"True","False"})
	CE_AddToggleSetting("end_on_one_only","Game Only ends on 1 Crewmate", false, {"True","False"})
	CE_AddToggleSetting("vent_visibility","Visibility In Vents", true, {"Yes","No"})
	
	return {"Base","base"} --Display Name then Internal Name
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

function CalculateLightRadius(player,minradius,maxradius,lightsab) --lightsab is a float ranging from 0-1
	if (not CE_GetBoolSetting("vent_visibility")) then
		if (player.InVent) then
			return 0
		end
	end
	local mult = CE_GetInternalNumberSetting("crewmate_vision")
	if (player.Role == "impostor") then
		return maxradius * CE_GetInternalNumberSetting("impostor_vision")
	else
		mult = CE_GetInternalNumberSetting("crewmate_vision")
	end
	
	
	
	
	return lerp(minradius,maxradius,lightsab) * mult

end




function SelectRoles(players) --WHAT. THE HAYSTACK. IS GOING ON.
	
	local RolesToGive = {}
	for i=1, CE_GetInternalNumberSetting("impostor_count") do
		table.insert(RolesToGive,"impostor")
	end
	print("got past imp")
	for i=1, #players - #RolesToGive do
		table.insert(RolesToGive,"crewmate")
	end
	print("witch will use impostor count soon or a custom witch count setting.")
	for i=1, CE_GetInternalNumberSetting("impostor_count") do
		table.insert(RolesToGive,"witch")
	end
	local Selected = {}
	local SelectedRoles = {}
	for i=1, #RolesToGive do
		local impid = math.random(1,#players) --randomly set the impostor id
		table.insert(Selected,players[impid]) --add it to the selected list
		table.insert(SelectedRoles,RolesToGive[i])
		table.remove(players,impid) --remove the chosen item from the playerinfo list
	end
	return {Selected,SelectedRoles} -- sets the sheriff's role
end

function CanUsePrimary(user,victim)
	if (user.ID == victim.ID) then --let them commit death on themselves lol, should probs be removed for other roles though lol
		return true
	end
	if (user.Role ~= "impostor") then
		return false
	end
	if (user.Role == "impostor") then
		if (victim.Role == "impostor") then
			return false
		end
	end
	return true
end

function CheckEndCriteria(tasks_complete, sab_loss)
	local impostors = CE_GetAllPlayersOnTeam(1,true)
	local crewmates = CE_GetAllPlayersOnTeam(0,true)
	
	if (sab_loss) then
		CE_WinGame(CE_GetAllPlayersOnTeam(1,false),"default_impostor")
	end
	
	if (#crewmates == 0 and #impostors == 0) then
		CE_WinGameAlt("error")
	end
	
	if (not CE_GetBoolSetting("end_on_zero_only")) then
		if (#impostors >= #crewmates) then
			CE_WinGame(CE_GetAllPlayersOnTeam(1,false),"default_impostor")
		end
		
		if (not CE_GetBoolSetting("end_on_one_only")) then
		if (#impostors >= #crewmates) then
			CE_WinGame(CE_GetAllPlayersOnTeam(1,false),"default_impostor")
		end
	else
		if (#crewmates == 0 and #impostors ~= 0) then
			CE_WinGame(CE_GetAllPlayersOnTeam(1,false),"default_impostor")
		end
		
	else if
		if (#crewmates == 1 and #impostors ~= 1) then
			CE_WinGame(CE_GetAllPlayersOnTeam(1,false),"default_impostor")
		end
	end
	
	if (#impostors == 0) then
		CE_WinGame(CE_GetAllPlayersOnTeam(0,false),"default_crewmate")
	end
			
	if (#impostors == 6) then
		CE_WinGame(CE_GetAllPlayersOnTeam(0,false),"default_error")
	end
	
	if (tasks_complete) then
		CE_WinGame(CE_GetAllPlayersOnTeam(0,false),"default_crewmate")
	end
	
	
	
	

end


function OnHostRecieve(sender,id,params)
	

end


function OnUsePrimary(user,victim) --attention all gamers, feel free to call CanUsePrimary here, also this is ran on the host
	if (not CanUsePrimary(user,victim)) then
		return
	end
	CE_MurderPlayer(user,victim,true)
	
end
