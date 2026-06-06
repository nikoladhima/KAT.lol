local NikoletoScripts = (...)
if type(NikoletoScripts) ~= "table" then
    error("[KAT.lol/src/Main.luau | ERROR]: Argument must be a table.", 2)
end

local Running = true

local ConnectionManager = NikoletoScripts["ConnectionManager"]
local ServiceManager = NikoletoScripts["ServiceManager"]
local DrawingManager = NikoletoScripts["DrawingManager"]
local ThreadManager = NikoletoScripts["ThreadManager"]
local FileManager = NikoletoScripts["FileManager"]
local RunService = NikoletoScripts["RunService"]
local Utils = NikoletoScripts["Utils"]
local UI = NikoletoScripts["UI"]
local Window = Utils.CreateWindow(UI)

local GenerateGUID = Utils["GenerateGUID"]
local SetEnabled = Utils["SetEnabled"]
local Create = Utils["Create"]
local GetDistanceSquared = Utils["GetDistanceSquared"]

local ExecutorName = NikoletoScripts["ExecutorName"]
local ExecutorFunctions = NikoletoScripts["ExecutorFunctions"]

local isrenderobj = ExecutorFunctions["isrenderobj"]
local newcclosure = ExecutorFunctions["newcclosure"]

local hookmetamethod = (not ExecutorName:lower():find("solara")) and ExecutorFunctions["hookmetamethod"]
local getnamecallmethod = ExecutorFunctions["getnamecallmethod"]
local getgc = ExecutorFunctions["getgc"]

local GetGunState = ExecutorFunctions["getupvalues"]
if not GetGunState then
	local getupvalue = ExecutorFunctions["getupvalue"]
	if getupvalue then
		GetGunState = function(Function)
			if not Function then
				return
			end

			local GunState
			for Index = 1, 11 do
				local Upvalue = getupvalue(Function, Index)
				if type(Upvalue) == "table" and rawget(Upvalue, "LoadedAmmo") then
					GunState = Upvalue
					break
				end
			end

			return GunState
		end
	end
else
	local getupvalues = GetGunState
	GetGunState = function(Function)
		if not Function then
			return
		end

		local GunState
		for _,Upvalue in next, getupvalues(Function) do
			if type(Upvalue) == "table" and rawget(Upvalue, "LoadedAmmo") then
				GunState = Upvalue
				break
			end
		end

		return GunState
	end
end

local getsenv = ExecutorFunctions["getsenv"]
local getconnections = ExecutorFunctions["getconnections"]

local MarketplaceService = ServiceManager["MarketplaceService"]
local ReplicatedStorage = ServiceManager["ReplicatedStorage"]
local UserInputService = ServiceManager["UserInputService"]
local HttpService = ServiceManager["HttpService"]
local Lighting = ServiceManager["Lighting"]
local Players = ServiceManager["Players"]
local CoreGui = ServiceManager["CoreGui"]
local Teams = ServiceManager["Teams"]

local CachedPlayers = {}
local CachedPlayersList = {}
local Camera = nil
local ViewportSize = Vector2.zero
local ScreenCenter = Vector2.zero
local LocalPlayer = ServiceManager()
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Mouse = LocalPlayer:GetMouse()
local MouseLocation = UserInputService:GetMouseLocation()

local LocalCharacter = nil
local LocalHumanoid = nil
local LocalHead = nil
local LocalRoot = nil

local Options = UI.Options
local Toggles = UI.Toggles
local Watermark = UI:AddDraggableLabel("[NikoletoHub/KAT] | 0 | 0")
local WatermarkIsVisible = true

local CachedRobloxGui = nil
local CachedClippingShield = nil
local CachedSettingsShield = nil

local EnumFreefallState = Enum.HumanoidStateType.Freefall
local EnumJumpingState = Enum.HumanoidStateType.Jumping
local HighlightDepthModeAlwaysOnTop = Enum.HighlightDepthMode.AlwaysOnTop
local HighlightDepthModeOccluded = Enum.HighlightDepthMode.Occluded

local ESPHeadOffset = Vector3.new(0, 1.5, 0)
local R6Neck = Vector3.new(0, 0.4, 0)
local R6Waist = Vector3.new(0, -0.5, 0)
local R6Top = Vector3.new(0, 0.5, 0)
local R6Bottom = Vector3.new(0, -0.5, 0)
local CFrameZero = CFrame.new(0, 0, 0)
local FixedBottomCenter = Vector2.zero
local ChinaHatCFrameOffset = CFrame.new(0, 1.1, 0)

local Aimbot = {
	Scale = false,
	Enabled = false,

	["Target"] = nil,
	["AimPart"] = "Root",

	["StickyAim"] = true,

	["FOVCircle"] = {
		Enabled = false,
		["Filled"] = false,
		["Transparency"] = 1,
		["Thickness"] = 1,
		["Radius"] = 50,
		["Color"] = Color3.fromRGB(255, 255, 255),
		["Position"] = "Mouse"
	},

	["ShakeOffset"] = 0,

	["ForceFieldCheck"] = false,
	["WallCheck"] = false,
	["TeamCheck"] = false,
	["DeadCheck"] = false,

	["StopOnCheck"] = true,

	["SmoothnessOffset"] = 0
}

local SilentAimbot = {
	Scale = false,
	Enabled = false,

	["AimPart"] = "Root",

	["FOVCircle"] = {
		Enabled = false,
		["Filled"] = false,
		["Transparency"] = 1,
		["Thickness"] = 1,
		["Radius"] = 50,
		["Color"] = Color3.fromRGB(255, 255, 255),
		["Position"] = "Mouse"
	},

	["ForceFieldCheck"] = true,
	["WallCheck"] = true,
	["TeamCheck"] = false,
	["DeadCheck"] = true
}

local TriggerBot = {
	Scale = false,
	Enabled = false,

	["Target"] = nil,

	["ForceFieldCheck"] = true,
	["TeamCheck"] = false,
	["DeadCheck"] = true,
	["WallCheck"] = true,
	["RevolverOnly"] = false,

	["TriggerDelay"] = 0.1,
	["MaxDistance"] = 2500,
}

local AimbotFOVCircles = {
	["Target"] = DrawingManager("Circle", {
		["Color"] = Aimbot.FOVCircle.Color,
		["Filled"] = Aimbot.FOVCircle.Filled,
		["Thickness"] = Aimbot.FOVCircle.Thickness,
		["Radius"] = Aimbot.FOVCircle.Radius,
		["Visible"] = false
	}),
	["Silent"] = DrawingManager("Circle", {
		["Color"] = SilentAimbot.FOVCircle.Color,
		["Filled"] = SilentAimbot.FOVCircle.Filled,
		["Thickness"] = SilentAimbot.FOVCircle.Thickness,
		["Radius"] = SilentAimbot.FOVCircle.Radius,
		["Visible"] = false
	})
}

local RageBot = {
	["TargetCache"] = nil,
	["TargetPart"] = nil,

	["LastAttackTime"] = 0,
	["IsAttacking"] = false,

	Scale = false,
	["Weapon"] = "Knife",
	["AimPart"] = "Head",
	["MultiTarget"] = true,

	["ForceFieldCheck"] = true,
	["WallCheck"] = true,
	["TeamCheck"] = false,

	["CustomTargetList"] = {},
	["MaxDistance"] = 2500,
}

local RageBotTargets = {}
local RageBotArguments = {["zSign"] = 1}

local HitConfiguration = {
	Scale = false,

	["Marker"] = {
		Enabled = false,
		["Color"] = Color3.fromRGB(255, 255, 255),
		["Lifetime"] = 1,
		["Scale"] = 1,
		["Style"] = "Broken X",
		["CenterDot"] = false,
		["FadeIn"] = false,
		["FadeOut"] = false,
	},

	["Log"] = {
		Enabled = false,
		["Color"] = Color3.fromRGB(255, 255, 255),
		["UseColor"] = false,
		["Duration"] = 1,
	},

	["Sound"] = {
		Enabled = false,
		["Selected"] = "Osu",
		["Volume"] = 5
	},

	["SavedHealth"] = {},
	["SavedPositions"] = {},
	["Connections"] = {},
	["PendingHits"] = {}
}
local HitMarkerDirections = {
	Vector2.new(-1, -1), Vector2.new( 1, -1),
	Vector2.new(-1,  1), Vector2.new( 1,  1)
}

local HitSounds = {
	["Sounds"] = {
		["Osu"] = "7172607676",
		["Pop"] = "102822111971881",
		["MLG"] = "109817519733426",
		["Metal"] = "8917041751",
		["Neverlose"] = "18391691942",
		["Jet Set Radio"] = "97113622160405",
		["TF2 Critical"] = "8255306220",
		["TF2 Alternative"] = "2868331684",
		["TF2 Frying Pan"] = "18922477538",
		["Bad Business Headshot"] = "9368845024"
	},
	["Folder"] = Create("Folder", CoreGui)
}

local AntiAim = {
	Scale = false,
	Enabled = false,
	["Mode"] = "None",
	["SpinBot"] = 1
}

local LocalHighlight = {
	Enabled = false,
	["Color"] = Color3.fromRGB(255, 255, 255),
	["Transparency"] = 0
}

local ChinaHat = {
    ["ChinaHatTrail"] = nil,
    ["Color"] = Color3.fromRGB(255, 0, 0),
    ["Scale"] = Vector3.new(3, 0.6, 3),
    ["ChinaHatTrailSize"] = Vector3.new(3, 0.7, 3),
}
local OldDevCameraOcclusionMode = LocalPlayer.DevCameraOcclusionMode

local ESPObjects = {}

local ESPToggled = false

local ESPDynamicRefreshRate = true
local ESPRefreshRate = 60
local ESPAccumulator = 0

local ESPPerformanceMode = false

local ESPDistanceCheck = 2500
local ESPForceFieldCheck = false
local ESPWallCheck = false
local ESPTeamCheck = false

local ChamESP = {
	Enabled = false,
	["FillColor"] = Color3.fromRGB(255, 255, 255),
	["OutlineColor"] = Color3.fromRGB(255, 255, 255),
	["FillTransparency"] = 0.5,
	["OutlineTransparency"] = 0
}

local HeadTagESP, TagBuffer = {
	Enabled = false,
	["Color"] = Color3.fromRGB(255, 255, 255),
	["Transparency"] = 1,
	["Position"] = "Top"
}, table.create(7)

local TracerESP = {
	Enabled = false,
	["Color"] = Color3.fromRGB(255, 255, 255),
	["Type"] = "Locked",
	["Part"] = "Root",
	["Transparency"] = 1
}

local BoxESP, BoxPointScreen, BoxPointOnScreen, Box3DOffsets, Box3DEdges = {
	["Box2D"] = {
		Enabled = false,
		["Color"] = Color3.fromRGB(255, 255, 255),
		["Filled"] = false,
		["Transparency"] = 1
	},
	["Box3D"] = {
		Enabled = false,
		["Color"] = Color3.fromRGB(255, 255, 255),
		["Transparency"] = 1
	}
}, table.create(8), table.create(8), {
	Vector3.new(-2, 3, -1.5), Vector3.new(2, 3, -1.5),
    Vector3.new(-2, -3, -1.5), Vector3.new(2, -3, -1.5),
    Vector3.new(-2, 3, 1.5), Vector3.new(2, 3, 1.5),
	Vector3.new(-2, -3, 1.5), Vector3.new(2, -3, 1.5)
}, {
	{1,2}, {2,4}, {4,3}, {3,1},
	{5,6}, {6,8}, {8,7}, {7,5},
	{1,5}, {2,6}, {3,7}, {4,8}
}

local SkeletonESP = {
	Enabled = false,    
	["Color"] = Color3.fromRGB(255, 255, 255),
	["Thickness"] = 1,
	["Transparency"] = 1
}

local World = {
	["OldExposureCompensation"] = Lighting.ExposureCompensation,
	["OldAmbient"] = Lighting.Ambient,
	["OldOutdoorAmbient"] = Lighting.OutdoorAmbient,
	["OldCameraFOV"] = nil
}

local NoRecoil = false

local CachedRaycastParams = RaycastParams.new()
CachedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
CachedRaycastParams.IgnoreWater = true

local CoolEmptyTable = {}

local PlayerJoinLogs = false
local PlayerLeaveLogs = false

workspace.FallenPartsDestroyHeight = -math.huge

local function UpdateCamera()
	local CurrentCamera = workspace.CurrentCamera
	if not CurrentCamera then
		return
	end

	Camera = CurrentCamera
	ViewportSize = CurrentCamera.ViewportSize
	ScreenCenter = ViewportSize * 0.5
	FixedBottomCenter = Vector2.new(ViewportSize.X * 0.5, ViewportSize.Y * 0.54054)
end

local function BindCamera()
	ConnectionManager:Disconnect("ViewportChanged")

	local CurrentCamera = workspace.CurrentCamera
	if not CurrentCamera then
		return
	end

	UpdateCamera()
	ConnectionManager:Connect("ViewportChanged", CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateCamera))
end

ConnectionManager:Connect("CameraChanged", workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCamera))
BindCamera()

ConnectionManager:Connect(GenerateGUID(false), Mouse.Move:Connect(function()
	MouseLocation = UserInputService:GetMouseLocation()
end))

ConnectionManager:Connect(GenerateGUID(false), LocalPlayer.CharacterAdded:Connect(function()
	table.clear(RageBotTargets)
	RageBot.TargetPart = nil
	RageBot.LastAttackTime = 0
	RageBot.IsAttacking = false
end))

local function GetSettingsShield()
    if CachedSettingsShield and CachedSettingsShield.Parent then
        return CachedSettingsShield
    end

    if not CachedRobloxGui or not CachedRobloxGui.Parent then
        CachedRobloxGui = CoreGui:FindFirstChild("RobloxGui")
        if not CachedRobloxGui then
            return nil
        end
    end

    if not CachedClippingShield or not CachedClippingShield.Parent then
        CachedClippingShield = CachedRobloxGui:FindFirstChild("SettingsClippingShield")
        if not CachedClippingShield then
            return nil
        end
    end

    CachedSettingsShield = CachedClippingShield:FindFirstChild("SettingsShield")
    return CachedSettingsShield
end

local function IsEnemy(Player)
	if not Player then
		return false
	end

	if #Teams:GetTeams() <= 1 or Player.Team ~= LocalPlayer.Team then
		return true
	end

	return false
end

local function IsDead(Character, Cache)
	if not Character or not Cache.Root or not Cache.Head then
		return true
	end

	local Humanoid = Cache.Humanoid
	if not Humanoid or Humanoid.Health <= 0 then
		return true
	end

	return false
end

local function CanHit(TargetPosition, Character)
	if not LocalHead then
		return false
	end

	local Origin = LocalHead.Position
	local Result = workspace:Raycast(Origin, (TargetPosition - Origin).Unit * 1000, CachedRaycastParams)
	if not Result then
		return true
	end

	return Result.Instance and Result.Instance:IsDescendantOf(Character)
end

local function WorldToViewportPoint(Position)
	if not Camera then
		return Vector2.zero, false
	end

	local Screen, OnScreen = Camera:WorldToViewportPoint(Position)
	return Vector2.new(Screen.X, Screen.Y), OnScreen
end

local function WorldToScreenPoint(Position, IncludeZ)
	if not Camera then
		return Vector2.zero, false
	end

	local Screen, OnScreen = Camera:WorldToScreenPoint(Position)
	if IncludeZ then
		return Screen, OnScreen
	else
		return Vector2.new(Screen.X, Screen.Y), OnScreen
	end
end

local function ClearCache(Player)
	local Cache = CachedPlayers[Player]
	if not Cache then
		return
	end

	local ESP = Cache.ESP
	if ESP then
		for Index, Object in next, ESP do
			if Index == "Cham" then
				Object:Destroy()
				continue
			end

			if Index == "Box3D" or Index == "Skeleton" then
				for _,DrawingObject in next, Object do
					DrawingManager:Remove(DrawingObject)
				end
				continue
			end

			DrawingManager:Remove(Object)
		end
	end

	CachedPlayers[Player] = nil
	for Index = 1, #CachedPlayersList do
		if CachedPlayersList[Index] == Cache then
			table.remove(CachedPlayersList, Index)
			break
		end
	end
end

