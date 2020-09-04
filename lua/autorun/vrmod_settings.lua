if SERVER then return end

g_VR = g_VR or {}

g_VR.convars = g_VR.convars or {}
g_VR.convars.configVersion 			=	CreateClientConVar("vrmod_configversion", "4", true, false)
g_VR.convars.altHead 				=	CreateClientConVar("vrmod_althead", "0", true, false)
g_VR.convars.autoStart				=	CreateClientConVar("vrmod_autostart", "0", true, false)
g_VR.convars.scale					=	CreateClientConVar("vrmod_scale", "38.7", true, false)
g_VR.convars.heightMenu				=	CreateClientConVar("vrmod_heightmenu", "1", true, false)
g_VR.convars.floatingHands			=	CreateClientConVar("vrmod_floatinghands", "0", true, false)
g_VR.convars.desktopView			=	CreateClientConVar("vrmod_desktopview", "3", true, false)
g_VR.convars.useWorldModels			= 	CreateClientConVar("vrmod_useworldmodels", "0", true, false)
g_VR.convars.laserPointer			=	CreateClientConVar("vrmod_laserpointer", "0", true, false)
g_VR.convars.znear					=	CreateClientConVar("vrmod_znear", "1", true, false)
g_VR.convars.oldCharacterYaw		=	CreateClientConVar("vrmod_oldcharacteryaw", "0", true, false)
g_VR.convars.locomotion				=	CreateClientConVar("vrmod_locomotion", "1", true, false)
g_VR.convars.controllerOffsetX		=	CreateClientConVar("vrmod_controlleroffset_x", "-15", true, false)
g_VR.convars.controllerOffsetY		=	CreateClientConVar("vrmod_controlleroffset_y", "-1", true, false)
g_VR.convars.controllerOffsetZ		=	CreateClientConVar("vrmod_controlleroffset_z", "5", true, false)
g_VR.convars.controllerOffsetPitch	=	CreateClientConVar("vrmod_controlleroffset_pitch", "50", true, false)
g_VR.convars.controllerOffsetYaw	=	CreateClientConVar("vrmod_controlleroffset_yaw", "0", true, false)
g_VR.convars.controllerOffsetRoll	=	CreateClientConVar("vrmod_controlleroffset_roll", "0", true, false)
g_VR.convars.showOnStartup			=	CreateClientConVar("vrmod_showonstartup", "0", true, false)
g_VR.convars.leftHanded				= 	CreateClientConVar("vrmod_lefthanded", "0", true, false)

if g_VR.convars.showOnStartup:GetBool() then
	hook.Add("CreateMove","vrmod_showonstartup",function()
		hook.Remove("CreateMove","vrmod_showonstartup")
		timer.Simple(1,function()
			RunConsoleCommand("vrmod")
		end)
	end)
end

concommand.Add( "vrmod", function( ply, cmd, args )
	timer.Simple(0,function() g_VR.CreateSettingsWindow() end) --dont open until game is unpaused (in sp atleast)
end )

local frame

