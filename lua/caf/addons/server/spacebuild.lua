--[[ Serverside Custom Addon file Base ]]--
--require("sb_space")

player_manager.AddValidModel( "MedicMarine", "models/player/samzanemesis/marinemedic.mdl" )
player_manager.AddValidModel( "SpecialMarine", "models/player/samzanemesis/marinespecial.mdl" )
player_manager.AddValidModel( "OfficerMarine", "models/player/samzanemesis/marineofficer.mdl" )
player_manager.AddValidModel( "TechMarine", "models/player/samzanemesis/marinetech.mdl" )

util.PrecacheModel( "models/player/samzanemesis/marinemedic.mdl" )
util.PrecacheModel( "models/player/samzanemesis/marinespecial.mdl" )
util.PrecacheModel( "models/player/samzanemesis/marineofficer.mdl" )
util.PrecacheModel( "models/player/samzanemesis/marinetech.mdl" )

local SB = {}

local status = false

--Local stuff
SB_DEBUG = true

--local NextUpdateTime

local SB_InSpace = 0
--SetGlobalInt("InSpace", 0)
TrueSun = {}
SunAngle = nil

SB.Override_PlayerHeatDestroy = 0
SB.Override_EntityHeatDestroy = 0
SB.Override_PressureDamage = 0
SB.PlayerOverride = 0
local sb_spawned_entities = {}
local volumes = {}

CreateConVar( "SB_NoClip", "1" )
CreateConVar( "SB_PlanetNoClipOnly", "1" )
CreateConVar( "SB_AdminSpaceNoclip", "1" )
CreateConVar( "SB_SuperAdminSpaceNoclip", "1" )
CreateConVar( "SB_StaticEnvironment", "0" )
local VolCheckIterations = CreateConVar( "SB_VolumeCheckIterations", "11",{ FCVAR_CHEAT, FCVAR_ARCHIVE } )
local ForceModel = CreateConVar( "SB_Force_Model", "0",{ FCVAR_ARCHIVE } )

--Think + Environments
local Environments = {}
local Planets = {}
local Stars = {}
local numenv = 0

local function PhysgunPickup(ply , ent)
	local notallowed =  { "base_sb_planet1", "base_sb_planet2", "base_sb_star1", "base_sb_star2", "nature_dev_tree", "sb_environment", "base_cube_environment"}
	if table.HasValue(notallowed, ent:GetClass()) then
		return false
	end
end
hook.Add("PhysgunPickup", "SB_PhysgunPickup_Check", PhysgunPickup)

local function OnEntitySpawn(ent)
	--Msg("Spawn: "..tostring(ent).."\n")
	if not table.HasValue(sb_spawned_entities, ent) then
		table.insert( sb_spawned_entities, ent)
	end
end
CAF.AddHook("OnEntitySpawn", OnEntitySpawn)

local function AllowAdminNoclip(ply)
	if (ply:IsAdmin() or ply:IsSuperAdmin()) and GetConVar( "SB_AdminSpaceNoclip" ):GetBool() then return true end
	if ply:IsSuperAdmin() and GetConVar( "SB_SuperAdminSpaceNoclip" ):GetBool() then return true end
	return false
end

local function PlayerNoClip( ply, on )
	if SB_InSpace == 1 and not game.SinglePlayer() and GetConVar("SB_NoClip"):GetBool() and not AllowAdminNoclip(ply) and GetConVar("SB_PlanetNoClipOnly"):GetBool() and ply.environment and ply.environment:IsSpace() then return false end
	--return server_settings.Bool( "sbox_noclip" ) --Let the gamemode or other hooks take care of it
end

local function SendColorAndBloom(ent, ply)
    if IsValid(ent) then
		umsg.Start( "AddPlanet", ply )
			umsg.Short( ent:EntIndex())
			umsg.String(ent:GetEnvironmentName())
			umsg.Vector( ent:GetPos() )
			umsg.Float( ent.sbenvironment.size )
			if ent.sbenvironment.color and table.Count(ent.sbenvironment.color) > 0 then
				umsg.Bool( true )
				umsg.Short( ent.sbenvironment.color.AddColor_r )
				umsg.Short( ent.sbenvironment.color.AddColor_g )
				umsg.Short( ent.sbenvironment.color.AddColor_b )
				umsg.Short( ent.sbenvironment.color.MulColor_r )
				umsg.Short( ent.sbenvironment.color.MulColor_g )
				umsg.Short( ent.sbenvironment.color.MulColor_b )
				umsg.Float( ent.sbenvironment.color.Brightness )
				umsg.Float( ent.sbenvironment.color.Contrast )
				umsg.Float( ent.sbenvironment.color.Color )
			else
				umsg.Bool(false)
			end
			if ent.sbenvironment.bloom and table.Count(ent.sbenvironment.bloom) > 0 then
				umsg.Bool(true)
				umsg.Short( ent.sbenvironment.bloom.Col_r )
				umsg.Short( ent.sbenvironment.bloom.Col_g )
				umsg.Short( ent.sbenvironment.bloom.Col_b )
				umsg.Float( ent.sbenvironment.bloom.SizeX )
				umsg.Float( ent.sbenvironment.bloom.SizeY )
				umsg.Float( ent.sbenvironment.bloom.Passes )
				umsg.Float( ent.sbenvironment.bloom.Darken )
				umsg.Float( ent.sbenvironment.bloom.Multiply )
				umsg.Float( ent.sbenvironment.bloom.Color )
			else
				umsg.Bool(false)
			end
		umsg.End()
    end
end