local function CachePlayer(Player)
	local Character = Player.Character

	if not Character then
		ClearCache(Player)
		return nil
	end

	local Cache = CachedPlayers[Player] or {}

	Cache.Player = Player
	local Name = Player.Name
	Cache.Name = Name
	Cache.DisplayName = Player.DisplayName

	Cache.Character = Character
	Cache.Humanoid = Character:FindFirstChildOfClass("Humanoid")

	local Children = Character:GetChildren()
	for Index = 1, #Children do
		local Child = Children[Index]
		if Child:IsA("BasePart") then
			Cache[Child.Name] = Child
		end
	end

	Cache.Root = Cache["HumanoidRootPart"]

	local ESP = Cache.ESP
	if not ESP then
		ESP = table.create(6)

		ESP.Cham = Create("Highlight", CoreGui, {
			Enabled = false,
			Name = "Cham_" .. Name,
			FillColor = ChamESP.FillColor,
			OutlineColor = ChamESP.OutlineColor,
			FillTransparency = ChamESP.FillTransparency,
			OutlineTransparency = ChamESP.OutlineTransparency,
			Adornee = Character
		})

		ESP.HeadTag = DrawingManager("Text", {
			Text = "",
			Color = HeadTagESP.Color,
			Transparency = HeadTagESP.Transparency,
			Size = 16,
			Center = true,
			Outline = true,
			Visible = false
		})

		ESP.Tracer = DrawingManager("Line", {
			Color = TracerESP.Color,
			Transparency = TracerESP.Transparency,
			Thickness = 2,
			Visible = false
		})

		ESP.Box2D = DrawingManager("Square", {
			Transparency = BoxESP.Box2D.Transparency,
			Thickness = 2,
			Size = Vector2.new(50, 50),
			Color = BoxESP.Box2D.Color,
			Visible = false
		})

		ESP.Box3D = table.create(12)
		for Index = 1, 12 do
			ESP.Box3D[Index] = DrawingManager("Line", {
				Color = BoxESP.Box3D.Color,
				Transparency = BoxESP.Box3D.Transparency,
				Thickness = 2,
				Visible = false
			})
		end

		ESP.Skeleton = table.create(16)
		for Index = 1, 16 do
			ESP.Skeleton[Index] = DrawingManager("Line", {
				Thickness = SkeletonESP.Thickness,
				Color = SkeletonESP.Color,
				Transparency = SkeletonESP.Transparency,
				Visible = false
			})
		end

		for Index, Object in next, ESP do
			if Index == "Box3D" or Index == "Skeleton" then
				for _,DrawingObject in next, Object do
					table.insert(ESPObjects, DrawingObject)
				end
			else
				table.insert(ESPObjects, Object)
			end
		end

		Cache.ESP = ESP
	end

	setmetatable(ESP, {
		__call = function(self, IgnoreCham)
			local ShouldCham = not IgnoreCham
			for Index, Object in next, self do
				if Index == "Cham" then
					if ShouldCham and Object.Enabled ~= false then
						Object.Enabled = false
					end
					continue
				end

				if Index == "Box3D" or Index == "Skeleton" then
					for _,Line in next, Object do
						if Line.Visible ~= false then
							Line.Visible = false
						end
					end
					continue
				end

				if Object.Visible ~= false then
					Object.Visible = false
				end
			end
		end
	})

	CachedPlayers[Player] = Cache
	table.insert(CachedPlayersList, Cache)
	return Character, CachedPlayers[Player]
end

local function AddCache(Player)
	CachePlayer(Player)
	ConnectionManager:Connect(GenerateGUID(false), Player.CharacterAdded:Connect(function()
		CachePlayer(Player)
	end))
	ConnectionManager:Connect(GenerateGUID(false), Player.CharacterRemoving:Connect(function()
		ClearCache(Player)
	end))
end

ThreadManager:Start("CachedPlayers", function()
	CachedRaycastParams.FilterDescendantsInstances = {LocalCharacter, Camera}

	for _,Player in ipairs(Players:GetPlayers()) do
		if Player == LocalPlayer then
			continue
		end

		local Cache = CachedPlayers[Player]
		if not Cache then
			AddCache(Player)
		else
			local Character = Cache.Character
			if not Character or not Character.Parent then
				ClearCache(Player)
				AddCache(Player)
				continue
			end

			local Humanoid = Cache.Humanoid
			if not Humanoid or not Humanoid.Parent then
				ClearCache(Player)
				AddCache(Player)
				continue
			end

			local Root = Cache.Root
			if not Root or not Root.Parent then
				ClearCache(Player)
				AddCache(Player)
				continue
			end

			local Head = Cache.Head
			if not Head or not Head.Parent then
				ClearCache(Player)
				AddCache(Player)
				continue
			end
		end
	end
end, 2.5)

ConnectionManager:Connect(GenerateGUID(false), Players.PlayerAdded:Connect(function(Player)
	AddCache(Player)
	if PlayerJoinLogs then
		UI:Notify({
			Title = "[[ KAT.lol ]]",
			Description = Player.DisplayName .. " (@" .. Player.Name .. ") has Joined the server.",
			Time = 3.5
		})
	end
end))
ConnectionManager:Connect(GenerateGUID(false), Players.PlayerRemoving:Connect(function(Player)
	ClearCache(Player)
	if PlayerLeaveLogs then
		UI:Notify({
			Title = "[[ KAT.lol ]]",
			Description = Player.DisplayName .. " (@" .. Player.Name .. ") has Left the server.",
			Time = 3.5
		})
	end
end))

local function PlayHitSound(Option, Volume)
	Create("Sound", HitSounds.Folder, {
		SoundId = "rbxassetid://" .. HitSounds.Sounds[Option],
		PlayOnRemove = true,
		Volume = Volume,
	}):Destroy()
end

local CurrentPing = 0
task.spawn(function()
	local Stats = game:GetService("Stats")
	local HeartbeatStats = Stats:WaitForChild("Workspace"):WaitForChild("Heartbeat")

	local WatermarkAccumulator = 0
	ConnectionManager:Connect(GenerateGUID(false), RunService.RenderStepped(function(DeltaTime)
		WatermarkAccumulator += DeltaTime

		if WatermarkAccumulator < 0.1 then
			return
		end

		WatermarkAccumulator = 0

		if WatermarkIsVisible then
			Watermark:SetText("[NikoletoHub/KAT] | FPS: " .. math.floor(HeartbeatStats:GetValue()) .. " | Ping: " .. math.floor(CurrentPing) .. "ms")
		end
	end))

	local DataPing = Stats:WaitForChild("Network"):WaitForChild("ServerStatsItem"):WaitForChild("Data Ping")
	ThreadManager:Start("Ping", function()
		CurrentPing = DataPing:GetValue()
	end, 0.1)
end)


local function UpdateFOVCircle(FOVCircle, FOVCircleTable, AimbotTable)
	if not isrenderobj(FOVCircle) or not FOVCircleTable.Enabled or not AimbotTable.FOVCircle.Enabled then
		return
	end

	local Position = FOVCircleTable.Position == "Center" and ScreenCenter or MouseLocation
	if FOVCircle.Position ~= Position then
		FOVCircle.Position = Position
	end
end

ConnectionManager:Connect(GenerateGUID(false), RunService.RenderStepped((hookmetamethod and getnamecallmethod) and function()
	UpdateFOVCircle(AimbotFOVCircles.Target, Aimbot.FOVCircle, Aimbot)
	UpdateFOVCircle(AimbotFOVCircles.Silent, SilentAimbot.FOVCircle, SilentAimbot)
end or function()
	UpdateFOVCircle(AimbotFOVCircles.Target, Aimbot.FOVCircle, Aimbot)
end))

local function CanRenderVisually(CanBeOptimized, Cache, Character, HeadPosition)
	if IsDead(Character, Cache) then
		return false, Vector3.zero, nil
	end

	local LocalHeadPosition
	local Distance

	if LocalHead then
		LocalHeadPosition = LocalHead.Position
		Distance = (LocalHeadPosition - HeadPosition).Magnitude

		if Distance > ESPDistanceCheck then
			return false, LocalHeadPosition, math.floor(Distance)
		end

		if ESPWallCheck and not (CanBeOptimized and CanHit(HeadPosition, Character)) then
			return false, LocalHeadPosition, math.floor(Distance)
		end
	end

	return true, LocalHeadPosition or Vector3.zero, Distance and math.floor(Distance) or nil
end

