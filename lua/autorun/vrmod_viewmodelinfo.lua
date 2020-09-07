if CLIENT then
	g_VR = g_VR or {}
	g_VR.viewModelInfo = g_VR.viewModelInfo or {}
	
	g_VR.viewModelInfo.autoOffsetAddPos = Vector(1, 0.2, 0)
	
	g_VR.currentvmi = nil

	-- Viewmodel Weapon Offsets & Overrides
	-- SWEPs that I've made offsets for (currently covers all vanilla SWEPS from the spawn menu):
	--weapon_357
	--weapon_pistol
	--weapon_bugbait
	--weapon_crossbow
	--weapon_crowbar
	--weapon_frag
	--weapon_physcannon
	--weapon_ar2
	--weapon_rpg
	--weapon_slam
	--weapon_shotgun
	--weapon_smg1
	--weapon_stunstick
	--weapon_medkit
	--gmod_tool
	--weapon_physgun

	-- Each offset pos is (forwards, left, up) from hand, unless the angle has been modified

	g_VR.viewModelInfo.weapon_357 = {
		offsetPos = Vector(-14.5, 3.5, 6),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 2.5, 0)
	}

	g_VR.viewModelInfo.weapon_pistol = {
		offsetPos = Vector(-21, 4.5, 7.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 2.5, 0)
	}

	-- Note, the laser pointer does not match the actual throw pos for this weapon
	g_VR.viewModelInfo.weapon_bugbait = {
		offsetPos = Vector(-24, 4, 6),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 4.5, 0)
	}

	g_VR.viewModelInfo.weapon_crossbow = {
		offsetPos = Vector(-14.5, 6, 8.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 3.5, 0)
	}

	-- Crowbar's angle had to be mangled to actually hit roughly forwards
	g_VR.viewModelInfo.weapon_crowbar = {
		offsetPos = Vector(10, 35, 10),
		offsetAng = Angle(0, -90, 45),
		rightHandOffset = Vector(0)
	}

	g_VR.viewModelInfo.weapon_frag = {
		offsetPos = Vector(-4, 12, 26),
		offsetAng = Angle(45, -45, 0),
		rightHandOffset = Vector(1, 4.5, 0)
	}

	g_VR.viewModelInfo.weapon_physcannon = {
		offsetPos = Vector(-27, 10, 15.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 4.5, 0)
	}

	g_VR.viewModelInfo.weapon_ar2 = {
		offsetPos = Vector(-15, 5, 8.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 2, 0)
	}

	g_VR.viewModelInfo.weapon_rpg = {
		offsetPos = Vector(-28.5, 15.5, 10.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 2.5, 0)
	}

	g_VR.viewModelInfo.weapon_slam = {
		offsetPos = Vector(-22, -1.5, 9.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(3, 8, -0.8)
	}

	g_VR.viewModelInfo.weapon_shotgun = {
		offsetPos = Vector(-14.5, 7.2, 10),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 3, 0)
	}

	g_VR.viewModelInfo.weapon_smg1 = {
		offsetPos = Vector(-15.5, 5.5, 7.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 2.3, 0)
	}

	g_VR.viewModelInfo.weapon_stunstick = {
		offsetPos = Vector(-28, 10, 18),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 2.5, 0)
	}

	g_VR.viewModelInfo.weapon_medkit = {
		offsetPos = Vector(-23.8, 0.5, 7),
		offsetAng = Angle(0),
		rightHandOffset = Vector(1, 10, -2)
	}

	g_VR.viewModelInfo.gmod_tool = {
		offsetPos = Vector(-12, 5, 7),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 2.5, 0)
	}

	g_VR.viewModelInfo.weapon_physgun = {
		offsetPos = Vector(-27, 10, 15.5),
		offsetAng = Angle(0),
		rightHandOffset = Vector(0, 4.5, 0)
	}
end