local function SendSunBeam(ent, ply)
    if IsValid(ent) then
		umsg.Start( "AddStar", ply )
			umsg.Short( ent:EntIndex())
			umsg.String(ent:GetName())
			umsg.Vector( ent:GetPos() )
			umsg.Float( ent.sbenvironment.size )
		umsg.End()
     end
end

local function PlayerInitialSpawn(ply) --Send the player info about the Stars and Planets for Effects
	if Planets and table.Count(Planets) > 0 then
		for k, v in pairs(Planets) do
			SendColorAndBloom(v, ply)
		end
	end
	if Stars and table.Count(Stars) > 0 then
		for k, v in pairs(Stars) do
			SendSunBeam(v, ply)
		end
	end
end

--[[function GM:SB_Ragdoll(ply)
	if ply:GetRagdollEntity() and ply:GetRagdollEntity():IsValid() then
		ply:GetRagdollEntity():SetGravity(0)
	else
		ply:CreateRagdoll()
		ply:GetRagdollEntity():SetGravity(0)
	end
end
hook.Add("PlayerKilled","SBRagdoll",GM.SB_Ragdoll)]]
local function PlayerSay( ply, txt )
	if not ply:IsAdmin() then return --[[tostring(txt)]] end
	if (string.sub(txt, 1, 10 ) == "!freespace") then
		SB.RemoveSBProps()
	elseif (string.sub(txt, 1, 10 ) == "!freeworld") then
		SB.RemoveSBProps(true)
	end
	--if not txt then txt = "" end
	--return tostring(txt)
end

local function Register_Sun()
	Msg("Registering Sun\n")
	local suns = ents.FindByClass( "env_sun" )
	for _, ent in ipairs( suns ) do
		if ent:IsValid() then
			local values = ent:GetKeyValues()
			for key, value in pairs(values) do
				if ((key == "target") and (string.len(value) > 0)) then
					local targets = ents.FindByName( "sun_target" )
					for _, target in pairs( targets ) do
						SunAngle = (target:GetPos() - ent:GetPos()):Normalize()
						return --Sunangle set, all that was needed
					end
				end
			end
			--Sun angle still not set, but sun found
		    local ang = ent:GetAngles()
			ang.p = ang.p - 180
			ang.y = ang.y - 180
		    --get within acceptable angle values no matter what...
			ang.p = math.NormalizeAngle( ang.p )
			ang.y = math.NormalizeAngle( ang.y )
			ang.r = math.NormalizeAngle( ang.r )
			SunAngle = ang:Forward()
			return
		end
	end
	--no sun found, so just set a default angle
	if not SunAngle then SunAngle = Vector(0,0,-1) end	
end

local sb_space = {}
function sb_space.Get()
	if sb_space.instance then
		return sb_space.instance
	end
	local space = {}
	function space:CheckAirValues()
		-- Do nothing
	end

	function space:IsOnPlanet()
		return nil
	end

	function space:AddExtraAirResource(resource, start, ispercentage)
		-- Do nothing
	end

	function space:PrintVars()
		Msg("No Values for Space\n")
	end

	function space:ConvertResource(res1, res2, amount)
		return 0
	end

	function space:GetEnvironmentName()
		return "Space"
	end

	function space:GetResourceAmount(res)
		return  0
	end

	function space:GetResourcePercentage(res)
		return 0
	end

	function space:SetEnvironmentName(value)
		--not implemented
	end

	function space:Convert(air1, air2, value)
		return 0
	end

	function space:GetSize()
		return 0
	end

	function space:SetSize(size)
		--not implemented
	end

	function space:GetGravity()
		return 0
	end

	function space:UpdatePressure(ent)
		-- not implemented
	end

	function space:GetO2Percentage()
		return 0
	end

	function space:GetCO2Percentage()
		return 0
	end

	function space:GetNPercentage()
		return 0
	end

	function space:GetHPercentage()
		return 0
	end

	function space:GetEmptyAirPercentage()
		return 0
	end

	function space:UpdateGravity(ent)
		if not ent then return end
		local phys = ent:GetPhysicsObject()
		if not phys:IsValid() then return end
		local trace = {}
		local pos = ent:GetPos()
		trace.start = pos
		trace.endpos = pos - Vector(0,0,512)
		trace.filter = { ent }
		local tr = util.TraceLine( trace )
		if (tr.Hit) then
			if (tr.Entity.grav_plate == 1 and (not ent.grav_plate or ent.grav_plate ~= 1)) then
				ent:SetGravity(1)
				ent.gravity = 1
				phys:EnableGravity( true )
				phys:EnableDrag( true )
				return
			end
		end
		if ent.gravity and ent.gravity == 0 then 
			return 
		end
		phys:EnableGravity( false )
		phys:EnableDrag( false )
		ent:SetGravity(0.00001)
		ent.gravity = 0
	end

	function space:GetPriority()
		return 0
	end

	function space:GetAtmosphere()
		return 0
	end

	function space:GetPressure()
		return 0
	end

	function space:GetTemperature()
		return 14
	end

	function space:GetEmptyAir()
		return 0
	end

	function space:GetO2()
		return 0
	end

	function space:GetCO2()
		return 0
	end

	function space:GetN()
		return 0
	end

	function space:CreateEnvironment(gravity, atmosphere, pressure, temperature, o2, co2, n)
		--Not implemented
	end

	function space:UpdateSize(oldsize, newsize)
		--not implemented
	end

	function space:UpdateEnvironment(gravity, atmosphere, pressure, temperature, o2, co2, n)
		--not implemented
	end

	function space:GetVolume()
		return 0
	end

	function space:IsPlanet()
		return false
	end

	function space:IsStar()
		return false
	end

	function space:IsSpace()
		return true
	end
	sb_space.instance = space;
	return space;