ConnectionManager:Connect(GenerateGUID(false), RunService.RenderStepped(function(DeltaTime)
	if ESPPerformanceMode then -- Interval = 1 / 30
		ESPAccumulator += DeltaTime

		if ESPAccumulator < 0.03333333333 then
			return
		end

		ESPAccumulator -= 0.03333333333
	elseif not ESPDynamicRefreshRate then
		local Interval = 1 / ESPRefreshRate

		ESPAccumulator += DeltaTime

		if ESPAccumulator < Interval then
			return
		end

		ESPAccumulator -= Interval
	end

	local PlayerCount = #CachedPlayersList

	if not ESPToggled or not Camera or ESPDistanceCheck <= 0 then
		for Index = 1, PlayerCount do
			local Cache = CachedPlayersList[Index]
			if not Cache.IsVisible then
				continue
			end

			Cache.ESP()
			Cache.IsVisible = false
		end
		return
	end

    local ChamEnabled = ChamESP.Enabled

	local HeadTagEnabled = HeadTagESP.Enabled
	local HeadTagDropdown, HeadTagPosition

	if HeadTagEnabled then
		HeadTagDropdown = Options["HeadTagOptions"]
		HeadTagPosition = HeadTagESP.Position
	end

	local TracerEnabled = TracerESP.Enabled
	local TracerTypeIsLocked, TracerPartIsHead

	if TracerEnabled then
		TracerTypeIsLocked = TracerESP.Type == "Locked"
		TracerPartIsHead = TracerESP.Part == "Head"
	end

	local Box2DEnabled = BoxESP.Box2D.Enabled
	local Box3DEnabled = BoxESP.Box3D.Enabled
	local SkeletonEnabled = SkeletonESP.Enabled

	local ShouldContinue = ChamEnabled or HeadTagEnabled or TracerEnabled or Box2DEnabled or Box3DEnabled or SkeletonEnabled

	if not ShouldContinue then
		for Index = 1, PlayerCount do
			local Cache = CachedPlayersList[Index]
			if not Cache.IsVisible then
				continue
			end

			Cache.ESP()
			Cache.IsVisible = false
		end
		return
	end

	local CameraCFrame = Camera.CFrame
	local CameraPosition = CameraCFrame.Position
	local CameraLookVector = CameraCFrame.LookVector

	local CanBeOptimized = ChamEnabled and not HeadTagEnabled and not TracerEnabled and not Box2DEnabled and not Box3DEnabled and not SkeletonEnabled

	for Player = 1, PlayerCount do
		local Cache = CachedPlayersList[Player]
		local ESP = Cache.ESP

		local Character = Cache.Character
		if not Character then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		local Humanoid = Cache.Humanoid
		if not Humanoid or Humanoid.Health <= 0 then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		if ESPForceFieldCheck and Character:FindFirstChildOfClass("ForceField") then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		local Head = Cache.Head
		if not Head then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		local Root = Cache.Torso or Cache.Root
		if not Root then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		local HeadPosition = Head.Position
		if CameraLookVector:Dot(HeadPosition - CameraPosition) <= 0 then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		if ESPTeamCheck and not IsEnemy(Player) then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		local CanRenderState, LocalHeadPosition, Distance = CanRenderVisually(CanBeOptimized, Cache, Character, HeadPosition)
		if not CanRenderState then
			if Cache.IsVisible then
				Cache.ESP()
				Cache.IsVisible = false
			end
			continue
		end

		local HeadScreen, HeadOnScreen = WorldToViewportPoint(HeadPosition)

		if not HeadOnScreen then
			if Cache.IsVisible then
				Cache.ESP(true)
				Cache.IsVisible = false
			end
			continue
		end

		local RootPosition = Root.Position
		local RootScreen, RootOnScreen = WorldToViewportPoint(RootPosition)

		if not RootOnScreen then
			if Cache.IsVisible then
				Cache.ESP(true)
				Cache.IsVisible = false
			end
			continue
		end

		local TopScreen, TopOnScreen = nil, false
		local TopScreenX, TopScreenY = 0, 0

		if HeadTagEnabled or Box2DEnabled then
			TopScreen, TopOnScreen = WorldToViewportPoint(HeadPosition + ESPHeadOffset)
			TopScreenX, TopScreenY = TopScreen.X, TopScreen.Y
		end

		local ChamObject = ESP.Cham
		if ChamEnabled and ChamObject then
			local Depth = ESPWallCheck and HighlightDepthModeOccluded or HighlightDepthModeAlwaysOnTop
			if ChamObject.DepthMode ~= Depth then
				ChamObject.DepthMode = Depth
			end

			if ChamObject.Enabled ~= true then
				ChamObject.Enabled = true
			end
		elseif ChamObject then
			if ChamObject.Enabled ~= false then
				ChamObject.Enabled = false
			end
		end

		local FootScreen, FootOnScreen = nil, false
		local FootScreenY = 0

		if (HeadTagEnabled and HeadTagPosition == "Bottom") or Box2DEnabled then
			FootScreen, FootOnScreen = WorldToViewportPoint(RootPosition - Vector3.new(0, Humanoid.HipHeight + 2, 0))
			FootScreenY = FootScreen.Y
		end

		local HeadTagObject = ESP.HeadTag
		if HeadTagEnabled and HeadTagObject and TopOnScreen then
			local HeadTagString = ""

			if HeadTagDropdown then
				local Values = HeadTagDropdown.Values
				if Values then
					local Selected = HeadTagDropdown.Value
					table.clear(TagBuffer)

					for _,Option in ipairs(Values) do
						if Selected and Selected[Option] then
							local OptionText = ""

							if Option == "Full Name" then
								OptionText = Cache.DisplayName .. " (@" .. Cache.Name .. ")"
							elseif Option == "Name" then
								OptionText = Cache.Name
							elseif Option == "DisplayName" then
								OptionText = Cache.DisplayName
							elseif Option == "Weapon" then
								local ToolName = "None"
								local Tool = Character:FindFirstChildOfClass("Tool")
								if Tool then
									ToolName = Tool.Name
								end
								OptionText = ToolName
							elseif Option == "Health" then
                        		OptionText = math.floor(Humanoid.Health) .. " Health"
							elseif Option == "Distance" then
								OptionText =  (Distance or math.floor((LocalHeadPosition - HeadPosition).Magnitude)) .. " Studs Away"
							end

							table.insert(TagBuffer, OptionText)
						end
					end

					HeadTagString = table.concat(TagBuffer, " | ")
				end
			end

			if HeadTagPosition == "Top" then
				if HeadTagObject.Position ~= TopScreen then
					HeadTagObject.Position = TopScreen
				end
			else
				if HeadTagObject.Position ~= FootScreen then
					HeadTagObject.Position = FootScreen
				end
			end

			if HeadTagObject.Text ~= HeadTagString then
				HeadTagObject.Text = HeadTagString
			end

			if HeadTagObject.Visible ~= true then
				HeadTagObject.Visible = true
			end
		elseif HeadTagObject then
			if HeadTagObject.Visible ~= false then
				HeadTagObject.Visible = false
			end
		end

		local TracerObject = ESP.Tracer
		if TracerEnabled and TracerObject then
			local FromScreen = TracerTypeIsLocked and FixedBottomCenter or MouseLocation
			if TracerObject.From ~= FromScreen then
				TracerObject.From = FromScreen
			end

			local ToScreen = TracerPartIsHead and HeadScreen or RootScreen
			if TracerObject.To ~= ToScreen then
				TracerObject.To = ToScreen
			end

			if TracerObject.Visible ~= true then
				TracerObject.Visible = true
			end
		elseif TracerObject then
			if TracerObject.Visible ~= false then
				TracerObject.Visible = false
			end
		end

		local Box2DObject = ESP.Box2D
		if TopOnScreen and FootOnScreen and Box2DEnabled and Box2DObject then
			local BoxHealthBarHeight = math.abs(FootScreenY - TopScreenY)
			local BoxHealthBarWidth = BoxHealthBarHeight * 0.5

			local Size = Vector2.new(BoxHealthBarWidth, BoxHealthBarHeight)
			if Box2DObject.Size ~= Size then
				Box2DObject.Size = Size
			end

			local Position = Vector2.new(TopScreenX - BoxHealthBarWidth * 0.5, TopScreenY)
			if Box2DObject.Position ~= Position then
				Box2DObject.Position = Position
			end

			if Box2DObject.Visible ~= true then
				Box2DObject.Visible = true
			end
		elseif Box2DObject then
			if Box2DObject.Visible ~= false then
				Box2DObject.Visible = false
			end
		end

		local Box3DLines = ESP.Box3D
        if Box3DEnabled then
            local RootCFrame = Root.CFrame

            for Index = 1, 8 do
                local Screen, OnScreen = WorldToViewportPoint(RootCFrame:PointToWorldSpace(Box3DOffsets[Index]))
                BoxPointScreen[Index] = Screen
                BoxPointOnScreen[Index] = OnScreen
            end

            for Index = 1, 12 do
                local Line = Box3DLines[Index]
                local Edge = Box3DEdges[Index]
                local P1, P2 = Edge[1], Edge[2]

                if BoxPointOnScreen[P1] and BoxPointOnScreen[P2] then
					local From = BoxPointScreen[P1]
					if Line.From ~= From then
						Line.From = From
					end

					local To = BoxPointScreen[P2]
					if Line.To ~= To then
						Line.To = To
					end

					if Line.Visible ~= true then
						Line.Visible = true
					end
                else
					if Line.Visible ~= false then
						Line.Visible = false
					end
                end
            end
        else
            for Index = 1, 12 do
				local Line = Box3DLines[Index]
				if Line.Visible ~= false then
					Line.Visible = false
				end
            end
        end

		local SkeletonLines = ESP.Skeleton
		if SkeletonEnabled then
			local Torso = Cache.Torso
			if Torso then
				local TorsoCFrame = Torso.CFrame
				local TorsoSize = Torso.Size

				local NeckPosition, NeckVisible = WorldToViewportPoint(TorsoCFrame:PointToWorldSpace(TorsoSize * R6Neck))
				local WaistPosition, WaistVisible = WorldToViewportPoint(TorsoCFrame:PointToWorldSpace(TorsoSize * R6Waist))

				local SpineLine = SkeletonLines[1]
				if NeckVisible and WaistVisible then
					local From = NeckPosition
					if SpineLine.From ~= From then
						SpineLine.From = From
					end

					local To = WaistPosition
					if SpineLine.To ~= To then
						SpineLine.To = To
					end

					if SpineLine.Visible ~= true then
						SpineLine.Visible = true
					end
				else
					if SpineLine.Visible ~= false then
						SpineLine.Visible = false
					end
				end

				local NeckLine = SkeletonLines[2]
				if NeckVisible and HeadOnScreen then
					local From = NeckPosition
					if NeckLine.From ~= From then
						NeckLine.From = From
					end

					local To = HeadScreen
					if NeckLine.To ~= To then
						NeckLine.To = To
					end

					if NeckLine.Visible ~= true then
						NeckLine.Visible = true
					end
				else
					if NeckLine.Visible ~= false then
						NeckLine.Visible = false
					end
				end

				local LeftArm = Cache["Left Arm"]
				local LeftShoulderLine, LeftArmLine = SkeletonLines[3], SkeletonLines[4]
				if LeftArm then
					local LeftArmCFrame = LeftArm.CFrame
					local LeftArmSize = LeftArm.Size
					local Position1, Visible1 = WorldToViewportPoint(LeftArmCFrame:PointToWorldSpace(LeftArmSize * R6Top))
					local Position2, Visible2 = WorldToViewportPoint(LeftArmCFrame:PointToWorldSpace(LeftArmSize * R6Bottom))

					if NeckVisible and Visible1 then
						local From = NeckPosition
						if LeftShoulderLine.From ~= From then
							LeftShoulderLine.From = From
						end

						local To = Position1
						if LeftShoulderLine.To ~= To then
							LeftShoulderLine.To = To
						end

						if LeftShoulderLine.Visible ~= true then
							LeftShoulderLine.Visible = true
						end
					else
						if LeftShoulderLine.Visible ~= false then
							LeftShoulderLine.Visible = false
						end
					end

					if Visible1 and Visible2 then
						local From = Position1
						if LeftArmLine.From ~= From then
							LeftArmLine.From = From
						end

						local To = Position2
						if LeftArmLine.To ~= To then
							LeftArmLine.To = To
						end

						if LeftArmLine.Visible ~= true then
							LeftArmLine.Visible = true
						end
					else
						if LeftArmLine.Visible ~= false then
							LeftArmLine.Visible = false
						end
					end
				else
					if LeftShoulderLine.Visible ~= false then
						LeftShoulderLine.Visible = false
					end

					if LeftArmLine.Visible ~= false then
						LeftArmLine.Visible = false
					end
				end

				local RightArm = Cache["Right Arm"]
				local RightShoulderLine, RightArmLine = SkeletonLines[5], SkeletonLines[6]
				if RightArm then
					local RightArmCFrame = RightArm.CFrame
					local RightArmSize = RightArm.Size
					local Position1, Visible1 = WorldToViewportPoint(RightArmCFrame:PointToWorldSpace(RightArmSize * R6Top))
					local Position2, Visible2 = WorldToViewportPoint(RightArmCFrame:PointToWorldSpace(RightArmSize * R6Bottom))

					if NeckVisible and Visible1 then
						local From = NeckPosition
						if RightShoulderLine.From ~= From then
							RightShoulderLine.From = From
						end

						local To = Position1
						if RightShoulderLine.To ~= To then
							RightShoulderLine.To = To
						end

						if RightShoulderLine.Visible ~= true then
							RightShoulderLine.Visible = true
						end
					else
						if RightShoulderLine.Visible ~= false then
							RightShoulderLine.Visible = false
						end
					end

					if Visible1 and Visible2 then
						local From = Position1
						if RightArmLine.From ~= From then
							RightArmLine.From = From
						end

						local To = Position2
						if RightArmLine.To ~= To then
							RightArmLine.To = To
						end

						if RightArmLine.Visible ~= true then
							RightArmLine.Visible = true
						end
					else
						if RightArmLine.Visible ~= false then
							RightArmLine.Visible = false
						end
					end
				else
					if RightShoulderLine.Visible ~= false then
						RightShoulderLine.Visible = false
					end

					if RightArmLine.Visible ~= false then
						RightArmLine.Visible = false
					end
				end

				local LeftLeg = Cache["Left Leg"]
				local LeftHipLine, LeftLegLine = SkeletonLines[7], SkeletonLines[8]
				if LeftLeg then
					local LeftLegCFrame = LeftLeg.CFrame
					local LeftLegSize = LeftLeg.Size
					local Position1, Visible1 = WorldToViewportPoint(LeftLegCFrame:PointToWorldSpace(LeftLegSize * R6Top))
					local Position2, Visible2 = WorldToViewportPoint(LeftLegCFrame:PointToWorldSpace(LeftLegSize * R6Bottom))

					if WaistVisible and Visible1 then
						local From = WaistPosition
						if LeftHipLine.From ~= From then
							LeftHipLine.From = From
						end

						local To = Position1
						if LeftHipLine.To ~= To then
							LeftHipLine.To = To
						end

						if LeftHipLine.Visible ~= true then
							LeftHipLine.Visible = true
						end
					else
						if LeftHipLine.Visible ~= false then
							LeftHipLine.Visible = false
						end
					end

					if Visible1 and Visible2 then
						local From = Position1
						if LeftLegLine.From ~= From then
							LeftLegLine.From = From
						end

						local To = Position2
						if LeftLegLine.To ~= To then
							LeftLegLine.To = To
						end

						if LeftLegLine.Visible ~= true then
							LeftLegLine.Visible = true
						end
					else
						if LeftLegLine.Visible ~= false then
							LeftLegLine.Visible = false
						end
					end
				else
					if LeftHipLine.Visible ~= false then
						LeftHipLine.Visible = false
					end

					if LeftLegLine.Visible ~= false then
						LeftLegLine.Visible = false
					end
				end

				local RightLeg = Cache["Right Leg"]
				local RightHipLine, RightLegLine = SkeletonLines[9], SkeletonLines[10]
				if RightLeg then
					local RightLegCFrame = RightLeg.CFrame
					local RightLegSize = RightLeg.Size
					local Position1, Visible1 = WorldToViewportPoint(RightLegCFrame:PointToWorldSpace(RightLegSize * R6Top))
					local Position2, Visible2 = WorldToViewportPoint(RightLegCFrame:PointToWorldSpace(RightLegSize * R6Bottom))

					if WaistVisible and Visible1 then
						local From = WaistPosition
						if RightHipLine.From ~= From then
							RightHipLine.From = From
						end

						local To = Position1
						if RightHipLine.To ~= To then
							RightHipLine.To = To
						end

						if RightHipLine.Visible ~= true then
							RightHipLine.Visible = true
						end
					else
						if RightHipLine.Visible ~= false then
							RightHipLine.Visible = false
						end
					end

					if Visible1 and Visible2 then
						local From = Position1
						if RightLegLine.From ~= From then
							RightLegLine.From = From
						end

						local To = Position2
						if RightLegLine.To ~= To then
							RightLegLine.To = To
						end

						if RightLegLine.Visible ~= true then
							RightLegLine.Visible = true
						end
					else
						if RightLegLine.Visible ~= false then
							RightLegLine.Visible = false
						end
					end
				else
					if RightHipLine.Visible ~= false then
						RightHipLine.Visible = false
					end

					if RightLegLine.Visible ~= false then
						RightLegLine.Visible = false
					end
				end
			else
				for Index = 1, 10 do
					local Line = SkeletonLines[Index]
					if Line.Visible ~= false then
						Line.Visible = false
					end
				end
			end
		else
			for Index = 1, #SkeletonLines do
				local Line = SkeletonLines[Index]
				if Line.Visible ~= false then
					Line.Visible = false
				end
			end
		end

		Cache.IsVisible = true
	end
end))

local function TriggerHitFunctions(PreviousHealth, Health, WorldPosition, TargetLabel)
	if not HitConfiguration.Toggled then
		return
	end

	local Log = HitConfiguration.Log
	if Log.Enabled then
		local HealthHit = math.floor(PreviousHealth - Health)
		if HealthHit ~= 0 then
			local FullName = TargetLabel ~= "" and TargetLabel or "???"

			local Description
			if Log.UseColor then
				local Color = Log.Color
				Description = FullName .. " has been hit for " .. string.format(
					'<font color="%s">%s</font>', string.format("#%02X%02X%02X", Color.R * 255, Color.G * 255, Color.B * 255), HealthHit
				) .. " health"
			else
				Description = FullName .. "Hit for " .. HealthHit .. " health"
			end

			task.defer(function()
				UI:Notify({
					Title = "Hit Information",
					Description = Description,
					Time = Log.Duration
				})
			end)
		end
	end

	if WorldPosition then
		local Marker = HitConfiguration.Marker
		if Marker.Enabled then
			local Style = Marker.Style
			local Scale = Marker.Scale
			local Color = Marker.Color
			local Lifetime = Marker.Lifetime
			local FadeIn = Marker.FadeIn
			local FadeOut = Marker.FadeOut

			local IsClassicX = Style == "Classic X"
			local IsBrokenX = Style == "Broken X"
			local IsPlus = Style == "Plus"
			local IsCircle = Style == "Circle"

			local Size = 15 * Scale
			local FadeTime = math.clamp(Lifetime * 0.2, 0.05, 0.25)

			local Lines = {}
			local Circle = nil
			local Dot = nil

			if Marker.CenterDot then
				Dot = DrawingManager("Circle", {
					NumSides = 24,
					Filled = true,
					Thickness = 2,
					Color = Color,
					Transparency = 1,
					Visible = false
				})
				Dot.Radius = 2 * Scale
			end

			if IsClassicX or IsBrokenX or IsPlus then
				for _ = 1, 4 do
					Lines[#Lines + 1] = DrawingManager("Line", {
						Thickness = 2,
						Color = Color,
						Transparency = 1,
						Visible = false
					})
				end
			elseif IsCircle then
				Circle = DrawingManager("Circle", {
					NumSides = 24,
					Filled = false,
					Thickness = 2,
					Color = Color,
					Transparency = 1,
					Visible = false
				})
				Circle.Radius = Size
			end

			local Offsets
			if IsPlus then
				Offsets = {
					Vector2.new(-Size, 0), Vector2.new(Size, 0),
					Vector2.new(0, -Size), Vector2.new(0, Size)
				}
			end

			local StartTime = tick()
			local LastCameraCFrame = Camera and Camera.CFrame or CFrameZero
			local Screen, OnScreen = WorldToViewportPoint(WorldPosition)

			local MarkerID = GenerateGUID(false)
			ConnectionManager:Connect(MarkerID, RunService.RenderStepped(function()
				local ElapsedTime = tick() - StartTime
				if ElapsedTime >= Lifetime then
					for _,Line in ipairs(Lines) do
						DrawingManager:Remove(Line)
					end

					if Circle then
						DrawingManager:Remove(Circle)
					end

					if Dot then
						DrawingManager:Remove(Dot)
					end

					ConnectionManager:Disconnect(MarkerID)
					return
				end

				local Alpha = 1
				if FadeIn and FadeOut then
					if ElapsedTime < FadeTime then
						Alpha = ElapsedTime / FadeTime
					elseif ElapsedTime > (Lifetime - FadeTime) then
						Alpha = (Lifetime - ElapsedTime) / FadeTime
					end
				elseif FadeIn then
					Alpha = math.clamp(ElapsedTime / FadeTime, 0, 1)
				elseif FadeOut then
					Alpha = math.clamp(1 - (ElapsedTime / Lifetime), 0, 1)
				end

				local CameraCFrame = Camera and Camera.CFrame or CFrameZero
				if CameraCFrame ~= LastCameraCFrame then
					Screen, OnScreen = WorldToViewportPoint(WorldPosition)
					LastCameraCFrame = CameraCFrame
				end

				for _,Line in next, Lines do
					if Line.Transparency ~= Alpha then
						Line.Transparency = Alpha
					end

					if Line.Visible ~= false then
						Line.Visible = false
					end
				end

				if Circle then
					if Circle.Transparency ~= Alpha then
						Circle.Transparency = Alpha
					end

					if Circle.Visible ~= false then
						Circle.Visible = false
					end
				end

				if Dot then
					if Dot.Transparency ~= Alpha then
						Dot.Transparency = Alpha
					end

					if Dot.Visible ~= false then
						Dot.Visible = false
					end
				end

				if not OnScreen then
					for _,Line in next, Lines do
						if Line and Line.Visible ~= false then
							Line.Visible = false
						end
					end

					if Circle and Circle.Visible ~= false then
						Circle.Visible = false
					end

					if Dot and Dot.Visible ~= false then
						Dot.Visible = false
					end

					return
				end

				if IsClassicX then
					for Index = 1, 4 do
						local Direction = HitMarkerDirections[Index]
						local Line = Lines[Index]

						local From = Screen + Direction
						if Line.From ~= From then
							Line.From = From
						end

						local To = Screen + Direction * Size
						if Line.To ~= To then
							Line.To = To
						end

						if Line.Visible ~= true then
							Line.Visible = true
						end
					end
				elseif IsBrokenX then
					local Gap = Size * 0.35
					for Index = 1, 4 do
						local Direction = HitMarkerDirections[Index]
						local Line = Lines[Index]

						local From = Screen + Direction * Gap
						if Line.From ~= From then
							Line.From = From
						end

						local To = Screen + Direction * Size
						if Line.To ~= To then
							Line.To = To
						end

						if Line.Visible ~= true then
							Line.Visible = true
						end
					end
				elseif IsPlus then
					for Index = 1, 4 do
						local Line = Lines[Index]

						if Line.From ~= Screen then
							Line.From = Screen
						end

						local To = Screen + Offsets[Index]
						if Line.To ~= To then
							Line.To = To
						end

						if Line.Visible ~= true then
							Line.Visible = true
						end
					end
				elseif IsCircle and Circle then
					if Circle.Position ~= Screen then
						Circle.Position = Screen
					end

					if Circle.Visible ~= true then
						Circle.Visible = true
					end
				end

				if Dot then
					if Dot.Position ~= Screen then
						Dot.Position = Screen
					end

					if Dot.Visible ~= true then
						Dot.Visible = true
					end
				end
			end))
		end
	end

	local Sound = HitConfiguration.Sound
	if Sound.Enabled then
		task.defer(PlayHitSound, Sound.Selected, Sound.Volume)
	end
end

local function GetWorldPosition(Cache)
	local AimPart = Cache[RageBot.AimPart]
	if AimPart then
		return AimPart.Position
	end
	return nil
end