function g_VR.CreateSettingsWindow()
	if IsValid(frame) then return frame end
	frame = vgui.Create("DFrame")
	frame:SetPos(ScrW()/2-270,ScrH()/2-250)
	frame:SetSize(540,500)
	frame:SetTitle("VRMod Menu")
	frame:MakePopup()
	
	function frame:Paint(w,h)
		surface.SetDrawColor(255,255,255,255)
		surface.DrawRect(0,0,w,h)
		surface.SetDrawColor(80,80,80,255)
		surface.DrawRect(0,0,w,28)
	end
	
	local scrollPanel = vgui.Create("DScrollPanel", frame)
	frame.ScrollPanel = scrollPanel
	scrollPanel:SetSize(270,0)
	scrollPanel:Dock( LEFT )
	--scrollPanel:SetPaintBackground(true)
	
	local form = vgui.Create("DForm",scrollPanel)
	frame.Form = form
	form:SetName("Settings")
	form:Dock(TOP)
	
	form.Header:SetVisible(false)
	function form:Paint()
	end
	
	form:CheckBox("Use floating hands", "vrmod_floatinghands")
	form:CheckBox("Use weapon world models", "vrmod_useworldmodels")
	form:CheckBox("Left handed mode (WORLD MODELS BUGGED)", "vrmod_lefthanded")
	form:CheckBox("Add laser pointer to tools/weapons", "vrmod_laserpointer")
	--
	local locomotionPanel = vgui.Create("DPanel")
	form:AddItem(locomotionPanel)
	local dlabel = vgui.Create( "DLabel", locomotionPanel )
	dlabel:SetSize(100,30)
	dlabel:SetPos(5,-3)
	dlabel:SetText( "Locomotion:" )
	dlabel:SetColor(Color(0,0,0))
	local locomotionControls = nil
	local function updateLocomotionCPanel( index )
		if IsValid(locomotionControls) then
			locomotionControls:Remove()
		end
		locomotionControls = vgui.Create("DPanel")
		g_VR.locomotionOptions[index].buildcpanelfunc( locomotionControls )
		locomotionControls:InvalidateLayout(true)
		locomotionControls:SizeToChildren(true,true)
		locomotionPanel:Add(locomotionControls)
		locomotionControls:Dock(TOP)
		locomotionPanel:InvalidateLayout(true)
		locomotionPanel:SizeToChildren(true,true)
	end
			
	local DComboBox = vgui.Create( "DComboBox" )
	locomotionPanel:Add(DComboBox)
	DComboBox:Dock( TOP )
	DComboBox:DockMargin( 70, 0, 0, 5 )
	DComboBox:SetValue("none")
	for i = 1,#g_VR.locomotionOptions do
		DComboBox:AddChoice( g_VR.locomotionOptions[i].name )
	end
	DComboBox.OnSelect = function( self, index, value )
		g_VR.convars.locomotion:SetInt(index)
	end
	DComboBox.Think = function(self)
		local v = g_VR.convars.locomotion:GetInt()
		if self.ConvarVal ~= v then
			self.ConvarVal = v
			if g_VR.locomotionOptions[v] then
				self:ChooseOptionID(v)
				updateLocomotionCPanel(v)
			end
		end
	end
	--
	local tmp = form:CheckBox("Show height adjustment menu", "vrmod_heightmenu")
	local checkTime = 0
	function tmp:OnChange(checked)
		if checked and SysTime()-checkTime < 0.1 then --only triggers when checked manually (not when using reset button)
			VRUtilOpenHeightMenu()
		end
		checkTime = SysTime()
	end
	form:CheckBox("Alternative head angle manipulation method", "vrmod_althead")
	form:ControlHelp("Less precise but compatible with more playermodels")
	form:CheckBox("Automatically start VR after map loads", "vrmod_autostart")
	--
	local panel = vgui.Create( "DPanel" )
	panel:SetSize( 300, 30 )
	panel.Paint = function() end			
	local dlabel = vgui.Create( "DLabel", panel )
	dlabel:SetSize(100,30)
	dlabel:SetPos(0,-3)
	dlabel:SetText( "Desktop view:" )
	dlabel:SetColor(Color(0,0,0))
	local DComboBox = vgui.Create( "DComboBox",panel )
	DComboBox:Dock( TOP )
	DComboBox:DockMargin( 70, 0, 0, 5 )
	DComboBox:AddChoice( "none" )
	DComboBox:AddChoice( "left eye" )
	DComboBox:AddChoice( "right eye" )
	DComboBox.OnSelect = function( self, index, value )
		g_VR.convars.desktopView:SetInt(index)
	end
	DComboBox.Think = function(self)
		local v = g_VR.convars.desktopView:GetInt()
		if self.ConvarVal ~= v then
			self.ConvarVal = v
			self:ChooseOptionID(v)
		end
	end
	form:AddItem(panel)
	--
	form:Button("Edit custom controller input actions","vrmod_actioneditor")
	form:Button("Reset settings to default","vrmod_reset")
	--
	local offsetForm = vgui.Create("DForm",form)
	offsetForm:SetName("Controller offsets")
	offsetForm:Dock(TOP)
	offsetForm:DockMargin(10,10,10,0)
	offsetForm:DockPadding(0,0,0,0)
	offsetForm:SetExpanded(false)
	local tmp = offsetForm:NumSlider("X","vrmod_controlleroffset_x",-30,30,0)
	tmp.PerformLayout = function(self) self.TextArea:SetWide(30) self.Label:SetWide(30) end
	tmp = offsetForm:NumSlider("Y","vrmod_controlleroffset_y",-30,30,0)
	tmp.PerformLayout = function(self) self.TextArea:SetWide(30) self.Label:SetWide(30) end
	tmp = offsetForm:NumSlider("Z","vrmod_controlleroffset_z",-30,30,0)
	tmp.PerformLayout = function(self) self.TextArea:SetWide(30) self.Label:SetWide(30) end
	tmp = offsetForm:NumSlider("Pitch","vrmod_controlleroffset_pitch",-180,180,0)
	tmp.PerformLayout = function(self) self.TextArea:SetWide(30) self.Label:SetWide(30) end
	tmp = offsetForm:NumSlider("Yaw","vrmod_controlleroffset_yaw",-180,180,0)
	tmp.PerformLayout = function(self) self.TextArea:SetWide(30) self.Label:SetWide(30) end
	tmp = offsetForm:NumSlider("Roll","vrmod_controlleroffset_roll",-180,180,0)
	tmp.PerformLayout = function(self) self.TextArea:SetWide(30) self.Label:SetWide(30) end
	local tmp = offsetForm:Button("Apply offsets","")
	function tmp:OnReleased()
		g_VR.rightControllerOffsetPos  = Vector(g_VR.convars.controllerOffsetX:GetFloat(), g_VR.convars.controllerOffsetY:GetFloat(), g_VR.convars.controllerOffsetZ:GetFloat())
		g_VR.leftControllerOffsetPos  = g_VR.rightControllerOffsetPos * Vector(1,-1,1)
		g_VR.rightControllerOffsetAng = Angle(g_VR.convars.controllerOffsetPitch:GetFloat(), g_VR.convars.controllerOffsetYaw:GetFloat(), g_VR.convars.controllerOffsetRoll:GetFloat())
		g_VR.leftControllerOffsetAng = g_VR.rightControllerOffsetAng
	end
	
	local panel = vgui.Create( "DPanel", frame )
	panel:Dock(FILL)
	panel:DockMargin(10,0,5,0)
	panel:SetPaintBackground(false)
	
	local tmp = vgui.Create("DButton", panel)
	frame.ExitVRButton = tmp
	tmp:SetText("")
	tmp:Dock(BOTTOM)
	tmp:SetTall(50)
	tmp:DockMargin(0,0,0,20)
	function tmp:Paint(w,h)
		if tmp:IsEnabled() then
			surface.SetDrawColor(0,108,204,255)
		else
			surface.SetDrawColor(150,150,150,255)
		end
		surface.DrawRect(0,0,w,h)
		draw.SimpleText( "Exit VR", "Trebuchet24", w/2,h/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	function tmp:DoClick()
		frame:Remove()
		VRUtilClientExit()
	end
	tmp:SetEnabled(g_VR.active)
	
	local tmp = vgui.Create("DButton", panel)
	frame.RestartVRButton = tmp
	tmp:SetText("")
	tmp:Dock(BOTTOM)
	tmp:SetTall(50)
	tmp:DockMargin(0,0,0,5)
	function tmp:Paint(w,h)
		if tmp:IsEnabled() then
			surface.SetDrawColor(0,108,204,255)
		else
			surface.SetDrawColor(150,150,150,255)
		end
		surface.DrawRect(0,0,w,h)
		draw.SimpleText( "Restart VR", "Trebuchet24", w/2,h/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	function tmp:DoClick()
		frame:Remove()
		VRUtilClientExit()
		timer.Simple(1,function()
			VRUtilClientStart()
		end)
	end
	tmp:SetEnabled(g_VR.active)
	
	local tmp = vgui.Create("DButton", panel)
	frame.StartVRButton = tmp
	tmp:SetText("")
	tmp:Dock(BOTTOM)
	tmp:SetTall(50)
	tmp:DockMargin(0,0,0,5)
	function tmp:Paint(w,h)
		if tmp:IsEnabled() then
			surface.SetDrawColor(0,108,204,255)
		else
			surface.SetDrawColor(150,150,150,255)
		end
		surface.DrawRect(0,0,w,h)
		draw.SimpleText( "Start VR", "Trebuchet24", w/2,h/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	function tmp:DoClick()
		frame:Remove()
		VRUtilClientStart()
	end
	
	local errors, warnings = "", ""
	if g_VR.moduleVersion == 0 then
		errors = errors .. "Error: Module not installed. Read the workshop description for instructions.\n"
	elseif VRMOD_IsHMDPresent and not VRMOD_IsHMDPresent() then
		errors = errors .. "Error: VR headset not detected\n"
	elseif g_VR.moduleVersion < 14 then
		errors = errors .. "Error: Module update required. Enter \"vrmod_update\" into the console for details\n"
	elseif g_VR.moduleVersion < 16 then
		warnings = warnings .. "Module update available. Enter \"vrmod_update\" into the console for details\n"
	end
	
	tmp:SetEnabled(#errors == 0 and not g_VR.active)
	
	local tmp = vgui.Create("DLabel", panel)
	tmp:SetText(errors .. warnings)
	tmp:SetWrap(true)
	tmp:SetAutoStretchVertical(true)
	tmp:SetTextColor(Color(255,0,0))
	tmp:SetFont("Trebuchet24")
	tmp:Dock(BOTTOM)
	
	local tmp = vgui.Create("DLabel", panel)
	tmp:SetText("\nAddon version: 100\n\nInstalled module version: "..g_VR.moduleVersion.."\n\nLatest module version: 16")
	tmp:SetWrap(true)
	tmp:SetAutoStretchVertical(true)
	tmp:SetTextColor(Color(0,0,0))
	tmp:SetFont("DermaDefaultBold")
	tmp:Dock(TOP)
	
	return frame
end