end


local valid_logic_cases={
    "planet",
    "planet2",
    "cube",
    "sb_dev_tree",
    "planet_color",
    "planet_bloom",
    "star",
    "star2"
}
local function Register_Environments()
    local CONFIGS = {}
	CAFLog.Info("Registering planets...")
	local Blooms = {}
	local Colors = {}
	local Planetscolor = {}
	local Planetsbloom = {}
	--Load the planets/stars/bloom/color
	local entities = ents.FindByClass( "logic_case" )
    local invalid, cases
	for _, ent in ipairs( entities ) do
        -- Fuck whoever did this
        --PrintTable(Planets)
        invalid=false
        cases={}
		local values = ent:GetKeyValues()
		for key, value in pairs(values) do
   			if key == "Case01" then
				cases[1] = value
			elseif key == "Case02" then
                cases[2] = value
			elseif key == "Case03" then
                cases[3] = value
			elseif key == "Case04" then
                cases[4] = value
			elseif key == "Case05" then
                cases[5] = value
			elseif key == "Case06" then
                cases[6] = value
			elseif key == "Case07" then
                cases[7] = value
			elseif key == "Case08" then
                cases[8] = value
			elseif key == "Case09" then
                cases[9] = value
			elseif key == "Case10" then
                cases[10] = value
			elseif key == "Case11" then
                cases[11] = value
			elseif key == "Case12" then
                cases[12] = value
			elseif key == "Case13" then
                cases[13] = value
			elseif key == "Case14" then
                cases[14] = value
			elseif key == "Case15" then
                cases[15] = value
			elseif key == "Case16" then
                cases[16] = value
			end
        end
        if not invalid then
            cases[17]=ent:GetAngles()
            cases[18]=ent:GetPos()
            table.insert(CONFIGS, cases)
        end
    end
    timer.Simple(1, function()
        for _, case in ipairs( CONFIGS ) do
            angles, pos = case[17], case[18]
            if case[1] == "planet" then
                SB_InSpace = 1
                --SetGlobalInt("InSpace", 1)
                if table.Count(TrueSun) == 0 or not table.HasValue(TrueSun, pos) then
                    case[2] = tonumber(case[2]) --radius
                    case[3] = tonumber(case[3]) -- gravity
                    case[4] = tonumber(case[4]) -- atmosphere
                    case[5] = tonumber(case[5]) -- stemperature
                    case[6] = tonumber(case[6]) -- ltemperature
                    if string.len(case[7]) == 0 then
                        case[7] = nil -- COLORID
                    end
                    if string.len(case[8]) == 0 then
                        case[8] = nil -- BloomID
                    end
                    case[15] = tonumber(case[15]) --disabled
                    case[16] = tonumber(case[16]) -- flags
                    if case[15] ~= 1 then
                        local planet = ents.Create( "base_sb_planet1" )
                        planet:SetModel("models/props_lab/huladoll.mdl") -- FIXME: Why
                        planet:SetAngles( angles )
                        planet:SetPos( pos )
                        planet:Spawn()
                        planet:CreateEnvironment(case[2], case[3], case[4], case[5], case[6], case[16])
                        if case[7] then
                            Planetscolor[case[7]] = planet
                        end
                        if case[8] then
                            Planetsbloom[case[8]] = planet
                        end
                        --print(planet)
                        table.insert(Planets, planet)
                        CAFLog.Info(string.format("Registered legacy (SB2) planet %s",case[15]))
                    else
                        CAFLog.Warn(string.format("Legacy (SB2) planet %s is disabled.",case[15]))
                    end
                end
            elseif case[1] == "planet2" then
                SB_InSpace = 1
                --SetGlobalInt("InSpace", 1)
                if table.Count(TrueSun) == 0 or not table.HasValue(TrueSun, pos) then
                    case[2] = tonumber(case[2]) -- radius
                    case[3] = tonumber(case[3]) -- gravity
                    case[4] = tonumber(case[4]) -- atmosphere
                    case[5] = tonumber(case[5]) -- pressure
                    case[6] = tonumber(case[6]) -- stemperature
                    case[7] = tonumber(case[7]) -- ltemperature
                    case[8] = tonumber(case[8]) -- flags
                    case[9] = tonumber(case[9]) -- o2
                    case[10] = tonumber(case[10]) -- co2
                    case[11] = tonumber(case[11]) -- n
                    case[12] = tonumber(case[12]) -- h
                    case[13] = tostring(case[13]) --name
                    if string.len(case[15]) == 0 then
                        case[15] = nil -- COLORID
                    end
                    if string.len(case[16]) == 0 then
                        case[16] = nil -- BloomID
                    end

                    local planet = ents.Create( "base_sb_planet2" )
                    planet:SetModel("models/props_lab/huladoll.mdl") -- FIXME: Why
                    planet:SetAngles( angles )
                    planet:SetPos( pos )
                    planet:Spawn()
                    if case[13] == "" then
                        case[13] = "Planet " .. tostring(planet:GetEnvironmentID())
                    end
                    planet:CreateEnvironment(case[2], case[3], case[4], case[5], case[6], case[7],  case[9], case[10], case[11], case[12], case[8], case[13])
                    if case[15] then
                        Planetscolor[case[15]] = planet
                    end
                    if case[16] then
                        Planetsbloom[case[16]] = planet
                    end

                    table.insert(Planets, planet)
                    CAFLog.Info(string.format("Registered new SB3 planet %s.",case[13]))
                end
            elseif case[1] == "cube" then
                SB_InSpace = 1
                --SetGlobalInt("InSpace", 1)
                if table.Count(TrueSun) == 0 or not table.HasValue(TrueSun, pos) then
                    case[2] = tonumber(case[2]) -- radius
                    case[3] = tonumber(case[3]) -- gravity
                    case[4] = tonumber(case[4]) -- atmosphere
                    case[5] = tonumber(case[5]) -- pressure
                    case[6] = tonumber(case[6]) -- stemperature
                    case[7] = tonumber(case[7]) -- ltemperature
                    case[8] = tonumber(case[8]) -- flags
                    case[9] = tonumber(case[9]) -- o2
                    case[10] = tonumber(case[10]) -- co2
                    case[11] = tonumber(case[11]) -- n
                    case[12] = tonumber(case[12]) -- h
                    case[13] = tostring(case[13]) --name
                    if string.len(case[15]) == 0 then
                        case[15] = nil -- COLORID
                    end
                    if string.len(case[16]) == 0 then
                        case[16] = nil -- BloomID
                    end
                    local planet = ents.Create( "base_cube_environment" )
                    planet:SetModel("models/props_lab/huladoll.mdl") -- FIXME: Why
                    planet:SetAngles( angles )
                    planet:SetPos( pos )
                    planet:Spawn()
                    if case[13] == "" then
                        case[13] = "Cube Environment " .. tostring(planet:GetEnvironmentID())
                    end
                    planet:CreateEnvironment(case[2], case[3], case[4], case[5], case[6], case[7],  case[9], case[10], case[11], case[12], case[8], case[13])
                    if case[15] then
                        Planetscolor[case[15]] = planet
                    end
                    if case[16] then
                        Planetsbloom[case[16]] = planet
                    end

                    table.insert(Planets, planet)
                    CAFLog.Info(string.format("Registered cubic environment %s.",case[13]))
                end
            elseif case[1] == "sb_dev_tree" then
                local tree = ents.Create( "nature_dev_tree" )
                tree:SetRate(tonumber(case[2]), true)
                tree:SetAngles( angles )
                tree:SetPos( pos )
                tree:Spawn()
                CAFLog.Info("Registered tree.")
            elseif case[1] == "planet_color" then
                hash = {}
                if string.len(case[2]) > 0 then
                    hash.AddColor_r = tonumber(string.Left(case[2], string.find(case[2]," ") - 1))
                    case[2] = string.Right(case[2], (string.len(case[2]) - string.find(case[2]," ")))
                    hash.AddColor_g = tonumber(string.Left(case[2], string.find(case[2]," ") - 1))
                    case[2] = string.Right(case[2], (string.len(case[2]) - string.find(case[2]," ")))
                    hash.AddColor_b = tonumber(case[2])
                end
                if string.len(case[3]) > 0 then
                    hash.MulColor_r = tonumber(string.Left(case[3], string.find(case[3]," ") - 1))
                    case[3] = string.Right(case[3], (string.len(case[3]) - string.find(case[3]," ")))
                    hash.MulColor_g = tonumber(string.Left(case[3], string.find(case[3]," ") - 1))
                    case[3] = string.Right(case[3], (string.len(case[3]) - string.find(case[3]," ")))
                    hash.MulColor_b = tonumber(case[3])
                end
                if case[4] then hash.Brightness = tonumber(case[4]) end
                if case[5] then hash.Contrast = tonumber(case[5]) end
                if case[6] then hash.Color = tonumber(case[6]) end
                Colors[case[16]] = hash
                CAFLog.Info(string.format("Registered planet color #%d.",case[16]))
            elseif case[1] == "planet_bloom" then
                hash = {}
                if string.len(case[2]) > 0 then
                    hash.Col_r = tonumber(string.Left(case[2], string.find(case[2]," ") - 1))
                    case[2] = string.Right(case[2], (string.len(case[2]) - string.find(case[2]," ")))
                    hash.Col_g = tonumber(string.Left(case[2], string.find(case[2]," ") - 1))
                    case[2] = string.Right(case[2], (string.len(case[2]) - string.find(case[2]," ")))
                    hash.Col_b = tonumber(case[2])
                end
                if string.len(case[3]) > 0 then
                    hash.SizeX = tonumber(string.Left(case[3], string.find(case[3]," ") - 1))
                    case[3] = string.Right(case[3], (string.len(case[3]) - string.find(case[3]," ")))
                    hash.SizeY = tonumber(case[3])
                end
                if case[4] then hash.Passes = tonumber(case[4]) end
                if case[5] then hash.Darken = tonumber(case[5]) end
                if case[6] then hash.Multiply = tonumber(case[6]) end
                if case[7] then hash.Color = tonumber(case[7]) end
                Blooms[case[16]] = hash
                CAFLog.Info(string.format("Registered planet bloom #%d.",case[16]))
            elseif case[1] == "star" then
                SB_InSpace = 1
                --SetGlobalInt("InSpace", 1)
                if table.Count(TrueSun) == 0 or not table.HasValue(TrueSun, pos) then
                    local planet = ents.Create( "base_sb_star1" )
                    planet:SetModel("models/props_lab/huladoll.mdl")
                    planet:SetAngles( angles )
                    planet:SetPos(pos )
                    planet:Spawn()
                    planet:CreateEnvironment(tonumber(case[2]))
                    table.insert(TrueSun, pos)
                    CAFLog.Info("Registered SB2 star.")
                end
            elseif case[1] == "star2" then
                SB_InSpace = 1
                --SetGlobalInt("InSpace", 1)
                if table.Count(TrueSun) == 0 or not table.HasValue(TrueSun, pos) then
                    case[2] = tonumber(case[2]) -- radius
                    case[3] = tonumber(case[3]) -- temp1
                    case[4] = tonumber(case[4]) -- temp2
                    case[5] = tonumber(case[5]) -- temp3
                    case[6] = tostring(case[6]) -- name
                    if case[6] =="" then
                        case[6] = "Star"
                    end
                    local planet = ents.Create( "base_sb_star2" )
                    planet:SetModel("models/props_lab/huladoll.mdl")
                    planet:SetAngles( angles )
                    planet:SetPos( pos )
                    planet:Spawn()
                    planet:CreateEnvironment(case[2], case[3], case[4], case[5], case[6])
                    table.insert(TrueSun, pos)
                    CAFLog.Info("Registered SB3 star.")
                end
            end
        end
        for k, v in pairs(Blooms) do
            if Planetsbloom[k] then
                Planetsbloom[k]:BloomEffect(v.Col_r, v.Col_g, v.Col_b, v.SizeX, v.SizeY, v.Passes, v.Darken, v.Multiply, v.Color)
            end
        end
        for k, v in pairs(Colors) do
            if Planetscolor[k] then
                Planetscolor[k]:ColorEffect(v.AddColor_r, v.AddColor_g, v.AddColor_b, v.MulColor_r, v.MulColor_g, v.MulColor_b, v.Brightness, v.Contrast, v.Color)
            end
        end
        -- compatibility patch, since this map does not convert to sb3 properly. ~Dubby
        if game.GetMap() == "gm_interplaneteryfunk" then
            CAFLog.Warning("gm_interplaneteryfunk detected, having to hax the map to work with SB3.")
            local p = Entity(40):GetParent()
            Entity(40):Remove()
            Entity(41):GetParent():Remove()
            Entity(42):GetParent():Remove()
            Entity(43):GetParent():Remove()
            Entity(44):GetParent():Remove()

            local e = ents.Create("base_cube_environment")
            e:SetModel("models/props_lab/huladoll.mdl")
            e:SetAngles( Angle(0,0,0) )
            e:SetPos( Vector(0,0,-17400) )
            e:Spawn()
            e:CreateEnvironment(p, 15344, 1, 1, 1, 289, 300,  21, 0.45, 78, 0.55, 0, "Earth")
            e.Active = true
            --lua_run local e = ents.Create("base_cube_environment") e:SetModel("models/props_lab/huladoll.mdl") e:SetAngles(Angle(0,0,0)) e:SetPos(Vector(0,0,-14472)) e:Spawn() e:CreateEnvironment(Entity(41):GetParent(),15000,1,1,1,289,300,21,0.45,78,0.55,0,"Earth")
            CAFLog.Warn("Map hax completed.")
        end
        if SB_InSpace == 1 then
            SB.__Construct();
        end
    end)