local function CanUseWeapon()
	if not LocalCharacter then
		return false
	end

	local Tool = LocalCharacter:FindFirstChildOfClass("Tool")
	if not Tool then
		return false
	end

	return Tool:FindFirstChild(RageBot.Weapon .. "Server") ~= nil
end

local function DisconnectHealthListeners()
	local Connections = HitConfiguration.Connections
	for _,Connection in next, Connections do
		if Connection and Connection.Connection then
			Connection.Connection:Disconnect()
		end
	end

	table.clear(Connections)
	table.clear(HitConfiguration.SavedHealth)
	table.clear(HitConfiguration.PendingHits)
	table.clear(HitConfiguration.SavedPositions)
end

local function AddHealthListener(Player, Cache)
	local Humanoid = Cache and Cache.Humanoid
	if not Humanoid then
		return
	end

	local Connection = HitConfiguration.Connections[Player]
	if Connection then
		if Connection.Humanoid ~= Humanoid then
			if Connection.Connection then
				Connection.Connection:Disconnect()
			end
			HitConfiguration.Connections[Player] = nil
			Connection = nil
		else
			return
		end
	end

	local SavedHealth = HitConfiguration.SavedHealth
	if SavedHealth[Player] == nil then
		SavedHealth[Player] = Humanoid.Health
	end

	HitConfiguration.Connections[Player] = {
		Humanoid = Humanoid,
		Connection = Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			if not HitConfiguration.Toggled or not RageBot.Toggled then
				return
			end

			local Cache = CachedPlayers[Player]
			if not Cache or Cache.Humanoid ~= Humanoid then
				return
			end

			local HumanoidHealth = Humanoid.Health
			local PreviousHealth = SavedHealth[Player]
			if PreviousHealth == nil then
				PreviousHealth = HumanoidHealth
			end

			if HumanoidHealth < PreviousHealth then
				local Now = tick()
				local PendingHits = HitConfiguration.PendingHits[Player]
				if PendingHits and PendingHits > Now and CanUseWeapon() then
					TriggerHitFunctions(
						PreviousHealth, HumanoidHealth,
						HitConfiguration.SavedPositions[Player] or GetWorldPosition(Cache),
						Cache.DisplayName .. " (@" .. Cache.Name .. ")"
					)
				end
			end

			SavedHealth[Player] = HumanoidHealth
		end),
	}
end

local function RegisterPendingHit(Cache, Player, Health)
	if not HitConfiguration.Toggled or not RageBot.Toggled or not CanUseWeapon() then
		return
	end

	HitConfiguration.PendingHits[Player] = tick() + 1.1
	HitConfiguration.SavedHealth[Player] = Health

	HitConfiguration.SavedPositions[Player] = GetWorldPosition(Cache)
	AddHealthListener(Player, Cache)
end

local function HandleHitConfiguration()
	if not RageBot.Toggled then
		return
	end

	if not HitConfiguration.Toggled then
		DisconnectHealthListeners()
		return
	end

	if not CanUseWeapon() then
		DisconnectHealthListeners()
		return
	end

	local PendingHits = HitConfiguration.PendingHits
	local Now = tick()

	for Player, Expiration in next, PendingHits do
		if Expiration <= Now then
			PendingHits[Player] = nil
		end
	end

	local Targets = {AddTarget = function(self, Cache)
		if not Cache or not Cache.Character or not Cache[RageBot.AimPart] then
			return
		end

		local Humanoid = Cache.Humanoid
		if not Humanoid or Humanoid.Health <= 0 then
			return
		end

		self[Cache.Player] = Cache
	end}

	if RageBot.MultiTarget then
		for Index = 1, #RageBotTargets do
			Targets:AddTarget(RageBotTargets[Index])
		end
	elseif RageBot.TargetCache then
		Targets:AddTarget(RageBot.TargetCache)
	end

	Targets.AddTarget = nil

	for Player, Expiration in next, PendingHits do
		if Expiration > Now then
			local Cache = CachedPlayers[Player]
			if Cache and Cache.Humanoid and Cache.Humanoid.Parent then
				Targets[Player] = Cache
			end
		end
	end

	for Player in next, HitConfiguration.Connections do
		if not Targets[Player] then
			HitConfiguration.PendingHits[Player] = nil
			HitConfiguration.SavedPositions[Player] = nil

			local Connection = HitConfiguration.Connections[Player]
			Connection = Connection and Connection.Connection

			if Connection then
				Connection:Disconnect()
			end

			HitConfiguration.Connections[Player] = nil
			HitConfiguration.SavedHealth[Player] = nil
		end
	end

	for _,Cache in next, Targets do
		local Player = Cache.Player
		HitConfiguration.SavedPositions[Player] = GetWorldPosition(Cache)
		AddHealthListener(Player, Cache)
	end
end

local function StopAimbot()
	ConnectionManager:Disconnect("Aimbot")
	Aimbot.Enabled = false
	Aimbot.Target = nil
end

local function GetClosestPlayer()
	Aimbot.Target = nil

	local AimbotAimPart = Aimbot.AimPart
	local FOVCircle = Aimbot.FOVCircle
	local ClosestDistance = FOVCircle.Enabled and FOVCircle.Radius or math.huge
	local DeadCheck = Aimbot.DeadCheck
	local ForceFieldCheck = Aimbot.ForceFieldCheck
	local WallCheck = Aimbot.WallCheck
	local TeamCheck = Aimbot.TeamCheck

	for Player, Cache in next, CachedPlayers do
		if TeamCheck and not IsEnemy(Player) then
			continue
		end

		local Character = Cache.Character

		if DeadCheck and IsDead(Character, Cache) then
			continue
		end

		if ForceFieldCheck and Character:FindFirstChildOfClass("ForceField") then
			continue
		end

		local AimPart = Cache[AimbotAimPart]
		if not AimPart then
			continue
		end

		local AimPartPosition = AimPart.Position

		local Screen, OnScreen = WorldToScreenPoint(AimPartPosition, false)
		if OnScreen then
			local Distance = (MouseLocation - Screen).Magnitude
			if Distance < ClosestDistance then
				if WallCheck and not CanHit(AimPartPosition, Character) then
					Aimbot.Target = nil
					continue
				end

				ClosestDistance = Distance
				Aimbot.Target = Player
			end
		end
	end
end

local function TargetAimbot()
	local Target = Aimbot.Target
	if not Target or not Target.Parent then
		StopAimbot()
		return
	end

	local Cache = CachedPlayers[Target]
	if not Cache then
		return
	end

	local StopOnCheck = Aimbot.StopOnCheck 

	if Aimbot.TeamCheck and not IsEnemy(Target) then
		if StopOnCheck then
			StopAimbot()
		end
		return
	end

	local Character = Cache.Character
	if Aimbot.DeadCheck and IsDead(Character, Cache) then
		if StopOnCheck then
			StopAimbot()
		end
		return
	end

	local AimPart = Cache[Aimbot.AimPart]
	if not AimPart then
		StopAimbot()
		return
	end

	local AimPartPosition = AimPart.Position

	if Aimbot.WallCheck and not CanHit(AimPartPosition, Character) then
		if StopOnCheck then
			StopAimbot()
		end
		return
	end

	local CameraCFrame = Camera.CFrame
	local CameraPosition = CameraCFrame.Position
	local ShakeOffset = Aimbot.ShakeOffset
	local TargetCFrame = CFrame.lookAt(CameraPosition, AimPartPosition)

	if ShakeOffset > 0 then
		TargetCFrame = CFrame.lookAt(CameraPosition, AimPartPosition + Vector3.new(
			math.random(-100, 100) * 0.01 * ShakeOffset,
			math.random(-100, 100) * 0.01 * ShakeOffset,
			math.random(-100, 100) * 0.01 * ShakeOffset
		))
	end

	if Aimbot.SmoothnessOffset > 0 then
		Camera.CFrame = CameraCFrame:Lerp(TargetCFrame, 1 / Aimbot.SmoothnessOffset)
	else
		Camera.CFrame = TargetCFrame
	end
end

local Click = mouse1press and mouse1release and function()
	mouse1press()
	task.wait()
	mouse1release()
end

task.spawn(function()
	local FOVCircle = SilentAimbot.FOVCircle
	local GetPartData = nil
	if hookmetamethod and getnamecallmethod then
		GetPartData = function()
			local ClosestDistance = (FOVCircle.Enabled and FOVCircle.Radius) or math.huge
			local ClosestPart

			local ForceFieldCheck = SilentAimbot.ForceFieldCheck
			local WallCheck = SilentAimbot.WallCheck
			local TeamCheck = SilentAimbot.TeamCheck
			local IsValidTeamCount = #Teams:GetTeams() > 0

			for Index = 1, #CachedPlayersList do
				local Cache = CachedPlayersList[Index]

				local Character = Cache.Character
				if not Character then
					continue
				end

				if TeamCheck and IsValidTeamCount and Cache.Player.Team == LocalPlayer.Team then
					continue
				end

				local Humanoid = Cache.Humanoid
				if not Humanoid or Humanoid.Health <= 0 then
					continue
				end

				if ForceFieldCheck and Character:FindFirstChildOfClass("ForceField") then
					continue
				end

				local AimPart = SilentAimbot.AimPart
				local AimPartPosition

				if AimPart == "Random" then
					AimPart = math.random(1, 2) == 1 and Cache["Root"] or Cache["Head"]

					if not AimPart then
						continue
					end

					AimPartPosition = AimPart.Position
				else
					AimPart = Cache[AimPart]

					if not AimPart then
						continue
					end

					AimPartPosition = AimPart.Position
				end

				if WallCheck and not CanHit(AimPartPosition, Character) then
					continue
				end

				local Screen, OnScreen = WorldToScreenPoint(AimPartPosition)
				if OnScreen then
					local Distance = (MouseLocation - Screen).Magnitude
					if Distance < ClosestDistance then
						ClosestDistance = Distance
						ClosestPart = AimPart
					end
				end
			end

			return ClosestPart
		end

		local __namecall
		__namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			if not Running or not Camera or self ~= workspace or getnamecallmethod() ~= "FindPartOnRayWithIgnoreList" then
				return __namecall(self, ...)
			end

			local TargetPart = RageBot.Toggled and RageBot.TargetPart
			if TargetPart then
				local Arguments = {...}
				if typeof(Arguments[1]) == "Ray" then
					local Origin = Arguments[1].Origin
					Arguments[1] = Ray.new(Origin, (TargetPart.Position - Origin).Unit * 1000)
					return __namecall(self, unpack(Arguments))
				end
				return __namecall(self, ...)
			end

			if not SilentAimbot.Enabled then
				return __namecall(self, ...)
			end

			local Arguments = {...}
			if typeof(Arguments[1]) == "Ray" then
				local _,PartData = coroutine.resume(coroutine.create(GetPartData))
				if PartData then
					local Origin = Arguments[1].Origin
					Arguments[1] = Ray.new(Origin, (PartData.Position - Origin).Unit * 1000)
					return __namecall(self, unpack(Arguments))
				end
			end

			return __namecall(self, ...)
		end))
	end
end)

ConnectionManager:Connect(GenerateGUID(false), workspace.ChildAdded:Connect(function(Child)
	if Child.ClassName == "Sound" and Child.SoundId == "rbxassetid://550209561" then
		Child.Looped = false
	end
end))

ThreadManager:Start("LocalPlayerCache", function()
    local CurrentCharacter = LocalPlayer.Character

    if not CurrentCharacter or not CurrentCharacter.Parent then
        LocalCharacter = nil
        return
    end

    LocalCharacter = CurrentCharacter

    if not LocalHumanoid or LocalHumanoid.Parent ~= LocalCharacter then
        LocalHumanoid = LocalCharacter:FindFirstChildOfClass("Humanoid")
    end

    if not LocalHead or LocalHead.Parent ~= LocalCharacter then
        LocalHead = LocalCharacter.PrimaryPart
    end

    if not LocalRoot or LocalRoot.Parent ~= LocalCharacter then
		LocalRoot = LocalCharacter:FindFirstChild("HumanoidRootPart")
		if not LocalRoot then
			LocalRoot = LocalCharacter:FindFirstChild("Torso") or LocalCharacter:FindFirstChild("LowerTorso")
		end
    end
end, 0.15)

ConnectionManager:Connect("LocalHighlight", RunService.Heartbeat(function()
	if not LocalCharacter then
		return
	end

	local Highlight = CoreGui:FindFirstChild("ns__LocalHighlight") or Create("Highlight", CoreGui, {Name = "ns__LocalHighlight"})
	if LocalHighlight.Enabled then
		Highlight.FillColor = LocalHighlight.Color
		Highlight.OutlineColor = LocalHighlight.Color
		Highlight.FillTransparency = LocalHighlight.Transparency
		Highlight.OutlineTransparency = LocalHighlight.Transparency
		if Highlight.Adornee ~= LocalCharacter then
			Highlight.Adornee = LocalCharacter
		end
	end
end))

Watermark:SetVisible(true)

local Tabs = Window.ns__Tabs

local AimbotTab = Tabs["AimbotTab"]
local SilentAimbotTab = Tabs["SilentAimbotTab"]

local TriggerBotMain = Tabs["TriggerBotMain"]
local TriggerBotChecks = Tabs["TriggerBotChecks"]

local AntiAimTab = Tabs["AntiAimTab"]
local MovementTab = Tabs["MovementTab"]

local LocalCharacterTab = Tabs["LocalCharacterTab"]

local VisualsTab = Tabs["VisualsTab"]
local LightingTab = Tabs["LightingTab"]

local WeaponsTab = Tabs["WeaponsTab"]
local WeaponsViewTab = Tabs["WeaponsViewTab"]

local RageBotTab = Tabs["RageBotTab"]
local HitConfigurationTab = Tabs["HitConfigurationTab"]

local SettingsTab = Tabs["SettingsTab"]

AimbotTab:AddToggle("AimbotMasterSwitch", {
	Text = "Toggle Aimbot",
	Default = Aimbot.Toggled,
	Callback = function(Value)
		Aimbot.Toggled = Value
		if not Value then
			StopAimbot()
			Toggles["AimbotFOVCircle"]:SetValue(false)
		end
	end
}):AddKeyPicker("AimbotKey", {
	Mode = "Toggle",
	Text = "Aimbot",
	Callback = function()
		if not Aimbot.Toggled then
			return
		end

		Aimbot.Enabled = not Aimbot.Enabled

		if not Aimbot.Enabled then
			StopAimbot()
			return
		end

		if Aimbot.StickyAim then
			GetClosestPlayer()
		end

		ConnectionManager:Connect("Aimbot", RunService.RenderStepped(function(DeltaTime)
			if not Aimbot.StickyAim then
				GetClosestPlayer()
			end
			TargetAimbot(DeltaTime)
		end))
	end
})

local AimbotDependencyBox = AimbotTab:AddDependencyBox()
AimbotDependencyBox:SetupDependencies({{Toggles["AimbotMasterSwitch"], true}})

AimbotDependencyBox:AddDropdown("AimbotAimPart", {
	Text = "Aim Part",
	Values = {"Head", "Root"},
	Default = 2,
	Callback = function(Value)
		Aimbot.AimPart = Value
	end,
})

AimbotDependencyBox:AddToggle("AimbotStickyAim", {
	Text = "Sticky Aim",
	Default = Aimbot.StickyAim,
	Callback = function(Value)
		Aimbot.StickyAim = Value
	end,
})

AimbotDependencyBox:AddToggle("AimbotForceField", {
	Text = "ForceField Check",
	Default = Aimbot.ForceFieldCheck,
	Callback = function(Value)
		Aimbot.ForceFieldCheck = Value
	end,
})

AimbotDependencyBox:AddToggle("AimbotWallCheck", {
	Text = "Wall Check",
	Default = Aimbot.WallCheck,
	Callback = function(Value)
		Aimbot.WallCheck = Value
	end,
})

AimbotDependencyBox:AddToggle("AimbotTeamCheck", {
	Text = "Team Check",
	Default = Aimbot.TeamCheck,
	Callback = function(Value)
		Aimbot.TeamCheck = Value
	end,
})

AimbotDependencyBox:AddToggle("AimbotDeadCheck", {
	Text = "Dead Check",
	Default = Aimbot.DeadCheck,
	Callback = function(Value)
		Aimbot.DeadCheck = Value
	end,
})

AimbotDependencyBox:AddToggle("StopOnCheck", {
	Text = "Stop Aimbot On Check",
	Default = Aimbot.StopOnCheck,
	Callback = function(Value)
		Aimbot.StopOnCheck = Value
	end,
})

