if SERVER then return end

local cv_controllerOriented = CreateClientConVar("vrmod_controlleroriented", "0", true, false)
local cv_smoothTurn = CreateClientConVar("vrmod_smoothturn", "0", true, false)
local cv_smoothTurnRate = CreateClientConVar("vrmod_smoothturnrate", "180", true, false)

local function start()
	local vehicleOffsetsReady = false
	local vehicleYawOffset = 0
	
	local moveParent = nil
	local originOffset = Vector(0,0,0)
	
	local blockTeleport = false
	local delayRelease = false

	local localPlayer = LocalPlayer()
	local steamid = localPlayer:SteamID()
	local controllerOriented = cv_controllerOriented:GetBool()
	local smoothTurn = cv_smoothTurn:GetBool()
	local smoothTurnRate = cv_smoothTurnRate:GetInt()
	
	hook.Add("PreRender","vrutil_hook_locomotion",function()
		if not g_VR.threePoints then return end
		--**************
		--    in-vehicle 
		--**************
		if localPlayer:InVehicle() then
			local v = localPlayer:GetVehicle()
			local attachment = v:GetAttachment(v:LookupAttachment("vehicle_driver_eyes"))
			local targetPos, targetAng = LocalToWorld(Vector(10,0,2), Angle(), attachment.Pos, attachment.Ang)
			--get offsets
			if not vehicleOffsetsReady then
				vehicleOffsetsReady = true
				vehicleYawOffset = math.AngleDifference(targetAng.yaw, g_VR.tracking.hmd.ang.yaw) - targetAng.yaw + g_VR.originAngle.yaw
				local wpos, wang = LocalToWorld(Vector(0,0,0),Angle(0,vehicleYawOffset,0),Vector(0,0,0),targetAng)
				VRUtilSetOriginAngle(wang)
				VRUtilSetOrigin(targetPos)
				originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),targetPos, targetAng)
				return
			end
			--offsets ready
			local wpos, wang = LocalToWorld(Vector(0,0,0),Angle(0,vehicleYawOffset,0),Vector(0,0,0),targetAng)
			VRUtilSetOriginAngle(wang)
			g_VR.origin = LocalToWorld(originOffset,Angle(0,0,0),targetPos, targetAng)
			return
		end
		if vehicleOffsetsReady then
			vehicleOffsetsReady = false
			VRUtilSetOriginAngle(Angle(0,g_VR.originAngle.yaw,0))
			originOffset = Vector(0,0,0)
			vehicleYawOffset = 0
		end
		--**************
		--  not in vehicle
		--**************
			
		--figure out movement parent
		local newMoveParent = (g_VR.input.boolean_walk or not localPlayer:IsFlagSet(FL_ONGROUND) or delayRelease) and localPlayer or localPlayer:GetGroundEntity()
		if newMoveParent ~= moveParent then
			moveParent = newMoveParent
			if IsValid(moveParent) then
				originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
			end
		end
		--move
		local plyPos = localPlayer:GetPos()
		local plyTargetPos = g_VR.tracking.hmd.pos + Angle(0,g_VR.tracking.hmd.ang.yaw,0):Forward()*-10
		if IsValid(moveParent) then
			g_VR.origin = LocalToWorld(originOffset,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
		elseif not blockTeleport and math.Distance( plyTargetPos.x, plyTargetPos.y, plyPos.x, plyPos.y) > 16 then
			g_VR.origin = plyPos + Vector(g_VR.origin.x - plyTargetPos.x, g_VR.origin.y - plyTargetPos.y,0)
			blockTeleport = true
			timer.Simple(1,function() if not g_VR.input.boolean_walk then blockTeleport = false end end)
		end
		g_VR.origin.z = plyPos.z
			
		if smoothTurn then
			if g_VR.input.vector2_smoothturn.x ~= 0 and math.abs(g_VR.input.vector2_smoothturn.x) > math.abs(g_VR.input.vector2_smoothturn.y) then
				VRUtilSetOriginAngle(g_VR.originAngle - Angle(0, g_VR.input.vector2_smoothturn.x * smoothTurnRate * RealFrameTime(), 0))
				if IsValid(moveParent) then
					originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
				end
			end
		end
	end)
	
	
	hook.Add("VRMod_Input","vrutil_hook_locomotioninput",function( action, pressed )
		if localPlayer:InVehicle() then return end
			
		if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end

		if not smoothTurn and (action == "boolean_turnleft" or action == "boolean_turnright") and pressed then
			if action == "boolean_turnright" then
				VRUtilSetOriginAngle(g_VR.originAngle - Angle(0, 360/12, 0))
			else
				VRUtilSetOriginAngle(g_VR.originAngle + Angle(0, 360/12, 0))
			end
			if IsValid(moveParent) then
				originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
			end
		end
			
		if action == "boolean_jump" then
			if pressed then
				localPlayer:ConCommand("+jump")
				if localPlayer:IsFlagSet(FL_ONGROUND) then
					localPlayer:ConCommand("+duck")
				end
			else
				localPlayer:ConCommand("-jump")
				localPlayer:ConCommand("-duck")
			end
		end
			
		if action == "boolean_walk" then
			if pressed then
				blockTeleport = true
				delayRelease = true
			else
				timer.Simple(0.5,function()
					if not g_VR.input.boolean_walk then 
						delayRelease = false 
						timer.Simple(0.5,function() if not g_VR.input.boolean_walk then blockTeleport = false end end)
					end
				end)
					
			end
		end
	end)
	
	hook.Add("CreateMove","vrutil_hook_createmove",function(cmd)
		if not g_VR.threePoints then return end
			
		--in vehicle
		if localPlayer:InVehicle() then
			cmd:SetForwardMove((g_VR.input.vector1_forward-g_VR.input.vector1_reverse)*400)
			cmd:SetSideMove(g_VR.input.vector2_steer.x*400)
			local _,relativeAng = WorldToLocal(Vector(0,0,0),g_VR.tracking.hmd.ang,Vector(0,0,0),localPlayer:GetVehicle():GetAngles())
			cmd:SetViewAngles(relativeAng)
			cmd:SetButtons( bit.bor(cmd:GetButtons(), g_VR.input.boolean_turbo and IN_SPEED or 0, g_VR.input.boolean_handbrake and IN_JUMP or 0) )
			return
		end
			
		--handle player (not vr) view angles
		if GetConVar("vrmod_lefthanded"):GetBool() then
			local viewAngles = g_VR.currentvmi and g_VR.currentvmi.wrongMuzzleAng and g_VR.tracking.pose_lefthand.ang or g_VR.viewModelMuzzle and g_VR.viewModelMuzzle.Ang or g_VR.tracking.hmd.ang
		else
			local viewAngles = g_VR.currentvmi and g_VR.currentvmi.wrongMuzzleAng and g_VR.tracking.pose_righthand.ang or g_VR.viewModelMuzzle and g_VR.viewModelMuzzle.Ang or g_VR.tracking.hmd.ang
		end

		viewAngles = viewAngles:Forward():Angle()
		cmd:SetViewAngles(viewAngles)
			
		--handle player movement
		if g_VR.input.boolean_walk or not localPlayer:IsFlagSet(FL_ONGROUND) or delayRelease then
			local walkDirectionWorld = LocalToWorld(Vector(g_VR.input.vector2_walkdirection.y * math.abs(g_VR.input.vector2_walkdirection.y), (-g_VR.input.vector2_walkdirection.x) * math.abs(g_VR.input.vector2_walkdirection.x), 0)*localPlayer:GetMaxSpeed(), Angle(0,0,0), Vector(0,0,0), Angle(0, controllerOriented and g_VR.tracking.pose_lefthand.ang.yaw or g_VR.tracking.hmd.ang.yaw, 0))
			local walkDirViewAngRelative = WorldToLocal(Vector( walkDirectionWorld.x , walkDirectionWorld.y,0), Angle(), Vector(), Angle(0,viewAngles.yaw,0))
			cmd:SetForwardMove( walkDirViewAngRelative.x )
			cmd:SetSideMove( -walkDirViewAngRelative.y )
			if localPlayer:IsFlagSet(FL_INWATER) then
				cmd:SetUpMove( (controllerOriented and g_VR.tracking.pose_lefthand.ang.pitch or g_VR.tracking.hmd.ang.pitch)*-4 )
			end
			cmd:SetButtons( bit.bor(cmd:GetButtons(), g_VR.input.boolean_sprint and IN_SPEED or 0, localPlayer:GetMoveType() == MOVETYPE_LADDER and IN_FORWARD or 0, (g_VR.tracking.hmd.pos.z < ( g_VR.origin.z + 40 )) and IN_DUCK or 0 ) )
		else --make the player follow the hmd
			local plyPos = localPlayer:GetPos()
			local plyTargetPos = g_VR.tracking.hmd.pos + Angle(0,g_VR.tracking.hmd.ang.yaw,0):Forward()*-10
			local walkDirViewAngRelative = WorldToLocal(Vector( (plyTargetPos.x - plyPos.x) * 8 , (plyPos.y - plyTargetPos.y) * -8,0), Angle(), Vector(), Angle(0,viewAngles.yaw,0))
			cmd:SetForwardMove( walkDirViewAngRelative.x )
			cmd:SetSideMove( -walkDirViewAngRelative.y )
		end
	end)