end

local function ForcePlyModel(ply)
	if ForceModel:GetInt() == 1 then
		if not ply.sbmodel then
			local i = math.Rand(0, 4)
			if i <= 1 then
				ply.sbmodel = "models/player/samzanemesis/marinemedic.mdl"
			elseif i <= 2 then
				ply.sbmodel = "models/player/samzanemesis/marinespecial.mdl"
			elseif i <= 3 then 
				ply.sbmodel = "models/player/samzanemesis/marineofficer.mdl"
			else --if i <= 4 then
				ply.sbmodel = "models/player/samzanemesis/marinetech.mdl"
			end
		end
		ply:SetModel(ply.sbmodel )
		return true
	end
end
  
--End Local Stuff
--[[
	The AutoStart functions
	Optional
	Get's called before/replacing __Construct on CAF Startup
	Return true = AutoStart (Addon got enabled)
	Return nil or false = addon didn't get enabled
]]
function SB.__AutoStart()
	Register_Sun()
	Register_Environments()

end

local function ResetGravity()
	for k, ent in ipairs( sb_spawned_entities) do
		if ent and IsValid(ent) then
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() and not (ent.IgnoreGravity and ent.IgnoreGravity == true) then
				ent:SetGravity(1)
				ent.gravity = 1
				phys:EnableGravity( true )
				phys:EnableDrag( true )
			end
		else
			table.remove(sb_spawned_entities, k)
		end
	end