AimbotDependencyBox:AddSlider("AimbotShakeOffset", {
	Text = "Shake Offset",
	Default = Aimbot.ShakeOffset,
	Min = 0,
	Max = 5,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		Aimbot.ShakeOffset = Value * 0.1
	end,
})

AimbotDependencyBox:AddSlider("AimbotSmoothnessOffset", {
	Text = "Smoothness Offset",
	Default = Aimbot.SmoothnessOffset,
	Min = 0,
	Max = 15,
	Rounding = 0,
	Compact = false,
	Callback = function(Value)
		Aimbot.SmoothnessOffset = Value
	end,
})

AimbotTab:AddDivider("FOV Circle")
AimbotTab:AddToggle("AimbotFOVCircle", {
	Text = "Enabled",
	Default = Aimbot.FOVCircle.Enabled,
	Callback = function(Value)
		Aimbot.FOVCircle.Enabled = Value
		AimbotFOVCircles.Target.Visible = Value
	end,
}):AddColorPicker("AimbotFOVCircleColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Transparency = 0,
	Callback = function(Value)
		AimbotFOVCircles.Target.Color = Value
		AimbotFOVCircles.Target.Transparency = 1 - Options["AimbotFOVCircleColor"].Transparency
	end,
})

local AimbotFOVDependencyBox = AimbotTab:AddDependencyBox()
AimbotFOVDependencyBox:SetupDependencies({{Toggles["AimbotFOVCircle"], true}})

AimbotFOVDependencyBox:AddToggle("AimbotFOVCircleFilled", {
	Text = "Filled Circle", Default = false,
	Callback = function(Value)
		AimbotFOVCircles.Target.Filled = Value
	end
})

AimbotFOVDependencyBox:AddSlider("AimbotFOVCircleThickness", {
	Text = "Circle Thickness", Default = 1, Min = 1, Max = 10, Rounding = 0, Compact = false,
	Callback = function(Value)
		AimbotFOVCircles.Target.Thickness = Value
	end
})

AimbotFOVDependencyBox:AddSlider("AimbotFOVCircleRadius", {
	Text = "Circle Radius", Default = 50, Min = 1, Max = 1000, Rounding = 0, Compact = false,
	Callback = function(Value)
		Aimbot.FOVCircle.Radius = Value
		AimbotFOVCircles.Target.Radius = Value
	end
})

AimbotFOVDependencyBox:AddDropdown("AimbotFOVCirclePosition", {
	Text = "Circle Position", Values = {"Center", "Mouse"}, Default = 1,
	Callback = function(Value)
		Aimbot.FOVCircle.Position = Value
	end,
})

if hookmetamethod and getnamecallmethod then
	local SilentAimbotLabel = SilentAimbotTab:AddLabel("Silent Aimbot: Disabled")
	SilentAimbotTab:AddToggle("SilentAimbotMasterSwitch", {
		Text = "Toggle Aimbot",
		Default = false,
		Callback = function(Value)
			SilentAimbot.Toggled = Value
			if not Value then
				SilentAimbotLabel:SetText("Silent Aimbot: Disabled")
				SilentAimbot.Enabled = false
				Toggles["SilentAimbotFOVCircle"]:SetValue(false)
			end
		end
	}):AddKeyPicker("SilentAimbotKey", {
		Mode = "Toggle",
		Text = "Silent Aimbot",
		Callback = function()
			if not SilentAimbot.Toggled then
				return
			end
			SilentAimbot.Enabled = not SilentAimbot.Enabled
			if SilentAimbot.Enabled then
				SilentAimbotLabel:SetText("Silent Aimbot: Enabled")
			else
				SilentAimbotLabel:SetText("Silent Aimbot: Disabled")
			end
		end
	})

	local SilentAimbotDependencyBox = SilentAimbotTab:AddDependencyBox()
	SilentAimbotDependencyBox:SetupDependencies({{Toggles["SilentAimbotMasterSwitch"], true}})

	SilentAimbotDependencyBox:AddDropdown("SilentAimbotAimPart", {
		Text = "Aim Part",
		Values = {"Head", "Root", "Random"},
		Default = 2,
		Callback = function(Value)
			SilentAimbot.AimPart = Value
		end
	})

	SilentAimbotDependencyBox:AddToggle("SilentAimbotForceFieldCheck", {
		Text = "ForceField Check",
		Default = false,
		Callback = function(Value)
			SilentAimbot.ForceFieldCheck = Value
		end
	})

	SilentAimbotDependencyBox:AddToggle("SilentAimbotWallCheck", {
		Text = "Wall Check",
		Default = false,
		Callback = function(Value)
			SilentAimbot.WallCheck = Value
		end
	})

	SilentAimbotDependencyBox:AddToggle("SilentAimbotTeamCheck", {
		Text = "Team Check",
		Default = false,
		Callback = function(Value)
			SilentAimbot.TeamCheck = Value
		end
	})

	SilentAimbotTab:AddDivider("FOV Circle")

	SilentAimbotTab:AddToggle("SilentAimbotFOVCircle", {
		Text = "Enabled",
		Default = SilentAimbot.FOVCircle.Enabled,
		Callback = function(Value)
			SilentAimbot.FOVCircle.Enabled = Value
			AimbotFOVCircles.Silent.Visible = Value
		end
	}):AddColorPicker("SilentAimbotFOVCircleColor", {
		Default = Color3.fromRGB(255, 255, 255),
		Transparency = 0,
		Callback = function(Value)
			AimbotFOVCircles.Silent.Color = Value
			AimbotFOVCircles.Silent.Transparency = 1 - Options["SilentAimbotFOVCircleColor"].Transparency
		end
	})

	local SilentAimbotFOVCircleDependencyBox = SilentAimbotTab:AddDependencyBox()
	SilentAimbotFOVCircleDependencyBox:SetupDependencies({{Toggles["SilentAimbotFOVCircle"], true}})

	SilentAimbotFOVCircleDependencyBox:AddToggle("SilentAimbotFOVCircleFilled", {
		Text = "Filled Circle",
		Default = false,
		Callback = function(Value)
			AimbotFOVCircles.Silent.Filled = Value
		end
	})

	SilentAimbotFOVCircleDependencyBox:AddSlider("SilentAimbotFOVCircleRadius", {
		Text = "Circle Radius",
		Default = 50,
		Min = 1,
		Max = 500,
		Rounding = 0,
		Compact = false,
		Callback = function(Value)
			SilentAimbot.FOVCircle.Radius = Value
			AimbotFOVCircles.Silent.Radius = Value
		end
	})

	SilentAimbotFOVCircleDependencyBox:AddSlider("SilentAimbotFOVCircleThickness", {
		Text = "Circle Thickness",
		Default = 1,
		Min = 1,
		Max = 10,
		Rounding = 0,
		Compact = false,
		Callback = function(Value)
			AimbotFOVCircles.Silent.Thickness = Value
		end
	})

	SilentAimbotFOVCircleDependencyBox:AddDropdown("SilentAimbotFOVCirclePosition", {
		Text = "Circle Position",
		Values = {"Center", "Mouse"},
		Default = 2,
		Callback = function(Value)
			SilentAimbot.FOVCircle.Position = Value
		end
	})
else
	SilentAimbotTab:AddLabel("Silent Aimbot not supported. Missing required function(s):", true)

	if not hookmetamethod then
		SilentAimbotTab:AddLabel("'hookmetamethod'", true)
	end

	if not getnamecallmethod then
		SilentAimbotTab:AddLabel(", 'getnamecallmethod'", true)
	end
end

