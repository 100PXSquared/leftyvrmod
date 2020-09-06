g_VR = g_VR or {}

if CLIENT then
	print("VRMOD INIT")
	g_VR.scale = 0
	g_VR.origin = Vector(0,0,0)
	g_VR.originAngle = Angle(0,0,0)
	g_VR.viewModel = nil --this will point to either the viewmodel, worldmodel or nil
	g_VR.viewModelMuzzle = nil
	g_VR.viewModelPos = Vector(0,0,0)
	g_VR.viewModelAng = Angle(0,0,0)
	g_VR.usingWorldModels = false
	g_VR.active = false
	g_VR.threePoints = false --hmd + 2 controllers
	g_VR.sixPoints = false --hmd + 2 controllers + 3 trackers
	g_VR.tracking = {}
	g_VR.input = {}
	g_VR.previousInput = {}
	g_VR.errorText = ""

	g_VR.leftHanded = false
		
	concommand.Add( "vrmod_start", function( ply, cmd, args )
		VRUtilClientStart()
	end )
	
	concommand.Add( "vrmod_exit", function( ply, cmd, args )
		VRUtilClientExit()
	end )
	
	concommand.Add( "vrmod_update", function( ply, cmd, args )
		local updateScriptPath = util.RelativePathToFull("lua\\bin\\update_vrmod.bat")
		print("\nUpdate script path:\n"..(updateScriptPath == "lua\\bin\\update_vrmod.bat" and "not found" or updateScriptPath))
		print("\nYou must disconnect from the game before running the script. If the module doesn't get updated after attempting to run the script multiple times, try updating it manually by following instructions in the workshop description.")
	end )
	
	concommand.Add( "vrmod_reset", function( ply, cmd, args )
		for k,v in pairs(g_VR.convars) do
			v:Revert()
		end
		hook.Call("VRMod_Reset")
	end )
	
	local moduleLoaded = false
	g_VR.moduleVersion = 0
	if file.Exists("lua/bin/gmcl_vrmod_win32.dll", "GAME") then
		moduleLoaded = pcall(function() require("vrmod") end)
		g_VR.moduleVersion = moduleLoaded and VRMOD_GetVersion and VRMOD_GetVersion() or 0
	end
	
	local mcoreOriginalValue = GetConVar("gmod_mcore_test"):GetString()
	local viewModelFovOriginalValue = GetConVar("viewmodel_fov"):GetString()
	
	
	hook.Add( "PopulateToolMenu", "vrutil_hook_populatetoolmenu", function()
		spawnmenu.AddToolMenuOption( "Utilities", "Virtual Reality", "vr_util", "VRMod", "", "", function( panel )
			local dlabel = vgui.Create( "DLabel", Panel )
			panel:AddItem(dlabel)
			dlabel:SetWrap(true)
			dlabel:SetAutoStretchVertical(true)
			dlabel:SetText( "This menu is deprecated.\nTo access VRMod, enter \"vrmod\" into the console.\nYou can also bind it to a key using the bind command, for example \"bind f2 vrmod\"" )
			dlabel:SetColor(Color(0,0,0))
		end )
	end )
	
	--set vr origin so that hmd will be at given pos
	function VRUtilSetOrigin(pos)
		g_VR.origin = pos + ( g_VR.origin - g_VR.tracking.hmd.pos )
	end
	
	--rotates origin while maintaining hmd pos
	function VRUtilSetOriginAngle(ang)
		local raw = WorldToLocal(g_VR.tracking.hmd.pos, Angle(0,0,0), g_VR.origin, g_VR.originAngle)
		g_VR.originAngle = ang
		local newPos = LocalToWorld(raw, Angle(0,0,0), g_VR.origin, g_VR.originAngle)
		g_VR.origin = g_VR.origin + ( g_VR.tracking.hmd.pos - newPos )
	end
	
	function VRUtilHandleTracking()
	
		local tracking = VRMOD_GetPoses()

		--convert to world positions and apply scale
		for k,v in pairs(tracking) do
			v.pos, v.ang = LocalToWorld(v.pos * g_VR.scale, v.ang, g_VR.origin, g_VR.originAngle)
			v.vel = LocalToWorld(v.vel, Angle(0,0,0), Vector(0,0,0), g_VR.originAngle) * g_VR.scale
			v.angvel = LocalToWorld(Vector(v.angvel.pitch, v.angvel.yaw, v.angvel.roll), Angle(0,0,0), Vector(0,0,0), g_VR.originAngle)
			if k == "pose_righthand" then
				v.pos, v.ang = LocalToWorld(g_VR.rightControllerOffsetPos * 0.01 * g_VR.scale, g_VR.rightControllerOffsetAng, v.pos, v.ang)
			elseif k == "pose_lefthand" then
				v.pos, v.ang = LocalToWorld(g_VR.leftControllerOffsetPos * 0.01 * g_VR.scale, g_VR.leftControllerOffsetAng, v.pos, v.ang)
			end
			g_VR.tracking[k] = v
		end

		g_VR.threePoints = (g_VR.tracking.hmd and g_VR.tracking.pose_lefthand and g_VR.tracking.pose_righthand) ~= nil
		g_VR.sixPoints = (g_VR.threePoints and g_VR.tracking.pose_waist and g_VR.tracking.pose_leftfoot and g_VR.tracking.pose_rightfoot) ~= nil
		
		hook.Call("VRMod_Tracking")
	end
	
	function VRUtilHandleInput()
		g_VR.input = VRMOD_GetActions()
		if g_VR.input.vector2_walkdirection.x == 0 and g_VR.input.vector2_walkdirection.y == 0 then
			g_VR.input.boolean_walk = false
		end
		local changes = false
		for k,v in pairs(g_VR.input) do
			if isbool(v) and v ~= g_VR.previousInput[k] then
				hook.Call("VRMod_Input",nil,k,v)
			end
		end
		g_VR.previousInput = g_VR.input
	end
	
	function VRUtilClientStart()
		RunConsoleCommand("gmod_mcore_test", "0")
		
		VRMOD_Shutdown() --in case we're retrying after an error and shutdown wasn't called
		
		if VRMOD_Init() == false then
			print("vr init failed")
			return
		end
		
		local vrViewParams = VRMOD_GetViewParameters()
		
		rtWidth, rtHeight = vrViewParams.recommendedWidth*2, vrViewParams.recommendedHeight

		
		VRMOD_ShareTextureBegin()
		g_VR.rt = GetRenderTarget( "vrmod_rt".. tostring(SysTime()), rtWidth, rtHeight)
		VRMOD_ShareTextureFinish()
		
		
		--set up active bindings
		VRMOD_SetActionManifest("vrmod/vrmod_action_manifest.txt")
		VRMOD_SetActiveActionSets("/actions/base", "/actions/main")
		
		VRUtilLoadCustomActions()
		
		--start transmit loop and send join msg to server
		VRUtilNetworkInit() 
		
		--set initial origin
		g_VR.origin = LocalPlayer():GetPos()
		
		--
		g_VR.scale = g_VR.convars.scale:GetFloat()
		
		--
		g_VR.rightControllerOffsetPos  = Vector(g_VR.convars.controllerOffsetX:GetFloat(), g_VR.convars.controllerOffsetY:GetFloat(), g_VR.convars.controllerOffsetZ:GetFloat())
		g_VR.leftControllerOffsetPos  = g_VR.rightControllerOffsetPos * Vector(1,-1,1)
		g_VR.rightControllerOffsetAng = Angle(g_VR.convars.controllerOffsetPitch:GetFloat(), g_VR.convars.controllerOffsetYaw:GetFloat(), g_VR.convars.controllerOffsetRoll:GetFloat())
		g_VR.leftControllerOffsetAng = g_VR.rightControllerOffsetAng
		
		--dont call the input changed hook on the first run
		g_VR.input = VRMOD_GetActions()
		g_VR.previousInput = g_VR.input
		
		g_VR.active = true
		
		--3D audio fix
		hook.Add("CalcView","vrutil_hook_calcview",function(ply, pos, ang, fv)
			if g_VR.threePoints then
				return {origin = g_VR.tracking.hmd.pos, angles = g_VR.tracking.hmd.ang, fov = fv} 
			end
		end)
		
		vrmod.StartLocomotion()
		
		--rendering
		local hfovLeft, hfovRight, aspectLeft, aspectRight = vrViewParams.horizontalFOVLeft, vrViewParams.horizontalFOVRight, vrViewParams.aspectRatioLeft, vrViewParams.aspectRatioRight

		g_VR.view = {
				x = 0, y = 0,
				w = rtWidth/2, h = rtHeight,
				--aspectratio = aspect,
				--fov = hfov,
				drawmonitors = true,
				drawviewmodel = false,
				znear = g_VR.convars.znear:GetFloat()
		}

		local	ipd, eyez = vrViewParams.eyeToHeadTransformPosRight.x*2, vrViewParams.eyeToHeadTransformPosRight.z
		
		local desktopView = g_VR.convars.desktopView:GetInt()
		local cropVerticalMargin = (1 - (ScrH()/ScrW() * (rtWidth/2) / rtHeight)) / 2
		local cropHorizontalOffset = (desktopView==3) and 0.5 or 0
		local mat_rt = CreateMaterial("vrmod_mat_rt"..tostring(SysTime()), "UnlitGeneric",{ ["$basetexture"] = g_VR.rt:GetName() })
			
		local localply = LocalPlayer()
		local currentViewEnt = localply
		local pos1, ang1
			
		hook.Add("RenderScene", "vrutil_hook_renderscene", function()
			VRMOD_SubmitSharedTexture()
			VRMOD_UpdatePosesAndActions()

			VRUtilHandleTracking()
			VRUtilHandleInput()
			
			if not g_VR.threePoints or not system.HasFocus() or #g_VR.errorText > 0 then
				render.Clear(0,0,0,255,true,true)
				cam.Start2D()
				local text = not system.HasFocus() and "Please focus the game window" or not g_VR.tracking.hmd and "Waiting for HMD tracking..." or not g_VR.tracking.pose_righthand and "Waiting for right hand tracking..." or not g_VR.tracking.pose_lefthand and "Waiting for left hand tracking..." or g_VR.errorText
				draw.DrawText( text, "DermaLarge", ScrW() / 2, ScrH() / 2, Color( 47,149,241, 255 ), TEXT_ALIGN_CENTER )
				cam.End2D()
				return true
			end
			
			--update clientside local player net frame
			local netFrame = VRUtilNetUpdateLocalPly()

			g_VR.leftHanded = g_VR.convars.leftHanded:GetBool()
			
			--update viewmodel position
			if g_VR.currentvmi then
				local pos, ang = LocalToWorld(
					g_VR.currentvmi.offsetPos,
					g_VR.currentvmi.offsetAng,
					g_VR.leftHanded and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos,
					g_VR.leftHanded and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang
				)

				g_VR.viewModelPos = pos
				g_VR.viewModelAng = ang
			end
			if IsValid(g_VR.viewModel) then
				if not g_VR.usingWorldModels then
					g_VR.viewModel:SetPos(g_VR.viewModelPos)
					g_VR.viewModel:SetAngles(g_VR.viewModelAng)
					g_VR.viewModel:SetupBones()

					--override hand pose in net frame
					--if netFrame then
					--	local b = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
					--	if b then
					--		local mtx = g_VR.viewModel:GetBoneMatrix(b)
					--		if g_VR.leftHanded then
					--			netFrame.lefthandPos = mtx:GetTranslation()
					--			netFrame.lefthandAng = mtx:GetAngles() - Angle(0,0,180)
					--		else
					--			netFrame.righthandPos = mtx:GetTranslation()
					--			netFrame.righthandAng = mtx:GetAngles() - Angle(0,0,180)
					--		end
					--	end
					--end
				end
				g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
			end
			
			--set view according to viewentity
			local viewEnt = localply:GetViewEntity()
			if viewEnt ~= localply then
				local rawPos, rawAng = WorldToLocal(g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang, g_VR.origin, g_VR.originAngle)
				if viewEnt ~= currentViewEnt then
					local pos,ang = LocalToWorld(rawPos,rawAng,viewEnt:GetPos(),viewEnt:GetAngles())
					pos1, ang1 = WorldToLocal(viewEnt:GetPos(),viewEnt:GetAngles(),pos,ang)
				end
				rawPos, rawAng = LocalToWorld(rawPos, rawAng, pos1, ang1)
				g_VR.view.origin, g_VR.view.angles = LocalToWorld(rawPos,rawAng,viewEnt:GetPos(),viewEnt:GetAngles())
			else
				g_VR.view.origin, g_VR.view.angles = g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
			end
			currentViewEnt = viewEnt
			
			--
			g_VR.view.origin = g_VR.view.origin + g_VR.view.angles:Forward()*-(eyez*g_VR.scale)
			g_VR.eyePosLeft = g_VR.view.origin + g_VR.view.angles:Right()*-(ipd*0.5*g_VR.scale)
			g_VR.eyePosRight = g_VR.view.origin + g_VR.view.angles:Right()*(ipd*0.5*g_VR.scale)

			render.PushRenderTarget( g_VR.rt )

				-- left
				g_VR.view.origin = g_VR.eyePosLeft
				g_VR.view.x = 0
				g_VR.view.fov = hfovLeft
				g_VR.view.aspectratio = aspectLeft
				hook.Call("VRMod_PreRender")
				render.RenderView(g_VR.view)
				-- right
				
				g_VR.view.origin = g_VR.eyePosRight
				g_VR.view.x = rtWidth/2
				g_VR.view.fov = hfovRight
				g_VR.view.aspectratio = aspectRight
				hook.Call("VRMod_PreRenderRight")
				render.RenderView(g_VR.view)
				--
				if not LocalPlayer():Alive() then
					cam.Start2D()
					surface.SetDrawColor( 255, 0, 0, 128 )
					surface.DrawRect( 0, 0, rtWidth, rtHeight )
					cam.End2D()
				end
			

			render.PopRenderTarget( g_VR.rt )
			
			if desktopView > 1 then
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(mat_rt)
				render.CullMode(1)
				surface.DrawTexturedRectUV(-1, -1, 2, 2, cropHorizontalOffset, 1-cropVerticalMargin, 0.5+cropHorizontalOffset, cropVerticalMargin)
				render.CullMode(0)
			end
			
			hook.Call("VRMod_PostRender")
			
			--return true to override default scene rendering
			return true
		end)
		
		g_VR.usingWorldModels = g_VR.convars.useWorldModels:GetBool()
		
		if not g_VR.usingWorldModels then
			RunConsoleCommand("viewmodel_fov", "90")

			hook.Add("CalcViewModelView","vrutil_hook_calcviewmodelview",function(wep, vm, oldPos, oldAng, pos, ang)
				return g_VR.viewModelPos, g_VR.viewModelAng
			end)

			local blockViewModelDraw = true
			g_VR.allowPlayerDraw = false
			local hideplayer = g_VR.convars.floatingHands:GetBool()
			hook.Add("PostDrawTranslucentRenderables","vrutil_hook_drawplayerandviewmodel",function( bDrawingDepth, bDrawingSkybox )
				if bDrawingSkybox or not LocalPlayer():Alive() or not (EyePos()==g_VR.eyePosLeft or EyePos()==g_VR.eyePosRight) then return end
				--draw viewmodel
				if IsValid(g_VR.viewModel) then
					blockViewModelDraw = false
					g_VR.viewModel:DrawModel()
					blockViewModelDraw = true
				end
				--draw playermodel
				if not hideplayer then
					g_VR.allowPlayerDraw = true
					cam.Start3D() cam.End3D() --this invalidates ShouldDrawLocalPlayer cache
					local tmp = render.GetBlend()
					render.SetBlend(1) --without this the despawning bullet casing effect gets applied to the player???
					LocalPlayer():DrawModel()
					render.SetBlend(tmp)
					cam.Start3D() cam.End3D()
					g_VR.allowPlayerDraw = false
				end
				--draw menus
				VRUtilRenderMenuSystem()
			end)

			hook.Add("PreDrawPlayerHands","vrutil_hook_predrawplayerhands",function()
				return true
			end)

			hook.Add("PreDrawViewModel","vrutil_hook_predrawviewmodel",function(vm, ply, wep)
				return blockViewModelDraw or nil
			end)
		else
			g_VR.allowPlayerDraw = true
		end
		
		hook.Add("ShouldDrawLocalPlayer","vrutil_hook_shoulddrawlocalplayer",function(ply)
			return g_VR.allowPlayerDraw
		end)
		
		-- add laser pointer
		if g_VR.convars.laserPointer:GetBool() then
			local mat = Material("cable/redlaser")
			hook.Add("PostDrawTranslucentRenderables","vr_laserpointer",function( bDrawingDepth, bDrawingSkybox )
				if bDrawingSkybox then return end
				if g_VR.viewModelMuzzle and not g_VR.menuFocus then
					render.SetMaterial(mat)
					render.DrawBeam(g_VR.viewModelMuzzle.Pos, g_VR.viewModelMuzzle.Pos + g_VR.viewModelMuzzle.Ang:Forward()*10000, 1, 0, 1, Color(255,255,255,255))
				end
			end)
		end
		
	end
	
	function VRUtilClientExit()
		RunConsoleCommand("gmod_mcore_test", mcoreOriginalValue)
		RunConsoleCommand("viewmodel_fov", viewModelFovOriginalValue)
		
		VRUtilMenuClose()
		
		VRUtilNetworkCleanup()
		
		vrmod.StopLocomotion()
		
		if IsValid(g_VR.viewModel) and g_VR.viewModel:GetClass() == "class C_BaseFlex" then
			g_VR.viewModel:Remove()
		end
		g_VR.viewModel = nil
		g_VR.viewModelMuzzle = nil
		
		LocalPlayer():GetViewModel().RenderOverride = nil
		LocalPlayer():GetViewModel():RemoveEffects(EF_NODRAW)
		
		hook.Remove("RenderScene","vrutil_hook_renderscene")
		hook.Remove("PreDrawViewModel","vrutil_hook_predrawviewmodel")
		hook.Remove( "DrawPhysgunBeam", "vrutil_hook_drawphysgunbeam")
		hook.Remove( "PreDrawHalos", "vrutil_hook_predrawhalos")
		hook.Remove("EntityFireBullets","vrutil_hook_entityfirebullets")
		hook.Remove("Tick","vrutil_hook_tick")
		hook.Remove("PostDrawSkyBox","vrutil_hook_postdrawskybox")
		hook.Remove("CalcView","vrutil_hook_calcview")
		hook.Remove("PostDrawTranslucentRenderables","vr_laserpointer")
		hook.Remove("CalcViewModelView","vrutil_hook_calcviewmodelview")
		hook.Remove("PostDrawTranslucentRenderables","vrutil_hook_drawplayerandviewmodel")
		hook.Remove("PreDrawPlayerHands","vrutil_hook_predrawplayerhands")
		hook.Remove("PreDrawViewModel","vrutil_hook_predrawviewmodel")
		hook.Remove("ShouldDrawLocalPlayer","vrutil_hook_shoulddrawlocalplayer")
		
		g_VR.tracking = {}
		g_VR.threePoints = false
		g_VR.sixPoints = false
		

		

		VRMOD_Shutdown()
		
		g_VR.active = false
		
		
	end
	
	hook.Add("ShutDown","vrutil_hook_shutdown",function()
		if g_VR.net[LocalPlayer():SteamID()] then
			VRUtilClientExit()
		end
	end)
	
	
elseif SERVER then
	
	hook.Add("AllowPlayerPickup","vrutil_hook_allowplayerpickup",function(ply)
		if g_VR[ply:SteamID()] ~= nil then
			return false
		end
	end)
	
end