end


--[[
	The Constructor for this Custom Addon Class
	Required
	Return True if succesfully able to start up this addon
	Return false, the reason of why it wasn't able to start
]]
function SB.__Construct()
	if status then return false , CAF.GetLangVar("This Addon is already Active!") end
	if SB_InSpace == 1 then
		hook.Add("PlayerNoClip", "SB_PlayerNoClip_Check", PlayerNoClip)
		hook.Add("PlayerInitialSpawn", "SB_PlayerInitialSpawn_Check", PlayerInitialSpawn)
		hook.Add("PlayerSay", "SB_PlayerSay_Check", PlayerSay)
		hook.Add("PlayerSetModel", "SB_Force_Model_Check", ForcePlyModel)
		CAF.AddHook("think3", SB.PerformEnvironmentCheck)
		ResetGravity()
		for k, v in pairs(player.GetAll()) do
			PlayerInitialSpawn(v);
		end
		CAF.AddServerTag("SB")
		status = true;
		return true
	end
	return false, CAF.GetLangVar("Not on a Spacebuild Map!")
end

--[[
	The Destructor for this Custom Addon Class
	Required
	Return true if disabled correctly
	Return false + the reason if disabling failed
]]
function SB.__Destruct()
	if not status then return false , CAF.GetLangVar("This Addon is already disabled!") end
	hook.Remove("PlayerNoClip", "SB_PlayerNoClip_Check")
	hook.Remove("PlayerInitialSpawn", "SB_PlayerInitialSpawn_Check")
	hook.Remove("PlayerSay", "SB_PlayerSay_Check")
	hook.Remove("PlayerSetModel", "SB_Force_Model_Check")
	CAF.RemoveHook("think3", SB.PerformEnvironmentCheck)
	ResetGravity()
	CAF.RemoveServerTag("SB")
	status = false;
	return true;