if getsenv and GetGunState then
	RageBotTab:AddLabel("Spamming Weapon with WallCheck OFF may cause rate limiting.", true)
	RageBotTab:AddToggle("RageBot", {
		Text = "Enable RageBot",
		Default = false,
		Callback = function(Value)
			RageBot.Toggled = Value
			if Value then
				for _,Toggle in next, RageBot.Weapon == "Knife" and {Toggles["ForceThrow"], Toggles["RapidThrow"]} or {--[[Toggles["InfiniteAmmo"]]} do
					Toggle:SetValue(false)
					Toggle:SetDisabled(true)
				end
			else
				for _,Toggle in next, {--[[Toggles["InfiniteAmmo"], ]]Toggles["ForceThrow"], Toggles["RapidThrow"]} do
					Toggle:SetDisabled(false)
				end
			end

			if not Value then
				ConnectionManager:Disconnect("RageBot")
				DisconnectHealthListeners()
				if LocalHumanoid then
					LocalHumanoid:UnequipTools()
				end
				return
			end

			ConnectionManager:Connect("RageBot", RunService.Heartbeat(function()
				if not RageBot.Toggled or not LocalRoot or not LocalHead then
					return
				end

				if not RageBot.IsAttacking then
					table.clear(RageBotTargets)
					local ClosestDistance = math.huge

					RageBot.TargetPart = nil
					RageBot.TargetCache = nil

					for Index = 1, #CachedPlayersList do
						local Cache = CachedPlayersList[Index]
						local Character = Cache.Character
						if not Character then
							continue
						end

						local AimPart = Cache[RageBot.AimPart]
						if not AimPart then
							continue
						end

						if RageBot.TeamCheck and LocalPlayer.Team == Cache.Player.Team then
							continue
						end

						if RageBot.ForceFieldCheck and Character:FindFirstChildOfClass("ForceField") then
							continue
						end

						local Humanoid = Cache.Humanoid
						if not Humanoid or Humanoid.Health <= 0 then
							continue
						end

						local AimPartPosition = AimPart.Position
						local Distance = (LocalRoot.Position - AimPartPosition).Magnitude

						if Distance > RageBot.MaxDistance then
							continue
						end

						if RageBot.WallCheck and not CanHit(AimPartPosition, Character) then
							continue
						end

						if RageBot.MultiTarget then
							RageBotTargets[#RageBotTargets + 1] = Cache
						else
							if Distance < ClosestDistance then
								ClosestDistance = Distance
								RageBot.TargetCache = Cache
								RageBot.TargetPart = AimPart
							end
						end
					end
				end

				HandleHitConfiguration()

				if RageBot.IsAttacking then
					return
				end

				local Tool = LocalCharacter:FindFirstChildOfClass("Tool")
				if Tool then
					--if RageBot.Weapon == "Knife" then
					if not (RageBot.MultiTarget and #RageBotTargets > 0 or RageBot.TargetPart) then
						return
					end

					local KnifeServer = Tool:FindFirstChild("KnifeServer")
					if not KnifeServer then
						return
					end

					if tick() - RageBot.LastAttackTime >= 0.165 then
						RageBot.LastAttackTime = tick()

						task.spawn(function()
							RageBot.IsAttacking = true
							HandleHitConfiguration()
							local KnifeClient = KnifeServer:FindFirstChild("KnifeClient")

							if KnifeClient then
								local ScriptEnvironment = getsenv(KnifeClient)
								if ScriptEnvironment then
									local Settings = ScriptEnvironment.ClientKnifeSettings
									if Settings then
										Settings.CanThrow = true
										Settings.EquipTime = 0
										Settings.SlashEquipDelay = 0
										Settings.GrabTime = 0
										Settings.ChargeTime = 1
										Settings.EffectiveChargeTime = 1
										Settings.StabTime = -10
										Settings.EffectiveStabTime = -10
										Settings.MinimumChargeTime = -999
										Settings.SlashTime = 0
										Settings.SlashCoolDownFactor = 0

										if RageBot.MultiTarget then
											for Index = 1, #RageBotTargets do
												local Cache = RageBotTargets[Index]
												local Character = Cache.Character

												if Character then
													local AimPart = Cache[RageBot.AimPart]
													if AimPart then
														local Health = Cache.Humanoid
														Health = Health and Health.Health
														if Health and Health > 0 then
															if (RageBot.WallCheck and CanHit(AimPart.Position, Character)) or true then
																RageBot.TargetCache = Cache
																RageBot.TargetPart = AimPart

																RegisterPendingHit(Cache, Cache.Player, Health)
																ScriptEnvironment.inputDown()
																task.wait()
																ScriptEnvironment.inputReleased()

																RunService.HeartbeatWait()
															end
														end
													end
												end
											end
										else
											local Cache = RageBot.TargetCache
											if Cache then
												local Character = Cache.Character
												if Character then
													local Health = Cache.Humanoid
													Health = Health and Health.Health
													if Health and Health > 0 and ((RageBot.WallCheck and CanHit(
														RageBot.TargetPart.Position, Character
													)) or true) then
														RegisterPendingHit(Cache, Cache.Player, Health)
														ScriptEnvironment.inputDown()
														task.wait()
														ScriptEnvironment.inputReleased()
													end
												end
											end
										end
									end
								end
							end

							RageBot.IsAttacking = false
						end)
					end
					--[[else
						if not (RageBot.MultiTarget and #RageBotTargets > 0 or RageBot.TargetPart) then
							return
						end

						local RevolverServer = Tool:FindFirstChild("RevolverServer")
						if not RevolverServer then
							return
						end

						local MultiTarget = RageBot.MultiTarget
						if tick() - RageBot.LastAttackTime >= (MultiTarget and 0.455 or 0.395) then
							RageBot.LastAttackTime = tick()

							task.spawn(function()
								RageBot.IsAttacking = true
								HandleHitConfiguration()
								local RevolverClient = RevolverServer:FindFirstChild("RevolverClient")
								if RevolverClient then
									local ScriptEnvironment = getsenv(RevolverClient)
									if ScriptEnvironment then
										local Settings = ScriptEnvironment.ClientWeaponSettings
										if Settings then
											Settings.FireDelay = 0
											Settings.EquipTime = 0
											Settings.ReloadTime = 0
											Settings.doFireKickback = false

											local InfiniteAmmoDisabled = ThreadManager:Exists("InfiniteAmmo")
											local LoadCapacity = InfiniteAmmoDisabled and Settings.LoadCapacity
											local GunState = InfiniteAmmoDisabled and GetGunState(ScriptEnvironment.ON_TOOL_EQUIP)

											if MultiTarget then
												for Index = 1, #RageBotTargets do
													local Cache = RageBotTargets[Index]
													local Character = Cache.Character

													if Character then
														local AimPart = Cache[RageBot.AimPart]
														if AimPart then
															local Health = Cache.Humanoid
															Health = Health and Health.Health
															if Health and Health > 0 and CanHit(AimPart.Position, Character) then
																RageBot.TargetCache = Cache
																RageBot.TargetPart = AimPart

																RegisterPendingHit(Cache, Cache.Player, Health)
																ScriptEnvironment.FireWeapon(RageBotArguments)

																if GunState then
																	local CurrentAmmo = rawget(GunState, "LoadedAmmo")
																	if CurrentAmmo <= 0 then
																		ScriptEnvironment.ReloadUpdate(1)
																		rawset(GunState, "LoadedAmmo", LoadCapacity - 1)
																		CurrentAmmo = LoadCapacity
																	end
																end

																RunService.HeartbeatWait()
															end
														end
													end
												end
											else
												local Cache = RageBot.TargetCache
												if Cache then
													local Character = Cache.Character
													if Character then
														local Health = Cache.Humanoid
														Health = Health and Health.Health
														if Health and Health > 0 and CanHit(
															RageBot.TargetPart.Position, Character
														) then
															RegisterPendingHit(Cache, Cache.Player, Health)
															ScriptEnvironment.FireWeapon(RageBotArguments)

															if GunState then
																local CurrentAmmo = rawget(GunState, "LoadedAmmo")
																rawset(GunState, "LoadedAmmo", CurrentAmmo - 1)
																if CurrentAmmo <= 0 then
																	ScriptEnvironment.ReloadUpdate(1)
																	rawset(GunState, "LoadedAmmo", LoadCapacity)
																	CurrentAmmo = LoadCapacity
																end
															end
														end
													end
												end
											end
										end
									end
								end

								RageBot.IsAttacking = false
							end)
						end
					end]]
				end
			end))
		end
	})

	local RageBotDependencyBox = RageBotTab:AddDependencyBox()
	RageBotDependencyBox:SetupDependencies({{Toggles["RageBot"], true}})

	--[[RageBotDependencyBox:AddDropdown("RageBotWeapon", {
		Text = "RageBot Weapon",
		Values = {"Knife", "Revolver [BETA]"},
		Default = 1,
		Callback = function(Value)
			if Value == "Knife" then
				for Index, Toggle in next, {Toggles["ForceThrow"], Toggles["RapidThrow"]} do
					Toggle:SetValue(false)
					Toggle:SetDisabled(true)
				end
				Toggles["InfiniteAmmo"]:SetDisabled(false)
			else
				Toggles["InfiniteAmmo"]:SetValue(false)
				Toggles["InfiniteAmmo"]:SetDisabled(true)
				Toggles["ForceThrow"]:SetDisabled(false)
				Toggles["RapidThrow"]:SetDisabled(false)
			end

			if Toggles["RageBotMultiTarget"] then
				if Value ~= "Knife" then
					Toggles["RageBotMultiTarget"]:SetValue(false)
					Toggles["RageBotMultiTarget"]:SetDisabled(true)
				else
					Toggles["RageBotMultiTarget"]:SetDisabled(false)
				end
			end

			RageBot.Weapon = Value:gsub(" %[BETA%]", "")
			RageBot.TargetPart = nil
			RageBot.LastAttackTime = 0
			RageBot.IsAttacking = false
		end
	})]]

	RageBotDependencyBox:AddToggle("RageBotMultiTarget", {
		Text = "Multi-Target Mode",
		Default = RageBot.MultiTarget,
		Callback = function(Value)
			RageBot.MultiTarget = Value
		end
	})

	RageBotDependencyBox:AddDropdown("RageBotAimPart", {
		Text = "Aim Part",
		Values = {"Head", "Root"},
		Default = 1,
		Callback = function(Value)
			RageBot.AimPart = Value
		end
	})
	RageBotDependencyBox:AddToggle("RageBotForceFieldCheck", {
		Text = "ForceField Check",
		Default = RageBot.ForceFieldCheck,
		Callback = function(Value)
			RageBot.ForceFieldCheck = Value
		end
	})
	RageBotDependencyBox:AddToggle("RageBotWallCheck", {
		Text = "Wall Check",
		Default = RageBot.WallCheck,
		Callback = function(Value)
			RageBot.WallCheck = Value
		end
	})
	RageBotDependencyBox:AddToggle("RageBotTeamCheck", {
		Text = "Team Check",
		Default = RageBot.TeamCheck,
		Callback = function(Value)
			RageBot.TeamCheck = Value
		end
	})
	RageBotDependencyBox:AddSlider("RageBotMaxDistance", {
		Text = "Max Distance (Studs)",
		Default = 2500,
		Min = 0,
		Max = 2500,
		Rounding = 0,
		Compact = false,
		Callback = function(Value)
			RageBot.MaxDistance = Value
		end
	})
else
	RageBotTab:AddLabel("RageBot not supported. Missing required 'getsenv' function", true)
end

HitConfigurationTab:AddToggle("AimbotHitMasterSwitch", {
	Text = "Master Switch",
	Default = HitConfiguration.Toggled,
	Callback = function(Value)
		HitConfiguration.Toggled = Value
		if not Value then
			DisconnectHealthListeners()
		end
	end
})
local HitConfigurationDependencyBox = HitConfigurationTab:AddDependencyBox()
HitConfigurationDependencyBox:SetupDependencies({{Toggles["AimbotHitMasterSwitch"], true}})
HitConfigurationDependencyBox:AddDivider("Hit Markers")
HitConfigurationDependencyBox:AddToggle("AimbotHitMarkers", {
	Text = "Enabled",
	Default = HitConfiguration.Marker.Enabled,
	Callback = function(Value)
		HitConfiguration.Marker.Enabled = Value
	end
}):AddColorPicker("AimbotHitMarkerColor", {
	Default = HitConfiguration.Marker.Color,
	Transparency = nil,
	Callback = function(Color)
		HitConfiguration.Marker.Color = Color
	end
})
HitConfigurationDependencyBox:AddSlider("AimbotHitMarkerScale", {
	Text = "Size Scale",
	Default = HitConfiguration.Marker.Scale,
	Min = 1,
	Max = 3,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		HitConfiguration.Marker.Scale = Value
	end
})
HitConfigurationDependencyBox:AddSlider("AimbotHitMarkerLifetime", {
	Text = "Lifetime",
	Default = HitConfiguration.Marker.Lifetime,
	Min = 1,
	Max = 5,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		HitConfiguration.Marker.Lifetime = Value
	end
})
HitConfigurationDependencyBox:AddDropdown("AimbotHitMarkerStyle", {
	Text = "Marker Style",
	Values = {"Classic X", "Broken X", "Circle", "Plus"},
	Default = 2,
	Callback = function(Value)
		HitConfiguration.Marker.Style = Value
		Toggles["AimbotHitMarkerCenterDot"]:SetDisabled(Value == "Classic X" or Value == "Plus")
	end
})
HitConfigurationDependencyBox:AddToggle("AimbotHitMarkerCenterDot", {
	Text = "Center Dot",
	Disabled = true,
	Default = HitConfiguration.Marker.CenterDot,
	Callback = function(Value)
		HitConfiguration.Marker.CenterDot = Value
	end
})
HitConfigurationDependencyBox:AddToggle("AimbotHitMarkerFadeInAnimation", {
	Text = "Fade In Animation",
	Default = HitConfiguration.Marker.FadeIn,
	Callback = function(Value)
		HitConfiguration.Marker.FadeIn = Value
	end
})
HitConfigurationDependencyBox:AddToggle("AimbotHitMarkerFadeOutAnimation", {
	Text = "Fade Out Animation",
	Default = HitConfiguration.Marker.FadeOut,
	Callback = function(Value)
		HitConfiguration.Marker.FadeOut = Value
	end
})

HitConfigurationDependencyBox:AddDivider("Hit Logs")
HitConfigurationDependencyBox:AddToggle("AimbotHitLog", {
	Text = "Enabled",
	Default = HitConfiguration.Log.Enabled,
	Callback = function(Value)
		HitConfiguration.Log.Enabled = Value
	end
})
HitConfigurationDependencyBox:AddToggle("AimbotHitLogUseColor", {
	Text = "Use Color",
	Default = HitConfiguration.Log.UseColor,
	Callback = function(Value)
		HitConfiguration.Log.UseColor = Value
	end
}):AddColorPicker("AimbotHitLogColor", {
	Default = HitConfiguration.Log.Color,
	Transparency = nil,
	Callback = function(Color)
		HitConfiguration.Log.Color = Color
	end
})
HitConfigurationDependencyBox:AddSlider("AimbotHitLogDuration", {
	Text = "Duration",
	Default = HitConfiguration.Log.Duration,
	Min = 1,
	Max = 2.5,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		HitConfiguration.Log.Duration = Value
	end
})
HitConfigurationDependencyBox:AddDivider("Hit Sounds")
HitConfigurationDependencyBox:AddToggle("AimbotHitSound", {
	Text = "Enabled",
	Default = HitConfiguration.Sound.Enabled,
	Callback = function(Value)
		HitConfiguration.Sound.Enabled = Value
	end
})
HitConfigurationDependencyBox:AddSlider("AimbotHitSoundVolume", {
	Text = "Volume",
	Default = HitConfiguration.Sound.Volume,
	Min = 1,
	Max = 10,
	Rounding = 0,
	Compact = false,
	Callback = function(Volume)
		HitConfiguration.Sound.Volume = Volume
	end
})
HitConfigurationDependencyBox:AddDropdown("AimbotHitSounds", {
	Text = "Sound",
	Values = {
		"Osu", "Pop", "MLG", "Metal",
		"Neverlose", "Jet Set Radio",
		"TF2 Critical", "TF2 Alternative",
		"TF2 Frying Pan", "Bad Business Headshot",
	},
	Default = 1,
	Callback = function(Sound)
		HitConfiguration.Sound.Selected = Sound
		PlayHitSound(Sound, HitConfiguration.Sound.Volume)
	end
})

if Click then
	local TriggerBotLabel = TriggerBotMain:AddLabel("TriggerBot: Disabled")
	TriggerBotMain:AddToggle("TriggerBot", {
		Text = "Toggle TriggerBot",
		Default = TriggerBot.Toggled,
		Callback = function(Value)
			TriggerBotLabel:SetText("TriggerBot: Disabled")
			TriggerBot.Toggled = Value
			if not Value and TriggerBot.Enabled then
				ConnectionManager:Disconnect("TriggerBot")
			end
		end
	}):AddKeyPicker("TriggerBotKey", {
		Mode = "Toggle",
		Text = "TriggerBot",
		Callback = function()
			if not TriggerBot.Toggled then
				return
			end
			TriggerBot.Enabled = not TriggerBot.Enabled
			if TriggerBot.Enabled then
				ConnectionManager:Connect("TriggerBot", RunService.RenderStepped(function()
					if not Camera or not LocalCharacter or not LocalHumanoid or not LocalRoot then
						return
					end

					local Target = Mouse.Target
					if not Target then
						return
					end

					local ModelInstance = Target:FindFirstAncestorOfClass("Model")
					if not ModelInstance then
						return
					end

					local Player = Players:GetPlayerFromCharacter(ModelInstance)
					if not Player or Player == LocalPlayer then
						return
					end

					local Cache = CachedPlayers[Player]
					if not Cache then
						return
					end

					if TriggerBot.TeamCheck and not IsEnemy(Player) then
						return
					end

					if TriggerBot.DeadCheck then
						if not Cache.Character then
							return
						end
						local Humanoid = Cache.Humanoid
						if not Humanoid or Humanoid.Health <= 0 then
							return
						end
					end

					if TriggerBot.ForceFieldCheck and ModelInstance:FindFirstChildOfClass("ForceField") then
						return
					end

					local RootPart = Cache.Root or ModelInstance.PrimaryPart
					if RootPart and (LocalRoot.Position - RootPart.Position).Magnitude > TriggerBot.MaxDistance then
						return
					end

					if TriggerBot.WallCheck and not CanHit(Target.Position, ModelInstance) then
						return
					end

					if TriggerBot.RevolverOnly then
						local Tool = LocalCharacter:FindFirstChildOfClass("Tool")
						if not Tool or Tool.Name ~= "Revolver" then
							return
						end
					end

					if UI.IsRobloxFocused then
						local SettingsShield = GetSettingsShield()
						if not SettingsShield or not SettingsShield.Visible then
							Click()
							task.wait(TriggerBot.TriggerDelay)
						end
					end
				end))
				TriggerBotLabel:SetText("TriggerBot: Enabled")
			else
				ConnectionManager:Disconnect("TriggerBot")
				TriggerBotLabel:SetText("TriggerBot: Disabled")
			end
		end
	})

	local TriggerBotDependencyBox = TriggerBotMain:AddDependencyBox()
	TriggerBotDependencyBox:SetupDependencies({{Toggles["TriggerBot"], true}})
	TriggerBotDependencyBox:AddSlider("TriggerBotTriggerDelay", {
		Text = "Trigger Delay",
		Default = 0.1,
		Min = 0.1,
		Max = 10,
		Rounding = 1,
		Compact = false,
		Callback = function(Value)
			TriggerBot.TriggerDelay = Value * 0.1
		end
	})
	TriggerBotDependencyBox:AddToggle("TriggerBotRevolverOnly", {
		Text = "Revolver Only",
		Default = TriggerBot.RevolverOnly,
		Callback = function(Value)
			TriggerBot.RevolverOnly = Value
		end
	})

	TriggerBotChecks:AddToggle("TriggerBotForceField", {
		Text = "ForceField Check",
		Default = TriggerBot.ForceFieldCheck,
		Callback = function(Value)
			TriggerBot.ForceFieldCheck = Value
		end
	})
	TriggerBotChecks:AddToggle("TriggerBotTeamCheck", {
		Text = "Team Check",
		Default = TriggerBot.TeamCheck,
		Callback = function(Value)
			TriggerBot.TeamCheck = Value
		end
	})
	TriggerBotChecks:AddToggle("TriggerBotDeadCheck", {
		Text = "Dead Check",
		Default = TriggerBot.DeadCheck,
		Callback = function(Value)
			TriggerBot.DeadCheck = Value
		end
	})
	TriggerBotChecks:AddToggle("TriggerBotWallCheck", {
		Text = "Wall Check",
		Default = TriggerBot.WallCheck,
		Callback = function(Value)
			TriggerBot.WallCheck = Value
		end
	})
else
	TriggerBotMain:AddLabel("TriggerBot is not supported, missing functions 'mouse1press' & 'mouse1release'", true)
end
MovementTab:AddToggle("InfiniteJump", {
	Text = "Infinite Jump [UNSAFE]",
	Default = false,
	Risky = true,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("InfiniteJump")
			return
		end

		ConnectionManager:Connect("InfiniteJump", UserInputService.JumpRequest:Connect(function()
			if not LocalHumanoid or LocalHumanoid:GetState() ~= EnumFreefallState then
				return
			end
			LocalHumanoid:ChangeState(EnumJumpingState)
		end))
	end
})

MovementTab:AddToggle("Speed", {
	Text = "Fast Walk",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("Speed")
			return
		end

		ConnectionManager:Connect("Speed", RunService.Heartbeat(function()
			if not LocalHumanoid or not LocalRoot then
				return
			end

			local MoveDirection = LocalHumanoid.MoveDirection
			if MoveDirection.Magnitude > 0 then
				LocalRoot.CFrame += MoveDirection * 0.039
			end
		end))
	end
})


MovementTab:AddToggle("NoclipMovement", {
	Text = "Noclip",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("Noclip")
			for _,Descendant in LocalCharacter:QueryDescendants("BasePart") do
				Descendant.CanCollide = true
			end
			return
		end

		ConnectionManager:Connect("Noclip", RunService.Stepped(function()
			if not LocalCharacter then
				return
			end

			for _,Descendant in LocalCharacter:QueryDescendants("BasePart") do
				Descendant.CanCollide = false
			end
		end))
	end
})
MovementTab:AddToggle("JumpMultiplier", {
	Text = "Jump Muliplier",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("JumpMultiplier")
			if LocalHumanoid then
				LocalHumanoid.JumpPower = 50
				LocalHumanoid.JumpHeight = 7.2
			end
			return
		end

		local Slider = Options["JumpMultiplierSlider"]
		ConnectionManager:Connect("JumpMultiplier", RunService.Heartbeat(function()
			if not LocalHumanoid then
				return
			end

			local JumpMultiplier = Slider["Value"]
			if LocalHumanoid.UseJumpPower then
				LocalHumanoid.JumpPower = 50 * JumpMultiplier
			else
				LocalHumanoid.JumpHeight = 7.2 * JumpMultiplier
			end
		end))
	end
})
MovementTab:AddSlider("JumpMultiplierSlider", {
	Text = "Jump Multiplier",
	Default = 1.35,
	Min = 1,
	Max = 2.5,
	Rounding = 2,
	Compact = false
})

AntiAimTab:AddLabel("CFrame & SpinBot doesn't work in First Person View or Shiftlock.", true)
local AntiAimStatusLabel = AntiAimTab:AddLabel("Status: Disabled")
AntiAimTab:AddToggle("AntiAimToggle", {
	Text = "Toggle AntiAim",
	Default = AntiAim.Toggled,
	Callback = function(Value)
		AntiAim.Toggled = Value
		if not Value and AntiAim.Enabled then
			AntiAim.Enabled = false
			ConnectionManager:Disconnect("AntiAim")
			AntiAimStatusLabel:SetText("Status: Disabled")
		end
	end
}):AddKeyPicker("VelocityKey", {
	Mode = "Toggle",
	Text = "Enable AntiAim",
	Callback = function(Value)
		if not AntiAim.Toggled then
			return
		end

		AntiAim.Enabled = Value

		if not Value then
			ConnectionManager:Disconnect("AntiAim")
			AntiAimStatusLabel:SetText("Status: Disabled")
			return
		end

		ConnectionManager:Connect("AntiAim", RunService.Heartbeat(function()
			if not Camera or not LocalRoot or not AntiAim.Enabled then
				return
			end

			local AntiAimMode = AntiAim.Mode

			if AntiAimMode == "None" then
				return
			end

			local LookVector = Camera.CFrame.LookVector
			local RootPosition = LocalRoot.Position
			if AntiAimMode == "Randomizer" then
				local RNG = math.random(1, 3)
				local Offset = RNG == 1 and Vector3.new(
					-LookVector.X, 0, -LookVector.Z
				).Unit or (RNG == 2 and Vector3.new(
					-LookVector.Z, 0, LookVector.X
				) or Vector3.new(LookVector.Z, 0, -LookVector.X))
				LocalRoot.CFrame = CFrame.new(RootPosition, RootPosition + Offset)
			elseif AntiAimMode == "Backwards" then
				LocalRoot.CFrame = CFrame.new(RootPosition, RootPosition + Vector3.new(-LookVector.X, 0, -LookVector.Z).Unit)
			elseif AntiAimMode == "Left" then
				LocalRoot.CFrame = CFrame.new(RootPosition, RootPosition + Vector3.new(-LookVector.Z, 0, LookVector.X))
			elseif AntiAimMode == "Right" then
				LocalRoot.CFrame = CFrame.new(RootPosition, RootPosition + Vector3.new(LookVector.Z, 0, -LookVector.X))
			elseif AntiAimMode == "Jitter" then
				local Angle = math.rad(math.random(-90, 90))
				local Cosine, Sine = math.cos(Angle), math.sin(Angle)
				local LookVectorX = LookVector.X
				local LookVectorZ = LookVector.Z
				LocalRoot.CFrame = CFrame.new(RootPosition, RootPosition + Vector3.new(
					LookVectorX * Cosine - LookVectorZ * Sine, 0, LookVectorX * Sine + LookVectorZ * Cosine
				))
			elseif AntiAimMode == "Reverse Jitter" then
				local Angle = math.rad(math.random(-45, 45))
				local Cosine, Sine = math.cos(Angle), math.sin(Angle)
				local ReversedLookVector = Vector3.new(-LookVector.X, 0, -LookVector.Z)
				local ReversedLookVectorX = ReversedLookVector.X
				local ReversedLookVectorZ = ReversedLookVector.Z
				LocalRoot.CFrame = CFrame.new(RootPosition, RootPosition + Vector3.new(
					ReversedLookVectorX * Cosine - ReversedLookVectorZ * Sine, 0, ReversedLookVectorX * Sine + ReversedLookVectorZ * Cosine
				))
			else
				local OldCFrame = LocalRoot.CFrame
				local OldPosition = OldCFrame.Position
				LocalRoot.CFrame = CFrame.new(Vector3.new(OldPosition.X, -999, OldPosition.Z), Vector3.new(0, -99999, 0))
				RunService.RenderSteppedWait()
				LocalRoot.CFrame = OldCFrame
			end
		end))

		AntiAimStatusLabel:SetText("Status: Enabled")
	end
})
AntiAimTab:AddDropdown("CFrameMode", {
	Text = "CFrame Mode",
	Values = {"None", "Randomizer", "Backwards", "Left", "Right", "Jitter", "Reverse Jitter"},
	Default = 1,
	Callback = function(Mode)
		AntiAim.Mode = Mode
	end
})
AntiAimTab:AddToggle("SpinBot", {
	Text = "SpinBot",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("SpinBot")
			return
		end
		ConnectionManager:Connect("SpinBot", RunService.Stepped(function()
			if LocalRoot then
				LocalRoot.CFrame *= CFrame.Angles(0, math.rad(AntiAim.SpinBot), 0)
			end
		end))
	end
})
AntiAimTab:AddSlider("SpinBotAmount", {
	Text = "SpinBot Speed",
	Default = AntiAim.SpinBot,
	Min = 0,
	Max = 250,
	Rounding = 0,
	Compact = false,
	Callback = function(Speed)
		AntiAim.SpinBot = Speed
	end
})

LocalCharacterTab:AddToggle("LocalHighlight", {
	Text = "Highlight",
	Default = false,
	Callback = function(Value)
		LocalHighlight.Enabled = Value
		if not Value then
			local Highlight = CoreGui:FindFirstChild("ns__LocalHighlight")
			if Highlight then
				Highlight.Adornee = nil
			end
		end
	end
}):AddColorPicker("HighlightColor", {
	Default = LocalHighlight.Color,
	Transparency = LocalHighlight.Transparency,
	Callback = function(Color)
		LocalHighlight.Color = Color
		LocalHighlight.Transparency = Options["HighlightColor"].Transparency
	end
})
LocalCharacterTab:AddToggle("ChinaHat", {
    Text = "China Hat",
    Default = false,
    Callback = function(Value)
        if not Value then
            ConnectionManager:Disconnect("ChinaHat")

            if ChinaHat.ChinaHatTrail then
                ChinaHat.ChinaHatTrail:Destroy()
                ChinaHat.ChinaHatTrail = nil
            end
            return
        end

        ConnectionManager:Connect("ChinaHat", RunService.Heartbeat(function()
            if not LocalHead then
				return
			end

            local CurrentHat = ChinaHat.ChinaHatTrail

            if not CurrentHat or not CurrentHat.Parent then
                CurrentHat = Create("Part", Camera, {
					Name = "ChinaHat",
					Material = Enum.Material.Neon,
					CanCollide = false,
					CanQuery = false,
					CanTouch = false,
					Transparency = 0.3
				})

                Create("SpecialMesh", CurrentHat, {
					MeshType = Enum.MeshType.FileMesh,
					MeshId = "http://www.roblox.com/asset/?id=1778999",
					Scale = ChinaHat["Scale"]
				})

                ChinaHat.ChinaHatTrail = CurrentHat
            end

            CurrentHat.CFrame = LocalHead.CFrame * ChinaHatCFrameOffset
            CurrentHat.Color = ChinaHat["Color"]
            CurrentHat.Size = ChinaHat.ChinaHatTrailSize
            CurrentHat.Velocity = Vector3.zero
        end))
    end
}):AddColorPicker("ChinaHatColor", {
	Default = ChinaHat["Color"],
	Transparency = nil,
	Callback = function(Color)
		ChinaHat["Color"] = Color
	end
})

LocalCharacterTab:AddToggle("AnimationFreezer", {
	Text = "Freeze Animations",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("AnimationFreezer")
			local AnimateInstance = LocalCharacter and LocalCharacter:FindFirstChild("Animate")
			if AnimateInstance then
				AnimateInstance.Disabled = false
			end
			return
		end

		ConnectionManager:Connect("AnimationFreezer", RunService.Heartbeat(function()
			local AnimateInstance = LocalCharacter and LocalCharacter:FindFirstChild("Animate")
			if AnimateInstance then
				AnimateInstance.Enabled = false
			end
		end))
	end
})

LocalCharacterTab:AddToggle("LocalTransparencyModification", {
	Text = "LocalTransparency Modification",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("LocalTransparencyModification")
			if LocalCharacter then
				for _,Child in LocalCharacter:GetChildren() do
					if Child:IsA("BasePart") then
						Child.LocalTransparencyModifier = 0
					end
				end
			end
			return
		end

		ConnectionManager:Connect("LocalTransparencyModification", RunService.Heartbeat(function()
			if not LocalCharacter then
				return
			end

			local LocalTransparencyModifier = Options["LocalTransparencyModificationSlider"].Value
			for _,Child in LocalCharacter:GetChildren() do
				if Child:IsA("BasePart") then
					Child.LocalTransparencyModifier = LocalTransparencyModifier
				end
			end
		end))
	end
})
LocalCharacterTab:AddSlider("LocalTransparencyModificationSlider", {
	Text = "Transparency amount",
	Default = 0.5,
	Min = 0,
	Max = 1,
	Rounding = 1,
	Compact = false
})

VisualsTab:AddToggle("ESPMasterSwitch", {
	Text = "Master Switch",
	Default = HitConfiguration.Toggled,
	Callback = function(Value)
		ESPToggled = Value
	end
})
local VisualsDependencyBox = VisualsTab:AddDependencyBox()
VisualsDependencyBox:SetupDependencies({{Toggles["ESPMasterSwitch"], true}})
VisualsDependencyBox:AddToggle("ESPDynamicRefreshRate", {
	Text = "Dynamic Refresh Rate",
	Tooltip = "Updates ESP depending on your FPS",
	Default = ESPDynamicRefreshRate,
	Callback = function(Value)
		ESPDynamicRefreshRate = Value
		Options["ESPRefreshRate"]:SetDisabled(Value)
	end
})
VisualsDependencyBox:AddSlider("ESPRefreshRate", {
	Text = "Refresh Rate [FPS]",
	Default = ESPRefreshRate,
	Disabled = true,
	Min = 1,
	Max = 240,
	Rounding = 0,
	Compact = false,
	Callback = function(Value)
		ESPRefreshRate = Value
	end
})
VisualsDependencyBox:AddToggle("ESPPerformanceMode", {
	Text = "Performance Mode",
	Default = ESPPerformanceMode,
	Callback = function(Value)
		ESPPerformanceMode = Value
	end
})
VisualsDependencyBox:AddButton({
	Text = "Reset Cache",
	Tooltip = "Click this if ESP is freezing/glitching.",
	Func = function()
		for _,DrawingObject in next, ESPObjects do
			if typeof(DrawingObject) == "Instance" then
				DrawingObject:Destroy()
			else
				DrawingManager:Remove(DrawingObject)
			end
		end
		table.clear(ESPObjects)

		for _,Player in ipairs(Players:GetPlayers()) do
			if Player == LocalPlayer then
				continue
			end

			ClearCache(Player)
			AddCache(Player)
		end

		table.clear(TagBuffer)
	end
})

VisualsDependencyBox:AddDivider("Cham ESP")
VisualsDependencyBox:AddToggle("ChamESP", {
	Text = "Enabled",
	Default = ChamESP.Enabled,
	Callback = function(Value)
		ChamESP.Enabled = Value
	end
})
VisualsDependencyBox:AddLabel("Fill Color"):AddColorPicker("ChamFillColor", {
	Default = ChamESP.FillColor,
	Transparency = 0,
	Callback = function(Color)
		ChamESP.FillColor = Color
		ChamESP.FillTransparency = Options["ChamFillColor"].Transparency

        for Index = 1, #CachedPlayersList do
            local Cham = CachedPlayersList[Index].ESP.Cham
			Cham.FillColor = Color
			Cham.FillTransparency = ChamESP.FillTransparency
        end
	end
})
VisualsDependencyBox:AddLabel("Outline Color"):AddColorPicker("ChamOutlineColor", {
	Default = ChamESP.OutlineColor,
	Transparency = 0,
	Callback = function(Color)
		ChamESP.OutlineColor = Color
		ChamESP.OutlineTransparency = Options["ChamOutlineColor"].Transparency

        for Index = 1, #CachedPlayersList do
            local Cham = CachedPlayersList[Index].ESP.Cham
			Cham.OutlineColor = Color
			Cham.OutlineTransparency = ChamESP.OutlineTransparency
        end
	end
})

VisualsDependencyBox:AddDivider("HeadTag ESP")
VisualsDependencyBox:AddToggle("HeadTagESP", {
	Text = "Enabled",
	Default = HeadTagESP.Enabled,
	Callback = function(Value)
		HeadTagESP.Enabled = Value
	end
}):AddColorPicker("HeadTagColor", {
	Default = HeadTagESP.Color,
	Transparency = 0,
	Callback = function(Color)
		HeadTagESP.Color = Color
		HeadTagESP.Transparency = 1 - Options["HeadTagColor"].Transparency

        for Index = 1, #CachedPlayersList do
            local HeadTag = CachedPlayersList[Index].ESP.HeadTag
			HeadTag.Color = Color
			HeadTag.Transparency = HeadTagESP.Transparency
        end
	end
})
VisualsDependencyBox:AddDropdown("HeadTagOptions", {
	Text = "Tag Options",
	Values = {"Full Name", "Name", "DisplayName", "Weapon", "Health", "Distance"},
	Multi = true,
	Default = 1
})
VisualsDependencyBox:AddDropdown("HeadTagPosition", {
	Text = "Position",
	Values = {"Top", "Bottom"},
	Default = 1,
	Callback = function(Position)
		HeadTagESP.Position = Position
	end
})

VisualsDependencyBox:AddDivider("Tracer ESP")
VisualsDependencyBox:AddToggle("TracerESP", {
	Text = "Enabled",
	Default = TracerESP.Enabled,
	Callback = function(Value)
		TracerESP.Enabled = Value
	end
}):AddColorPicker("TracerColor", {
	Default = TracerESP.Color,
	Transparency = 0,
	Callback = function(Color)
		TracerESP.Color = Color
		TracerESP.Transparency = 1 - Options["TracerColor"].Transparency

        for Index = 1, #CachedPlayersList do
            local Tracer = CachedPlayersList[Index].ESP.Tracer
			Tracer.Color = Color
			Tracer.Transparency = TracerESP.Transparency
        end
	end
})
VisualsDependencyBox:AddDropdown("TracerType", {
	Text = "Type",
	Values = {"Locked", "Unlocked"},
	Default = 1,
	Callback = function(Value)
		TracerESP.Type = Value
	end
})
VisualsDependencyBox:AddDropdown("TracerPart", {
	Text = "Part",
	Values = {"Head", "Root"},
	Default = 2,
	Callback = function(Value)
		TracerESP.Part = Value
	end
})

VisualsDependencyBox:AddDivider("2D Box ESP")
VisualsDependencyBox:AddToggle("2DBoxESP", {
	Text = "Enabled",
	Default = BoxESP.Box2D.Enabled,
	Callback = function(Value)
		BoxESP.Box2D.Enabled = Value
	end
}):AddColorPicker("2DBoxColor", {
	Default = BoxESP.Box2D.Color,
	Transparency = 0,
	Callback = function(Color)
		BoxESP.Box2D.Color = Color
		BoxESP.Box2D.Transparency = 1 - Options["2DBoxColor"].Transparency

        for Index = 1, #CachedPlayersList do
            local Box2D = CachedPlayersList[Index].ESP.Box2D
			Box2D.Color = Color
			Box2D.Transparency = BoxESP.Box2D.Transparency
        end
	end
})
VisualsDependencyBox:AddToggle("2DBoxFilled", {
	Text = "Filled",
	Default = BoxESP.Box2D.Filled,
	Callback = function(Value)
		BoxESP.Box2D.Filled = Value
        for Index = 1, #CachedPlayersList do
			CachedPlayersList[Index].ESP.Box2D.Filled = Value
        end
	end
})

VisualsDependencyBox:AddDivider("3D Box ESP")
VisualsDependencyBox:AddToggle("3DBoxESP", {
	Text = "Enabled",
	Default = BoxESP.Box3D.Enabled,
	Callback = function(Value)
		BoxESP.Box3D.Enabled = Value
	end
}):AddColorPicker("3DBoxColor", {
	Default = BoxESP.Box3D.Color,
	Transparency = 0,
	Callback = function(Color)
		BoxESP.Box3D.Color = Color
		BoxESP.Box3D.Transparency = 1 - Options["3DBoxColor"].Transparency

		for Index = 1, #CachedPlayersList do
			local Box3DLines = CachedPlayersList[Index].ESP.Box3D
			for Index2 = 1, #Box3DLines do
				Box3DLines[Index2].Color = Color
				Box3DLines[Index2].Transparency = BoxESP.Box3D.Transparency
			end
		end
	end
})

VisualsDependencyBox:AddDivider("Skeleton ESP")
VisualsDependencyBox:AddToggle("SkeletonESP", {
	Text = "Enabled",
	Default = SkeletonESP.Enabled,
	Callback = function(Value)
		SkeletonESP.Enabled = Value
	end
}):AddColorPicker("SkeletonColor", {
	Default = SkeletonESP.Color,
	Transparency = 0,
	Callback = function(Color)
		SkeletonESP.Color = Color
		SkeletonESP.Transparency = 1 - Options["SkeletonColor"].Transparency

		for Index = 1, #CachedPlayersList do
			local SkeletonLines = CachedPlayersList[Index].ESP.Skeleton
			for Index2 = 1, #SkeletonLines do
				SkeletonLines[Index2].Color = Color
				SkeletonLines[Index2].Transparency = SkeletonESP.Transparency
			end
		end
	end
})
VisualsDependencyBox:AddSlider("SkeletonThickness", {
	Text = "Thickness",
	Default = SkeletonESP.Thickness,
	Min = 1,
	Max = 10,
	Rounding = 0,
	Compact = false,
	Callback = function(Value)
		SkeletonESP.Thickness = Value
		for Index = 1, #CachedPlayersList do
			local SkeletonLines = CachedPlayersList[Index].ESP.Skeleton
			for Index2 = 1, #SkeletonLines do
				SkeletonLines[Index2].Thickness = Value
			end
		end
	end
})

VisualsDependencyBox:AddDivider("Checks")
VisualsDependencyBox:AddSlider("ESPConfigurationDistanceCheck", {
	Text = "Max Distance",
	Default = 2500,
	Min = 0,
	Max = 5000,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		ESPDistanceCheck = Value
	end
})
VisualsDependencyBox:AddToggle("ESPConfigurationForceField", {
	Text = "ForceField Check",
	Default = ESPForceFieldCheck,
	Callback = function(Value)
		ESPForceFieldCheck = Value
		if Value then
			for _,DrawingObject in next, ESPObjects do
				if typeof(DrawingObject) == "Instance" then
					DrawingObject:Destroy()
				else
					DrawingManager:Remove(DrawingObject)
				end
			end
			table.clear(ESPObjects)

			for _,Player in ipairs(Players:GetPlayers()) do
				if Player == LocalPlayer then
					continue
				end

				ClearCache(Player)
				AddCache(Player)
			end

			table.clear(TagBuffer)
		end
	end
})
VisualsDependencyBox:AddToggle("ESPConfigurationWallCheck", {
	Text = "Wall Check",
	Default = ESPWallCheck,
	Callback = function(Value)
		ESPWallCheck = Value
	end
})
VisualsDependencyBox:AddToggle("ESPConfigurationTeamCheck", {
	Text = "Team Check",
	Default = ESPTeamCheck,
	Callback = function(Value)
		ESPTeamCheck = Value
	end
})

LightingTab:AddToggle("WorldShadowDisabler", {
	Text = "Disable Global Shadows",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("ShadowDisabler")
			Lighting.GlobalShadows = true
			return
		end

		Lighting.GlobalShadows = false
		ConnectionManager:Connect("ShadowDisabler", Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
			Lighting.GlobalShadows = false
		end))
	end
})
LightingTab:AddToggle("WorldForceNight", {
	Text = "Force Night",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("ForceNight")
			return
		end

		Lighting.TimeOfDay = 0
		ConnectionManager:Connect("ForceNight", Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
			Lighting.TimeOfDay = 0
		end))
	end
})
LightingTab:AddToggle("WorldForceDay", {
	Text = "Force Day",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("ForceDay")
			return
		end

		Lighting.TimeOfDay = 12
		ConnectionManager:Connect("ForceDay", Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
			Lighting.TimeOfDay = 12
		end))
	end
})

LightingTab:AddSlider("ExposureCompensationSlider", {
	Text = "Exposure Compensation",
	Default = Lighting.ExposureCompensation * 0.1,
	Min = -1,
	Max = 1,
	Rounding = 10,
	Compact = false,
	Callback = function(Value)
		Lighting.ExposureCompensation = Value * 10
	end
})

LightingTab:AddButton({
	Text = "Restore Original Exposure Compensation",
	Func = function()
		Lighting.ExposureCompensation = World.OldExposureCompensation
		Options["ExposureCompensationSlider"]:SetValue(World.OldExposureCompensation)
	end
})

LightingTab:AddLabel("Change Ambient"):AddColorPicker("AmbientColor", {
	Default = World.OldAmbient,
	Transparency = nil,
	Callback = function(Color)
		Lighting.Ambient = Color
	end
})
LightingTab:AddButton({
	Text = "Save Current Ambient as Original",
	Func = function()
		World.OldAmbient = Lighting.Ambient
	end
})
LightingTab:AddButton({
	Text = "Restore Original Ambient",
	Func = function()
		Lighting.Ambient = World.OldAmbient
		Options["AmbientColor"]:SetValue(World.OldAmbient)
	end
})
LightingTab:AddLabel("Change Outdoor Ambient"):AddColorPicker("OutdoorAmbientColor", {
	Default = World["OldOutdoorAmbient"],
	Transparency = nil,
	Callback = function(Color)
		Lighting.OutdoorAmbient = Color
	end
})
LightingTab:AddButton({
	Text = "Save Current Outdoor Ambient as Original",
	Func = function()
		World["OldOutdoorAmbient"] = Lighting.OutdoorAmbient
	end
})
LightingTab:AddButton({
	Text = "Restore Original Outdoor Ambient",
	Func = function()
		Lighting.OutdoorAmbient = World["OldOutdoorAmbient"]
		Options["OutdoorAmbientColor"]:SetValue(World["OldOutdoorAmbient"])
	end
})

WeaponsViewTab:AddToggle("FOVModification", {
	Text = "FOV Modification",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("FOVModification")
			if Camera and World.OldCameraFOV then
				Camera.FieldOfView = World.OldCameraFOV
			end
			return
		end

		if Camera then
			World.OldCameraFOV = Camera.FieldOfView
		end

		ConnectionManager:Connect("FOVModification", RunService.RenderStepped(function()
			local Toggle = Camera and Toggles["FOVModification"]
			if not Toggle then
				return
			end

			if Toggle.Value then
				Camera.FieldOfView = Options["FOVAmountSlider"].Value
			end
		end))
	end
})
local WeaponsViewDependencyBox = WeaponsViewTab:AddDependencyBox()
WeaponsViewDependencyBox:SetupDependencies({{Toggles["FOVModification"], true}})
WeaponsViewDependencyBox:AddSlider("FOVAmountSlider", {
	Text = "FOV Amount",
	Default = 90,
	Min = 60,
	Max = 120,
	Rounding = 0,
	Compact = false
})
WeaponsViewTab:AddToggle("NoclipCamera", {
	Text = "Noclip Camera",
	Default = false,
	Callback = function(Value)
		if not Value then
			ConnectionManager:Disconnect("NoclipCamera")
			LocalPlayer.DevCameraOcclusionMode = OldDevCameraOcclusionMode
			return
		end

		OldDevCameraOcclusionMode = LocalPlayer.DevCameraOcclusionMode
		LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
		ConnectionManager:Connect("NoclipCamera", LocalPlayer:GetPropertyChangedSignal("DevCameraOcclusionMode"):Connect(function()
			OldDevCameraOcclusionMode = LocalPlayer.DevCameraOcclusionMode
			LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
		end))
	end
})

if getsenv and GetGunState then
	--[[WeaponsTab:AddToggle("InfiniteAmmo", {
		Text = "Infinite Ammo",
		Default = false,
		Callback = function(Value)
			if not Value then
				ConnectionManager:Disconnect("InfiniteAmmo")
				return
			end

			ConnectionManager:Connect("InfiniteAmmo", RunService.Heartbeat(function()
				local Tool = LocalCharacter and LocalCharacter:FindFirstChildOfClass("Tool")
				if not Tool then
					return
				end

				local RevolverServer = Tool:FindFirstChild("RevolverServer")
				if not RevolverServer then
					return
				end

				local RevolverClient = RevolverServer:FindFirstChild("RevolverClient")
				if not RevolverClient then
					return
				end

				local ScriptEnvironment = getsenv(RevolverClient)
				if not ScriptEnvironment then
					return
				end

				local GunState = GetGunState(ScriptEnvironment.ON_TOOL_EQUIP)
				if GunState then
					local Settings = ScriptEnvironment.ClientWeaponSettings
					if not Settings then
						return
					end

					local LoadCapacity = Settings.LoadCapacity or 3
					local CurrentAmmo = rawget(GunState, "LoadedAmmo")
					if CurrentAmmo <= 1 then
						rawset(GunState, "LoadedAmmo", LoadCapacity - 1)
						ScriptEnvironment.ReloadUpdate(1)
						CurrentAmmo = LoadCapacity
					end
				end
			end, 0.5))
		end
	})

	WeaponsTab:AddToggle("ForceThrow", {
		Text = "Force Throw",
		Default = false,
		Callback = function(Value)
			if not Value then
				ThreadManager:Stop("ForceThrow")
				return
			end

			ThreadManager:Start("ForceThrow", function()
				local Tool = LocalCharacter and LocalCharacter:FindFirstChildOfClass("Tool")
				if not Tool then
					return
				end

				local KnifeServer = Tool:FindFirstChild("KnifeServer")
				if not KnifeServer then
					return
				end

				local KnifeClient = KnifeServer:FindFirstChild("KnifeClient")
				if not KnifeClient then
					return
				end

				local ScriptEnvironment = getsenv(KnifeClient)
				if not ScriptEnvironment then
					return
				end

				local Settings = ScriptEnvironment.ClientKnifeSetting
				if Settings then
					Settings.CanThrow = true
				end
			end, 0.5)
		end
	})]]

	WeaponsTab:AddToggle("RapidThrow", {
		Text = "Rapid Throw (Disables stabbing)",
		Default = false,
		Callback = function(Value)
			local OldSettings = nil

			if not Value then
				ThreadManager:Stop("RapidThrow")
				if OldSettings and LocalCharacter then
					local Tool = LocalCharacter:FindFirstChildOfClass("Tool")
					if not Tool then
						return
					end

					local KnifeClient = Tool:FindFirstChild("KnifeServer") and Tool.KnifeServer:FindFirstChild("KnifeClient")
					if not KnifeClient then
						return
					end

					local ScriptEnvironment = getsenv(KnifeClient)
					if not ScriptEnvironment then
						return
					end

					if ScriptEnvironment.ClientKnifeSettings then
						ScriptEnvironment.ClientKnifeSettings = OldSettings
					end
				end
				return
			end

			ThreadManager:Start("RapidThrow", function()
				local Tool = LocalCharacter and LocalCharacter:FindFirstChildOfClass("Tool")
				if not Tool then
					return
				end

				local KnifeServer = Tool:FindFirstChild("KnifeServer")
				if not KnifeServer then
					return
				end

				local KnifeClient = KnifeServer:FindFirstChild("KnifeClient")
				if not KnifeClient then
					return
				end

				local ScriptEnvironment = getsenv(KnifeClient)
				if not ScriptEnvironment then
					return
				end

				local Settings = ScriptEnvironment.ClientKnifeSettings
				if not Settings then
					return
				end

				if not Settings.__nsRapidThrow then
					OldSettings = Settings
					Settings.__nsRapidThrow = true
				end
				Settings.CanThrow = true
				Settings.EquipTime = 0
				Settings.SlashEquipDelay = 0
				Settings.GrabTime = 0
				Settings.ChargeTime = 1
				Settings.EffectiveChargeTime = 1
				Settings.StabTime = -10
				Settings.EffectiveStabTime = -10
				Settings.MinimumChargeTime = -999
				Settings.SlashTime = 0
				Settings.SlashCoolDownFactor = 0
			end, 0.5)
		end
	})
else
	WeaponsTab:AddLabel("Force Throw & Rapid Throw is not supported, missing function 'getsenv'", true)
end

if getgc then
	local Found = false
	for _,Table in getgc(true) do
		if type(Table) == "table" then
			local CameraRecoilFunction = rawget(Table, "CameraRecoil")
			if CameraRecoilFunction then
				Found = true
				rawset(Table, "CameraRecoil", function(Argument1, Argument2, ...)
					if Running and NoRecoil then
						return CameraRecoilFunction(Argument1, 0, ...)
					end
					return CameraRecoilFunction(Argument1, Argument2, ...)
				end)
			end
		end
	end

	if Found then
		WeaponsTab:AddToggle("NoRecoil", {
			Text = "No Recoil",
			Default = false,
			Callback = function(Value)
				NoRecoil = Value
			end
		})
	else
		WeaponsTab:AddLabel("No Recoil is not supported, function 'getgc' is broken", true)
	end
else
	WeaponsTab:AddLabel("No Recoil is not supported, missing function 'getgc'", true)
end

SettingsTab:AddToggle("DisableDiscordNotification", {
	Text = "Disable Discord Invite Notifications",
	Default = false
})

SettingsTab:AddToggle("ns__Watermark", {
	Text = "Library Watermark",
	Default = true,
	Callback = function(Value)
		Watermark:SetVisible(Value)
		WatermarkIsVisible = Value
	end
})

SettingsTab:AddToggle("GlobalSearch", {
	Text = "Global Search",
	Default = true,
	Callback = function(Value)
		UI.GlobalSearch = Value
	end
})

SettingsTab:AddLabel("Toggle menu keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})
UI.ToggleKeybind = Options["MenuKeybind"]
--[[SettingsTab:AddToggle("ns__KeybindsMenu", {
	Text = "Keybinds Menu",
	Default = true,
	Callback = function(Value)
		UI.ShowToggleFrameInKeybinds = Value
	end
})]]

SettingsTab:AddToggle("ns__PlayerJoinLogs", {
	Text = "Player Join Logs",
	Default = PlayerJoinLogs,
	Callback = function(Value)
		PlayerJoinLogs = Value
	end
})
SettingsTab:AddToggle("ns__PlayerLeaveLogs", {
	Text = "Player Leave Logs",
	Default = PlayerLeaveLogs,
	Callback = function(Value)
		PlayerLeaveLogs = Value
	end
})

local function Unload()
	UI.Unload()
	Running = false

	task.wait()

	ConnectionManager:Shutdown()
	ThreadManager:Shutdown()

	for _,Player in ipairs(Players:GetPlayers()) do
		ClearCache(Player)
	end

	local AnimateInstance = LocalCharacter and LocalCharacter:FindFirstChild("Animate")
	if AnimateInstance then
		AnimateInstance.Disabled = false
	end

	Lighting.ExposureCompensation = World.OldExposureCompensation
	Lighting.Ambient = World.OldAmbient
	Lighting.OutdoorAmbient = World.OldOutdoorAmbient

	if Camera and World.OldCameraFOV then
		Camera.FieldOfView = World.OldCameraFOV
	end

	if CoreGui:FindFirstChild("ns__LocalHighlight") then
		CoreGui:FindFirstChild("ns__LocalHighlight"):Destroy()
	end

	if HitSounds.Folder then
		HitSounds.Folder:Destroy()
	end

	if ChinaHat.ChinaHatTrail then
		ChinaHat.ChinaHatTrail:Destroy()
		ChinaHat.ChinaHatTrail = nil
	end

	local function Clear()
		for _,FOVCircle in next, AimbotFOVCircles do
			DrawingManager:Remove(FOVCircle)
		end

		for _,DrawingObject in next, ESPObjects do
			if typeof(DrawingObject) == "Instance" then
				DrawingObject:Destroy()
			else
				DrawingManager:Remove(DrawingObject)
			end
		end

		table.clear(ESPObjects)
		return true
	end

	if not pcall(cleardrawcache or Clear) then
		Clear()
	end
end

SettingsTab:AddButton({
	Text = "Reload Script",
	Func = function()
		Unload()
		print([[ // Reloading KAT.lol || Made by nikoleto scripts - github.com/nikoladhima \\ --]])
		NikoletoScripts["LoadScript"]("Loader.lua", "Main.luau")
	end
})
SettingsTab:AddButton({
	Text = "Unload Script",
	Func = function()
		Unload()
		print([[ // Unloaded KAT.lol || Made by nikoleto scripts - github.com/nikoladhima \\ --]])
	end
})

UI:Notify({
	Title = "[[ KAT.lol ]]",
	Description = "Loaded KAT.lol successfully || Made by nikoleto scripts - github.com/nikoladhima",
	Time = 3.5
})

UI:Toggle(true)

if FileManager then
	FileManager = FileManager()
end

local Errors = 0
if FileManager then
	local ThemeManager = NikoletoScripts:GetThemeManager()
	if ThemeManager then
		ThemeManager:SetLibrary(UI)
		ThemeManager:SetDefaultTheme({
			BackgroundColor = Color3.fromRGB(15, 15, 15),
			MainColor = Color3.fromRGB(25, 25, 25),
			AccentColor = Color3.fromRGB(125, 85, 255),
			OutlineColor = Color3.fromRGB(40, 40, 40),
			FontColor = Color3.new(1, 1, 1),
			FontFace = Font.fromEnum(Enum.Font.Code),
		})
		ThemeManager:ApplyToTab(Tabs.SettingsWindow)
	else
		Errors += 1
	end

	local SaveManager = NikoletoScripts:GetSaveManager()
	if SaveManager then
		SaveManager:SetLibrary(UI)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({"MenuKeybind"})
		SaveManager:BuildConfigSection(Tabs.SettingsWindow)
		SaveManager:LoadAutoloadConfig()
	else
		Errors += 1
	end
end

print("[KAT.lol/src/Main.luau | INFO]: Successfully loaded KAT.lol in", tick() - NikoletoScripts["Start"] .. "s")
if Errors > 0 then
	warn("[nikoletoscripts/KAT.lol]:", Errors, "Module Errors were found. Script will continue to function.")
end

ThreadManager:Start("DiscordNotifier", function()
	if not Toggles["DisableDiscordNotification"].Value then
		UI:Notify({
			Title = "[[ KAT.lol ]]",
			Description = "Friendly reminder to join the Discord Server for updates! [discord.gg/DwRT2nH93D]\nYou can disable this notification in Settings.",
			Time = 25
		})
	end
end, 60)