end

local function stop()
	hook.Remove("CreateMove","vrutil_hook_createmove")
	hook.Remove("VRMod_Input","vrutil_hook_locomotioninput")
	hook.Remove("PreRender","vrutil_hook_locomotion")
	LocalPlayer():SetEyeAngles(Angle(0,0,0))
end

local function options( panel )
	
	local tmp = vgui.Create("DCheckBoxLabel")
	panel:Add(tmp)
	tmp:Dock( TOP )
	tmp:DockMargin( 0, 0, 0, 5 )
	tmp:SetDark(true)
	tmp:SetText("Controller oriented locomotion")
	tmp:SetChecked(cv_controllerOriented:GetBool())
	function tmp:OnChange(val)
		cv_controllerOriented:SetBool(val)
	end
			
	local tmp = vgui.Create("DCheckBoxLabel")
	panel:Add(tmp)
	tmp:Dock( TOP )
	tmp:DockMargin( 0, 0, 0, 5 )
	tmp:SetDark(true)
	tmp:SetText("Smooth turning")
	tmp:SetChecked(cv_smoothTurn:GetBool())
	function tmp:OnChange(val)
		cv_smoothTurn:SetBool(val)
	end
			
	local tmp = vgui.Create("DNumSlider")
	panel:Add(tmp)
	tmp:Dock( TOP )
	tmp:DockMargin( 0, 0, 0, 5 )
	tmp:SetMin(1)
	tmp:SetMax(360)
	tmp:SetDecimals(0)
	tmp:SetValue(cv_smoothTurnRate:GetInt())
	tmp:SetDark(true)
	tmp:SetText("Smooth turn rate")
	function tmp:OnValueChanged(val)
		cv_smoothTurnRate:SetInt(dnumslider1:GetValue())
	end

end

timer.Simple(0,function()
	vrmod.AddLocomotionOption("smooth", start, stop, options)
end)