end

--[[
	Get the required Addons for this Addon Class
	Optional
	Put the string names of the Addons in here in table format
	The CAF startup system will use this to decide if the Addon can be Started up or not. If a required addon isn't installed then Construct will not be called
	Example: return {"Resource Distribution", "Life Support"}
	
	Works together with the startup Level number at the bottom of this file
]]
function SB.GetRequiredAddons()
	return {}
end

--[[
	Get the Boolean Status from this Addon Class
	Required, used to know if this addon is active or not
]]
function SB.GetStatus()
	return status
end

--[[
	Get the Version of this Custom Addon Class
	Optional (but should be put it in most cases!)
]]
function SB.GetVersion()
	return 3.1, CAF.GetLangVar("Beta")
end

--[[
	Get any custom options this Custom Addon Class might have
	Not implemented yet
]]
function SB.GetExtraOptions()
	return {}
end

--[[
	Get the Custom String Status from this Addon Class
	Optional, returns a custom String status, could be used if your addon has more then 1 status based on the options activated?
]]
function SB.GetCustomStatus()
	return
end

--[[
	You can send all the files from here that you want to add to send to the client
	Optional
]]
function SB.AddResourcesToSend()
	resource.AddFile( "models/player/samzanemesis/marinemedic.mdl" )
	resource.AddFile( "models/player/samzanemesis/marinespecial.mdl" )
	resource.AddFile( "models/player/samzanemesis/marineofficer.mdl" )
	resource.AddFile( "models/player/samzanemesis/marinetech.mdl" )
	
	resource.AddFile( "materials/models/player/male/medic_body.vmt")
	resource.AddFile( "materials/models/player/male/medic_body_female.vmt")
	resource.AddFile( "materials/models/player/male/medic_helmet.vmt")
	resource.AddFile( "materials/models/player/male/medic_helmet_female.vmt")
	resource.AddFile( "materials/models/player/male/officer_body.vmt")
	resource.AddFile( "materials/models/player/male/medic_helmet.vmt")
	resource.AddFile( "materials/models/player/male/special_weapons_body.vmt")
	resource.AddFile( "materials/models/player/male/special_weapons_body_female.vmt")
	resource.AddFile( "materials/models/player/male/special_weapons_helmet.vmt")
	resource.AddFile( "materials/models/player/male/special_weapons_helmet_female.vmt")
	resource.AddFile( "materials/models/player/male/tech_body.vmt")
	resource.AddFile( "materials/models/player/male/tech_helmet.vmt")
	
	resource.AddFile( "materials/models/player/male/back_unit/medic_back_unit.vmt")
	resource.AddFile( "materials/models/player/male/back_unit/medic_back_unit_female.vmt")
	resource.AddFile( "materials/models/player/male/back_unit/officer_back_unit.vmt")
	resource.AddFile( "materials/models/player/male/back_unit/special_weapons_back_unit.vmt")
	resource.AddFile( "materials/models/player/male/back_unit/special_weapons_back_unit_female.vmt")
	resource.AddFile( "materials/models/player/male/back_unit/tech_back_unit.vmt")
end
CAF.RegisterAddon("Spacebuild",  SB, "1") 

--Thinks Checks

--local time_count = 0;
--local time_amount = 0;

function SB.PerformEnvironmentCheck()
	if (SB_InSpace == 0) then return end
	--local begintime = CAF.begintime()
	--local amount = #sb_spawned_entities;
	for k, ent in ipairs( sb_spawned_entities) do
		if ent and IsValid(ent) and not ent.IsEnvironment  then
			SB.PerformEnvironmentCheckOnEnt( ent )
		else
			table.remove(sb_spawned_entities, k)
		end
	end
	--local endtime = CAF.endtime(begintime)
	--time_count = time_count + endtime
	--time_amount = time_amount + 1
	--Msg("SB - Seconds to loop over "..tostring(amount).." entities: "..tostring(endtime).."s / "..tostring(time_count/time_amount).." ("..tostring(time_amount)..")\n")
end



function SB.PerformEnvironmentCheckOnEnt(ent)
	if not ent then return end
	if not ent:IsPlayer() or SB.PlayerOverride == 0 then
		--if ent.environment ~= sb_space.Get() then
		local space = sb_space.Get()
		local environment = space --restore to default before doing the Environment checks
		local oldenvironment = ent.environment
		--end
    for k, v in pairs(Planets) do
			if v and v:IsValid() then
				--Msg("Checking planet\n")
				environment = v:OnEnvironment(ent, environment, space) or environment
            else
				table.remove(Planets, k)
			end
		end
		if environment == space then
			for k, v in pairs(Stars) do
				if v and v:IsValid() then
					environment = v:OnEnvironment(ent, environment, space) or environment
				else
					table.remove(Stars, k)
				end
			end
		end
		for k, v in pairs(Environments) do
			if v and v:IsValid() then
				environment = v:OnEnvironment(ent, environment, space) or environment
			else
				table.remove(Environments, k)
			end
		end
		if oldenvironment ~= environment then
			--Msg("Changing environment\n")
			ent.environment = environment
			SB.OnEnvironmentChanged(ent)
		elseif oldenvironment ~= ent.environment then
			ent.environment = oldenvironment
		end
		ent.environment:UpdateGravity(ent) --Always update gravity!!
		ent.environment:UpdatePressure(ent) -- Should pressure even be here (appart from for players?)
	end
	if ent:IsPlayer() then
		if SB_InSpace == 1 and (ent.environment == sb_space.Get()  or (ent.environment and (not ent.environment:IsPlanet()) and ent.environment.environment and ent.environment.environment == sb_space.Get())) then
			if not ent:InVehicle() or not game.SinglePlayer() then
				if not AllowAdminNoclip(ent) then
					if ent:GetMoveType() == MOVETYPE_NOCLIP then
						ent:SetMoveType(MOVETYPE_WALK)
					end
				end
			end
		end
		if SB.PlayerOverride == 0 and SB.Override_PlayerHeatDestroy == 0 then
			if ent.environment:GetTemperature(ent) > 10000 then
				ent:SilentKill()
			end
		end
	else
		if (not ent.IsEnvironment or not ent:IsEnvironment() or (ent:GetVolume() == 0 and not ent:IsPlanet() and not ent:IsStar())) and ent.environment:GetTemperature(ent) > 10000 then
			ent:Remove()
		end
	end
