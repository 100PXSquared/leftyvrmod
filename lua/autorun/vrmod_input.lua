if CLIENT then

	g_VR = g_VR or {}
	
	local menuPressTime = 0
	local flashlight
	
	function VRUtilPickup(leftHand)
		net.Start("vrutil_net_pickup")
		net.WriteBool(leftHand)
		net.WriteVector(leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos)
		net.WriteAngle(leftHand and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang)
		net.SendToServer()
	end
	
	function VRUtilDrop(leftHand)
		net.Start("vrutil_net_drop")
		net.WriteBool(leftHand)
		net.WriteVector(leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos)
		net.WriteAngle(leftHand and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang)
		net.SendToServer()
		if leftHand then
			g_VR.heldEntityLeft = nil
		else
			g_VR.heldEntityRight = nil
		end
	end
	
	hook.Add("VRMod_EnterVehicle","vrmod_switchactionset",function()
		VRMOD_SetActiveActionSets("/actions/base", "/actions/driving")
	end)
	
	hook.Add("VRMod_ExitVehicle","vrmod_switchactionset",function()
		VRMOD_SetActiveActionSets("/actions/base", "/actions/main")
	end)
	

	hook.Add("VRMod_Input","vrutil_hook_defaultinput",function( action, pressed )

		if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
		
		if (action == "boolean_primaryfire" or action == "boolean_turret") and not g_VR.menuFocus then
			LocalPlayer():ConCommand(pressed and "+attack" or "-attack")
			return
		end
		
		if action == "boolean_secondaryfire" then
			LocalPlayer():ConCommand(pressed and "+attack2" or "-attack2")
			return
		end
		
		if action == "boolean_left_pickup" then
			if pressed then
				VRUtilPickup(true)
			else
				VRUtilDrop(true)
			end
			return
		end
		
		if action == "boolean_right_pickup" then
			if pressed then
				VRUtilPickup(false)
			else
				VRUtilDrop(false)
			end
			return
		end
		
		if action == "boolean_use" or action == "boolean_exit" then
			if pressed then
				LocalPlayer():ConCommand("+use")
				local wep = LocalPlayer():GetActiveWeapon()
				if IsValid(wep) and wep:GetClass() == "weapon_physgun" then
					hook.Add("CreateMove", "vrutil_hook_cmphysguncontrol", function(cmd)
						if  g_VR.input.vector2_walkdirection.y > 0.9 then
							cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_FORWARD))
						elseif g_VR.input.vector2_walkdirection.y < -0.9 then
							cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_BACK))
						else
							cmd:SetMouseX(g_VR.input.vector2_walkdirection.x*50)
							cmd:SetMouseY(g_VR.input.vector2_walkdirection.y*-50)
						end
					end)
				end
			else
				LocalPlayer():ConCommand("-use")
				hook.Remove("CreateMove", "vrutil_hook_cmphysguncontrol")
			end
			return
		end
		
		if action == "boolean_changeweapon" then
			if pressed then
				VRUtilWeaponMenuOpen()
			else
				VRUtilWeaponMenuClose()
			end
			return
		end
		
		if action == "boolean_flashlight" then
			if pressed then
				surface.PlaySound("items/flashlight1.wav")
				if not IsValid(flashlight) then
					flashlight = ProjectedTexture()
					flashlight:SetTexture( "effects/flashlight001" )
					flashlight:SetFOV(60)
					flashlight:SetFarZ(750)
					hook.Add("PreRender","vrutil_hook_flashlight",function()
						if not g_VR.threePoints then return end
						local pos = GetConVar("vrmod_lefthanded"):GetBool() and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
						local ang = GetConVar("vrmod_lefthanded"):GetBool() and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang
						local muzzle
						if IsValid(g_VR.viewModel) then
							muzzle = g_VR.viewModel:GetAttachment(1)
						end
						if muzzle then
							pos = muzzle.Pos
							if g_VR.currentvmi and g_VR.currentvmi.wrongMuzzleAng then
								ang = GetConVar("vrmod_lefthanded"):GetBool() and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang
							else
								ang = muzzle.Ang
							end
						end
						flashlight:SetPos(pos + ang:Forward()*10)
						flashlight:SetAngles(ang)
						flashlight:Update()
					end)
				else
					hook.Remove("PreRender","vrutil_hook_flashlight")
					flashlight:Remove()
				end
			end
			return
		end
		
		if action == "boolean_reload" then
			LocalPlayer():ConCommand(pressed and "+reload" or "-reload")
			return
		end
		
		if action == "boolean_undo" then
			if pressed then
				LocalPlayer():ConCommand("gmod_undo")
			end
			return
		end
		
		if action == "boolean_spawnmenu" then
			if pressed then
				g_VR.MenuOpen()
			else
				g_VR.MenuClose()
			end
			return
		end
		
		for i = 1,#g_VR.CustomActions do
			if action == g_VR.CustomActions[i][1] then
				local commands = string.Explode(";",g_VR.CustomActions[i][pressed and 2 or 3],false)
				for j = 1,#commands do
					local args = string.Explode(" ",commands[j],false)
					RunConsoleCommand(args[1],unpack(args,2))
				end
			end
		end
		
	end)
end