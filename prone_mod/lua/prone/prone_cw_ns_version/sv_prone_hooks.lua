-- Copyright 2016 George "Stalker" Petrou, enjoy!

local GameMode = tobool(DarkRP) and "darkrp" or engine.ActiveGamemode()

net.Receive("Prone_HandleProne", function(len, ply)
	ply:HandleProne()
end)

hook.Add("PlayerInitialSpawn", "Prone_SetupVariables", function(ply)
	ply.Prone_LastBindKeyPress = 0
	ply.Prone_LastProneRequestDelay = 0

	-- Without this server only variable we would have to call ply:IsProne() a lot
	-- which is a bit more expensive
	ply.InProne = false
end)

net.Receive("Prone_LoadPronedPlayers", function(len, ply)
	for i, v in ipairs(player.GetAll()) do
		if v.InProne then
			net.Start("Prone_StartProne")
				net.WriteEntity(v)
				net.WriteString(v.Prone_OldModel)
				net.WriteColor(Color(v.Prone_OldColor.r, v.Prone_OldColor.g, v.Prone_OldColor.b, v.Prone_OldColor.a))
				net.WriteString(v.Prone_OldBodyGroups)
				net.WriteInt(v.Prone_OldSkin, 8)
				net.WriteColor(v.Prone_OldPlayerColor:ToColor())
			net.Send(ply)
		end
	end
end)

hook.Add("PlayerDisconnected", "Prone_CleanupFakeModels", function(ply)
	if ply.InProne then
		net.Start("Prone_EndProne")
			net.WriteEntity(ply)
		net.Broadcast()
	end
end)

hook.Add("InitPostEntity", "Prone_LoadoutSwitchFix", function()
	local Derived = GAMEMODE.DerivedFrom
	local hookname = "PlayerLoadout"

	if Derived == "nutscript" then
		hookname = "PostPlayerLoadout"
	end

	if Derived ~= "clockwork" then
		hook.Add(hookname, "Prone_LoadoutSwitchFix", function(ply)
			if ply.InProne then
				ply.Prone_OldModel = ply:GetModel()
				prone.UpdateProneModel(ply, ply.Prone_OldModel)

				ply:SetModel("models/player/p_kleiner.mdl")

				ply.Prone_OldColor = ply:GetColor()
			end
		end)
	end
end)

if prone.BindKey then
	if prone.BindKeyDoubleTap then
		hook.Add("KeyRelease", "Prone_BindKeyRelease", function(ply, key)
			if IsFirstTimePredicted() and key == prone.BindKey then
				if key == prone.BindKey then
					if (ply.Prone_LastBindKeyPress or 0) < CurTime() then
						ply.Prone_LastBindKeyPress = CurTime() + .8
					else
						ply:HandleProne()
						ply.Prone_LastBindKeyPress = 0
					end
				elseif prone.JumpToGetUp and key == IN_JUMP and ply.InProne then
					if prone.JumpToGetUpDoubleTap then
						if (ply.Prone_LastBindKeyPress or 0) < CurTime() then
							ply.Prone_LastBindKeyPress = CurTime() + .8
						else
							ply:HandleProne()
							ply.Prone_LastBindKeyPress = 0
						end
					else
						ply:HandleProne()
						ply.Prone_LastBindKeyPress = 0
					end
				end
			end
		end)
	else
		hook.Add("KeyPress", "Prone_BindKeyPress", function(ply, key)
			if IsFirstTimePredicted() and (key == prone.BindKey or (prone.JumpToGetUp and key == IN_JUMP)) then
				prone.HandleProne(ply)
			end
		end)
	end
end

hook.Add("DoPlayerDeath", "Prone_ExitOnDeath", function(ply)
	if IsFirstTimePredicted() and ply.InProne then
		prone.EndProne(ply, true)
	end
end)

hook.Add("PlayerNoClip", "Prone_ExitOnEnterNoclip", function(ply)
	if IsFirstTimePredicted() and ply.InProne then
		prone.EndProne(ply, true)
	end
end)

hook.Add("VehicleMove", "Prone_ExitOnEnterVehicle", function(ply)
	if IsFirstTimePredicted() and ply.InProne then
		prone.EndProne(ply, true)
	end
end)

-- Before we used PlayerTick, that was unnecessary
timer.Create("Prone_ManagePlayersActions", 1, 0, function()
	for i, v in ipairs(player.GetAll()) do
		if v.InProne then
			if v:IsRagdoll() or v:InVehicle() then
				prone.EndProne(v, true)
			elseif not v.Prone_AnimWaterFix and v:WaterLevel() > 1 then
				prone.EndProne(v)
				v.Prone_AnimWaterFix = true
			end
		end
	end
end)

hook.Add("PlayerFootstep", "Prone_MuteFootstepSound", function(ply)
	return ply.InProne
end)

if GameMode == "terrortown" then
	hook.Add("TTTPrepareRound", "Prone_FixRemove", function()
		for i, v in ipairs(player.GetAll()) do
			if v.InProne then
				prone.EndProne(v)
			end
		end
	end)

	hook.Add("TTTBeginRound", "Prone_FixRemove", function()
		for i, v in ipairs(player.GetAll()) do
			if v.InProne then
				prone.EndProne(v)
			end
		end
	end)
end