end

-- Override functions

function SB.AddOverride_PlayerHeatDestroy()
	SB.Override_PlayerHeatDestroy = SB.Override_PlayerHeatDestroy + 1
end

function SB.RemoveOverride_PlayerHeatDestroy()
	SB.Override_PlayerHeatDestroy = SB.Override_PlayerHeatDestroy - 1
end

function SB.AddOverride_EntityHeatDestroy()
	SB.Override_EntityHeatDestroy = SB.Override_EntityHeatDestroy + 1
end

function SB.RemoveOverride_EntityHeatDestroy()
	SB.Override_EntityHeatDestroy = SB.Override_EntityHeatDestroy - 1
end

function SB.AddOverride_PressureDamage()
	SB.Override_PressureDamage = SB.Override_PressureDamage + 1
end

function SB.RemoveOverride_PressureDamage()
	SB.Override_PressureDamage = SB.Override_PressureDamage - 1
end

function SB.AddPlayerOverride()
	SB.PlayerOverride = SB.PlayerOverride + 1
end

function SB.RemovePlayerOverride()
	SB.PlayerOverride = SB.PlayerOverride - 1
end

-- Environment Functions

function SB.GetPlanets()
	local tmp = {}
	if table.Count(Planets) > 0 then
		for k, v in pairs(Planets) do
			--if v.IsPlanet and v:IsPlanet() then
			table.insert(tmp, v)
			--end
		end
	end
	return tmp
end

function SB.GetStars()
	local tmp = {}
	if table.Count(Stars) > 0 then
		for k, v in pairs(Stars) do
			--if v.IsStar and v:IsStar() then
			table.insert(tmp, v)
			--end
		end
	end
	return tmp
end

function SB.GetArtificialEnvironments() --not 100 sure this is correct
	local tmp = {}
	if table.Count(Environments) > 0 then
		for k, v in pairs(Environments) do
			--if v.IsStar and not v:IsStar() and v.IsPlanet and not v:IsPlanet() then
				table.insert(tmp, v)
			--end
		end
	end
	return tmp
end

function SB.OnEnvironmentChanged(ent)
	if not ent.oldsbtmpenvironment or ent.oldsbtmpenvironment ~= ent.environment then
		local tmp = ent.oldsbtmpenvironment
		ent.oldsbtmpenvironment = ent.environment
		if tmp then
			gamemode.Call( "OnEnvironmentChanged", ent, tmp, ent.environment )
		end
	end
end

function SB.GetSpace()
	return sb_space.Get()
end

function SB.AddEnvironment(env)
	if not env or not env.GetEnvClass or env:GetEnvClass() ~= "SB ENVIRONMENT" then return 0 end
	--if v.IsStar and not v:IsStar() and v.IsPlanet and not v:IsPlanet() then
	if env.IsStar and env:IsStar() then
		if not table.HasValue(Stars, env) then
			table.insert(Stars, env)
			numenv = numenv + 1
			env:SetEnvironmentID(numenv)
			return numenv
		end
	elseif env.IsPlanet and env:IsPlanet() then
		if not table.HasValue(Planets, env) then
			table.insert(Planets, env)
			numenv = numenv + 1
			env:SetEnvironmentID(numenv)
			return numenv
		end
	elseif not table.HasValue(Environments, env) then
			table.insert(Environments, env)
			numenv = numenv + 1
			env:SetEnvironmentID(numenv)
			return numenv
	end
	return env:GetEnvironmentID()
end

function SB.RemoveEnvironment(env)
	if not env or not env.GetEnvClass or env:GetEnvClass() ~= "SB ENVIRONMENT" then return end
	if env.IsStar and env:IsStar() then
		for k, v in pairs(Stars) do
			if env == v then
				table.remove(Stars, k)
			end
		end
	elseif env.IsPlanet and env:IsPlanet() then
		for k, v in pairs(Planets) do
			if env == v then
				table.remove(Planets, k)
			end
		end
	else
		for k, v in pairs(Environments) do
			if env == v then
				table.remove(Environments, k)
			end
		end
	end
	
end

function SB.GetEnvironments()
	local tmp = {}
	for k, v in pairs(Planets) do
		table.insert(tmp, v)
	end
	for k, v in pairs(Stars) do
		table.insert(tmp, v)
	end
	for k, v in pairs(Environments) do
		table.insert(tmp, v)
	end

	return tmp
end

--Chat Commands

function SB.RemoveSBProps(world)
	for _, ent in pairs( sb_spawned_entities ) do
		if world and ent.environment and ent.environment:IsPlanet() then
			if not (ent:IsPlayer() or (ent.IsPlanet and ent:IsPlanet()) or (ent.IsStar and ent:IsStar())) then
				ent:Remove()
			end
		elseif not world and (not ent.environment or ent.environment:IsSpace()) then
			if not (ent:IsPlayer() or (ent.IsPlanet and ent:IsPlanet()) or (ent.IsStar and ent:IsStar())) then
				ent:Remove()
			end
		end
	end
end

--Volume Functions

--[[
* @param name
* @return Volume(table) or nil
*
]]
function SB.GetVolume(name)
	return volumes[name]
end

--[[
* @param name
* @param radius
* @return Volume(table) or ( false + errormessage)
*
* Notes: If the volume name already exists, that volume is returned! 
*
]]
function SB.CreateVolume(name, radius)
	return SB.FindVolume(name, radius)
end

--[[
* @param name
* @param radius
* @return Volume(table) or ( false + errormessage)
*
* Notes: If the volume name already exists, that volume is returned! 
*
]]
function SB.FindVolume(name, radius)
	if not name then return false, "No Name Entered!" end
	if not radius or radius < 0 then radius = 0 end
	if not volumes[name] then
		volumes[name] = {}
		volumes[name].radius = radius
		volumes[name].pos = Vector(0, 0 ,0 )
		local tries = VolCheckIterations:GetInt()
		local found = 0
		while ( ( found == 0 ) and ( tries > 0 ) ) do
			tries = tries - 1
			pos = VectorRand()*16384
			if (util.IsInWorld( pos ) == true) then
				found = 1
				for k, v in pairs(volumes) do
					--if v and v.pos and (v.pos == pos or v.pos:Distance(pos) < v.radius) then -- Hur hur. This is why i had planetary collisions.
					if v and v.pos and (v.pos == pos or v.pos:Distance(pos) < v.radius+radius) then
						found = 0
					end
				end
				if found == 1 then
					for k, v in pairs(Environments) do
						if v and IsValid(v) and ((v.IsPlanet and v.IsPlanet()) or (v.IsStar and v.IsStar())) and (v:GetPos() == pos or v:GetPos():Distance(pos) < v:GetSize()) then
							found = 0
						end
					end
				end
				if (found == 1) and radius > 0 then
					local edges = {
						pos+(Vector(1, 0, 0)*radius),
						pos+(Vector(0, 1, 0)*radius),
						pos+(Vector(0, 0, 1)*radius),
						pos+(Vector(-1, 0, 0)*radius),
						pos+(Vector(0, -1, 0)*radius),
						pos+(Vector(0, 0, -1)*radius)
					}
					local trace = {}
					trace.start = pos
					for _, edge in pairs( edges ) do
						trace.endpos = edge
						trace.filter = { }
						local tr = util.TraceLine( trace )
						if (tr.Hit) then
							found = 0
							break
						end
					end
				end
				if (found == 0) then Msg( "Rejected Volume.\n" ) end
			end
			if (found == 1) then
				volumes[name].pos = pos
			elseif tries <= 0 then
				volumes[name] = nil
			end
		end
	end
	return volumes[name]
end

--[[
* @param name
* @return nil
*
]]
function SB.DestroyVolume(name)
	SB.RemoveVolume(name);
end

--[[
* @param name
* @return nil
*
]]
function SB.RemoveVolume(name)
	if name and volumes[name] then volumes[name] = nil end
end

--[[
* @param name
* @param pos
* @param radius
* @return nil
*
* Note: this is meant for people who spawn their props in space using a custom Spawner (like the Stargate Spawner)
]]
function SB.AddCustomVolume(name, pos, radius)
	if not name or not radius or not pos then return false, "Invalid Parameters" end
	if volumes[name] then return false, "this volume already exists!" end
	volumes[name] = {}
	volumes[name].pos = pos
	volumes[name].radius = radius
end

function SB.FindClosestPlanet(pos, starsto)
	local closestplanet = nil
	if table.Count(Planets) > 0 then
		for k, v in pairs(Planets) do
			if v and IsValid(v) and v.IsPlanet and v.IsPlanet() then
				if not closestplanet then
					closestplanet = v
				else
					if (v:GetPos():Distance(pos) - v:GetSize() < closestplanet:GetPos():Distance(pos) - closestplanet:GetSize()) then
						closestplanet = v
					end
				end
			end
		end
	end
	if starsto and table.Count(Stars) > 0 then
		for k, v in pairs(Stars) do
			if v and IsValid(v) and v.IsStar and v.IsStar() then
				if not closestplanet then
					closestplanet = v
				else
					if (v:GetPos():Distance(pos) - v:GetSize() < closestplanet:GetPos():Distance(pos) - closestplanet:GetSize()) then
						closestplanet = v
					end
				end
			end
		end
	end
	return closestplanet
end

function SB.FindEnvironmentOnPos(pos)
	local env = nil
	if table.Count(Planets) > 0 then
		for k, v in pairs(Planets) do
			if v and IsValid(v) and v.IsEnvironment and v:IsEnvironment() then
				env = v:PosInEnvironment(pos, env)
			end
		end
	end
	if not env and table.Count(Stars) > 0 then
		for k, v in pairs(Stars) do
			if v and IsValid(v) and v.IsEnvironment and v:IsEnvironment() then
				env = v:PosInEnvironment(pos, env)
			end
		end
	end
	if table.Count(Environments) > 0 then
		for k, v in pairs(Environments) do
			if v and IsValid(v) and v.IsEnvironment and v:IsEnvironment() then
				env = v:PosInEnvironment(pos, env)
			end
		end
	end
	return env or SB.GetSpace()
end
