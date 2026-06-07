print('start init')

local Context = (...)
if type(Context) ~= "table" then
    error("[KAT.lol/src/Init.luau | ERROR]: Argument must be a table.", 2)
end

local function IsFunction(Function)
    return typeof(Function) == "function" and Function
end

if not Drawing then
	game:GetService("Players").LocalPlayer:Kick("Exploit not supported.\nReason: Drawing Library is missing.")
    return
end

local ConnectionManager = (function()
	local ConnectionManager = {Connections = {}}

	function ConnectionManager:Connect(Name, Connection)
		local Existing = self.Connections[Name]
		if Existing then
			Existing:Disconnect()
		end
		self.Connections[Name] = Connection
		return Connection
	end

	function ConnectionManager:Disconnect(Name)
		local Connection = self.Connections[Name]
		if Connection then
			Connection:Disconnect()
			self.Connections[Name] = nil
		end
	end

	function ConnectionManager:Shutdown()
		for _,Connection in self.Connections do
			Connection:Disconnect()
		end
		table.clear(self.Connections)
	end

	return ConnectionManager
end)()

local ServiceManager = setmetatable({}, {
    __index = function(self, Name)
        local Service = game:GetService(Name)
        rawset(self, Name, Service)
        return Service
    end,

    __call = function(self)
        return self.Players.LocalPlayer
    end
})

local FileManager = (function()
	if not (isfolder and makefolder and isfile and writefile and readfile and delfile and listfiles) then
		warn("[FileManager]: Failed to load, Configuration & Theme System will not be initialized.")
		return nil
	end

    local HttpService = ServiceManager.HttpService
	local FileManager = {}

	function FileManager:IsFile(Path)
        return isfile(Path)
	end

	function FileManager:IsFolder(Path)
		return isfolder(Path)
	end

	function FileManager:CreateFolder(Path)
		if not isfolder(Path) then
			makefolder(Path)
		end
	end

	function FileManager:DeleteFile(Path)
		if isfile(Path) then
			deletefile(Path)
		end
	end

	function FileManager:Read(Path)
		if isfile(Path) then
			return readfile(Path)
		end
		return nil
	end

	function FileManager:ReadJSON(Path)
		if isfile(Path) then
            local Content = readfile(Path)
			return Content and HttpService:JSONDecode(Content)
		end
		return nil
	end

	function FileManager:Write(Path, Content)
		writefile(Path, Content)
	end

	function FileManager:WriteJSON(Path, Content)
		writefile(Path, HttpService:JSONEncode(Content))
	end

	function FileManager:List(Path)
		return listfiles(Path) or {}
	end

	function FileManager:Exists(Path)
		return isfile(Path) or isfolder(Path)
	end

	return setmetatable(FileManager, {
        __call = function()
            FileManager:CreateFolder("NikoletoScripts")
            FileManager:CreateFolder("NikoletoScripts/KAT.lol")
            return FileManager
        end
    })
end)()

local RunService = (function()
	local RunService, Service = {}, ServiceManager.RunService

	function RunService:BindToRenderStep(Name, Priority, Function)
		return Service:BindToRenderStep(Name, Priority, Function)
	end

	function RunService:UnbindFromRenderStep(Name)
		return Service:UnbindFromRenderStep(Name)
	end

	for _,EventName in {"Stepped", "RenderStepped", "Heartbeat"} do
		local Event = Service[EventName]
		RunService[EventName] = function(Function)
			return Event:Connect(Function)
		end
		RunService[EventName .. "Wait"] = function()
			return Event:Wait()
		end
	end

	return RunService
end)()

local Utils = (function()
	local Utils = {}

    local HttpService = ServiceManager.HttpService
	function Utils.GenerateGUID(WrapInCurlyBraces)
		return HttpService:GenerateGUID(WrapInCurlyBraces)
	end

	function Utils.Create(Type, Parent, Properties)
		local Object = Instance.new(Type)

		if Properties then
			for Property, Value in next, Properties do
				Object[Property] = Value
			end
		end

		if Parent then
			Object.Parent = Parent
		end

		return Object
	end

	function Utils.SetEnabled(Object, Value)
		if Object.Enabled ~= Value then
			Object.Enabled = Value
		end
	end

	function Utils.GetDistanceSquared(Point1, Point2)
		local DeltaX = Point1.X - Point2.X
		local DeltaY = Point1.Y - Point2.Y
		local DeltaZ = Point1.Z - Point2.Z
		return DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ
	end

    function Utils.CreateWindow(Library)
        local Success, Window = pcall(function()
            return Library:CreateWindow({ Icon = "130975824766445" })
        end)

        if not Success or not Window then
            error("Failed to Create Window, rejoin and try again: " .. tostring(Window))
        end

        local Aiming = Window:AddTab("Target Aimbot", "crosshair")
        local TriggerBot = Window:AddTab("TriggerBot", "bot")
        local Players = Window:AddTab("LocalPlayer", "users")
        local Visuals = Window:AddTab("Visuals", "eye")
        local Weapons = Window:AddTab("Weapons", "gamepad-2")
        local RageBot = Window:AddTab("RageBot", "skull")
        local Settings = Window:AddTab("Settings", "settings")

        local Tabs = {SettingsWindow = Settings}
        local function AddTab(Name, WindowTab, Method, Title)
            Tabs[Name] = WindowTab[Method](WindowTab, Title)
        end

        AddTab("AimbotTab", Aiming, "AddLeftGroupbox", "Aimbot | Camera & Mouse")
        AddTab("SilentAimbotTab", Aiming, "AddRightGroupbox", "Silent Aimbot")

        AddTab("TriggerBotMain", TriggerBot, "AddLeftGroupbox", "TriggerBot")
        AddTab("TriggerBotChecks", TriggerBot, "AddRightGroupbox", "Checks")

        local LocalPlayerTabBox = Players:AddLeftTabbox("LocalPlayerTabBox")
        AddTab("AntiAimTab", LocalPlayerTabBox, "AddTab", "Anti Aim")
        AddTab("MovementTab", LocalPlayerTabBox, "AddTab", "Movement")

        AddTab("LocalCharacterTab", Players, "AddRightGroupbox", "Local Char")

        AddTab("VisualsTab", Visuals, "AddLeftGroupbox", "Extra-Sensory Perception")
        AddTab("LightingTab", Visuals, "AddRightGroupbox", "Lighting")

        AddTab("WeaponsTab", Weapons, "AddLeftGroupbox", "Weapon Modification")
        AddTab("WeaponsViewTab", Weapons, "AddRightGroupbox", "Camera & view")

        AddTab("RageBotTab", RageBot, "AddLeftGroupbox", "Bot Control [Knife]")
        AddTab("HitConfigurationTab", RageBot, "AddRightGroupbox", "Hit Configuration")

        AddTab("SettingsTab", Settings, "AddLeftGroupbox", "Settings")

        Window.ns__Tabs = Tabs
        return Window
    end

	return Utils
end)()

--[=[Context.LoadScript("src/Main.luau", "src/Init.luau", {
	["Start"] = Context["Start"],
	["Version"] = Context["Version"],
	["LoadScript"] = Context["LoadScript"],
    ["ExecutorName"] = IsFunction(identifyexecutor) or IsFunction(getexecutorname) or function()
        return "Unknown"
    end,

	["ConnectionManager"] = ConnectionManager,
    ["ServiceManager"] = ServiceManager,
	["DrawingManager"] = (function()
        local DrawingManager = setmetatable({}, {
            __call = function(_,DrawingType, Properties)
                local DrawingObject = Drawing.new(DrawingType)
                if Properties then
                    for Property, Value in next, Properties do
                        DrawingObject[Property] = Value
                    end
                end
                return DrawingObject
            end
        })

        function DrawingManager:Remove(DrawingObject)
            pcall(function()
                DrawingObject:Remove()
            end)
        end

        return DrawingManager
    end)(),
	["ThreadManager"] = (function()
        local ThreadManager = {Threads = {}}

        function ThreadManager:Start(Name, Callback, Interval)
            if self.Threads[Name] then
                return
            end

            local IsRunning = true
            self.Threads[Name] = {
                Kill = function()
                    IsRunning = false
                end
            }

            task.spawn(function()
                while IsRunning do
                    Callback()
                    task.wait(Interval)
                end
            end)
        end

        function ThreadManager:Stop(Name)
            local Thread = self.Threads[Name]
            if Thread then
                Thread.Kill()
                self.Threads[Name] = nil
            end
        end

        function ThreadManager:Exists(Name)
            return self.Threads[Name] ~= nil
        end

        function ThreadManager:Shutdown()
            for _,Thread in self.Threads do
                Thread.Kill()
            end
            table.clear(self.Threads)
        end

        return ThreadManager
    end)(),
	["FileManager"] = FileManager,
	["RunService"] = RunService,
	["Utils"] = Utils,
    ["UI"] = (function()
        local UserInputService = ServiceManager.UserInputService
        local SoundService = ServiceManager.SoundService
        local TweenService = ServiceManager.TweenService
        local TextService = ServiceManager.TextService
        local CoreGui = ServiceManager.CoreGui
        local Players = ServiceManager.Players

        local setclipboard = IsFunction(setclipboard) or IsFunction(writeclipboard)
        local Create = Utils.Create

        local LocalPlayer = Players.LocalPlayer
        local Mouse = LocalPlayer:GetMouse()

        local Labels = {}
        local Buttons = {}
        local Toggles = {}
        local Options = {}
        local Tooltips = {}

        local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
        local CustomImageManager = {}
        local CustomImageManagerAssets = {
            TransparencyTexture = {
                RobloxId = 139785960036434,
                Path = "Obsidian/assets/TransparencyTexture.png",
                URL = BaseURL .. "assets/TransparencyTexture.png",

                Id = nil,
            },

            SaturationMap = {
                RobloxId = 4155801252,
                Path = "Obsidian/assets/SaturationMap.png",
                URL = BaseURL .. "assets/SaturationMap.png",

                Id = nil,
            },
        }
        do
            local function RecursiveCreatePath(Path, IsFile)
                if not FileManager then
                    return
                end

                local Segments = Path:split("/")
                local TraversedPath = ""

                if IsFile then
                    table.remove(Segments, #Segments)
                end

                for _,Segment in ipairs(Segments) do
                    FileManager:CreateFolder(TraversedPath .. Segment)
                    TraversedPath = TraversedPath .. Segment .. "/"
                end

                return TraversedPath
            end

            function CustomImageManager.AddAsset(AssetName, RobloxAssetId, URL, ForceRedownload)
                if CustomImageManagerAssets[AssetName] ~= nil then
                    error(string.format("Asset %q already exists", AssetName))
                end

                assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

                CustomImageManagerAssets[AssetName] = {
                    RobloxId = RobloxAssetId,
                    Path = string.format("Obsidian/custom_assets/%s", AssetName),
                    URL = URL,

                    Id = nil,
                }

                CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
            end

            function CustomImageManager.GetAsset(AssetName)
                if not CustomImageManagerAssets[AssetName] then
                    return nil
                end

                local AssetData = CustomImageManagerAssets[AssetName]
                if AssetData.Id then
                    return AssetData.Id
                end

                local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)
                AssetData.Id = AssetID
                return AssetID
            end

            function CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
                if not FileManager then
                    return
                end

                local AssetData = CustomImageManagerAssets[AssetName]
                RecursiveCreatePath(AssetData.Path, true)

                if ForceRedownload ~= true and FileManager:Exists(AssetData.Path) then
                    return true, nil
                end

                FileManager:Write(AssetData.Path, game:HttpGet(AssetData.URL))
            end

            for AssetName,_ in CustomImageManagerAssets do
                CustomImageManager.DownloadAsset(AssetName)
            end
        end

        local Library = {
            LocalPlayer = LocalPlayer,
            DevicePlatform = nil,
            IsMobile = false,
            IsRobloxFocused = true,

            ScreenGui = nil,

            SearchText = "",
            Searching = false,
            GlobalSearch = true,
            LastSearchTab = nil,

            ActiveTab = nil,
            Tabs = {},
            TabButtons = {},
            DependencyBoxes = {},

            KeybindFrame = nil,
            KeybindContainer = nil,
            KeybindToggles = {},

            Notifications = {},

            ToggleKeybind = Enum.KeyCode.RightShift,

            BaseTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            TabTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            SliderTweenInfo = TweenInfo.new(0.025, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

            Toggled = false,
            Unloaded = false,

            Labels = Labels,
            Buttons = Buttons,
            Toggles = Toggles,
            Options = Options,

            NotifySide = "Right",
            ForceCheckbox = false,
            ShowToggleFrameInKeybinds = true,
            NotifyOnError = false,

            CantDragForced = false,

            Signals = {},
            UnloadSignals = {},

            OriginalMinSize = Vector2.new(480, 360),
            MinSize = Vector2.new(480, 360),
            DPIScale = 1,
            CornerRadius = 6,

            IsLightTheme = false,
            Scheme = {
                BackgroundColor = Color3.fromRGB(15, 15, 15),
                MainColor = Color3.fromRGB(25, 25, 25),
                AccentColor = Color3.fromRGB(125, 85, 255),
                OutlineColor = Color3.fromRGB(40, 40, 40),
                FontColor = Color3.new(1, 1, 1),
                Font = Font.fromEnum(Enum.Font.Code),

                RedColor = Color3.fromRGB(255, 50, 50),
                DarkColor = Color3.new(0, 0, 0),
                WhiteColor = Color3.new(1, 1, 1),
            },

            Registry = {},
            Scales = {},

            ImageManager = CustomImageManager,
        }

        local Templates = {
            Frame = {
                BorderSizePixel = 0,
            },
            ImageLabel = {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            },
            ImageButton = {
                AutoButtonColor = false,
                BorderSizePixel = 0,
            },
            ScrollingFrame = {
                BorderSizePixel = 0,
            },
            TextLabel = {
                BorderSizePixel = 0,
                FontFace = "Font",
                RichText = true,
                TextColor3 = "FontColor",
            },
            TextButton = {
                AutoButtonColor = false,
                BorderSizePixel = 0,
                FontFace = "Font",
                RichText = true,
                TextColor3 = "FontColor",
            },
            TextBox = {
                BorderSizePixel = 0,
                FontFace = "Font",
                PlaceholderColor3 = function()
                    local H, S, V = Library.Scheme.FontColor:ToHSV()
                    return Color3.fromHSV(H, S, V / 2)
                end,
                Text = "",
                TextColor3 = "FontColor",
            },
            UIListLayout = {
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
            UIStroke = {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            },

            Window = {
                Title = "KAT.lol",
                Footer = "v" .. Context["Version"] .. " | discord.gg/DwRT2nH93D",
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.fromOffset(1000, 520),
                IconSize = UDim2.fromOffset(30, 30),
                Center = true,
                Resizable = true,
                SearchbarSize = UDim2.fromScale(1, 1),
                GlobalSearch = true,
                CornerRadius = 6,
                NotifySide = "Right",
                Font = Enum.Font.Code,
                ToggleKeybind = Enum.KeyCode.RightShift,
                MobileButtonsSide = "Left"
            },
            Toggle = {
                Text = "Toggle",
                Default = false,

                Callback = function() end,
                Changed = function() end,

                Risky = false,
                Disabled = false,
                Visible = true,
            },
            Input = {
                Text = "Input",
                Default = "",
                Finished = false,
                Numeric = false,
                ClearTextOnFocus = true,
                Placeholder = "",
                AllowEmpty = true,
                EmptyReset = "---",

                Callback = function() end,
                Changed = function() end,

                Disabled = false,
                Visible = true,
            },
            Slider = {
                Text = "Slider",
                Default = 0,
                Min = 0,
                Max = 100,
                Rounding = 0,

                Prefix = "",
                Suffix = "",

                Callback = function() end,
                Changed = function() end,

                Disabled = false,
                Visible = true,
            },
            Dropdown = {
                Values = {},
                DisabledValues = {},
                Multi = false,
                MaxVisibleDropdownItems = 8,

                Callback = function() end,
                Changed = function() end,

                Disabled = false,
                Visible = true,
            },
            Viewport = {
                Object = nil,
                Camera = nil,
                Clone = true,
                AutoFocus = true,
                Interactive = false,
                Height = 200,
                Visible = true,
            },
            Image = {
                Image = "",
                Transparency = 0,
                BackgroundTransparency = 0,
                Color = Color3.new(1, 1, 1),
                RectOffset = Vector2.zero,
                RectSize = Vector2.zero,
                ScaleType = Enum.ScaleType.Fit,
                Height = 200,
                Visible = true,
            },
            Video = {
                Video = "",
                Looped = false,
                Playing = false,
                Volume = 1,
                Height = 200,
                Visible = true,
            },
            UIPassthrough = {
                Instance = nil,
                Height = 24,
                Visible = true,
            },

            KeyPicker = {
                Text = "KeyPicker",
                Default = "None",
                DefaultModifiers = {},
                Mode = "Toggle",
                Modes = { "Always", "Toggle", "Hold" },
                SyncToggleState = false,

                Callback = function() end,
                ChangedCallback = function() end,
                Changed = function() end,
                Clicked = function() end,
            },
            ColorPicker = {
                Default = Color3.new(1, 1, 1),

                Callback = function() end,
                Changed = function() end,
            },
        }

        local Places = {
            Bottom = { 0, 1 },
            Right = { 1, 0 },
        }
        local Sizes = {
            Left = { 0.5, 1 },
            Right = { 0.5, 1 },
        }

        local SchemeReplaceAlias = {
            RedColor = "Red",
            WhiteColor = "White",
            DarkColor = "Dark"
        }

        local SchemeAlias = {
            Red = "RedColor",
            White = "WhiteColor",
            Dark = "DarkColor"
        }

        local function GetSchemeValue(Index)
            if not Index then
                return nil
            end

            local ReplaceAliasIndex = SchemeReplaceAlias[Index]
            if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
                Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
                Library.Scheme[ReplaceAliasIndex] = nil

                return Library.Scheme[Index]
            end

            local AliasIndex = SchemeAlias[Index]
            if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
                warn(string.format("Scheme Value %q is deprecated, please use %q instead.", Index, AliasIndex))
                return Library.Scheme[AliasIndex]
            end

            return Library.Scheme[Index]
        end

        local function WaitForEvent(Event, Timeout, Condition)
            local Bindable = Create("BindableEvent")
            local Connection = Event:Once(function(...)
                if not Condition or typeof(Condition) == "function" and Condition(...) then
                    Bindable:Fire(true)
                else
                    Bindable:Fire(false)
                end
            end)
            task.delay(Timeout, function()
                Connection:Disconnect()
                Bindable:Fire(false)
            end)

            local Result = Bindable.Event:Wait()
            Bindable:Destroy()

            return Result
        end

        local function IsMouseInput(Input, IncludeM2)
            return Input.UserInputType == Enum.UserInputType.MouseButton1
                or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
                or Input.UserInputType == Enum.UserInputType.Touch
        end
        local function IsClickInput(Input, IncludeM2)
            return IsMouseInput(Input, IncludeM2)
                and Input.UserInputState == Enum.UserInputState.Begin
                and Library.IsRobloxFocused
        end
        local function IsHoverInput(Input)
            return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
                and Input.UserInputState == Enum.UserInputState.Change
        end
        local function IsDragInput(Input, IncludeM2)
            return IsMouseInput(Input, IncludeM2)
                and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
                and Library.IsRobloxFocused
        end

        local function GetTableSize(Table)
            local Size = 0

            for _, _ in Table do
                Size += 1
            end

            return Size
        end
        local function StopTween(Tween)
            if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
                return
            end

            Tween:Cancel()
        end
        local function Trim(Text)
            return Text:match("^%s*(.-)%s*$")
        end
        local function Round(Value, Rounding)
            assert(Rounding >= 0, "Invalid rounding number.")

            if Rounding == 0 then
                return math.floor(Value)
            end

            return tonumber(string.format("%." .. Rounding .. "f", Value))
        end

        local function GetPlayers()
            local PlayerList = Players:GetPlayers()

            local Idx = table.find(PlayerList, LocalPlayer)
            if Idx then
                table.remove(PlayerList, Idx)
            end

            table.sort(PlayerList, function(Player1, Player2)
                return Player1.Name:lower() < Player2.Name:lower()
            end)

            return PlayerList
        end

        function Library:UpdateDependencyBoxes()
            for _, Depbox in Library.DependencyBoxes do
                Depbox:Update(true)
            end

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        local function CheckDepbox(Box, Search)
            local VisibleElements = 0

            for _, ElementInfo in Box.Elements do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    local Visible = false

                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements += 1
                    end

                    continue
                end

                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in Box.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements += CheckDepbox(Depbox, Search)
            end

            Box.Holder.Visible = VisibleElements > 0
            return VisibleElements
        end
        local function RestoreDepbox(Box)
            for _, ElementInfo in Box.Elements do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            Box:Resize()
            Box.Holder.Visible = true

            for _, Depbox in Box.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end
        end

        local function ApplySearchToTab(Tab, Search)
            if not Tab then
                return
            end

            local HasVisible = false

            for _, Groupbox in Tab.Groupboxes do
                local VisibleElements = 0

                for _, ElementInfo in Groupbox.Elements do
                    if ElementInfo.Type == "Divider" then
                        ElementInfo.Holder.Visible = false
                        continue
                    elseif ElementInfo.SubButton then
                        local Visible = false

                        if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                            Visible = true
                        else
                            ElementInfo.Base.Visible = false
                        end
                        if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                            Visible = true
                        else
                            ElementInfo.SubButton.Base.Visible = false
                        end
                        ElementInfo.Holder.Visible = Visible
                        if Visible then
                            VisibleElements += 1
                        end

                        continue
                    end

                    if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        ElementInfo.Holder.Visible = true
                        VisibleElements += 1
                    else
                        ElementInfo.Holder.Visible = false
                    end
                end

                for _, Depbox in Groupbox.DependencyBoxes do
                    if not Depbox.Visible then
                        continue
                    end

                    VisibleElements += CheckDepbox(Depbox, Search)
                end

                if VisibleElements > 0 then
                    Groupbox:Resize()
                    HasVisible = true
                end
                Groupbox.BoxHolder.Visible = VisibleElements > 0
            end

            for _, Tabbox in Tab.Tabboxes do
                local VisibleTabs = 0
                local VisibleElements = {}

                for _, SubTab in Tabbox.Tabs do
                    VisibleElements[SubTab] = 0

                    for _, ElementInfo in SubTab.Elements do
                        if ElementInfo.Type == "Divider" then
                            ElementInfo.Holder.Visible = false
                            continue
                        elseif ElementInfo.SubButton then
                            local Visible = false

                            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                                Visible = true
                            else
                                ElementInfo.Base.Visible = false
                            end
                            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                                Visible = true
                            else
                                ElementInfo.SubButton.Base.Visible = false
                            end
                            ElementInfo.Holder.Visible = Visible
                            if Visible then
                                VisibleElements[SubTab] += 1
                            end

                            continue
                        end

                        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                            ElementInfo.Holder.Visible = true
                            VisibleElements[SubTab] += 1
                        else
                            ElementInfo.Holder.Visible = false
                        end
                    end

                    for _, Depbox in SubTab.DependencyBoxes do
                        if not Depbox.Visible then
                            continue
                        end

                        VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
                    end
                end

                for SubTab, Visible in VisibleElements do
                    SubTab.ButtonHolder.Visible = Visible > 0
                    if Visible > 0 then
                        VisibleTabs += 1
                        HasVisible = true

                        if Tabbox.ActiveTab == SubTab then
                            SubTab:Resize()
                        elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                            SubTab:Show()
                        end
                    end
                end

                Tabbox.BoxHolder.Visible = VisibleTabs > 0
            end

            return HasVisible
        end
        local function ResetTab(Tab)
            if not Tab then
                return
            end

            for _, Groupbox in Tab.Groupboxes do
                for _, ElementInfo in Groupbox.Elements do
                    ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                    if ElementInfo.SubButton then
                        ElementInfo.Base.Visible = ElementInfo.Visible
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end

                for _, Depbox in Groupbox.DependencyBoxes do
                    if not Depbox.Visible then
                        continue
                    end

                    RestoreDepbox(Depbox)
                end

                Groupbox:Resize()
                Groupbox.BoxHolder.Visible = true
            end

            for _, Tabbox in Tab.Tabboxes do
                for _, SubTab in Tabbox.Tabs do
                    for _, ElementInfo in SubTab.Elements do
                        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                        if ElementInfo.SubButton then
                            ElementInfo.Base.Visible = ElementInfo.Visible
                            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                        end
                    end

                    for _, Depbox in SubTab.DependencyBoxes do
                        if not Depbox.Visible then
                            continue
                        end

                        RestoreDepbox(Depbox)
                    end

                    SubTab.ButtonHolder.Visible = true
                end

                if Tabbox.ActiveTab then
                    Tabbox.ActiveTab:Resize()
                end
                Tabbox.BoxHolder.Visible = true
            end
        end

        function Library:UpdateSearch(SearchText)
            Library.SearchText = SearchText

            local TabsToReset = {}

            if Library.GlobalSearch then
                for _, Tab in Library.Tabs do
                    if typeof(Tab) == "table" and not Tab.IsKeyTab then
                        table.insert(TabsToReset, Tab)
                    end
                end
            elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
                table.insert(TabsToReset, Library.LastSearchTab)
            end

            for _, Tab in ipairs(TabsToReset) do
                ResetTab(Tab)
            end

            local Search = SearchText:lower()
            if Trim(Search) == "" then
                Library.Searching = false
                Library.LastSearchTab = nil
                return
            end
            if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
                Library.Searching = false
                Library.LastSearchTab = nil
                return
            end

            Library.Searching = true

            local TabsToSearch = {}

            if Library.GlobalSearch then
                TabsToSearch = TabsToReset
                if #TabsToSearch == 0 then
                    for _, Tab in Library.Tabs do
                        if typeof(Tab) == "table" and not Tab.IsKeyTab then
                            table.insert(TabsToSearch, Tab)
                        end
                    end
                end
            elseif Library.ActiveTab then
                table.insert(TabsToSearch, Library.ActiveTab)
            end

            local FirstVisibleTab = nil
            local ActiveHasVisible = false

            for _, Tab in ipairs(TabsToSearch) do
                local HasVisible = ApplySearchToTab(Tab, Search)
                if HasVisible then
                    if not FirstVisibleTab then
                        FirstVisibleTab = Tab
                    end
                    if Tab == Library.ActiveTab then
                        ActiveHasVisible = true
                    end
                end
            end

            if Library.GlobalSearch then
                if ActiveHasVisible and Library.ActiveTab then
                    Library.ActiveTab:RefreshSides()
                elseif FirstVisibleTab then
                    local SearchMarker = SearchText
                    task.defer(function()
                        if Library.SearchText ~= SearchMarker then
                            return
                        end

                        if Library.ActiveTab ~= FirstVisibleTab then
                            FirstVisibleTab:Show()
                        end
                    end)
                end
                Library.LastSearchTab = nil
            else
                Library.LastSearchTab = Library.ActiveTab
            end
        end

        function Library:AddToRegistry(Instance, Properties)
            Library.Registry[Instance] = Properties
        end

        function Library:RemoveFromRegistry(Instance)
            Library.Registry[Instance] = nil
        end

        function Library:UpdateColorsUsingRegistry()
            for Instance, Properties in Library.Registry do
                for Property, Index in Properties do
                    local SchemeValue = GetSchemeValue(Index)

                    if SchemeValue or typeof(Index) == "function" then
                        Instance[Property] = SchemeValue or Index()
                    end
                end
            end
        end

        function Library:SetDPIScale(DPIScale)
            Library.DPIScale = DPIScale / 100
            Library.MinSize = Library.OriginalMinSize * Library.DPIScale

            for _, UIScale in Library.Scales do
                UIScale.Scale = Library.DPIScale
            end

            for _, Option in Options do
                if Option.Type == "Dropdown" then
                    Option:RecalculateListSize()
                end
            end

            for _, Notification in Library.Notifications do
                Notification:Resize()
            end
        end

        function Library:GiveSignal(Connection)
            local ConnectionType = typeof(Connection)
            if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
                table.insert(Library.Signals, Connection)
            end

            return Connection
        end

        function IsValidCustomIcon(Icon)
            return typeof(Icon) == "string" and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
        end
        local FetchIcons, Icons = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()
        end)

        function Library:GetIcon(IconName)
            if not FetchIcons then
                return
            end

            local Success, Icon = pcall(Icons.GetAsset, IconName)
            if not Success then
                return
            end
            return Icon
        end

        function Library:GetCustomIcon(IconName)
            if not IsValidCustomIcon(IconName) then
                return Library:GetIcon(IconName)
            else
                return {
                    Url = IconName,
                    ImageRectOffset = Vector2.zero,
                    ImageRectSize = Vector2.zero,
                    Custom = true,
                }
            end
        end

        function Library:Validate(Table, Template)
            if typeof(Table) ~= "table" then
                return Template
            end

            for k, v in Template do
                if typeof(k) == "number" then
                    continue
                end

                if typeof(v) == "table" then
                    Table[k] = Library:Validate(Table[k], v)
                elseif Table[k] == nil then
                    Table[k] = v
                end
            end

            return Table
        end

        local function FillInstance(Table, Instance)
            local ThemeProperties = Library.Registry[Instance] or {}

            for key, value in Table do
                if ThemeProperties[key] then
                    ThemeProperties[key] = nil
                
                elseif key ~= "Text" then
                    local SchemeValue = GetSchemeValue(value)

                    if SchemeValue or typeof(value) == "function" then
                        ThemeProperties[key] = value
                        value = SchemeValue or value()
                    end
                end

                Instance[key] = value
            end

            if GetTableSize(ThemeProperties) > 0 then
                Library.Registry[Instance] = ThemeProperties
            end
        end

        local function New(ClassName, Properties)
            local Instance = Create(ClassName)

            if Templates[ClassName] then
                FillInstance(Templates[ClassName], Instance)
            end
            FillInstance(Properties, Instance)

            if Properties["Parent"] and not Properties["ZIndex"] then
                pcall(function()
                    Instance.ZIndex = Properties.Parent.ZIndex
                end)
            end

            return Instance
        end

        local function SafeParentUI(Instance, Parent)
            local Success, _error = pcall(function()
                if not Parent then
                    Parent = CoreGui
                end

                local DestinationParent
                if typeof(Parent) == "function" then
                    DestinationParent = Parent()
                else
                    DestinationParent = Parent
                end

                Instance.Parent = DestinationParent
            end)

            if not (Success and Instance.Parent) then
                Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
            end
        end

        local function ParentUI(UI, SkipHiddenUI)
            if SkipHiddenUI then
                SafeParentUI(UI, CoreGui)
                return
            end

            SafeParentUI(UI, gethui)
        end

        local function GetRandomString()
            local Output = ""
            for _ = 2, 25 do
                Output = Output .. string.char(math.random(1, 250))
            end
            
            return Output
        end

        local ScreenGui = New("ScreenGui", {
            Name = "ns__Obsidian|" .. GetRandomString(),
            DisplayOrder = 999,
            ResetOnSpawn = false,
        })
        ParentUI(ScreenGui)
        Library.ScreenGui = ScreenGui
        ScreenGui.DescendantRemoving:Connect(function(Instance)
            Library:RemoveFromRegistry(Instance)
        end)

        local ModalElement = New("TextButton", {
            BackgroundTransparency = 1,
            Modal = false,
            Size = UDim2.fromScale(0, 0),
            AnchorPoint = Vector2.zero,
            Text = "",
            ZIndex = -999,
            Parent = ScreenGui,
        })

        local NotificationArea
        local NotificationList
        do
            NotificationArea = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -6, 0, 6),
                Size = UDim2.new(0, 300, 1, -6),
                Parent = ScreenGui,
            })
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = NotificationArea,
                })
            )

            NotificationList = New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 8),
                Parent = NotificationArea,
            })
        end

        function Library:GetBetterColor(Color, Add)
            Add = Add * (Library.IsLightTheme and -4 or 2)
            return Color3.fromRGB(
                math.clamp(Color.R * 255 + Add, 0, 255),
                math.clamp(Color.G * 255 + Add, 0, 255),
                math.clamp(Color.B * 255 + Add, 0, 255)
            )
        end

        function Library:GetLighterColor(Color)
            local H, S, V = Color:ToHSV()
            return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
        end

        function Library:GetDarkerColor(Color)
            local H, S, V = Color:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end

        function Library:GetKeyString(KeyCode: Enum.KeyCode)
            if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
                return string.char(KeyCode.Value)
            end

            return KeyCode.Name
        end

        function Library:GetTextBounds(Text, Font: Font, Size, Width): (number, number)
            local Params = Create("GetTextBoundsParams", nil, {
                Text = Text,
                RichText = true,
                Font = Font,
                Size = Size,
                Width = Width or workspace.CurrentCamera.ViewportSize.X - 32
            })

            local Bounds = TextService:GetTextBoundsAsync(Params)
            return Bounds.X, Bounds.Y
        end

        function Library:MouseIsOverFrame(Frame, Mouse)
            local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
            return Mouse.X >= AbsPos.X
                and Mouse.X <= AbsPos.X + AbsSize.X
                and Mouse.Y >= AbsPos.Y
                and Mouse.Y <= AbsPos.Y + AbsSize.Y
        end

        function Library:SafeCallback(Func, ...)
            if not (Func and typeof(Func) == "function") then
                return
            end

            local Result = table.pack(xpcall(Func, function(Error)
                task.defer(error, debug.traceback(Error, 2))
                if Library.NotifyOnError then
                    Library:Notify(Error)
                end

                return Error
            end, ...))

            if not Result[1] then
                return nil
            end

            return table.unpack(Result, 2, Result.n)
        end

        function Library:MakeDraggable(UI, DragFrame, IgnoreToggled, IsMainWindow)
            local StartPos
            local FramePos
            local Dragging = false
            local Changed
            DragFrame.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
                    return
                end

                StartPos = Input.Position
                FramePos = UI.Position
                Dragging = true

                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState ~= Enum.UserInputState.End then
                        return
                    end

                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end
                end)
            end)
            Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
                if
                    (not IgnoreToggled and not Library.Toggled)
                    or (IsMainWindow and Library.CantDragForced)
                    or not (ScreenGui and ScreenGui.Parent)
                then
                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    return
                end

                if Dragging and IsHoverInput(Input) then
                    local Delta = Input.Position - StartPos
                    UI.Position =
                        UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
                end
            end))
        end

        function Library:MakeResizable(UI, DragFrame, Callback)
            local StartPos
            local FrameSize
            local Dragging = false
            local Changed

            DragFrame.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                StartPos = Input.Position
                FrameSize = UI.Size
                Dragging = true

                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState ~= Enum.UserInputState.End then
                        return
                    end

                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end
                end)
            end)

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
                if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    return
                end

                if Dragging and IsHoverInput(Input) then
                    local Delta = Input.Position - StartPos
                    UI.Size = UDim2.new(
                        FrameSize.X.Scale,
                        math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                        FrameSize.Y.Scale,
                        math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
                    )
                    if Callback then
                        Library:SafeCallback(Callback)
                    end
                end
            end))
        end

        function Library:MakeCover(Holder, Place)
            local Pos = Places[Place] or { 0, 0 }
            local Size = Sizes[Place] or { 1, 0.5 }

            local Cover = New("Frame", {
                AnchorPoint = Vector2.new(Pos[1], Pos[2]),
                BackgroundColor3 = Holder.BackgroundColor3,
                Position = UDim2.fromScale(Pos[1], Pos[2]),
                Size = UDim2.fromScale(Size[1], Size[2]),
                Parent = Holder,
            })

            return Cover
        end

        function Library:MakeLine(Frame, Info)
            local Line = New("Frame", {
                AnchorPoint = Info.AnchorPoint or Vector2.zero,
                BackgroundColor3 = "OutlineColor",
                Position = Info.Position,
                Size = Info.Size,
                ZIndex = Info.ZIndex or Frame.ZIndex,
                Parent = Frame,
            })

            return Line
        end

        function Library:AddOutline(Frame)
            local OutlineStroke = New("UIStroke", {
                Color = "OutlineColor",
                Thickness = 1,
                ZIndex = 2,
                Parent = Frame,
            })
            local ShadowStroke = New("UIStroke", {
                Color = "DarkColor",
                Thickness = 1.5,
                ZIndex = 1,
                Parent = Frame,
            })
            return OutlineStroke, ShadowStroke
        end

        function Library:AddBlank(Frame, Size)
            return New("Frame", {
                BackgroundTransparency = 1,
                Size = Size or UDim2.fromScale(0, 0),
                Parent = Frame,
            })
        end

        function Library:AddDraggableLabel(Text)
            local Table = {}

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromOffset(0, 0),
                Position = UDim2.fromOffset(6, 6),
                Text = Text,
                TextSize = 15,
                ZIndex = 10,
                Parent = ScreenGui,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Label,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 6),
                Parent = Label,
            })
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = Label,
                })
            )
            Library:AddOutline(Label)

            Library:MakeDraggable(Label, Label, true)

            Table.Label = Label

            function Table:SetText(Text)
                Label.Text = Text
            end

            function Table:SetVisible(Visible)
                Label.Visible = Visible
            end

            return Table
        end

        function Library:AddDraggableButton(Text, Func, ExcludeScaling)
            local Table = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(6, 6),
                TextSize = 16,
                ZIndex = 10,
                Parent = ScreenGui,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Button,
            })
            if not ExcludeScaling then
                table.insert(
                    Library.Scales,
                    New("UIScale", {
                        Parent = Button,
                    })
                )
            end
            Library:AddOutline(Button)

            Button.MouseButton1Click:Connect(function()
                Library:SafeCallback(Func, Table)
            end)
            Library:MakeDraggable(Button, Button, true)

            Table.Button = Button

            function Table:SetText(Text)
                local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

                Button.Text = Text
                Button.Size = UDim2.fromOffset(X * 2, Y * 2)
            end
            Table:SetText(Text)

            return Table
        end

        function Library:AddDraggableMenu(Name)
            local Holder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.fromOffset(0, 0),
                ZIndex = 10,
                Parent = ScreenGui,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Holder,
            })
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = Holder,
                })
            )
            Library:AddOutline(Holder)

            Library:MakeLine(Holder, {
                Position = UDim2.fromOffset(0, 34),
                Size = UDim2.new(1, 0, 0, 1),
            })

            local Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                Text = Name,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = Label,
            })

            local Container = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 35),
                Size = UDim2.new(1, 0, 1, -35),
                Parent = Holder,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 7),
                Parent = Container,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = Container,
            })

            Library:MakeDraggable(Holder, Label, true)
            return Holder, Container
        end

        local CurrentMenu
        function Library:AddContextMenu(Holder,  Size, Offset, List, ActiveCallback)
            local Menu
            if List then
                Menu = New("ScrollingFrame", {
                    AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    BackgroundColor3 = "BackgroundColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    CanvasSize = UDim2.fromOffset(0, 0),
                    ScrollBarImageColor3 = "OutlineColor",
                    ScrollBarThickness = List == 2 and 2 or 0,
                    Size = typeof(Size) == "function" and Size() or Size,
                    TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    Visible = false,
                    ZIndex = 10,
                    Parent = ScreenGui,
                })
            else
                Menu = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Size = typeof(Size) == "function" and Size() or Size,
                    Visible = false,
                    ZIndex = 10,
                    Parent = ScreenGui,
                })
            end
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = Menu,
                })
            )

            local Table = {
                Active = false,
                Holder = Holder,
                Menu = Menu,
                List = nil,
                Signal = nil,

                Size = Size,
            }

            if List then
                Table.List = New("UIListLayout", {
                    Parent = Menu,
                })
            end

            function Table:Open()
                if CurrentMenu == Table then
                    return
                elseif CurrentMenu then
                    CurrentMenu:Close()
                end

                CurrentMenu = Table
                Table.Active = true

                if typeof(Offset) == "function" then
                    Menu.Position = UDim2.fromOffset(
                        math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                        math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                    )
                else
                    Menu.Position = UDim2.fromOffset(
                        math.floor(Holder.AbsolutePosition.X + Offset[1]),
                        math.floor(Holder.AbsolutePosition.Y + Offset[2])
                    )
                end
                Menu.Size = typeof(Table.Size) == "function" and Table.Size() or Table.Size
                if typeof(ActiveCallback) == "function" then
                    Library:SafeCallback(ActiveCallback, true)
                end

                Menu.Visible = true

                Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                    if typeof(Offset) == "function" then
                        Menu.Position = UDim2.fromOffset(
                            math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                            math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                        )
                    else
                        Menu.Position = UDim2.fromOffset(
                            math.floor(Holder.AbsolutePosition.X + Offset[1]),
                            math.floor(Holder.AbsolutePosition.Y + Offset[2])
                        )
                    end
                end)
            end

            function Table:Close()
                if CurrentMenu ~= Table then
                    return
                end
                Menu.Visible = false

                if Table.Signal then
                    Table.Signal:Disconnect()
                    Table.Signal = nil
                end
                Table.Active = false
                CurrentMenu = nil
                if typeof(ActiveCallback) == "function" then
                    Library:SafeCallback(ActiveCallback, false)
                end
            end

            function Table:Toggle()
                if Table.Active then
                    Table:Close()
                else
                    Table:Open()
                end
            end

            function Table:SetSize(Size)
                Table.Size = Size
                Menu.Size = typeof(Size) == "function" and Size() or Size
            end

            return Table
        end

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if IsClickInput(Input, true) then
                local Location = Input.Position

                if
                    CurrentMenu
                    and not (
                        Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                        or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
                    )
                then
                    CurrentMenu:Close()
                end
            end
        end))

        local TooltipLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            TextSize = 14,
            TextWrapped = true,
            Visible = false,
            ZIndex = 20,
            Parent = ScreenGui,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 2),
            Parent = TooltipLabel,
        })
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = TooltipLabel,
            })
        )
        TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if Library.Unloaded then
                return
            end

            local X, _ = Library:GetTextBounds(
                TooltipLabel.Text,
                TooltipLabel.FontFace,
                TooltipLabel.TextSize,
                (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale
            )

            TooltipLabel.Size = UDim2.fromOffset(X + 8)
        end)

        local CurrentHoverInstance
        function Library:AddTooltip(InfoStr, DisabledInfoStr, HoverInstance)
            local TooltipTable = {
                Disabled = false,
                Hovering = false,
                Signals = {},
            }

            local function DoHover()
                if
                    CurrentHoverInstance == HoverInstance
                    or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
                    or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
                    or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
                then
                    return
                end
                CurrentHoverInstance = HoverInstance

                TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
                TooltipLabel.Visible = true

                while
                    Library.Toggled
                    and Library:MouseIsOverFrame(HoverInstance, Mouse)
                    and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
                do
                    TooltipLabel.Position = UDim2.fromOffset(
                        Mouse.X + 14,
                        Mouse.Y + 12
                    )

                    RunService.RenderSteppedWait()
                end

                TooltipLabel.Visible = false
                CurrentHoverInstance = nil
            end

            local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
                local ConnectionType = typeof(Connection)
                if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
                    table.insert(TooltipTable.Signals, Connection)
                end

                return Connection
            end

            GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
            GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
            GiveSignal(HoverInstance.MouseLeave:Connect(function()
                if CurrentHoverInstance ~= HoverInstance then
                    return
                end

                TooltipLabel.Visible = false
                CurrentHoverInstance = nil
            end))

            function TooltipTable:Destroy()
                for Index = #TooltipTable.Signals, 1, -1 do
                    local Connection = table.remove(TooltipTable.Signals, Index)
                    if Connection and Connection.Connected then
                        Connection:Disconnect()
                    end
                end

                if CurrentHoverInstance == HoverInstance then
                    if TooltipLabel then
                        TooltipLabel.Visible = false
                    end

                    CurrentHoverInstance = nil
                end
            end

            table.insert(Tooltips, TooltipLabel)
            return TooltipTable
        end

        function Library:OnUnload(Callback)
            table.insert(Library.UnloadSignals, Callback)
        end

        function Library:Unload()
            for Index = #Library.Signals, 1, -1 do
                local Connection = table.remove(Library.Signals, Index)
                if Connection and Connection.Connected then
                    Connection:Disconnect()
                end
            end

            for _, Callback in Library.UnloadSignals do
                Library:SafeCallback(Callback)
            end

            for _, Tooltip in Tooltips do
                Library:SafeCallback(Tooltip.Destroy, Tooltip)
            end

            Library.Unloaded = true
            ScreenGui:Destroy()
        end

        local CheckIcon = Library:GetIcon("check")
        local ArrowIcon = Library:GetIcon("chevron-up")
        local ResizeIcon = Library:GetIcon("move-diagonal-2")
        local KeyIcon = Library:GetIcon("key")
        local MoveIcon = Library:GetIcon("move")

        function Library:SetIconModule(module)
            FetchIcons = true
            Icons = module

            CheckIcon = Library:GetIcon("check")
            ArrowIcon = Library:GetIcon("chevron-up")
            ResizeIcon = Library:GetIcon("move-diagonal-2")
            KeyIcon = Library:GetIcon("key")
            MoveIcon = Library:GetIcon("move")
        end

        local BaseAddons = {}
        do
            local Funcs = {}

            function Funcs:AddKeyPicker(Idx, Info)
                Info = Library:Validate(Info, Templates.KeyPicker)

                local ParentObj = self
                local ToggleLabel = ParentObj.TextLabel

                local KeyPicker = {
                    Text = Info.Text,
                    Value = Info.Default,
                    Modifiers = Info.DefaultModifiers,
                    DisplayValue = Info.Default,

                    Toggled = false,
                    Mode = Info.Mode,
                    SyncToggleState = Info.SyncToggleState,

                    Callback = Info.Callback,
                    ChangedCallback = Info.ChangedCallback,
                    Changed = Info.Changed,
                    Clicked = Info.Clicked,

                    Type = "KeyPicker",
                }

                if KeyPicker.Mode == "Press" then
                    assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

                    KeyPicker.SyncToggleState = false
                    Info.Modes = { "Press" }
                    Info.Mode = "Press"
                end

                if KeyPicker.SyncToggleState then
                    Info.Modes = { "Toggle", "Hold" }

                    if not table.find(Info.Modes, Info.Mode) then
                        Info.Mode = "Toggle"
                    end
                end

                local Picking = false

                local SpecialKeys = {
                    ["MB1"] = Enum.UserInputType.MouseButton1,
                    ["MB2"] = Enum.UserInputType.MouseButton2,
                    ["MB3"] = Enum.UserInputType.MouseButton3,
                }

                local SpecialKeysInput = {
                    [Enum.UserInputType.MouseButton1] = "MB1",
                    [Enum.UserInputType.MouseButton2] = "MB2",
                    [Enum.UserInputType.MouseButton3] = "MB3",
                }

                local Modifiers = {
                    ["LAlt"] = Enum.KeyCode.LeftAlt,
                    ["RAlt"] = Enum.KeyCode.RightAlt,

                    ["LCtrl"] = Enum.KeyCode.LeftControl,
                    ["RCtrl"] = Enum.KeyCode.RightControl,

                    ["LShift"] = Enum.KeyCode.LeftShift,
                    ["RShift"] = Enum.KeyCode.RightShift,

                    ["Tab"] = Enum.KeyCode.Tab,
                    ["CapsLock"] = Enum.KeyCode.CapsLock,
                }

                local ModifiersInput = {
                    [Enum.KeyCode.LeftAlt] = "LAlt",
                    [Enum.KeyCode.RightAlt] = "RAlt",

                    [Enum.KeyCode.LeftControl] = "LCtrl",
                    [Enum.KeyCode.RightControl] = "RCtrl",

                    [Enum.KeyCode.LeftShift] = "LShift",
                    [Enum.KeyCode.RightShift] = "RShift",

                    [Enum.KeyCode.Tab] = "Tab",
                    [Enum.KeyCode.CapsLock] = "CapsLock",
                }

                local IsModifierInput = function(Input)
                    return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
                end

                local GetActiveModifiers = function()
                    local ActiveModifiers = {}

                    for Name, Input in Modifiers do
                        if table.find(ActiveModifiers, Name) then
                            continue
                        end
                        if not UserInputService:IsKeyDown(Input) then
                            continue
                        end

                        table.insert(ActiveModifiers, Name)
                    end

                    return ActiveModifiers
                end

                local AreModifiersHeld = function(Required)
                    if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                        return true
                    end

                    local ActiveModifiers = GetActiveModifiers()
                    local Holding = true

                    for _, Name in Required do
                        if table.find(ActiveModifiers, Name) then
                            continue
                        end

                        Holding = false
                        break
                    end

                    return Holding
                end

                local IsInputDown = function(Input)
                    if not Input then
                        return false
                    end

                    if SpecialKeysInput[Input.UserInputType] ~= nil then
                        return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                            and not UserInputService:GetFocusedTextBox()
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
                    else
                        return false
                    end
                end

                local ConvertToInputModifiers = function(CurrentModifiers)
                    local InputModifiers = {}

                    for _, name in CurrentModifiers do
                        table.insert(InputModifiers, Modifiers[name])
                    end

                    return InputModifiers
                end

                local VerifyModifiers = function(CurrentModifiers)
                    if typeof(CurrentModifiers) ~= "table" then
                        return {}
                    end

                    local ValidModifiers = {}

                    for _, name in CurrentModifiers do
                        if not Modifiers[name] then
                            continue
                        end

                        table.insert(ValidModifiers, name)
                    end

                    return ValidModifiers
                end

                KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers)

                local Picker = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Size = UDim2.fromOffset(18, 18),
                    Text = KeyPicker.Value,
                    TextSize = 14,
                    Parent = ToggleLabel,
                })

                local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
                do
                    local Holder = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 16),
                        Text = "",
                        Visible = not Info.NoUI,
                        Parent = Library.KeybindContainer,
                    })

                    local Label = New("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(0, 1),
                        Text = "",
                        TextSize = 14,
                        TextTransparency = 0.5,
                        Parent = Holder,
                    })

                    local Checkbox = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "MainColor",
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.fromOffset(14, 14),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Parent = Holder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = Checkbox,
                    })
                    New("UIStroke", {
                        Color = "OutlineColor",
                        Parent = Checkbox,
                    })

                    local CheckImage = New("ImageLabel", {
                        Image = CheckIcon and CheckIcon.Url or "",
                        ImageColor3 = "FontColor",
                        ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                        ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                        ImageTransparency = 1,
                        Position = UDim2.fromOffset(2, 2),
                        Size = UDim2.new(1, -4, 1, -4),
                        Parent = Checkbox,
                    })

                    function KeybindsToggle:Display(State)
                        Label.TextTransparency = State and 0 or 0.5
                        CheckImage.ImageTransparency = State and 0 or 1
                    end

                    function KeybindsToggle:SetText(Text)
                        Label.Text = Text
                    end

                    function KeybindsToggle:SetVisibility(Visibility)
                        Holder.Visible = Visibility
                    end

                    function KeybindsToggle:SetNormal(Normal)
                        KeybindsToggle.Normal = Normal

                        Holder.Active = not Normal
                        Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22, 0)
                        Checkbox.Visible = not Normal
                    end

                    KeyPicker.DoClick = function(...) end
                    Holder.MouseButton1Click:Connect(function()
                        if KeybindsToggle.Normal then
                            return
                        end

                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                    end)

                    KeybindsToggle.Holder = Holder
                    KeybindsToggle.Label = Label
                    KeybindsToggle.Checkbox = Checkbox
                    KeybindsToggle.Loaded = true
                    table.insert(Library.KeybindToggles, KeybindsToggle)
                end

                local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
                    return { Picker.AbsoluteSize.X + 1.5, 0.5 }
                end, 1)
                KeyPicker.Menu = MenuTable

                local ModeButtons = {}
                for _, Mode in Info.Modes do
                    local ModeButton = {}

                    local Button = New("TextButton", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 21),
                        Text = Mode,
                        TextSize = 14,
                        TextTransparency = 0.5,
                        Parent = MenuTable.Menu,
                    })

                    function ModeButton:Select()
                        for _, Button in ModeButtons do
                            Button:Deselect()
                        end

                        KeyPicker.Mode = Mode

                        Button.BackgroundTransparency = 0
                        Button.TextTransparency = 0

                        MenuTable:Close()
                    end

                    function ModeButton:Deselect()
                        KeyPicker.Mode = nil

                        Button.BackgroundTransparency = 1
                        Button.TextTransparency = 0.5
                    end

                    Button.MouseButton1Click:Connect(function()
                        ModeButton:Select()
                    end)

                    if KeyPicker.Mode == Mode then
                        ModeButton:Select()
                    end

                    ModeButtons[Mode] = ModeButton
                end

                function KeyPicker:Display(PickerText)
                    if Library.Unloaded then
                        return
                    end

                    local X, Y = Library:GetTextBounds(
                        PickerText or KeyPicker.DisplayValue,
                        Picker.FontFace,
                        Picker.TextSize,
                        ToggleLabel.AbsoluteSize.X
                    )
                    Picker.Text = PickerText or KeyPicker.DisplayValue
                    TweenService:Create(Picker, Library.BaseTweenInfo, {
                        Size = UDim2.fromOffset((X + 9), (Y + 4))
                    }):Play()
                end

                function KeyPicker:Update()
                    KeyPicker:Display()

                    if Info.NoUI then
                        return
                    end

                    if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                        KeybindsToggle:SetVisibility(false)
                        return
                    end

                    local State = KeyPicker:GetState()
                    local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

                    if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                        ParentObj:SetValue(State)
                    end

                    if KeybindsToggle.Loaded then
                        if ShowToggle then
                            KeybindsToggle:SetNormal(false)
                        else
                            KeybindsToggle:SetNormal(true)
                        end

                        KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                        KeybindsToggle:SetVisibility(true)
                        KeybindsToggle:Display(State)
                    end
                end

                function KeyPicker:GetState()
                    if KeyPicker.Mode == "Always" then
                        return true
                    elseif KeyPicker.Mode == "Hold" then
                        local Key = KeyPicker.Value
                        if Key == "None" then
                            return false
                        end

                        if not AreModifiersHeld(KeyPicker.Modifiers) then
                            return false
                        end

                        if SpecialKeys[Key] ~= nil then
                            return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                                and not UserInputService:GetFocusedTextBox()
                        else
                            return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                        end
                    else
                        return KeyPicker.Toggled
                    end
                end

                function KeyPicker:OnChanged(Func)
                    KeyPicker.Changed = Func
                end

                function KeyPicker:OnClick(Func)
                    KeyPicker.Clicked = Func
                end

                function KeyPicker:DoClick()
                    if KeyPicker.Mode == "Press" then
                        if KeyPicker.Toggled and Info.WaitForCallback == true then
                            return
                        end

                        KeyPicker.Toggled = true
                    end

                    Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
                    Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

                    if KeyPicker.Mode == "Press" then
                        KeyPicker.Toggled = false
                    end
                end

                function KeyPicker:SetValue(Data)
                    local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

                    local IsKeyValid, UserInputType = pcall(function()
                        if Key == "None" then
                            Key = nil
                            return nil
                        end

                        if SpecialKeys[Key] == nil then
                            return Enum.KeyCode[Key]
                        end

                        return SpecialKeys[Key]
                    end)

                    if Key == nil then
                        KeyPicker.Value = "None"
                    elseif IsKeyValid then
                        KeyPicker.Value = Key
                    else
                        KeyPicker.Value = "Unknown"
                    end

                    KeyPicker.Modifiers =
                        VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
                    KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                        then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                        else KeyPicker.Value

                    if ModeButtons[Mode] then
                        ModeButtons[Mode]:Select()
                    end

                    local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
                    Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
                    Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)

                    KeyPicker:Update()
                end

                function KeyPicker:SetText(Text)
                    KeybindsToggle:SetText(Text)
                    KeyPicker:Update()
                end

                Picker.MouseButton1Click:Connect(function()
                    if Picking then
                        return
                    end

                    Picking = true

                    Picker.Text = "..."
                    Picker.Size = UDim2.fromOffset(29, 18)

                    local Input
                    local ActiveModifiers = {}

                    local GetInput = function()
                        Input = UserInputService.InputBegan:Wait()
                        return UserInputService:GetFocusedTextBox() ~= nil
                    end

                    repeat task.wait()
                        Picker.Text = "..."
                        Picker.Size = UDim2.fromOffset(29, 18)

                        if GetInput() then
                            Picking = false
                            KeyPicker:Update()
                            return
                        end

                        if Input.KeyCode == Enum.KeyCode.Escape then
                            break
                        end

                        if IsModifierInput(Input) then
                            local StopLoop = false

                            repeat
                                task.wait()
                                if UserInputService:IsKeyDown(Input.KeyCode) then
                                    task.wait(0.075)

                                    if UserInputService:IsKeyDown(Input.KeyCode) then
                                        if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                            ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                            KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                        end

                                        if GetInput() then
                                            StopLoop = true
                                            break
                                        end

                                        if Input.KeyCode == Enum.KeyCode.Escape then
                                            break
                                        end

                                        if not IsModifierInput(Input) then
                                            break
                                        end
                                    else
                                        if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                            break
                                        end
                                    end
                                end
                            until false

                            if StopLoop then
                                Picking = false
                                KeyPicker:Update()
                                return
                            end
                        end

                        break
                    until false

                    local Key = "Unknown"
                    if SpecialKeysInput[Input.UserInputType] ~= nil then
                        Key = SpecialKeysInput[Input.UserInputType]
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
                    end

                    ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

                    KeyPicker.Toggled = false
                    KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

                    repeat
                        task.wait()
                    until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
                    Picking = false
                end)
                Picker.MouseButton2Click:Connect(MenuTable.Toggle)

                Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
                    if Library.Unloaded then
                        return
                    end

                    if KeyPicker.Mode == "Always"
                        or KeyPicker.Value == "Unknown"
                        or KeyPicker.Value == "None"
                        or Picking
                        or UserInputService:GetFocusedTextBox()
                    then
                        return
                    end

                    local Key = KeyPicker.Value
                    local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
                    local HoldingKey = false

                    if
                        Key
                        and HoldingModifiers == true
                        and (
                            SpecialKeysInput[Input.UserInputType] == Key
                            or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                        )
                    then
                        HoldingKey = true
                    end

                    if KeyPicker.Mode == "Toggle" then
                        if HoldingKey then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    elseif KeyPicker.Mode == "Press" then
                        if HoldingKey then
                            KeyPicker:DoClick()
                        end
                    end

                    KeyPicker:Update()
                end))

                Library:GiveSignal(UserInputService.InputEnded:Connect(function()
                    if Library.Unloaded then
                        return
                    end

                    if
                        KeyPicker.Value == "Unknown"
                        or KeyPicker.Value == "None"
                        or Picking
                        or UserInputService:GetFocusedTextBox()
                    then
                        return
                    end

                    KeyPicker:Update()
                end))

                KeyPicker:Update()

                if ParentObj.Addons then
                    table.insert(ParentObj.Addons, KeyPicker)
                end

                KeyPicker.Default = KeyPicker.Value
                KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

                Options[Idx] = KeyPicker

                return self
            end

            local HueSequenceTable = {}
            for Hue = 0, 1, 0.1 do
                table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
            end
            function Funcs:AddColorPicker(Idx, Info)
                Info = Library:Validate(Info, Templates.ColorPicker)

                local ParentObj = self
                local ToggleLabel = ParentObj.TextLabel

                local ColorPicker = {
                    Value = Info.Default,

                    Transparency = Info.Transparency or 0,
                    Title = Info.Title,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Type = "ColorPicker",
                }
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

                local Holder = New("TextButton", {
                    BackgroundColor3 = ColorPicker.Value,
                    BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
                    BorderSizePixel = 1,
                    Size = UDim2.fromOffset(18, 18),
                    Text = "",
                    Parent = ToggleLabel,
                })

                local HolderTransparency = New("ImageLabel", {
                    Image = "rbxassetid://139785960036434",
                    ImageTransparency = (1 - ColorPicker.Transparency),
                    ScaleType = Enum.ScaleType.Tile,
                    Size = UDim2.fromScale(1, 1),
                    TileSize = UDim2.fromOffset(9, 9),
                    Parent = Holder,
                })

                local ColorMenu = Library:AddContextMenu(
                    Holder,
                    UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
                    function()
                        return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
                    end,
                    1
                )
                ColorMenu.List.Padding = UDim.new(0, 8)
                ColorPicker.ColorMenu = ColorMenu

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 6),
                    Parent = ColorMenu.Menu,
                })

                if typeof(ColorPicker.Title) == "string" then
                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 8),
                        Text = ColorPicker.Title,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = ColorMenu.Menu,
                    })
                end

                local ColorHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 200),
                    Parent = ColorMenu.Menu,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 6),
                    Parent = ColorHolder,
                })

                local SatVipMap = New("ImageButton", {
                    BackgroundColor3 = ColorPicker.Value,
                    Image = "rbxassetid://4155801252",
                    Size = UDim2.fromOffset(200, 200),
                    Parent = ColorHolder,
                })

                local SatVibCursor = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "WhiteColor",
                    Size = UDim2.fromOffset(6, 6),
                    Parent = SatVipMap,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SatVibCursor,
                })
                New("UIStroke", {
                    Color = "DarkColor",
                    Parent = SatVibCursor,
                })

                local HueSelector = New("TextButton", {
                    Size = UDim2.fromOffset(16, 200),
                    Text = "",
                    Parent = ColorHolder,
                })
                New("UIGradient", {
                    Color = ColorSequence.new(HueSequenceTable),
                    Rotation = 90,
                    Parent = HueSelector,
                })

                local HueCursor = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "WhiteColor",
                    BorderColor3 = "DarkColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0.5, ColorPicker.Hue),
                    Size = UDim2.new(1, 2, 0, 1),
                    Parent = HueSelector,
                })

                local TransparencySelector, TransparencyColor, TransparencyCursor
                if Info.Transparency then
                    TransparencySelector = New("ImageButton", {
                        Image = "rbxassetid://139785960036434",
                        ScaleType = Enum.ScaleType.Tile,
                        Size = UDim2.fromOffset(16, 200),
                        TileSize = UDim2.fromOffset(8, 8),
                        Parent = ColorHolder,
                    })

                    TransparencyColor = New("Frame", {
                        BackgroundColor3 = ColorPicker.Value,
                        Size = UDim2.fromScale(1, 1),
                        Parent = TransparencySelector,
                    })
                    New("UIGradient", {
                        Rotation = 90,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Parent = TransparencyColor,
                    })

                    TransparencyCursor = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "WhiteColor",
                        BorderColor3 = "DarkColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                        Size = UDim2.new(1, 2, 0, 1),
                        Parent = TransparencySelector,
                    })
                end

                local InfoHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ColorMenu.Menu,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDim.new(0, 8),
                    Parent = InfoHolder,
                })

                local HueBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    ClearTextOnFocus = false,
                    Size = UDim2.fromScale(1, 1),
                    Text = "#??????",
                    TextSize = 14,
                    Parent = InfoHolder,
                })

                local RgbBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    ClearTextOnFocus = false,
                    Size = UDim2.fromScale(1, 1),
                    Text = "?, ?, ?",
                    TextSize = 14,
                    Parent = InfoHolder,
                })

                local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
                    return { Holder.AbsoluteSize.X + 1.5, 0.5 }
                end, 1)
                ColorPicker.ContextMenu = ContextMenu
                do
                    local function CreateButton(Text, Func)
                        local Button = New("TextButton", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 21),
                            Text = Text,
                            TextSize = 14,
                            Parent = ContextMenu.Menu,
                        })

                        Button.MouseButton1Click:Connect(function()
                            Library:SafeCallback(Func)
                            ContextMenu:Close()
                        end)
                    end

                    CreateButton("Copy color", function()
                        Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
                    end)

                    ColorPicker.SetValueRGB = function(...) end
                    CreateButton("Paste color", function()
                        ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
                    end)

                    if setclipboard then
                        CreateButton("Copy Hex", function()
                            setclipboard(tostring(ColorPicker.Value:ToHex()))
                        end)
                        CreateButton("Copy RGB", function()
                            setclipboard(table.concat({
                                math.floor(ColorPicker.Value.R * 255),
                                math.floor(ColorPicker.Value.G * 255),
                                math.floor(ColorPicker.Value.B * 255),
                            }, ", "))
                        end)
                    end
                end

                function ColorPicker:SetHSVFromRGB(Color)
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
                end

                function ColorPicker:Display()
                    if Library.Unloaded then
                        return
                    end

                    ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

                    Holder.BackgroundColor3 = ColorPicker.Value
                    Holder.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
                    HolderTransparency.ImageTransparency = (1 - ColorPicker.Transparency)

                    SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
                    if TransparencyColor then
                        TransparencyColor.BackgroundColor3 = ColorPicker.Value
                    end

                    TweenService:Create(SatVibCursor, Library.BaseTweenInfo, {
                        Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
                    }):Play()

                    TweenService:Create(HueCursor, Library.BaseTweenInfo, {
                        Position = UDim2.fromScale(0.5, ColorPicker.Hue)
                    }):Play()

                    if TransparencyCursor then
                        TweenService:Create(TransparencyCursor, Library.BaseTweenInfo, {
                            Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
                        }):Play()
                    end

                    HueBox.Text = "#" .. ColorPicker.Value:ToHex()
                    RgbBox.Text = table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", ")
                end

                function ColorPicker:Update()
                    ColorPicker:Display()

                    Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
                    Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
                end

                function ColorPicker:OnChanged(Func)
                    ColorPicker.Changed = Func
                end

                function ColorPicker:SetValue(HSV, Transparency)
                    if typeof(HSV) == "Color3" then
                        ColorPicker:SetValueRGB(HSV, Transparency)
                        return
                    end

                    local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
                    ColorPicker.Transparency = Info.Transparency and Transparency or 0
                    ColorPicker:SetHSVFromRGB(Color)
                    ColorPicker:Update()
                end

                function ColorPicker:SetValueRGB(Color, Transparency)
                    ColorPicker.Transparency = Info.Transparency and Transparency or 0
                    ColorPicker:SetHSVFromRGB(Color)
                    ColorPicker:Update()
                end

                Holder.MouseButton1Click:Connect(ColorMenu.Toggle)
                Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

                SatVipMap.InputBegan:Connect(function(Input)
                    while IsDragInput(Input) do
                        local MinX = SatVipMap.AbsolutePosition.X
                        local MaxX = MinX + SatVipMap.AbsoluteSize.X
                        local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                        local MinY = SatVipMap.AbsolutePosition.Y
                        local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                        local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                        local OldSat = ColorPicker.Sat
                        local OldVib = ColorPicker.Vib
                        ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                        ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                        if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                            ColorPicker:Update()
                        end

                        RunService.RenderSteppedWait()
                    end
                end)
                HueSelector.InputBegan:Connect(function(Input)
                    while IsDragInput(Input) do
                        local Min = HueSelector.AbsolutePosition.Y
                        local Max = Min + HueSelector.AbsoluteSize.Y
                        local Location = math.clamp(Mouse.Y, Min, Max)

                        local OldHue = ColorPicker.Hue
                        ColorPicker.Hue = (Location - Min) / (Max - Min)

                        if ColorPicker.Hue ~= OldHue then
                            ColorPicker:Update()
                        end

                        RunService.RenderSteppedWait()
                    end
                end)
                if TransparencySelector then
                    TransparencySelector.InputBegan:Connect(function(Input)
                        while IsDragInput(Input) do
                            local Min = TransparencySelector.AbsolutePosition.Y
                            local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                            local Location = math.clamp(Mouse.Y, Min, Max)

                            local OldTransparency = ColorPicker.Transparency
                            ColorPicker.Transparency = (Location - Min) / (Max - Min)

                            if ColorPicker.Transparency ~= OldTransparency then
                                ColorPicker:Update()
                            end

                            RunService.RenderSteppedWait()
                        end
                    end)
                end

                HueBox.FocusLost:Connect(function(Enter)
                    if not Enter then
                        return
                    end

                    local Success, Color = pcall(Color3.fromHex, HueBox.Text)
                    if Success and typeof(Color) == "Color3" then
                        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
                    end

                    ColorPicker:Update()
                end)
                RgbBox.FocusLost:Connect(function(Enter)
                    if not Enter then
                        return
                    end

                    local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
                    if R and G and B then
                        ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
                    end

                    ColorPicker:Update()
                end)

                ColorPicker:Display()

                if ParentObj.Addons then
                    table.insert(ParentObj.Addons, ColorPicker)
                end

                ColorPicker.Default = ColorPicker.Value

                Options[Idx] = ColorPicker

                return self
            end

            BaseAddons.__index = Funcs
            BaseAddons.__namecall = function(_, Key, ...)
                return Funcs[Key](...)
            end
        end

        local BaseGroupbox = {}
        do
            local Funcs = {}

            function Funcs:AddDivider(Text)
                local Groupbox = self
                local Container = Groupbox.Container

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.new(1, 0, 0, 0),
                    Parent = Container,
                })

                if Text then
                    local TextLabel = New("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0),
                        Text = Text,
                        TextSize = 14,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Parent = Holder,
                    })

                    local X,_ = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    local SizeX = X // 2 + 10

                    New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.new(0.5, -SizeX, 0, 2),
                        Parent = Holder,
                    })
                    New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(1, 0.5),
                        Size = UDim2.new(0.5, -SizeX, 0, 2),
                        Parent = Holder,
                    })
                else
                    New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.new(1, 0, 0, 2),
                        Parent = Holder,
                    })
                end

                Groupbox:Resize()

                table.insert(Groupbox.Elements, {
                    Holder = Holder,
                    Type = "Divider",
                })
            end

            function Funcs:AddLabel(...)
                local Data = {}
                local Addons = {}

                local First = select(1, ...)
                local Second = select(2, ...)

                if typeof(First) == "table" or typeof(Second) == "table" then
                    local Params = typeof(First) == "table" and First or Second

                    Data.Text = Params.Text or ""
                    Data.DoesWrap = Params.DoesWrap or false
                    Data.Size = Params.Size or 14
                    Data.Visible = Params.Visible or true
                    Data.Idx = typeof(Second) == "table" and First or nil
                else
                    Data.Text = First or ""
                    Data.DoesWrap = Second or false
                    Data.Size = 14
                    Data.Visible = true
                    Data.Idx = select(3, ...) or nil
                end

                local Groupbox = self
                local Container = Groupbox.Container

                local Label = {
                    Text = Data.Text,
                    DoesWrap = Data.DoesWrap,

                    Addons = Addons,

                    Visible = Data.Visible,
                    Type = "Label",
                }

                local TextLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = Label.Text,
                    TextSize = Data.Size,
                    TextWrapped = Label.DoesWrap,
                    TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
                    Parent = Container,
                })

                function Label:SetVisible(Visible)
                    Label.Visible = Visible

                    TextLabel.Visible = Label.Visible
                    Groupbox:Resize()
                end

                function Label:SetText(Text)
                    Label.Text = Text
                    TextLabel.Text = Text

                    if Label.DoesWrap then
                        local _, Y =
                            Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                        TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
                    end

                    Groupbox:Resize()
                end

                if Label.DoesWrap then
                    local _, Y =
                        Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                    local Last = TextLabel.AbsoluteSize
                    TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        if TextLabel.AbsoluteSize == Last then
                            return
                        end

                        local _, Y =
                            Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                        TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                        Last = TextLabel.AbsoluteSize
                        Groupbox:Resize()
                    end)
                else
                    New("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        Padding = UDim.new(0, 6),
                        Parent = TextLabel,
                    })
                end

                Groupbox:Resize()

                Label.TextLabel = TextLabel
                Label.Container = Container
                if not Data.DoesWrap then
                    setmetatable(Label, BaseAddons)
                end

                Label.Holder = TextLabel
                table.insert(Groupbox.Elements, Label)

                if Data.Idx then
                    Labels[Data.Idx] = Label
                else
                    table.insert(Labels, Label)
                end

                return Label
            end

            function Funcs:AddButton(...)
                local function GetInfo(...)
                    local Info = {}

                    local First = select(1, ...)
                    local Second = select(2, ...)

                    if typeof(First) == "table" or typeof(Second) == "table" then
                        local Params = typeof(First) == "table" and First or Second

                        Info.Text = Params.Text or ""
                        Info.Func = Params.Func or Params.Callback or function() end
                        Info.DoubleClick = Params.DoubleClick

                        Info.Tooltip = Params.Tooltip
                        Info.DisabledTooltip = Params.DisabledTooltip

                        Info.Risky = Params.Risky or false
                        Info.Disabled = Params.Disabled or false
                        Info.Visible = Params.Visible or true
                        Info.Idx = typeof(Second) == "table" and First or nil
                    else
                        Info.Text = First or ""
                        Info.Func = Second or function() end
                        Info.DoubleClick = false

                        Info.Tooltip = nil
                        Info.DisabledTooltip = nil

                        Info.Risky = false
                        Info.Disabled = false
                        Info.Visible = true
                        Info.Idx = select(3, ...) or nil
                    end

                    return Info
                end
                local Info = GetInfo(...)

                local Groupbox = self
                local Container = Groupbox.Container

                local Button = {
                    Text = Info.Text,
                    Func = Info.Func,
                    DoubleClick = Info.DoubleClick,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Risky = Info.Risky,
                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Tween = nil,
                    Type = "Button",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Parent = Container,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDim.new(0, 9),
                    Parent = Holder,
                })

                local function CreateButton(Button)
                    local Base = New("TextButton", {
                        Active = not Button.Disabled,
                        BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                        Size = UDim2.fromScale(1, 1),
                        Text = Button.Text,
                        TextSize = 14,
                        TextTransparency = 0.4,
                        Visible = Button.Visible,
                        Parent = Holder,
                    })

                    local Stroke = New("UIStroke", {
                        Color = "OutlineColor",
                        Transparency = Button.Disabled and 0.5 or 0,
                        Parent = Base,
                    })

                    return Base, Stroke
                end

                local function InitEvents(Button)
                    Button.Base.MouseEnter:Connect(function()
                        if Button.Disabled then
                            return
                        end

                        Button.Tween = TweenService:Create(Button.Base, Library.TabTweenInfo, {
                            TextTransparency = 0,
                        })
                        Button.Tween:Play()
                    end)
                    Button.Base.MouseLeave:Connect(function()
                        if Button.Disabled then
                            return
                        end

                        Button.Tween = TweenService:Create(Button.Base, Library.TabTweenInfo, {
                            TextTransparency = 0.4,
                        })
                        Button.Tween:Play()
                    end)

                    Button.Base.MouseButton1Click:Connect(function()
                        if Button.Disabled or Button.Locked then
                            return
                        end

                        if Button.DoubleClick then
                            Button.Locked = true

                            Button.Base.Text = "Are you sure?"
                            Button.Base.TextColor3 = Library.Scheme.AccentColor
                            Library.Registry[Button.Base].TextColor3 = "AccentColor"

                            local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                            Button.Base.Text = Button.Text
                            Button.Base.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                            Library.Registry[Button.Base].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                            if Clicked then
                                Library:SafeCallback(Button.Func)
                            end

                            RunService.RenderSteppedWait()
                            Button.Locked = false
                            return
                        end

                        Library:SafeCallback(Button.Func)
                    end)
                end

                Button.Base, Button.Stroke = CreateButton(Button)
                InitEvents(Button)

                function Button:AddButton(...)
                    local Info = GetInfo(...)

                    local SubButton = {
                        Text = Info.Text,
                        Func = Info.Func,
                        DoubleClick = Info.DoubleClick,

                        Tooltip = Info.Tooltip,
                        DisabledTooltip = Info.DisabledTooltip,
                        TooltipTable = nil,

                        Risky = Info.Risky,
                        Disabled = Info.Disabled,
                        Visible = Info.Visible,

                        Tween = nil,
                        Type = "SubButton",
                    }

                    Button.SubButton = SubButton
                    SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
                    InitEvents(SubButton)

                    function SubButton:UpdateColors()
                        if Library.Unloaded then
                            return
                        end

                        StopTween(SubButton.Tween)

                        SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                            or Library.Scheme.MainColor
                        SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                        SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                        Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                            or "MainColor"
                    end

                    function SubButton:SetDisabled(Disabled)
                        SubButton.Disabled = Disabled

                        if SubButton.TooltipTable then
                            SubButton.TooltipTable.Disabled = SubButton.Disabled
                        end

                        SubButton.Base.Active = not SubButton.Disabled
                        SubButton:UpdateColors()
                    end

                    function SubButton:SetVisible(Visible)
                        SubButton.Visible = Visible

                        SubButton.Base.Visible = SubButton.Visible
                        Groupbox:Resize()
                    end

                    function SubButton:SetText(Text)
                        SubButton.Text = Text
                        SubButton.Base.Text = Text
                    end

                    if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                        SubButton.TooltipTable =
                            Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                        SubButton.TooltipTable.Disabled = SubButton.Disabled
                    end

                    if SubButton.Risky then
                        SubButton.Base.TextColor3 = Library.Scheme.RedColor
                        Library.Registry[SubButton.Base].TextColor3 = "RedColor"
                    end

                    SubButton:UpdateColors()

                    if Info.Idx then
                        Buttons[Info.Idx] = SubButton
                    else
                        table.insert(Buttons, SubButton)
                    end

                    return SubButton
                end

                function Button:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    StopTween(Button.Tween)

                    Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                        or Library.Scheme.MainColor
                    Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
                    Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

                    Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
                end

                function Button:SetDisabled(Disabled)
                    Button.Disabled = Disabled

                    if Button.TooltipTable then
                        Button.TooltipTable.Disabled = Button.Disabled
                    end

                    Button.Base.Active = not Button.Disabled
                    Button:UpdateColors()
                end

                function Button:SetVisible(Visible)
                    Button.Visible = Visible

                    Holder.Visible = Button.Visible
                    Groupbox:Resize()
                end

                function Button:SetText(Text)
                    Button.Text = Text
                    Button.Base.Text = Text
                end

                if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
                    Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
                    Button.TooltipTable.Disabled = Button.Disabled
                end

                if Button.Risky then
                    Button.Base.TextColor3 = Library.Scheme.RedColor
                    Library.Registry[Button.Base].TextColor3 = "RedColor"
                end

                Button:UpdateColors()
                Groupbox:Resize()

                Button.Holder = Holder
                table.insert(Groupbox.Elements, Button)

                if Info.Idx then
                    Buttons[Info.Idx] = Button
                else
                    table.insert(Buttons, Button)
                end

                return Button
            end

            function Funcs:AddCheckbox(Idx, Info)
                Info = Library:Validate(Info, Templates.Toggle)

                local Groupbox = self
                local Container = Groupbox.Container

                local Toggle = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Risky = Info.Risky,
                    Disabled = Info.Disabled,
                    Visible = Info.Visible,
                    Addons = {},

                    Type = "Toggle",
                }

                local Button = New("TextButton", {
                    Active = not Toggle.Disabled,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = "",
                    Visible = Toggle.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(26, 0),
                    Size = UDim2.new(1, -26, 1, 0),
                    Text = Toggle.Text,
                    TextSize = 14,
                    TextTransparency = 0.4,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Button,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 6),
                    Parent = Label,
                })

                local Checkbox = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = Button,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Checkbox,
                })

                local CheckboxStroke = New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = Checkbox,
                })

                local CheckImage = New("ImageLabel", {
                    Image = CheckIcon and CheckIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 1,
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Checkbox,
                })

                function Toggle:UpdateColors()
                    Toggle:Display()
                end

                function Toggle:Display()
                    if Library.Unloaded then
                        return
                    end

                    CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

                    if Toggle.Disabled then
                        Label.TextTransparency = 0.8
                        CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                        Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                        Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                        return
                    end

                    TweenService:Create(Label, Library.BaseTweenInfo, {
                        TextTransparency = Toggle.Value and 0 or 0.4,
                    }):Play()
                    TweenService:Create(CheckImage, Library.BaseTweenInfo, {
                        ImageTransparency = Toggle.Value and 0 or 1,
                    }):Play()

                    Checkbox.BackgroundColor3 = Library.Scheme.MainColor
                    Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
                end

                function Toggle:OnChanged(Func)
                    Toggle.Changed = Func
                end

                function Toggle:SetValue(Value)
                    if Toggle.Disabled then
                        return
                    end

                    Toggle.Value = Value
                    Toggle:Display()

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon.Toggled = Toggle.Value
                            Addon:Update()
                        end
                    end

                    Library:UpdateDependencyBoxes()
                    Library:SafeCallback(Toggle.Callback, Toggle.Value)
                    Library:SafeCallback(Toggle.Changed, Toggle.Value)
                end

                function Toggle:SetDisabled(Disabled)
                    Toggle.Disabled = Disabled

                    if Toggle.TooltipTable then
                        Toggle.TooltipTable.Disabled = Toggle.Disabled
                    end

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon:Update()
                        end
                    end

                    Button.Active = not Toggle.Disabled
                    Toggle:Display()
                end

                function Toggle:SetVisible(Visible)
                    Toggle.Visible = Visible

                    Button.Visible = Toggle.Visible
                    Groupbox:Resize()
                end

                function Toggle:SetText(Text)
                    Toggle.Text = Text
                    Label.Text = Text
                end

                Button.MouseButton1Click:Connect(function()
                    if Toggle.Disabled then
                        return
                    end

                    Toggle:SetValue(not Toggle.Value)
                end)

                if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
                    Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
                    Toggle.TooltipTable.Disabled = Toggle.Disabled
                end

                if Toggle.Risky then
                    Label.TextColor3 = Library.Scheme.RedColor
                    Library.Registry[Label].TextColor3 = "RedColor"
                end

                Toggle:Display()
                Groupbox:Resize()

                Toggle.TextLabel = Label
                Toggle.Container = Container
                setmetatable(Toggle, BaseAddons)

                Toggle.Holder = Button
                table.insert(Groupbox.Elements, Toggle)

                Toggle.Default = Toggle.Value

                Toggles[Idx] = Toggle

                return Toggle
            end

            function Funcs:AddToggle(Idx, Info)
                if Library.ForceCheckbox then
                    return Funcs.AddCheckbox(self, Idx, Info)
                end

                Info = Library:Validate(Info, Templates.Toggle)

                local Groupbox = self
                local Container = Groupbox.Container

                local Toggle = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Risky = Info.Risky,
                    Disabled = Info.Disabled,
                    Visible = Info.Visible,
                    Addons = {},

                    Type = "Toggle",
                }

                local Button = New("TextButton", {
                    Active = not Toggle.Disabled,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = "",
                    Visible = Toggle.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -40, 1, 0),
                    Text = Toggle.Text,
                    TextSize = 14,
                    TextTransparency = 0.4,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Button,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 6),
                    Parent = Label,
                })

                local Switch = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromScale(1, 0),
                    Size = UDim2.fromOffset(32, 18),
                    Parent = Button,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = Switch,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 2),
                    PaddingLeft = UDim.new(0, 2),
                    PaddingRight = UDim.new(0, 2),
                    PaddingTop = UDim.new(0, 2),
                    Parent = Switch,
                })
                local SwitchStroke = New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = Switch,
                })

                local Ball = New("Frame", {
                    BackgroundColor3 = "FontColor",
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = Switch,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = Ball,
                })

                function Toggle:UpdateColors()
                    Toggle:Display()
                end

                function Toggle:Display()
                    if Library.Unloaded then
                        return
                    end

                    local Offset = Toggle.Value and 1 or 0

                    Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
                    SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

                    Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
                    SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

                    Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
                    Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

                    if Toggle.Disabled then
                        Label.TextTransparency = 0.8
                        Ball.AnchorPoint = Vector2.new(Offset, 0)
                        Ball.Position = UDim2.fromScale(Offset, 0)

                        Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                        Library.Registry[Ball].BackgroundColor3 = function()
                            return Library:GetDarkerColor(Library.Scheme.FontColor)
                        end

                        return
                    end

                    TweenService:Create(Label, Library.BaseTweenInfo, {
                        TextTransparency = Toggle.Value and 0 or 0.4,
                    }):Play()
                    TweenService:Create(Ball, Library.BaseTweenInfo, {
                        AnchorPoint = Vector2.new(Offset, 0),
                        Position = UDim2.fromScale(Offset, 0),
                    }):Play()

                    Ball.BackgroundColor3 = Library.Scheme.FontColor
                    Library.Registry[Ball].BackgroundColor3 = "FontColor"
                end

                function Toggle:OnChanged(Func)
                    Toggle.Changed = Func
                end

                function Toggle:SetValue(Value)
                    if Toggle.Disabled then
                        return
                    end

                    Toggle.Value = Value
                    Toggle:Display()

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon.Toggled = Toggle.Value
                            Addon:Update()
                        end
                    end

                    Library:UpdateDependencyBoxes()
                    Library:SafeCallback(Toggle.Callback, Toggle.Value)
                    Library:SafeCallback(Toggle.Changed, Toggle.Value)
                end

                function Toggle:SetDisabled(Disabled)
                    Toggle.Disabled = Disabled

                    if Toggle.TooltipTable then
                        Toggle.TooltipTable.Disabled = Toggle.Disabled
                    end

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon:Update()
                        end
                    end

                    Button.Active = not Toggle.Disabled
                    Toggle:Display()
                end

                function Toggle:SetVisible(Visible)
                    Toggle.Visible = Visible

                    Button.Visible = Toggle.Visible
                    Groupbox:Resize()
                end

                function Toggle:SetText(Text)
                    Toggle.Text = Text
                    Label.Text = Text
                end

                Button.MouseButton1Click:Connect(function()
                    if Toggle.Disabled then
                        return
                    end

                    Toggle:SetValue(not Toggle.Value)
                end)

                if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
                    Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
                    Toggle.TooltipTable.Disabled = Toggle.Disabled
                end

                if Toggle.Risky then
                    Label.TextColor3 = Library.Scheme.RedColor
                    Library.Registry[Label].TextColor3 = "RedColor"
                end

                Toggle:Display()
                Groupbox:Resize()

                Toggle.TextLabel = Label
                Toggle.Container = Container
                setmetatable(Toggle, BaseAddons)

                Toggle.Holder = Button
                table.insert(Groupbox.Elements, Toggle)

                Toggle.Default = Toggle.Value

                Toggles[Idx] = Toggle

                return Toggle
            end

            function Funcs:AddInput(Idx, Info)
                Info = Library:Validate(Info, Templates.Input)

                local Groupbox = self
                local Container = Groupbox.Container

                local Input = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Finished = Info.Finished,
                    Numeric = Info.Numeric,
                    ClearTextOnFocus = Info.ClearTextOnFocus,
                    Placeholder = Info.Placeholder,
                    AllowEmpty = Info.AllowEmpty,
                    EmptyReset = Info.EmptyReset,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Type = "Input",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 39),
                    Visible = Input.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = Input.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                local Box = New("TextBox", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
                    PlaceholderText = Input.Placeholder,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Input.Value,
                    TextEditable = not Input.Disabled,
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                function Input:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    Label.TextTransparency = Input.Disabled and 0.8 or 0
                    Box.TextTransparency = Input.Disabled and 0.8 or 0
                end

                function Input:OnChanged(Func)
                    Input.Changed = Func
                end

                function Input:SetValue(Text)
                    if not Input.AllowEmpty and Trim(Text) == "" then
                        Text = Input.EmptyReset
                    end

                    if Info.MaxLength and #Text > Info.MaxLength then
                        Text = Text:sub(1, Info.MaxLength)
                    end

                    if Input.Numeric then
                        if #tostring(Text) > 0 and not tonumber(Text) then
                            Text = Input.Value
                        end
                    end

                    Input.Value = Text
                    Box.Text = Text

                    if not Input.Disabled then
                        Library:SafeCallback(Input.Callback, Input.Value)
                        Library:SafeCallback(Input.Changed, Input.Value)
                    end
                end

                function Input:SetDisabled(Disabled)
                    Input.Disabled = Disabled

                    if Input.TooltipTable then
                        Input.TooltipTable.Disabled = Input.Disabled
                    end

                    Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
                    Box.TextEditable = not Input.Disabled
                    Input:UpdateColors()
                end

                function Input:SetVisible(Visible)
                    Input.Visible = Visible

                    Holder.Visible = Input.Visible
                    Groupbox:Resize()
                end

                function Input:SetText(Text)
                    Input.Text = Text
                    Label.Text = Text
                end

                if Input.Finished then
                    Box.FocusLost:Connect(function(Enter)
                        if not Enter then
                            return
                        end

                        Input:SetValue(Box.Text)
                    end)
                else
                    Box:GetPropertyChangedSignal("Text"):Connect(function()
                        if Box.Text == Input.Value then
                            return
                        end

                        Input:SetValue(Box.Text)
                    end)
                end

                if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
                    Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
                    Input.TooltipTable.Disabled = Input.Disabled
                end

                Groupbox:Resize()

                Input.Holder = Holder
                table.insert(Groupbox.Elements, Input)

                Input.Default = Input.Value

                Options[Idx] = Input

                return Input
            end

            function Funcs:AddSlider(Idx, Info)
                Info = Library:Validate(Info, Templates.Slider)

                local Groupbox = self
                local Container = Groupbox.Container

                local Slider = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Min = Info.Min,
                    Max = Info.Max,

                    Prefix = Info.Prefix,
                    Suffix = Info.Suffix,
                    Compact = Info.Compact,
                    Rounding = Info.Rounding,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Type = "Slider",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Compact and 13 or 31),
                    Visible = Slider.Visible,
                    Parent = Container,
                })

                local SliderLabel
                if not Info.Compact then
                    SliderLabel = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Text = Slider.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = Holder,
                    })
                end

                local Bar = New("TextButton", {
                    Active = not Slider.Disabled,
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 13),
                    Text = "",
                    Parent = Holder,
                })

                local DisplayLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    TextSize = 14,
                    ZIndex = 2,
                    Parent = Bar,
                })
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    Color = "DarkColor",
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    Parent = DisplayLabel,
                })

                local Fill = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    Size = UDim2.fromScale(0.5, 1),
                    Parent = Bar,
                })

                function Slider:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    if SliderLabel then
                        SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
                    end
                    DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

                    Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
                    Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
                end

                function Slider:Display()
                    if Library.Unloaded then
                        return
                    end

                    local CustomDisplayText = nil
                    if Info.FormatDisplayValue then
                        CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
                    end

                    if CustomDisplayText then
                        DisplayLabel.Text = tostring(CustomDisplayText)
                    else
                        if Info.Compact then
                            DisplayLabel.Text =
                                string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                        elseif Info.HideMax then
                            DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                        else
                            DisplayLabel.Text = string.format(
                                "%s%s%s/%s%s%s",
                                Slider.Prefix,
                                Slider.Value,
                                Slider.Suffix,
                                Slider.Prefix,
                                Slider.Max,
                                Slider.Suffix
                            )
                        end
                    end

                    local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                    TweenService:Create(Fill, Library.SliderTweenInfo, {
                        Size = UDim2.fromScale(X, 1)
                    }):Play()
                end

                function Slider:OnChanged(Func)
                    Slider.Changed = Func
                end

                function Slider:SetMax(Value)
                    assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

                    Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
                    Slider.Max = Value
                    Slider:Display()
                end

                function Slider:SetMin(Value)
                    assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

                    Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
                    Slider.Min = Value
                    Slider:Display()
                end

                function Slider:SetValue(Str)
                    if Slider.Disabled then
                        return
                    end

                    local Num = tonumber(Str)
                    if not Num or Num == Slider.Value then
                        return
                    end

                    Num = math.clamp(Num, Slider.Min, Slider.Max)

                    Slider.Value = Num
                    Slider:Display()

                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                function Slider:SetDisabled(Disabled)
                    Slider.Disabled = Disabled

                    if Slider.TooltipTable then
                        Slider.TooltipTable.Disabled = Slider.Disabled
                    end

                    Bar.Active = not Slider.Disabled
                    Slider:UpdateColors()
                end

                function Slider:SetVisible(Visible)
                    Slider.Visible = Visible

                    Holder.Visible = Slider.Visible
                    Groupbox:Resize()
                end

                function Slider:SetText(Text)
                    Slider.Text = Text
                    if SliderLabel then
                        SliderLabel.Text = Text
                        return
                    end
                    Slider:Display()
                end

                function Slider:SetPrefix(Prefix)
                    Slider.Prefix = Prefix
                    Slider:Display()
                end

                function Slider:SetSuffix(Suffix)
                    Slider.Suffix = Suffix
                    Slider:Display()
                end

                Bar.InputBegan:Connect(function(Input)
                    if not IsClickInput(Input) or Slider.Disabled then
                        return
                    end

                    for _, Side in Library.ActiveTab.Sides do
                        Side.ScrollingEnabled = false
                    end

                    while IsDragInput(Input) do
                        local Location = Mouse.X
                        local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                        local OldValue = Slider.Value
                        Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                        Slider:Display()
                        if Slider.Value ~= OldValue then
                            Library:SafeCallback(Slider.Callback, Slider.Value)
                            Library:SafeCallback(Slider.Changed, Slider.Value)
                        end

                        RunService.RenderSteppedWait()
                    end

                    for _, Side in Library.ActiveTab.Sides do
                        Side.ScrollingEnabled = true
                    end
                end)

                if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
                    Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
                    Slider.TooltipTable.Disabled = Slider.Disabled
                end

                Slider:UpdateColors()
                Slider:Display()
                Groupbox:Resize()

                Slider.Holder = Holder
                table.insert(Groupbox.Elements, Slider)

                Slider.Default = Slider.Value

                Options[Idx] = Slider

                return Slider
            end

            function Funcs:AddDropdown(Idx, Info)
                Info = Library:Validate(Info, Templates.Dropdown)

                local Groupbox = self
                local Container = Groupbox.Container

                if Info.SpecialType == "Player" then
                    Info.Values = GetPlayers()
                    Info.AllowNull = true
                end

                local Dropdown = {
                    Text = typeof(Info.Text) == "string" and Info.Text or nil,
                    Value = Info.Multi and {} or nil,
                    Values = Info.Values,
                    DisabledValues = Info.DisabledValues,
                    Multi = Info.Multi,

                    SpecialType = Info.SpecialType,
                    ExcludeLocalPlayer = Info.ExcludeLocalPlayer,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Type = "Dropdown",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Dropdown.Text and 39 or 21),
                    Visible = Dropdown.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = Dropdown.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Visible = not not Info.Text,
                    Parent = Holder,
                })

                local Display = New("TextButton", {
                    Active = not Dropdown.Disabled,
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = "---",
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 4),
                    Parent = Display,
                })

                local ArrowImage = New("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Image = ArrowIcon and ArrowIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromScale(1, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = Display,
                })

                local SearchBox
                if Info.Searchable then
                    SearchBox = New("TextBox", {
                        BackgroundTransparency = 1,
                        PlaceholderText = "Search...",
                        Position = UDim2.fromOffset(-8, 0),
                        Size = UDim2.new(1, -12, 1, 0),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Visible = false,
                        Parent = Display,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        Parent = SearchBox,
                    })
                end

                local MenuTable = Library:AddContextMenu(
                    Display,
                    function()
                        return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, 0)
                    end,
                    function()
                        return { 0.5, Display.AbsoluteSize.Y + 1.5 }
                    end,
                    2,
                    function(Active)
                        Display.TextTransparency = (Active and SearchBox) and 1 or 0
                        ArrowImage.ImageTransparency = Active and 0 or 0.5
                        ArrowImage.Rotation = Active and 180 or 0
                        if SearchBox then
                            SearchBox.Text = ""
                            SearchBox.Visible = Active
                        end
                    end
                )
                Dropdown.Menu = MenuTable

                function Dropdown:RecalculateListSize(Count)
                    local Y = math.clamp((Count or GetTableSize(Dropdown.Values)) * 21, 0, Info.MaxVisibleDropdownItems * 21)

                    MenuTable:SetSize(function()
                        return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, Y)
                    end)
                end

                function Dropdown:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
                    Display.TextTransparency = Dropdown.Disabled and 0.8 or 0
                    ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
                end

                function Dropdown:Display()
                    if Library.Unloaded then
                        return
                    end

                    local Str = ""

                    if Info.Multi then
                        for _, Value in Dropdown.Values do
                            if Dropdown.Value[Value] then
                                Str = Str .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value)) .. ", "
                            end
                        end

                        Str = Str:sub(1, #Str - 2)
                    else
                        Str = Dropdown.Value and tostring(Dropdown.Value) or ""
                        if Str ~= "" and Info.FormatDisplayValue then
                            Str = tostring(Info.FormatDisplayValue(Str))
                        end
                    end

                    if #Str > 25 then
                        Str = Str:sub(1, 22) .. "..."
                    end

                    Display.Text = (Str == "" and "---" or Str)
                end

                function Dropdown:OnChanged(Func)
                    Dropdown.Changed = Func
                end

                function Dropdown:GetActiveValues()
                    if Info.Multi then
                        local Table = {}

                        for Value,_ in Dropdown.Value do
                            table.insert(Table, Value)
                        end

                        return Table
                    end

                    return Dropdown.Value and 1 or 0
                end

                local Buttons = {}
                function Dropdown:BuildDropdownList()
                    local Values = Dropdown.Values
                    local DisabledValues = Dropdown.DisabledValues

                    for Button, _ in Buttons do
                        Button:Destroy()
                    end
                    table.clear(Buttons)

                    local Count = 0
                    for _, Value in Values do
                        if SearchBox and not tostring(Value):lower():match(SearchBox.Text:lower()) then
                            continue
                        end

                        Count += 1
                        local IsDisabled = table.find(DisabledValues, Value)
                        local Table = {}

                        local Button = New("TextButton", {
                            BackgroundColor3 = "MainColor",
                            BackgroundTransparency = 1,
                            LayoutOrder = IsDisabled and 1 or 0,
                            Size = UDim2.new(1, 0, 0, 21),
                            Text = tostring(Value),
                            TextSize = 14,
                            TextTransparency = 0.5,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = MenuTable.Menu,
                        })
                        New("UIPadding", {
                            PaddingLeft = UDim.new(0, 7),
                            PaddingRight = UDim.new(0, 7),
                            Parent = Button,
                        })

                        local Selected
                        if Info.Multi then
                            Selected = Dropdown.Value[Value]
                        else
                            Selected = Dropdown.Value == Value
                        end

                        function Table:UpdateButton()
                            if Info.Multi then
                                Selected = Dropdown.Value[Value]
                            else
                                Selected = Dropdown.Value == Value
                            end

                            Button.BackgroundTransparency = Selected and 0 or 1
                            Button.TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.5
                        end

                        if not IsDisabled then
                            Button.MouseButton1Click:Connect(function()
                                local Try = not Selected

                                if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                                    Selected = Try
                                    if Info.Multi then
                                        Dropdown.Value[Value] = Selected and true or nil
                                    else
                                        Dropdown.Value = Selected and Value or nil
                                    end

                                    for _, OtherButton in Buttons do
                                        OtherButton:UpdateButton()
                                    end
                                end

                                Table:UpdateButton()
                                Dropdown:Display()

                                Library:UpdateDependencyBoxes()
                                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                            end)
                        end

                        Table:UpdateButton()
                        Dropdown:Display()

                        Buttons[Button] = Table
                    end

                    Dropdown:RecalculateListSize(Count)
                end

                function Dropdown:SetValue(Value)
                    if Info.Multi then
                        local Table = {}

                        for Val, Active in Value or {} do
                            if typeof(Active) ~= "boolean" then
                                Table[Active] = true
                            elseif Active and table.find(Dropdown.Values, Val) then
                                Table[Val] = true
                            end
                        end

                        Dropdown.Value = Table
                    else
                        if table.find(Dropdown.Values, Value) then
                            Dropdown.Value = Value
                        elseif not Value then
                            Dropdown.Value = nil
                        end
                    end

                    Dropdown:Display()
                    for _, Button in Buttons do
                        Button:UpdateButton()
                    end

                    if not Dropdown.Disabled then
                        Library:UpdateDependencyBoxes()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                    end
                end

                function Dropdown:SetValues(Values)
                    Dropdown.Values = Values
                    Dropdown:BuildDropdownList()
                end

                function Dropdown:AddValues(Values)
                    if typeof(Values) == "table" then
                        for _, val in Values do
                            table.insert(Dropdown.Values, val)
                        end
                    elseif typeof(Values) == "string" then
                        table.insert(Dropdown.Values, Values)
                    else
                        return
                    end

                    Dropdown:BuildDropdownList()
                end

                function Dropdown:SetDisabledValues(DisabledValues)
                    Dropdown.DisabledValues = DisabledValues
                    Dropdown:BuildDropdownList()
                end

                function Dropdown:AddDisabledValues(DisabledValues)
                    if typeof(DisabledValues) == "table" then
                        for _, val in DisabledValues do
                            table.insert(Dropdown.DisabledValues, val)
                        end
                    elseif typeof(DisabledValues) == "string" then
                        table.insert(Dropdown.DisabledValues, DisabledValues)
                    else
                        return
                    end

                    Dropdown:BuildDropdownList()
                end

                function Dropdown:SetDisabled(Disabled)
                    Dropdown.Disabled = Disabled

                    if Dropdown.TooltipTable then
                        Dropdown.TooltipTable.Disabled = Dropdown.Disabled
                    end

                    MenuTable:Close()
                    Display.Active = not Dropdown.Disabled
                    Dropdown:UpdateColors()
                end

                function Dropdown:SetVisible(Visible)
                    Dropdown.Visible = Visible

                    Holder.Visible = Dropdown.Visible
                    Groupbox:Resize()
                end

                function Dropdown:SetText(Text)
                    Dropdown.Text = Text
                    Holder.Size = UDim2.new(1, 0, 0, Text and 39 or 21)

                    Label.Text = Text and Text or ""
                    Label.Visible = not not Text
                end

                Display.MouseButton1Click:Connect(function()
                    if Dropdown.Disabled then
                        return
                    end

                    MenuTable:Toggle()
                end)

                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
                end

                local Defaults = {}
                if typeof(Info.Default) == "string" then
                    local Index = table.find(Dropdown.Values, Info.Default)
                    if Index then
                        table.insert(Defaults, Index)
                    end
                elseif typeof(Info.Default) == "table" then
                    for _, Value in next, Info.Default do
                        local Index = table.find(Dropdown.Values, Value)
                        if Index then
                            table.insert(Defaults, Index)
                        end
                    end
                elseif Dropdown.Values[Info.Default] ~= nil then
                    table.insert(Defaults, Info.Default)
                end

                if next(Defaults) then
                    for i = 1, #Defaults do
                        local Index = Defaults[i]
                        if Info.Multi then
                            Dropdown.Value[Dropdown.Values[Index]] = true
                        else
                            Dropdown.Value = Dropdown.Values[Index]
                        end

                        if not Info.Multi then
                            break
                        end
                    end
                end

                if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
                    Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
                    Dropdown.TooltipTable.Disabled = Dropdown.Disabled
                end

                Dropdown:UpdateColors()
                Dropdown:Display()
                Dropdown:BuildDropdownList()
                Groupbox:Resize()

                Dropdown.Holder = Holder
                table.insert(Groupbox.Elements, Dropdown)

                Dropdown.Default = Defaults
                Dropdown.DefaultValues = Dropdown.Values

                Options[Idx] = Dropdown

                return Dropdown
            end

            function Funcs:AddViewport(Idx, Info)
                Info = Library:Validate(Info, Templates.Viewport)

                local Groupbox = self
                local Container = Groupbox.Container

                local Dragging, Pinching = false, false
                local LastMousePos, LastPinchDist = nil, 0

                local ViewportObject = Info.Object
                if Info.Clone and typeof(Info.Object) == "Instance" then
                    if Info.Object.Archivable then
                        ViewportObject = ViewportObject:Clone()
                    else
                        Info.Object.Archivable = true
                        ViewportObject = ViewportObject:Clone()
                        Info.Object.Archivable = false
                    end
                end

                local Viewport = {
                    Object = ViewportObject,
                    Camera = if not Info.Camera then
                        Create("Camera")
                    else Info.Camera,
                    Interactive = Info.Interactive,
                    AutoFocus = Info.AutoFocus,
                    Visible = Info.Visible,
                    Type = "Viewport",
                }

                assert(
                    typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
                    "Instance must be a BasePart or Model."
                )

                assert(
                    typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
                    "Camera must be a valid Camera instance."
                )

                local function GetModelSize(model)
                    if model:IsA("BasePart") then
                        return model.Size
                    end

                    return select(2, model:GetBoundingBox())
                end

                local function FocusCamera()
                    local ModelSize = GetModelSize(Viewport.Object)
                    local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
                    local CameraDistance = MaxExtent * 2
                    local ModelPosition = Viewport.Object:GetPivot().Position

                    Viewport.Camera.CFrame =
                        CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
                end

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Viewport.Visible,
                    Parent = Container,
                })

                local Box = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 1),
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                local ViewportFrame = New("ViewportFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Parent = Box,
                    CurrentCamera = Viewport.Camera,
                    Active = Viewport.Interactive,
                })

                ViewportFrame.MouseEnter:Connect(function()
                    if not Viewport.Interactive then
                        return
                    end

                    for _, Side in Groupbox.Tab.Sides do
                        Side.ScrollingEnabled = false
                    end
                end)

                ViewportFrame.MouseLeave:Connect(function()
                    if not Viewport.Interactive then
                        return
                    end

                    for _, Side in Groupbox.Tab.Sides do
                        Side.ScrollingEnabled = true
                    end
                end)

                ViewportFrame.InputBegan:Connect(function(input)
                    if not Viewport.Interactive then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Dragging = true
                        LastMousePos = input.Position
                    elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                        Dragging = true
                        LastMousePos = input.Position
                    end
                end)

                Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                    if Library.Unloaded then
                        return
                    end

                    if not Viewport.Interactive then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Dragging = false
                    elseif input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = false
                    end
                end))

                Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                    if Library.Unloaded then
                        return
                    end

                    if not Viewport.Interactive or not Dragging or Pinching then
                        return
                    end

                    if
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        local MouseDelta = input.Position - LastMousePos
                        LastMousePos = input.Position

                        local Position = Viewport.Object:GetPivot().Position
                        local Camera = Viewport.Camera

                        local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                        Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                        local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                        local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                        if PitchedCFrame.UpVector.Y > 0.1 then
                            Camera.CFrame = PitchedCFrame
                        end
                    end
                end))

                ViewportFrame.InputChanged:Connect(function(input)
                    if not Viewport.Interactive then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseWheel then
                        local ZoomAmount = input.Position.Z * 2
                        Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
                    end
                end)

                Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
                    if Library.Unloaded then
                        return
                    end

                    if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                        return
                    end

                    if state == Enum.UserInputState.Begin then
                        Pinching = true
                        Dragging = false
                        LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
                    elseif state == Enum.UserInputState.Change then
                        local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                        local delta = (currentDist - LastPinchDist) * 0.1
                        LastPinchDist = currentDist
                        Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
                    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                        Pinching = false
                    end
                end))

                Viewport.Object.Parent = ViewportFrame
                if Viewport.AutoFocus then
                    FocusCamera()
                end

                function Viewport:SetObject(Object, Clone)
                    assert(Object, "Object cannot be nil.")

                    if Clone then
                        Object = Object:Clone()
                    end

                    if Viewport.Object then
                        Viewport.Object:Destroy()
                    end

                    Viewport.Object = Object
                    Viewport.Object.Parent = ViewportFrame

                    Groupbox:Resize()
                end

                function Viewport:SetHeight(Height)
                    assert(Height > 0, "Height must be greater than 0.")

                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Viewport:Focus()
                    if not Viewport.Object then
                        return
                    end

                    FocusCamera()
                end

                function Viewport:SetCamera(Camera)
                    assert(
                        Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                        "Camera must be a valid Camera instance."
                    )

                    Viewport.Camera = Camera
                    ViewportFrame.CurrentCamera = Camera
                end

                function Viewport:SetInteractive(Interactive)
                    Viewport.Interactive = Interactive
                    ViewportFrame.Active = Interactive
                end

                function Viewport:SetVisible(Visible)
                    Viewport.Visible = Visible

                    Holder.Visible = Viewport.Visible
                    Groupbox:Resize()
                end

                Groupbox:Resize()

                Viewport.Holder = Holder
                table.insert(Groupbox.Elements, Viewport)

                Options[Idx] = Viewport

                return Viewport
            end

            function Funcs:AddImage(Idx, Info)
                Info = Library:Validate(Info, Templates.Image)

                local Groupbox = self
                local Container = Groupbox.Container

                local Image = {
                    Image = Info.Image,
                    Color = Info.Color,
                    RectOffset = Info.RectOffset,
                    RectSize = Info.RectSize,
                    Height = Info.Height,
                    ScaleType = Info.ScaleType,
                    Transparency = Info.Transparency,
                    BackgroundTransparency = Info.BackgroundTransparency,

                    Visible = Info.Visible,
                    Type = "Image",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Image.Visible,
                    Parent = Container,
                })

                local Box = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    BackgroundTransparency = Image.BackgroundTransparency,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 1),
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                local ImageProperties = {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Image = Image.Image,
                    ImageTransparency = Image.Transparency,
                    ImageColor3 = Image.Color,
                    ImageRectOffset = Image.RectOffset,
                    ImageRectSize = Image.RectSize,
                    ScaleType = Image.ScaleType,
                    Parent = Box,
                }

                local Icon = Library:GetCustomIcon(ImageProperties.Image)
                assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

                ImageProperties.Image = Icon.Url
                ImageProperties.ImageRectOffset = Icon.ImageRectOffset
                ImageProperties.ImageRectSize = Icon.ImageRectSize

                local ImageLabel = New("ImageLabel", ImageProperties)

                function Image:SetHeight(Height)
                    assert(Height > 0, "Height must be greater than 0.")

                    Image.Height = Height
                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Image:SetImage(NewImage)
                    assert(typeof(NewImage) == "string", "Image must be a string.")

                    local Icon = Library:GetCustomIcon(NewImage)
                    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

                    NewImage = Icon.Url
                    Image.RectOffset = Icon.ImageRectOffset
                    Image.RectSize = Icon.ImageRectSize

                    ImageLabel.Image = NewImage
                    Image.Image = NewImage
                end

                function Image:SetColor(Color)
                    assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

                    ImageLabel.ImageColor3 = Color
                    Image.Color = Color
                end

                function Image:SetRectOffset(RectOffset)
                    assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

                    ImageLabel.ImageRectOffset = RectOffset
                    Image.RectOffset = RectOffset
                end

                function Image:SetRectSize(RectSize)
                    assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

                    ImageLabel.ImageRectSize = RectSize
                    Image.RectSize = RectSize
                end

                function Image:SetScaleType(ScaleType: Enum.ScaleType)
                    assert(
                        typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                        "ScaleType must be a valid Enum.ScaleType."
                    )

                    ImageLabel.ScaleType = ScaleType
                    Image.ScaleType = ScaleType
                end

                function Image:SetTransparency(Transparency)
                    assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
                    assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

                    ImageLabel.ImageTransparency = Transparency
                    Image.Transparency = Transparency
                end

                function Image:SetVisible(Visible)
                    Image.Visible = Visible

                    Holder.Visible = Image.Visible
                    Groupbox:Resize()
                end

                Groupbox:Resize()

                Image.Holder = Holder
                table.insert(Groupbox.Elements, Image)

                Options[Idx] = Image

                return Image
            end

            function Funcs:AddVideo(Idx, Info)
                Info = Library:Validate(Info, Templates.Video)

                local Groupbox = self
                local Container = Groupbox.Container

                local Video = {
                    Video = Info.Video,
                    Looped = Info.Looped,
                    Playing = Info.Playing,
                    Volume = Info.Volume,
                    Height = Info.Height,
                    Visible = Info.Visible,

                    Type = "Video",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Video.Visible,
                    Parent = Container,
                })

                local Box = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 1),
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                local VideoFrameInstance = New("VideoFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Video = Video.Video,
                    Looped = Video.Looped,
                    Volume = Video.Volume,
                    Parent = Box,
                })

                VideoFrameInstance.Playing = Video.Playing

                function Video:SetHeight(Height)
                    assert(Height > 0, "Height must be greater than 0.")

                    Video.Height = Height
                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Video:SetVideo(NewVideo)
                    assert(typeof(NewVideo) == "string", "Video must be a string.")

                    VideoFrameInstance.Video = NewVideo
                    Video.Video = NewVideo
                end

                function Video:SetLooped(Looped)
                    assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

                    VideoFrameInstance.Looped = Looped
                    Video.Looped = Looped
                end

                function Video:SetVolume(Volume)
                    assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

                    VideoFrameInstance.Volume = Volume
                    Video.Volume = Volume
                end

                function Video:SetPlaying(Playing)
                    assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

                    VideoFrameInstance.Playing = Playing
                    Video.Playing = Playing
                end

                function Video:Play()
                    VideoFrameInstance.Playing = true
                    Video.Playing = true
                end

                function Video:Pause()
                    VideoFrameInstance.Playing = false
                    Video.Playing = false
                end

                function Video:SetVisible(Visible)
                    Video.Visible = Visible

                    Holder.Visible = Video.Visible
                    Groupbox:Resize()
                end

                Groupbox:Resize()

                Video.Holder = Holder
                Video.VideoFrame = VideoFrameInstance
                table.insert(Groupbox.Elements, Video)

                Options[Idx] = Video

                return Video
            end

            function Funcs:AddUIPassthrough(Idx, Info)
                Info = Library:Validate(Info, Templates.UIPassthrough)

                local Groupbox = self
                local Container = Groupbox.Container

                assert(Info.Instance, "Instance must be provided.")
                assert(
                    typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
                    "Instance must inherit from GuiBase2d."
                )
                assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

                local Passthrough = {
                    Instance = Info.Instance,
                    Height = Info.Height,
                    Visible = Info.Visible,

                    Type = "UIPassthrough",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Passthrough.Visible,
                    Parent = Container,
                })

                Passthrough.Instance.Parent = Holder

                Groupbox:Resize()

                function Passthrough:SetHeight(Height)
                    assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

                    Passthrough.Height = Height
                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Passthrough:SetInstance(Instance)
                    assert(Instance, "Instance must be provided.")
                    assert(
                        typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                        "Instance must inherit from GuiBase2d."
                    )

                    if Passthrough.Instance then
                        Passthrough.Instance.Parent = nil
                    end

                    Passthrough.Instance = Instance
                    Passthrough.Instance.Parent = Holder
                end

                function Passthrough:SetVisible(Visible)
                    Passthrough.Visible = Visible

                    Holder.Visible = Passthrough.Visible
                    Groupbox:Resize()
                end

                Passthrough.Holder = Holder
                table.insert(Groupbox.Elements, Passthrough)

                Options[Idx] = Passthrough

                return Passthrough
            end

            function Funcs:AddDependencyBox()
                local Groupbox = self
                local Container = Groupbox.Container

                local DepboxContainer
                local DepboxList

                do
                    DepboxContainer = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Visible = false,
                        Parent = Container,
                    })

                    DepboxList = New("UIListLayout", {
                        Padding = UDim.new(0, 8),
                        Parent = DepboxContainer,
                    })
                end

                local Depbox = {
                    Visible = false,
                    Dependencies = {},

                    Holder = DepboxContainer,
                    Container = DepboxContainer,

                    Elements = {},
                    DependencyBoxes = {},
                }

                function Depbox:Resize()
                    DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y / Library.DPIScale)
                    Groupbox:Resize()
                end

                function Depbox:Update(CancelSearch)
                    for _, Dependency in Depbox.Dependencies do
                        local Element = Dependency[1]
                        local Value = Dependency[2]

                        if Element.Type == "Toggle" and Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        elseif Element.Type == "Dropdown" then
                            if typeof(Element.Value) == "table" then
                                if not Element.Value[Value] then
                                    DepboxContainer.Visible = false
                                    Depbox.Visible = false
                                    return
                                end
                            else
                                if Element.Value ~= Value then
                                    DepboxContainer.Visible = false
                                    Depbox.Visible = false
                                    return
                                end
                            end
                        end
                    end

                    Depbox.Visible = true
                    DepboxContainer.Visible = true
                    if not Library.Searching then
                        task.defer(function()
                            Depbox:Resize()
                        end)
                    elseif not CancelSearch then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if not Depbox.Visible then
                        return
                    end

                    Depbox:Resize()
                end)

                function Depbox:SetupDependencies(Dependencies)
                    for _, Dependency in Dependencies do
                        assert(typeof(Dependency) == "table", "Dependency should be a table.")
                        assert(Dependency[1] ~= nil, "Dependency is missing element.")
                        assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
                    end

                    Depbox.Dependencies = Dependencies
                    Depbox:Update()
                end

                DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
                    Depbox:Resize()
                end)

                setmetatable(Depbox, BaseGroupbox)

                table.insert(Groupbox.DependencyBoxes, Depbox)
                table.insert(Library.DependencyBoxes, Depbox)

                return Depbox
            end

            function Funcs:AddDependencyGroupbox()
                local Groupbox = self
                local Tab = Groupbox.Tab
                local BoxHolder = Groupbox.BoxHolder

                local DepGroupboxContainer
                local DepGroupboxList

                do
                    DepGroupboxContainer = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.fromScale(1, 0),
                        Visible = false,
                        Parent = BoxHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius),
                        Parent = DepGroupboxContainer,
                    })
                    Library:AddOutline(DepGroupboxContainer)

                    DepGroupboxList = New("UIListLayout", {
                        Padding = UDim.new(0, 8),
                        Parent = DepGroupboxContainer,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 7),
                        PaddingLeft = UDim.new(0, 7),
                        PaddingRight = UDim.new(0, 7),
                        PaddingTop = UDim.new(0, 7),
                        Parent = DepGroupboxContainer,
                    })
                end

                local DepGroupbox = {
                    Visible = false,
                    Dependencies = {},

                    BoxHolder = BoxHolder,
                    Holder = DepGroupboxContainer,
                    Container = DepGroupboxContainer,

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function DepGroupbox:Resize()
                    DepGroupboxContainer.Size = UDim2.new(1, 0, 0, (DepGroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
                end

                function DepGroupbox:Update(CancelSearch)
                    for _, Dependency in DepGroupbox.Dependencies do
                        local Element = Dependency[1]
                        local Value = Dependency[2]

                        if Element.Type == "Toggle" and Element.Value ~= Value then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        elseif Element.Type == "Dropdown" then
                            if typeof(Element.Value) == "table" then
                                if not Element.Value[Value] then
                                    DepGroupboxContainer.Visible = false
                                    DepGroupbox.Visible = false
                                    return
                                end
                            else
                                if Element.Value ~= Value then
                                    DepGroupboxContainer.Visible = false
                                    DepGroupbox.Visible = false
                                    return
                                end
                            end
                        end
                    end

                    DepGroupbox.Visible = true
                    if not Library.Searching then
                        DepGroupboxContainer.Visible = true
                        DepGroupbox:Resize()
                    elseif not CancelSearch then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                function DepGroupbox:SetupDependencies(Dependencies)
                    for _, Dependency in Dependencies do
                        assert(typeof(Dependency) == "table", "Dependency should be a table.")
                        assert(Dependency[1] ~= nil, "Dependency is missing element.")
                        assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
                    end

                    DepGroupbox.Dependencies = Dependencies
                    DepGroupbox:Update()
                end

                setmetatable(DepGroupbox, BaseGroupbox)

                table.insert(Tab.DependencyGroupboxes, DepGroupbox)
                table.insert(Library.DependencyBoxes, DepGroupbox)

                return DepGroupbox
            end

            BaseGroupbox.__index = Funcs
            BaseGroupbox.__namecall = function(_, Key, ...)
                return Funcs[Key](...)
            end
        end

        function Library:SetFont(FontFace)
            if typeof(FontFace) == "EnumItem" then
                FontFace = Font.fromEnum(FontFace)
            end

            Library.Scheme.Font = FontFace
            Library:UpdateColorsUsingRegistry()
        end

        function Library:SetNotifySide(Side)
            Library.NotifySide = Side

            if Side:lower() == "left" then
                NotificationArea.AnchorPoint = Vector2.new(0, 0)
                NotificationArea.Position = UDim2.fromOffset(6, 6)
                NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
            else
                NotificationArea.AnchorPoint = Vector2.new(1, 0)
                NotificationArea.Position = UDim2.new(1, -6, 0, 6)
                NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
            end
        end

        function Library:Notify(...)
            local Data = {}
            local Info = select(1, ...)

            if typeof(Info) == "table" then
                Data.Title = tostring(Info.Title)
                Data.Description = tostring(Info.Description)
                Data.Time = Info.Time or 5
                Data.SoundId = Info.SoundId
                Data.Steps = Info.Steps
                Data.Persist = Info.Persist
            else
                Data.Description = tostring(Info)
                Data.Time = select(2, ...) or 5
                Data.SoundId = select(3, ...)
            end
            Data.Destroyed = false

            local DeletedInstance = false
            local DeleteConnection = nil
            if typeof(Data.Time) == "Instance" then
                DeleteConnection = Data.Time.Destroying:Connect(function()
                    DeletedInstance = true

                    DeleteConnection:Disconnect()
                    DeleteConnection = nil
                end)
            end

            local FakeBackground = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = NotificationArea,
            })

            local Holder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = "MainColor",
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
                Size = UDim2.fromScale(1, 1),
                ZIndex = 5,
                Parent = FakeBackground,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Holder,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 4),
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                Parent = Holder,
            })
            Library:AddOutline(Holder)

            local Title
            local Desc
            local TitleX = 0
            local DescX = 0

            local TimerFill

            if Data.Title then
                Title = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0, 0),
                    Text = Data.Title,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = Holder,
                })
            end

            if Data.Description then
                Desc = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0, 0),
                    Text = Data.Description,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = Holder,
                })
            end

            function Data:Resize()
                if Title then
                    local X, Y =
                        Library:GetTextBounds(Title.Text, Title.FontFace, Title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24)
                    Title.Size = UDim2.fromOffset(0, Y)
                    TitleX = X
                end

                if Desc then
                    local X, Y =
                        Library:GetTextBounds(Desc.Text, Desc.FontFace, Desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24)
                    Desc.Size = UDim2.fromOffset(0, Y)
                    DescX = X
                end

                FakeBackground.Size = UDim2.fromOffset(math.max(TitleX, DescX) + 24, 0)
            end

            function Data:ChangeTitle(Text)
                if Title then
                    Data.Title = tostring(Text)
                    Title.Text = Data.Title
                    Data:Resize()
                end
            end

            function Data:ChangeDescription(Text)
                if Desc then
                    Data.Description = tostring(Text)
                    Desc.Text = Data.Description
                    Data:Resize()
                end
            end

            function Data:ChangeStep(NewStep)
                if TimerFill and Data.Steps then
                    NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
                    TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
                end
            end

            function Data:Destroy()
                Data.Destroyed = true

                if typeof(Data.Time) == "Instance" then
                    pcall(Data.Time.Destroy, Data.Time)
                end

                if DeleteConnection then
                    DeleteConnection:Disconnect()
                end

                TweenService
                    :Create(Holder, Library.NotifyTweenInfo, {
                        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
                    })
                    :Play()

                task.delay(Library.NotifyTweenInfo.Time, function()
                    Library.Notifications[FakeBackground] = nil
                    FakeBackground:Destroy()
                end)
            end

            Data:Resize()

            local TimerHolder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 7),
                Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
                Parent = Holder,
            })
            local TimerBar = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromOffset(0, 3),
                Size = UDim2.new(1, 0, 0, 2),
                Parent = TimerHolder,
            })
            TimerFill = New("Frame", {
                BackgroundColor3 = "AccentColor",
                Size = UDim2.fromScale(1, 1),
                Parent = TimerBar,
            })

            if typeof(Data.Time) == "Instance" then
                TimerFill.Size = UDim2.fromScale(0, 1)
            end
            if Data.SoundId then
                local SoundId = Data.SoundId
                if typeof(SoundId) == "number" then
                    SoundId = string.format("rbxassetid://%d", SoundId)
                end

                New("Sound", {
                    SoundId = SoundId,
                    Volume = 3,
                    PlayOnRemove = true,
                    Parent = SoundService,
                }):Destroy()
            end

            Library.Notifications[FakeBackground] = Data

            FakeBackground.Visible = true
            TweenService:Create(Holder, Library.NotifyTweenInfo, {
                Position = UDim2.fromOffset(0, 0),
            }):Play()

            task.delay(Library.NotifyTweenInfo.Time, function()
                if Data.Persist then
                    return
                elseif typeof(Data.Time) == "Instance" then
                    repeat
                        task.wait()
                    until DeletedInstance or Data.Destroyed
                else
                    TweenService
                        :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                            Size = UDim2.fromScale(0, 1),
                        })
                        :Play()
                    task.wait(Data.Time)
                end

                if not Data.Destroyed then
                    Data:Destroy()
                end
            end)

            return Data
        end

        function Library:CreateWindow(WindowInfo)
            WindowInfo = Library:Validate(WindowInfo, Templates.Window)
            local ViewportSize = workspace.CurrentCamera.ViewportSize

            local MaxX = ViewportSize.X - 64
            local MaxY = ViewportSize.Y - 64

            Library.OriginalMinSize =
                Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
            Library.MinSize = Library.OriginalMinSize

            WindowInfo.Size = UDim2.fromOffset(
                math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
                math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
            )
            if typeof(WindowInfo.Font) == "EnumItem" then
                WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
            end
            WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)

            Library.CornerRadius = WindowInfo.CornerRadius
            Library:SetNotifySide(WindowInfo.NotifySide)
            Library.Scheme.Font = WindowInfo.Font
            Library.ToggleKeybind = WindowInfo.ToggleKeybind
            Library.GlobalSearch = WindowInfo.GlobalSearch

            local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
            local MainFrame
            local DividerLine
            local TitleHolder
            local WindowTitle
            local WindowIcon
            local RightWrapper
            local SearchBox
            local CurrentTabInfo
            local CurrentTabLabel
            local CurrentTabDescription
            local ResizeButton
            local Tabs
            local Container

            local InitialLeftWidth = math.ceil(WindowInfo.Size.X.Offset * 0.3)
            local LastExpandedWidth = InitialLeftWidth

            do
                Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
                Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
                Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
                Library.KeybindFrame.Visible = false

                MainFrame = New("TextButton", {
                    BackgroundColor3 = function()
                        return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
                    end,
                    Name = "Main",
                    Text = "",
                    Position = WindowInfo.Position,
                    Size = WindowInfo.Size,
                    Visible = false,
                    Parent = ScreenGui,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = MainFrame,
                })
                table.insert(
                    Library.Scales,
                    New("UIScale", {
                        Parent = MainFrame,
                    })
                )
                Library:AddOutline(MainFrame)
                Library:MakeLine(MainFrame, {
                    Position = UDim2.fromOffset(0, 48),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                DividerLine = New("Frame", {
                    BackgroundColor3 = "OutlineColor",
                    Position = UDim2.fromOffset(InitialLeftWidth, 0),
                    Size = UDim2.new(0, 1, 1, -21),
                    Parent = MainFrame,
                })

                if WindowInfo.BackgroundImage then
                    New("ImageLabel", {
                        Image = WindowInfo.BackgroundImage,
                        Position = UDim2.fromScale(0, 0),
                        Size = UDim2.fromScale(1, 1),
                        ScaleType = Enum.ScaleType.Stretch,
                        ZIndex = 999,
                        BackgroundTransparency = 1,
                        ImageTransparency = 0.75,
                        Parent = MainFrame,
                    })
                end

                if WindowInfo.Center then
                    MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
                end

                local TopBar = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 48),
                    Parent = MainFrame,
                })
                Library:MakeDraggable(MainFrame, TopBar, false, true)

                TitleHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, InitialLeftWidth, 1, 0),
                    Parent = TopBar,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                    Parent = TitleHolder,
                })

                if WindowInfo.Icon then
                    WindowIcon = New("ImageLabel", {
                        Image = if tonumber(WindowInfo.Icon)
                            then string.format("rbxassetid://%d", WindowInfo.Icon)
                            else WindowInfo.Icon,
                        Size = WindowInfo.IconSize,
                        Parent = TitleHolder,
                    })
                else
                    WindowIcon = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = WindowInfo.IconSize,
                        Text = WindowInfo.Title:sub(1, 1),
                        TextScaled = true,
                        Visible = false,
                        Parent = TitleHolder,
                    })
                end

                local X = Library:GetTextBounds(
                    WindowInfo.Title,
                    Library.Scheme.Font,
                    20,
                    TitleHolder.AbsoluteSize.X - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0) - 12
                )
                WindowTitle = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, X, 1, 0),
                    Text = WindowInfo.Title,
                    TextSize = 20,
                    Parent = TitleHolder,
                })

                RightWrapper = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -49, 0.5, 0),
                    Size = UDim2.new(1, -InitialLeftWidth - 57 - 1, 1, -16),
                    Parent = TopBar,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = RightWrapper,
                })

                CurrentTabInfo = New("Frame", {
                    Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
                    Visible = false,
                    BackgroundTransparency = 1,
                    Parent = RightWrapper,
                })

                New("UIFlexItem", {
                    FlexMode = Enum.UIFlexMode.Grow,
                    Parent = CurrentTabInfo,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Parent = CurrentTabInfo,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 8),
                    Parent = CurrentTabInfo,
                })

                CurrentTabLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = "",
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = CurrentTabInfo,
                })

                CurrentTabDescription = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = "",
                    TextWrapped = true,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTransparency = 0.5,
                    Parent = CurrentTabInfo,
                })

                SearchBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    PlaceholderText = "Search",
                    Size = WindowInfo.SearchbarSize,
                    TextScaled = true,
                    Visible = not (WindowInfo.DisableSearch or false),
                    Parent = RightWrapper,
                })
                New("UIFlexItem", {
                    FlexMode = Enum.UIFlexMode.Shrink,
                    Parent = SearchBox,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = SearchBox,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 8),
                    Parent = SearchBox,
                })
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = SearchBox,
                })

                local SearchIcon = Library:GetIcon("search")
                if SearchIcon then
                    New("ImageLabel", {
                        Image = SearchIcon.Url,
                        ImageColor3 = "FontColor",
                        ImageRectOffset = SearchIcon.ImageRectOffset,
                        ImageRectSize = SearchIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = UDim2.fromScale(1, 1),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Parent = SearchBox,
                    })
                end

                if MoveIcon then
                    New("ImageLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Image = MoveIcon.Url,
                        ImageColor3 = "OutlineColor",
                        ImageRectOffset = MoveIcon.ImageRectOffset,
                        ImageRectSize = MoveIcon.ImageRectSize,
                        Position = UDim2.new(1, -10, 0.5, 0),
                        Size = UDim2.fromOffset(28, 28),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Parent = TopBar,
                    })
                end

                Library:MakeLine(MainFrame, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, -20),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BottomBar = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = MainFrame,
                })

                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = WindowInfo.Footer,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    Parent = BottomBar,
                })

                if WindowInfo.Resizable then
                    ResizeButton = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -WindowInfo.CornerRadius / 4, 0, 0),
                        Size = UDim2.fromScale(1, 1),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Text = "",
                        Parent = BottomBar,
                    })

                    Library:MakeResizable(MainFrame, ResizeButton, function()
                        for _, Tab in Library.Tabs do
                            Tab:Resize(true)
                        end
                    end)
                end

                New("ImageLabel", {
                    Image = ResizeIcon and ResizeIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = ResizeButton,
                })

                Tabs = New("ScrollingFrame", {
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = "BackgroundColor",
                    CanvasSize = UDim2.fromScale(0, 0),
                    Position = UDim2.fromOffset(0, 49),
                    ScrollBarThickness = 0,
                    Size = UDim2.new(0, InitialLeftWidth, 1, -70),
                    Parent = MainFrame,
                })
                New("UIListLayout", {
                    Parent = Tabs,
                })

                Container = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = function()
                        return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
                    end,
                    Name = "Container",
                    Position = UDim2.new(1, 0, 0, 49),
                    Size = UDim2.new(1, -InitialLeftWidth - 1, 1, -70),
                    Parent = MainFrame,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 0),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 0),
                    Parent = Container,
                })
            end

            local Window = {}

            function Window:ChangeTitle(title)
                assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

                WindowTitle.Text = title
                WindowInfo.Title = title
            end

            function Window:ShowTabInfo(Name, Description)
                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end
                CurrentTabInfo.Visible = true
            end
            function Window:HideTabInfo()
                CurrentTabInfo.Visible = false
                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(1, 1)
                end
            end

            function Window:AddTab(...)
                local Name = nil
                local Icon = nil
                local Description = nil

                if select("#", ...) == 1 and typeof(...) == "table" then
                    local Info = select(1, ...)
                    Name = Info.Name or "Tab"
                    Icon = Info.Icon
                    Description = Info.Description
                else
                    Name = select(1, ...)
                    Icon = select(2, ...)
                    Description = select(3, ...)
                end

                local TabButton: TextButton
                local TabLabel
                local TabIcon

                local TabContainer
                local TabLeft
                local TabRight

                Icon = Library:GetCustomIcon(Icon)
                do
                    TabButton = New("TextButton", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        Text = "",
                        Parent = Tabs,
                    })
                    local ButtonPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 11),
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        PaddingTop = UDim.new(0, 11),
                        Parent = TabButton,
                    })

                    TabLabel = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(30, 0),
                        Size = UDim2.new(1, -30, 1, 0),
                        Text = Name,
                        TextSize = 16,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Visible = true,
                        Parent = TabButton,
                    })

                    if Icon then
                        TabIcon = New("ImageLabel", {
                            Image = Icon.Url,
                            ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                            ImageRectOffset = Icon.ImageRectOffset,
                            ImageRectSize = Icon.ImageRectSize,
                            ImageTransparency = 0.5,
                            ScaleType = Enum.ScaleType.Fit,
                            Size = UDim2.fromScale(1, 1),
                            SizeConstraint = Enum.SizeConstraint.RelativeYY,
                            Parent = TabButton,
                        })
                    end

                    table.insert(Library.TabButtons, {
                        Label = TabLabel,
                        Padding = ButtonPadding,
                        Icon = TabIcon,
                    })

                    TabContainer = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Visible = false,
                        Parent = Container,
                    })

                    TabLeft = New("ScrollingFrame", {
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2.fromScale(0, 0),
                        ScrollBarImageTransparency = 1,
                        ScrollBarThickness = 0,
                        Size = UDim2.new(0.5, -3, 1, 0),
                        Parent = TabContainer,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        Parent = TabLeft,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 2),
                        PaddingLeft = UDim.new(0, 2),
                        PaddingRight = UDim.new(0, 2),
                        PaddingTop = UDim.new(0, 2),
                        Parent = TabLeft,
                    })
                    do
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = -1,
                            Parent = TabLeft,
                        })
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = 1,
                            Parent = TabLeft,
                        })
                    end

                    TabRight = New("ScrollingFrame", {
                        AnchorPoint = Vector2.new(1, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2.fromScale(0, 0),
                        Position = UDim2.fromScale(1, 0),
                        ScrollBarImageTransparency = 1,
                        ScrollBarThickness = 0,
                        Size = UDim2.new(0.5, -3, 1, 0),
                        Parent = TabContainer,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        Parent = TabRight,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 2),
                        PaddingLeft = UDim.new(0, 2),
                        PaddingRight = UDim.new(0, 2),
                        PaddingTop = UDim.new(0, 2),
                        Parent = TabRight,
                    })
                    do
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = -1,
                            Parent = TabRight,
                        })
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = 1,
                            Parent = TabRight,
                        })
                    end
                end

                local WarningBoxHolder = New("Frame", {
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 7),
                    Size = UDim2.fromScale(1, 0),
                    Visible = false,
                    Parent = TabContainer,
                })

                local WarningBox
                local WarningBoxOutline
                local WarningBoxShadowOutline
                local WarningBoxScrollingFrame
                local WarningTitle
                local WarningStroke
                local WarningText
                do
                    WarningBox = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(2, 0),
                        Size = UDim2.new(1, -5, 0, 0),
                        Parent = WarningBoxHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = WarningBox,
                    })
                    WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)

                    WarningBoxScrollingFrame = New("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.fromScale(1, 1),
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        ScrollBarThickness = 3,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        Parent = WarningBox,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 6),
                        PaddingRight = UDim.new(0, 6),
                        PaddingTop = UDim.new(0, 4),
                        Parent = WarningBoxScrollingFrame,
                    })

                    WarningTitle = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -4, 0, 14),
                        Text = "",
                        TextColor3 = Color3.fromRGB(255, 50, 50),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = WarningBoxScrollingFrame,
                    })

                    WarningStroke = New("UIStroke", {
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        Color = Color3.fromRGB(169, 0, 0),
                        LineJoinMode = Enum.LineJoinMode.Miter,
                        Parent = WarningTitle,
                    })

                    WarningText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(0, 16),
                        Size = UDim2.new(1, -4, 0, 0),
                        Text = "",
                        TextSize = 14,
                        TextWrapped = true,
                        Parent = WarningBoxScrollingFrame,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                    })

                    New("UIStroke", {
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        Color = "DarkColor",
                        LineJoinMode = Enum.LineJoinMode.Miter,
                        Parent = WarningText,
                    })
                end

                local Tab = {
                    Groupboxes = {},
                    Tabboxes = {},
                    DependencyGroupboxes = {},
                    Sides = {
                        TabLeft,
                        TabRight,
                    },
                    WarningBox = {
                        IsNormal = false,
                        LockSize = false,
                        Visible = false,
                        Title = "WARNING",
                        Text = "",
                    },
                }

                function Tab:UpdateWarningBox(Info)
                    if typeof(Info.IsNormal) == "boolean" then
                        Tab.WarningBox.IsNormal = Info.IsNormal
                    end
                    if typeof(Info.LockSize) == "boolean" then
                        Tab.WarningBox.LockSize = Info.LockSize
                    end
                    if typeof(Info.Visible) == "boolean" then
                        Tab.WarningBox.Visible = Info.Visible
                    end
                    if typeof(Info.Title) == "string" then
                        Tab.WarningBox.Title = Info.Title
                    end
                    if typeof(Info.Text) == "string" then
                        Tab.WarningBox.Text = Info.Text
                    end

                    WarningBoxHolder.Visible = Tab.WarningBox.Visible
                    WarningTitle.Text = Tab.WarningBox.Title
                    WarningText.Text = Tab.WarningBox.Text
                    Tab:Resize(true)

                    WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
                        or Color3.fromRGB(127, 0, 0)

                    WarningBoxShadowOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor
                        or Color3.fromRGB(85, 0, 0)
                    WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                        or Color3.fromRGB(255, 50, 50)

                    WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                        or Color3.fromRGB(255, 50, 50)
                    WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                        or Color3.fromRGB(169, 0, 0)

                    if not Library.Registry[WarningBox] then
                        Library:AddToRegistry(WarningBox, {})
                    end
                    if not Library.Registry[WarningBoxShadowOutline] then
                        Library:AddToRegistry(WarningBoxShadowOutline, {})
                    end
                    if not Library.Registry[WarningBoxOutline] then
                        Library:AddToRegistry(WarningBoxOutline, {})
                    end
                    if not Library.Registry[WarningTitle] then
                        Library:AddToRegistry(WarningTitle, {})
                    end
                    if not Library.Registry[WarningStroke] then
                        Library:AddToRegistry(WarningStroke, {})
                    end

                    Library.Registry[WarningBox].BackgroundColor3 = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
                    end

                    Library.Registry[WarningBoxShadowOutline].Color = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor or Color3.fromRGB(85, 0, 0)
                    end

                    Library.Registry[WarningBoxOutline].Color = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
                    end

                    Library.Registry[WarningTitle].TextColor3 = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
                    end

                    Library.Registry[WarningStroke].Color = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
                    end
                end

                function Tab:RefreshSides()
                    local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
                    for _, Side in Tab.Sides do
                        Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
                        Side.Size = UDim2.new(0.5, -3, 1, -Offset)
                    end
                end

                function Tab:Resize(ResizeWarningBox)
                    if ResizeWarningBox then
                        local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                        local _, YText = Library:GetTextBounds(
                            WarningText.Text,
                            Library.Scheme.Font,
                            WarningText.TextSize,
                            WarningText.AbsoluteSize.X
                        )

                        local YBox = 24 + YText
                        if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                            WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                            YBox = MaximumSize
                        else
                            WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                        end

                        WarningText.Size = UDim2.new(1, -4, 0, YText)
                        WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
                    end

                    Tab:RefreshSides()
                end

                function Tab:AddGroupbox(Info)
                    local BoxHolder = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0),
                        Parent = Info.Side == 1 and TabLeft or TabRight,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 6),
                        Parent = BoxHolder,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = BoxHolder,
                    })

                    local GroupboxHolder
                    local GroupboxLabel

                    local GroupboxContainer
                    local GroupboxList

                    do
                        GroupboxHolder = New("Frame", {
                            BackgroundColor3 = "BackgroundColor",
                            Size = UDim2.fromScale(1, 0),
                            Parent = BoxHolder,
                        })
                        New("UICorner", {
                            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                            Parent = GroupboxHolder,
                        })
                        Library:AddOutline(GroupboxHolder)

                        Library:MakeLine(GroupboxHolder, {
                            Position = UDim2.fromOffset(0, 34),
                            Size = UDim2.new(1, 0, 0, 1),
                        })

                        local BoxIcon = Library:GetCustomIcon(Info.IconName)
                        if BoxIcon then
                            New("ImageLabel", {
                                Image = BoxIcon.Url,
                                ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                                ImageRectOffset = BoxIcon.ImageRectOffset,
                                ImageRectSize = BoxIcon.ImageRectSize,
                                Position = UDim2.fromOffset(6, 6),
                                Size = UDim2.fromOffset(22, 22),
                                Parent = GroupboxHolder,
                            })
                        end

                        GroupboxLabel = New("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                            Size = UDim2.new(1, 0, 0, 34),
                            Text = Info.Name,
                            TextSize = 15,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = GroupboxHolder,
                        })
                        New("UIPadding", {
                            PaddingLeft = UDim.new(0, 12),
                            PaddingRight = UDim.new(0, 12),
                            Parent = GroupboxLabel,
                        })

                        GroupboxContainer = New("Frame", {
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(0, 35),
                            Size = UDim2.new(1, 0, 1, -35),
                            Parent = GroupboxHolder,
                        })

                        GroupboxList = New("UIListLayout", {
                            Padding = UDim.new(0, 8),
                            Parent = GroupboxContainer,
                        })
                        New("UIPadding", {
                            PaddingBottom = UDim.new(0, 7),
                            PaddingLeft = UDim.new(0, 7),
                            PaddingRight = UDim.new(0, 7),
                            PaddingTop = UDim.new(0, 7),
                            Parent = GroupboxContainer,
                        })
                    end

                    local Groupbox = {
                        BoxHolder = BoxHolder,
                        Holder = GroupboxHolder,
                        Container = GroupboxContainer,

                        Tab = Tab,
                        DependencyBoxes = {},
                        Elements = {},
                    }

                    function Groupbox:Resize()
                        GroupboxHolder.Size = UDim2.new(1, 0, 0, (GroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                    end

                    setmetatable(Groupbox, BaseGroupbox)

                    Groupbox:Resize()
                    Tab.Groupboxes[Info.Name] = Groupbox

                    return Groupbox
                end

                function Tab:AddLeftGroupbox(Name, IconName)
                    return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName })
                end

                function Tab:AddRightGroupbox(Name, IconName)
                    return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName })
                end

                function Tab:AddTabbox(Info)
                    local BoxHolder = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0),
                        Parent = Info.Side == 1 and TabLeft or TabRight,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 6),
                        Parent = BoxHolder,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = BoxHolder,
                    })

                    local TabboxHolder
                    local TabboxButtons

                    do
                        TabboxHolder = New("Frame", {
                            BackgroundColor3 = "BackgroundColor",
                            Size = UDim2.fromScale(1, 0),
                            Parent = BoxHolder,
                        })
                        New("UICorner", {
                            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                            Parent = TabboxHolder,
                        })
                        Library:AddOutline(TabboxHolder)

                        TabboxButtons = New("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 34),
                            Parent = TabboxHolder,
                        })
                        New("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalFlex = Enum.UIFlexAlignment.Fill,
                            Parent = TabboxButtons,
                        })
                    end

                    local Tabbox = {
                        ActiveTab = nil,

                        BoxHolder = BoxHolder,
                        Holder = TabboxHolder,
                        Tabs = {},
                    }

                    function Tabbox:AddTab(Name)
                        local Button = New("TextButton", {
                            BackgroundColor3 = "MainColor",
                            BackgroundTransparency = 0,
                            Size = UDim2.fromOffset(0, 34),
                            Text = Name,
                            TextSize = 15,
                            TextTransparency = 0.5,
                            Parent = TabboxButtons,
                        })

                        local Line = Library:MakeLine(Button, {
                            AnchorPoint = Vector2.new(0, 1),
                            Position = UDim2.new(0, 0, 1, 1),
                            Size = UDim2.new(1, 0, 0, 1),
                        })

                        local Container = New("Frame", {
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(0, 35),
                            Size = UDim2.new(1, 0, 1, -35),
                            Visible = false,
                            Parent = TabboxHolder,
                        })
                        local List = New("UIListLayout", {
                            Padding = UDim.new(0, 8),
                            Parent = Container,
                        })
                        New("UIPadding", {
                            PaddingBottom = UDim.new(0, 7),
                            PaddingLeft = UDim.new(0, 7),
                            PaddingRight = UDim.new(0, 7),
                            PaddingTop = UDim.new(0, 7),
                            Parent = Container,
                        })

                        local Tab = {
                            ButtonHolder = Button,
                            Container = Container,

                            Tab = Tab,
                            Elements = {},
                            DependencyBoxes = {},
                        }

                        function Tab:Show()
                            if Tabbox.ActiveTab then
                                Tabbox.ActiveTab:Hide()
                            end

                            Button.BackgroundTransparency = 1
                            Button.TextTransparency = 0
                            Line.Visible = false

                            Container.Visible = true

                            Tabbox.ActiveTab = Tab
                            Tab:Resize()
                        end

                        function Tab:Hide()
                            Button.BackgroundTransparency = 0
                            Button.TextTransparency = 0.5
                            Line.Visible = true
                            Container.Visible = false

                            Tabbox.ActiveTab = nil
                        end

                        function Tab:Resize()
                            if Tabbox.ActiveTab ~= Tab then
                                return
                            end

                            TabboxHolder.Size = UDim2.new(1, 0, 0, (List.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                        end

                        if not Tabbox.ActiveTab then
                            Tab:Show()
                        end

                        Button.MouseButton1Click:Connect(Tab.Show)

                        setmetatable(Tab, BaseGroupbox)

                        Tabbox.Tabs[Name] = Tab

                        return Tab
                    end

                    if Info.Name then
                        Tab.Tabboxes[Info.Name] = Tabbox
                    else
                        table.insert(Tab.Tabboxes, Tabbox)
                    end

                    return Tabbox
                end

                function Tab:AddLeftTabbox(Name)
                    return Tab:AddTabbox({ Side = 1, Name = Name })
                end

                function Tab:AddRightTabbox(Name)
                    return Tab:AddTabbox({ Side = 2, Name = Name })
                end

                function Tab:Hover(Hovering)
                    if Library.ActiveTab == Tab then
                        return
                    end

                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = Hovering and 0.25 or 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = Hovering and 0.25 or 0.5,
                        }):Play()
                    end
                end

                function Tab:Show()
                    if Library.ActiveTab then
                        Library.ActiveTab:Hide()
                    end

                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 0,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0,
                        }):Play()
                    end

                    if Description then
                        Window:ShowTabInfo(Name, Description)
                    end

                    TabContainer.Visible = true
                    Tab:RefreshSides()

                    Library.ActiveTab = Tab

                    if Library.Searching then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                function Tab:Hide()
                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 1,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0.5,
                        }):Play()
                    end
                    TabContainer.Visible = false

                    Window:HideTabInfo()

                    Library.ActiveTab = nil
                end

                if not Library.ActiveTab then
                    Tab:Show()
                end

                TabButton.MouseEnter:Connect(function()
                    Tab:Hover(true)
                end)
                TabButton.MouseLeave:Connect(function()
                    Tab:Hover(false)
                end)
                TabButton.MouseButton1Click:Connect(Tab.Show)

                Library.Tabs[Name] = Tab

                return Tab
            end

            function Window:AddKeyTab(...)
                local Name = nil
                local Icon = nil
                local Description = nil

                if select("#", ...) == 1 and typeof(...) == "table" then
                    local Info = select(1, ...)
                    Name = Info.Name or "Tab"
                    Icon = Info.Icon
                    Description = Info.Description
                else
                    Name = select(1, ...) or "Tab"
                    Icon = select(2, ...)
                    Description = select(3, ...)
                end

                Icon = Icon or "key"

                local TabButton: TextButton
                local TabLabel
                local TabIcon

                local TabContainer

                Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
                do
                    TabButton = New("TextButton", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        Text = "",
                        Parent = Tabs,
                    })
                    local ButtonPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 11),
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        PaddingTop = UDim.new(0, 11),
                        Parent = TabButton,
                    })

                    TabLabel = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(30, 0),
                        Size = UDim2.new(1, -30, 1, 0),
                        Text = Name,
                        TextSize = 16,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Visible = true,
                        Parent = TabButton,
                    })

                    if Icon then
                        TabIcon = New("ImageLabel", {
                            Image = Icon.Url,
                            ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                            ImageRectOffset = Icon.ImageRectOffset,
                            ImageRectSize = Icon.ImageRectSize,
                            ImageTransparency = 0.5,
                            Size = UDim2.fromScale(1, 1),
                            SizeConstraint = Enum.SizeConstraint.RelativeYY,
                            Parent = TabButton,
                        })
                    end

                    table.insert(Library.TabButtons, {
                        Label = TabLabel,
                        Padding = ButtonPadding,
                        Icon = TabIcon,
                    })

                    TabContainer = New("ScrollingFrame", {
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2.fromScale(0, 0),
                        ScrollBarThickness = 0,
                        Size = UDim2.fromScale(1, 1),
                        Visible = false,
                        Parent = Container,
                    })
                    New("UIListLayout", {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 8),
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Parent = TabContainer,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 1),
                        PaddingRight = UDim.new(0, 1),
                        Parent = TabContainer,
                    })
                end

                local Tab = {
                    Elements = {},
                    IsKeyTab = true,
                }

                function Tab:AddKeyBox(Callback)
                    assert(typeof(Callback) == "function", "Callback must be a function")

                    local Holder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.75, 0, 0, 21),
                        Parent = TabContainer,
                    })

                    local Box = New("TextBox", {
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        PlaceholderText = "Key",
                        Size = UDim2.new(1, -71, 1, 0),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = Holder,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8),
                        Parent = Box,
                    })

                    local Button = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.new(0, 63, 1, 0),
                        Text = "Execute",
                        TextSize = 14,
                        Parent = Holder,
                    })

                    Button.InputBegan:Connect(function(Input)
                        if not IsClickInput(Input) then
                            return
                        end

                        if not Library:MouseIsOverFrame(Button, Input.Position) then
                            return
                        end

                        Callback(Box.Text)
                    end)
                end

                function Tab:RefreshSides() end
                function Tab:Resize() end

                function Tab:Hover(Hovering)
                    if Library.ActiveTab == Tab then
                        return
                    end

                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = Hovering and 0.25 or 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = Hovering and 0.25 or 0.5,
                        }):Play()
                    end
                end

                function Tab:Show()
                    if Library.ActiveTab then
                        Library.ActiveTab:Hide()
                    end

                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 0,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0,
                        }):Play()
                    end
                    TabContainer.Visible = true

                    if Description then
                        Window:ShowTabInfo(Name, Description)
                    end

                    Tab:RefreshSides()

                    Library.ActiveTab = Tab

                    if Library.Searching then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                function Tab:Hide()
                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 1,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0.5,
                        }):Play()
                    end
                    TabContainer.Visible = false

                    Window:HideTabInfo()

                    Library.ActiveTab = nil
                end

                if not Library.ActiveTab then
                    Tab:Show()
                end

                TabButton.MouseEnter:Connect(function()
                    Tab:Hover(true)
                end)
                TabButton.MouseLeave:Connect(function()
                    Tab:Hover(false)
                end)
                TabButton.MouseButton1Click:Connect(Tab.Show)

                Tab.Container = TabContainer
                setmetatable(Tab, BaseGroupbox)

                Library.Tabs[Name] = Tab
                return Tab
            end

            function Library:Toggle(Value)
                if typeof(Value) == "boolean" then
                    Library.Toggled = Value
                else
                    Library.Toggled = not Library.Toggled
                end

                MainFrame.Visible = Library.Toggled
                ModalElement.Modal = Library.Toggled

                if Library.Toggled and not Library.IsMobile then
                    local OldMouseIconEnabled = UserInputService.MouseIconEnabled
                    ConnectionManager:Connect("ForceMouseIconEnabled", RunService.RenderStepped(function()
                        if Library.Toggled and ScreenGui and ScreenGui.Parent then
                            UserInputService.MouseIconEnabled = true
                        else
                            UserInputService.MouseIconEnabled = OldMouseIconEnabled
                            ConnectionManager:Disconnect("ForceMouseIconEnabled")
                        end
                    end))
                elseif not Library.Toggled then
                    TooltipLabel.Visible = false

                    for _, Option in Library.Options do
                        if Option.Type == "ColorPicker" then
                            Option.ColorMenu:Close()
                            Option.ContextMenu:Close()
                        elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                            Option.Menu:Close()
                        end
                    end
                end
            end

            if Library.IsMobile then
                local ToggleButton = Library:AddDraggableButton("Toggle", function()
                    Library:Toggle()
                end, true)

                local LockButton = Library:AddDraggableButton("Lock", function(self)
                    Library.CantDragForced = not Library.CantDragForced
                    self:SetText(Library.CantDragForced and "Unlock" or "Lock")
                end, true)

                if WindowInfo.MobileButtonsSide == "Right" then
                    ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)
                    ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)

                    LockButton.Button.Position = UDim2.new(1, -6, 0, 46)
                    LockButton.Button.AnchorPoint = Vector2.new(1, 0)
                else
                    LockButton.Button.Position = UDim2.fromOffset(6, 46)
                end
            end

            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                Library:UpdateSearch(SearchBox.Text)
            end)

            Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
                if Library.Unloaded then
                    return
                end

                if UserInputService:GetFocusedTextBox() then
                    return
                end

                if (typeof(Library.ToggleKeybind) == "table"  and Library.ToggleKeybind.Type == "KeyPicker"
                    and Input.KeyCode.Name == Library.ToggleKeybind.Value
                ) or Input.KeyCode == Library.ToggleKeybind then
                    Library.Toggle()
                end
            end))

            Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
                Library.IsRobloxFocused = true
            end))
            Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
                Library.IsRobloxFocused = false
            end))

            return Window
        end

        local function OnPlayerChange()
            if Library.Unloaded then
                return
            end

            for _,Dropdown in Options do
                if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
                    Dropdown:SetValues(GetPlayers())
                end
            end
        end

        Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
        Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

        return Library
    end)(),

    GetThemeManager = function()
        local ThemeManager = {}
        do
            local ThemeFields = {"FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor"}
            ThemeManager.Folder = "NikoletoScripts/KAT.lol"

            ThemeManager.Library = nil
            ThemeManager.AppliedToTab = false
            ThemeManager.BuiltInThemes = {
                ["Default"] = {
                    1,
                    { FontColor = "f0f5ff", MainColor = "11161e", AccentColor = "00bfff", BackgroundColor = "090c11", OutlineColor = "2f3d52" },
                },
                ["Neverlose"] = {
                    19,
                    { FontColor = "f0f5ff", MainColor = "121923", AccentColor = "00c6ff", BackgroundColor = "0a0f15", OutlineColor = "324154" },
                },
                ["BBot"] = {
                    2,
                    { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" },
                },
                ["Fatality"] = {
                    3,
                    { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" },
                },
                ["Jester"] = {
                    4,
                    { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" },
                },
                ["Mint"] = {
                    5,
                    { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" },
                },
                ["Tokyo Night"] = {
                    6,
                    { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" },
                },
                ["Ubuntu"] = {
                    7,
                    { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" },
                },
                ["Quartz"] = {
                    8,
                    { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" },
                },
                ["Nord"] = {
                    9,
                    { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" },
                },
                ["Dracula"] = {
                    10,
                    { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" },
                },
                ["Monokai"] = {
                    11,
                    { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e" },
                },
                ["Gruvbox"] = {
                    12,
                    { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945" },
                },
                ["Solarized"] = {
                    13,
                    { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75" },
                },
                ["Catppuccin"] = {
                    14,
                    { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268" },
                },
                ["One Dark"] = {
                    15,
                    { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370" },
                },
                ["Cyberpunk"] = {
                    16,
                    { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e" },
                },
                ["Oceanic Next"] = {
                    17,
                    { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46" },
                },
                ["Material"] = {
                    18,
                    { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242" },
                }
            }

            function ThemeManager:SetLibrary(library)
                self.Library = library
            end

            function ThemeManager:GetPaths()
                local Paths = {}

                local Parts = self.Folder:split("/")
                for Index = 1, #Parts do
                    Paths[#Paths + 1] = table.concat(Parts, "/", 1, Index)
                end

                Paths[#Paths + 1] = self.Folder .. "/Themes"

                return Paths
            end

            function ThemeManager:BuildFolderTree()
                local Paths = self:GetPaths()

                for i = 1, #Paths do
                    local str = Paths[i]
                    if FileManager:IsFolder(str) then
                        continue
                    end
                    FileManager:CreateFolder(str)
                end
            end

            function ThemeManager:CheckFolderTree()
                if FileManager:IsFolder(self.Folder) then
                    return
                end
                self:BuildFolderTree()

                task.wait(0.1)
            end

            function ThemeManager:ApplyTheme(theme)
                local customThemeData = self:GetCustomTheme(theme)
                local Data = customThemeData or self.BuiltInThemes[theme]

                if not Data then
                    return
                end

                local scheme = Data[2]
                for Index, val in pairs(customThemeData or scheme) do
                    if Index == "VideoLink" then
                        continue
                    elseif Index == "FontFace" then
                        self.Library:SetFont(Enum.Font[val])

                        if self.Library.Options[Index] then
                            self.Library.Options[Index]:SetValue(val)
                        end
                    else
                        self.Library.Scheme[Index] = Color3.fromHex(val)

                        if self.Library.Options[Index] then
                            self.Library.Options[Index]:SetValueRGB(Color3.fromHex(val))
                        end
                    end
                end

                self:ThemeUpdate()
            end

            function ThemeManager:ThemeUpdate()
                for i,Field in ThemeFields do
                    if self.Library.Options and self.Library.Options[Field] then
                        self.Library.Scheme[Field] = self.Library.Options[Field].Value
                    end
                end

                self.Library:UpdateColorsUsingRegistry()
            end

            function ThemeManager:GetCustomTheme(File)
                local Path = self.Folder .. "/Themes/" .. File .. ".json"
                return FileManager:Exists(Path) and FileManager:ReadJSON(Path) or nil
            end

            function ThemeManager:LoadDefault()
                local theme = "Default"
                local content = FileManager:Read(self.Folder .. "/Themes/default.txt")

                local isDefault = true
                if content then
                    if self.BuiltInThemes[content] then
                        theme = content
                    elseif self:GetCustomTheme(content) then
                        theme = content
                        isDefault = false
                    end
                elseif self.BuiltInThemes[self.DefaultTheme] then
                    theme = self.DefaultTheme
                end

                if isDefault then
                    self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
                else
                    self:ApplyTheme(theme)
                end
            end

            function ThemeManager:SaveDefault(theme)
                FileManager:Write(self.Folder .. "/Themes/default.txt", theme)
            end

            function ThemeManager:SetDefaultTheme(theme)
                assert(self.Library, "Must set ThemeManager.Library first!")
                assert(not self.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")

                local FinalTheme = {}
                local LibraryScheme = {}
                for _,Field in ThemeFields do
                    if typeof(theme[Field]) == "Color3" then
                        FinalTheme[Field] = "#" .. theme[Field]:ToHex()
                        LibraryScheme[Field] = theme[Field]

                    elseif typeof(theme[Field]) == "string" then
                        FinalTheme[Field] = if theme[Field]:sub(1, 1) == "#" then theme[Field] else ("#" .. theme[Field])
                        LibraryScheme[Field] = Color3.fromHex(theme[Field])

                    else
                        FinalTheme[Field] = ThemeManager.BuiltInThemes["Default"][2][Field]
                        LibraryScheme[Field] = Color3.fromHex(ThemeManager.BuiltInThemes["Default"][2][Field])
                    end
                end

                if typeof(theme["FontFace"]) == "EnumItem" then
                    FinalTheme["FontFace"] = theme["FontFace"].Name
                    LibraryScheme["Font"] = Font.fromEnum(theme["FontFace"])

                elseif typeof(theme["FontFace"]) == "string" then
                    FinalTheme["FontFace"] = theme["FontFace"]
                    LibraryScheme["Font"] = Font.fromEnum(Enum.Font[theme["FontFace"]])

                else
                    FinalTheme["FontFace"] = "Code"
                    LibraryScheme["Font"] = Font.fromEnum(Enum.Font.Code)
                end

                for _,Field in { "RedColor", "DarkColor", "WhiteColor" } do
                    LibraryScheme[Field] = self.Library.Scheme[Field]
                end

                self.Library.Scheme = LibraryScheme
                self.BuiltInThemes["Default"] = { 1, FinalTheme }

                self.Library:UpdateColorsUsingRegistry()
            end

            function ThemeManager:SaveCustomTheme(File)
                if File:gsub(" ", "") == "" then
                    self.Library:Notify("Invalid File Name for theme (empty)", 3)
                    return
                end

                local theme = {}
                for _,Field in ThemeFields do
                    theme[Field] = self.Library.Options[Field].Value:ToHex()
                end
                theme["FontFace"] = self.Library.Options["FontFace"].Value

                FileManager:WriteJSON(self.Folder .. "/Themes/" .. File .. ".json", theme)
            end

            function ThemeManager:Delete(Name)
                if not Name then
                    return false, "no config File is selected"
                end

                local File = self.Folder .. "/Themes/" .. Name .. ".json"
                if not FileManager:Exist(File) then
                    return false, "invalid File"
                end

                FileManager:DeleteFile(File)
                return true
            end

            function ThemeManager:ReloadCustomThemes()
                local List = FileManager:List(self.Folder .. "/Themes")

                local Out = {}
                for i = 1, #List do
                    local File = List[i]
                    if File:sub(-5) == ".json" then
                        local Start = File:find(".json", 1, true)
                        local Position = Start

                        local Char = File:sub(Position, Position)
                        while Char ~= "/" and Char ~= "\\" and Char ~= "" do
                            Position += 1
                            Char = File:sub(Position, Position)
                        end

                        if Char == "/" or Char == "\\" then
                            table.insert(Out, File:sub(Position + 1, Start - 1))
                        end
                    end
                end

                return Out
            end

            function ThemeManager:CreateThemeManager(Groupbox)
                Groupbox:AddLabel("Background color"):AddColorPicker("BackgroundColor", { Default = self.Library.Scheme.BackgroundColor })
                Groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = self.Library.Scheme.MainColor })
                Groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.Scheme.AccentColor })
                Groupbox:AddLabel("Outline color"):AddColorPicker("OutlineColor", { Default = self.Library.Scheme.OutlineColor })
                Groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = self.Library.Scheme.FontColor })
                Groupbox:AddDropdown("FontFace", {
                    Text = "Font Face",
                    Default = "Code",
                    Values = {"BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans"},
                })

                local ThemesArray = {}
                for Name, Theme in pairs(self.BuiltInThemes) do
                    table.insert(ThemesArray, Name)
                end

                table.sort(ThemesArray, function(A, B)
                    return self.BuiltInThemes[A][1] < self.BuiltInThemes[B][1]
                end)

                Groupbox:AddDivider()

                Groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme List", Values = ThemesArray, Default = 1 })
                Groupbox:AddButton("Set as default", function()
                    self:SaveDefault(self.Library.Options.ThemeManager_ThemeList.Value)
                    self.Library:Notify(
                        string.format("Set default theme to %q", self.Library.Options.ThemeManager_ThemeList.Value)
                    )
                end)

                self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
                    self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
                end)

                Groupbox:AddDivider()

                Groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme Name" })
                Groupbox:AddButton("Create theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeName.Value

                    if Name:gsub(" ", "") == "" then
                        self.Library:Notify("Invalid theme Name (empty)", 2)
                        return
                    end

                    self:SaveCustomTheme(Name)

                    self.Library:Notify(string.format("Created theme %q", Name))
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)

                Groupbox:AddDivider()

                Groupbox:AddDropdown(
                    "ThemeManager_CustomThemeList",
                    { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 }
                )
                Groupbox:AddButton("Load theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeList.Value

                    self:ApplyTheme(Name)
                    self.Library:Notify(string.format("Loaded theme %q", Name))
                end)
                Groupbox:AddButton("Overwrite theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeList.Value

                    self:SaveCustomTheme(Name)
                    self.Library:Notify(string.format("Overwrote config %q", Name))
                end)
                Groupbox:AddButton("Delete theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeList.Value

                    local Success, Error = self:Delete(Name)
                    if not Success then
                        self.Library:Notify("Failed to delete theme: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Deleted theme %q", Name))
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)
                Groupbox:AddButton("Refresh List", function()
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)
                Groupbox:AddButton("Set as default", function()
                    if
                        self.Library.Options.ThemeManager_CustomThemeList.Value ~= nil
                        and self.Library.Options.ThemeManager_CustomThemeList.Value ~= ""
                    then
                        self:SaveDefault(self.Library.Options.ThemeManager_CustomThemeList.Value)
                        self.Library:Notify(
                            string.format("Set default theme to %q", self.Library.Options.ThemeManager_CustomThemeList.Value)
                        )
                    end
                end)
                Groupbox:AddButton("Reset default", function()
                    FileManager:DeleteFile(self.Folder .. "/Themes/default.txt")
                    self.Library:Notify("Set default theme to nothing")
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)

                self:LoadDefault()
                self.AppliedToTab = true

                local function UpdateTheme()
                    self:ThemeUpdate()
                end

                self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
                self.Library.Options.MainColor:OnChanged(UpdateTheme)
                self.Library.Options.AccentColor:OnChanged(UpdateTheme)
                self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
                self.Library.Options.FontColor:OnChanged(UpdateTheme)
                self.Library.Options.FontFace:OnChanged(function(Value)
                    self.Library:SetFont(Enum.Font[Value])
                    self.Library:UpdateColorsUsingRegistry()
                end)
            end

            function ThemeManager:CreateGroupBox(tab)
                assert(self.Library, "Must set ThemeManager.Library first!")
                return tab:AddLeftGroupbox("Themes", "paintbrush")
            end

            function ThemeManager:ApplyToTab(tab)
                assert(self.Library, "Must set ThemeManager.Library first!")
                local Groupbox = self:CreateGroupBox(tab)
                self:CreateThemeManager(Groupbox)
            end

            function ThemeManager:ApplyToGroupbox(Groupbox)
                assert(self.Library, "Must set ThemeManager.Library first!")
                self:CreateThemeManager(Groupbox)
            end

            ThemeManager:BuildFolderTree()
        end

        return ThemeManager
    end,

    GetSaveManager = function()
        local SaveManager = {} do
            SaveManager.Folder = "NikoletoScripts/KAT.lol"
            SaveManager.Ignore = {}
            SaveManager.Library = nil
            SaveManager.Parser = {
                Toggle = {
                    Save = function(Index, Object)
                        return { Type = "Toggle", Index = Index, value = Object.Value }
                    end,
                    Load = function(Index, Data)
                        local Object = SaveManager.Library.Toggles[Index]
                        if Object and Object.Value ~= Data.value then
                            Object:SetValue(Data.value)
                        end
                    end,
                },
                Slider = {
                    Save = function(Index, Object)
                        return { Type = "Slider", Index = Index, value = tostring(Object.Value) }
                    end,
                    Load = function(Index, Data)
                        local Object = SaveManager.Library.Options[Index]
                        if Object and Object.Value ~= Data.value then
                            Object:SetValue(Data.value)
                        end
                    end,
                },
                Dropdown = {
                    Save = function(Index, Object)
                        return { Type = "Dropdown", Index = Index, value = Object.Value, multi = Object.Multi }
                    end,
                    Load = function(Index, Data)
                        local object = SaveManager.Library.Options[Index]
                        if object and object.Value ~= Data.value then
                            object:SetValue(Data.value)
                        end
                    end,
                },
                ColorPicker = {
                    Save = function(Index, Object)
                        return { Type = "ColorPicker", Index = Index, value = Object.Value:ToHex(), transparency = Object.Transparency }
                    end,
                    Load = function(Index, Data)
                        if SaveManager.Library.Options[Index] then
                            SaveManager.Library.Options[Index]:SetValueRGB(Color3.fromHex(Data.value), Data.transparency)
                        end
                    end,
                },
                KeyPicker = {
                    Save = function(Index, Object)
                        return { Type = "KeyPicker", Index = Index, mode = Object.Mode, key = Object.Value, modifiers = Object.Modifiers }
                    end,
                    Load = function(Index, Data)
                        if SaveManager.Library.Options[Index] then
                            SaveManager.Library.Options[Index]:SetValue({ Data.key, Data.mode, Data.modifiers })
                        end
                    end,
                },
                Input = {
                    Save = function(Index, Object)
                        return { Type = "Input", Index = Index, text = Object.Value }
                    end,
                    Load = function(Index, Data)
                        local Object = SaveManager.Library.Options[Index]
                        if Object and Object.Value ~= Data.text and type(Data.text) == "string" then
                            SaveManager.Library.Options[Index]:SetValue(Data)
                        end
                    end,
                },
            }

            function SaveManager:SetLibrary(library)
                self.Library = library
            end

            function SaveManager:IgnoreThemeSettings()
                self:SetIgnoreIndexes({
                    "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "FontFace",
                    "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
                })
            end

            function SaveManager:GetPaths()
                local Paths = {}

                local Parts = self.Folder:split("/")
                for Index = 1, #Parts do
                    local Path = table.concat(Parts, "/", 1, Index)
                    if not table.find(Paths, Path) then
                        Paths[#Paths + 1] = Path
                    end
                end

                Paths[#Paths + 1] = self.Folder .. "/Themes"
                Paths[#Paths + 1] = self.Folder .. "/Settings"
                return Paths
            end

            function SaveManager:BuildFolderTree()
                local Paths = self:GetPaths()
                for Index = 1, #Paths do
                    local String = Paths[Index]
                    if FileManager:IsFolder(String) then
                        continue
                    end
                    FileManager:CreateFolder(String)
                end
            end

            function SaveManager:CheckFolderTree()
                if FileManager:IsFolder(self.Folder) then
                    return
                end
                SaveManager:BuildFolderTree()
                task.wait(0.1)
            end

            function SaveManager:SetIgnoreIndexes(List)
                for _,Key in next, List do
                    self.Ignore[Key] = true
                end
            end

            function SaveManager:Save(Name)
                if not Name then
                    return false, "no config File is selected"
                end

                SaveManager:CheckFolderTree()
                local Objects = {}

                for Index, Toggle in pairs(self.Library.Toggles) do
                    if not Toggle.Type or not self.Parser[Toggle.Type] or self.Ignore[Index] then
                        continue
                    end
                    table.insert(Objects, self.Parser[Toggle.Type].Save(Index, Toggle))
                end

                for Index, Option in pairs(self.Library.Options) do
                    if not Option.Type or not self.Parser[Option.Type] or self.Ignore[Index] then
                        continue
                    end
                    table.insert(Objects, self.Parser[Option.Type].Save(Index, Option))
                end

                FileManager:WriteJSON(self.Folder .. "/Settings/" .. Name .. ".json", {Objects = Objects})
                return true
            end

            function SaveManager:Load(Name)
                if not Name then
                    return false, "no config File is selected"
                end
                SaveManager:CheckFolderTree()

                local Decoded = FileManager:ReadJSON(self.Folder .. "/Settings/" .. Name .. ".json")
                if not Decoded then
                    return false
                end

                for _,Option in pairs(Decoded.Objects) do
                    if not Option.Type or not self.Parser[Option.Type] or self.Ignore[Option.Index] then
                        continue
                    end
                    task.spawn(self.Parser[Option.Type].Load, Option.Index, Option)
                end

                return true
            end

            function SaveManager:Delete(Name)
                if not Name then
                    return false, "no config File is selected"
                end

                FileManager:DeleteFile(self.Folder .. "/Settings/" .. Name .. ".json")
                return true
            end

            function SaveManager:RefreshConfigList()
                local Success, Data = pcall(function()
                    SaveManager:CheckFolderTree()

                    local List = FileManager:List(self.Folder .. "/Settings")
                    local Out = {}

                    if type(List) ~= "table" then
                        List = {}
                    end

                    for Index = 1, #List do
                        local File = List[Index]
                        if File:sub(-5) == ".json" then
                            local Start = File:find(".json", 1, true)
                            local Position = Start

                            local Char = File:sub(Position, Position)
                            while Char ~= "/" and Char ~= "\\" and Char ~= "" do
                                Position -= 1
                                Char = File:sub(Position, Position)
                            end

                            if Char == "/" or Char == "\\" then
                                table.insert(Out, File:sub(Position + 1, Start - 1))
                            end
                        end
                    end

                    return Out
                end)

                if not Success then
                    if self.Library then
                        self.Library:Notify("Failed to load config List: " .. tostring(Data))
                    else
                        warn("Failed to load config List: " .. tostring(Data))
                    end

                    return {}
                end

                return Data
            end

            function SaveManager:GetAutoloadConfig()
                SaveManager:CheckFolderTree()

                local AutoLoadPath = self.Folder .. "/Settings/autoload.txt"
                if FileManager:IsFile(AutoLoadPath) then
                    return FileManager:Read(AutoLoadPath) or "None"
                end

                return "None"
            end

            function SaveManager:LoadAutoloadConfig()
                SaveManager:CheckFolderTree()
                local AutoLoadPath = self.Folder .. "/Settings/autoload.txt"
                if FileManager:IsFile(AutoLoadPath) then
                    local Name = FileManager:Read(AutoLoadPath)

                    local Success, Error = self:Load(Name)
                    if not Success then
                        self.Library:Notify("Failed to load autoload config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Auto loaded config %q", Name))
                end
            end

            function SaveManager:SaveAutoloadConfig(Name)
                SaveManager:CheckFolderTree()
                FileManager:Write(self.Folder .. "/Settings/autoload.txt", Name)
                return true, ""
            end

            function SaveManager:DeleteAutoLoadConfig()
                SaveManager:CheckFolderTree()
                FileManager:DeleteFile(self.Folder .. "/Settings/autoload.txt")
                return true, ""
            end

            function SaveManager:BuildConfigSection(tab)
                assert(self.Library, "Must set SaveManager.Library")

                local section = tab:AddRightGroupbox("Configuration", "folder-cog")

                section:AddInput("SaveManager_ConfigName",    { Text = "Config Name" })
                section:AddButton("Create config", function()
                    local Name = self.Library.Options.SaveManager_ConfigName.Value

                    if Name:gsub(" ", "") == "" then
                        self.Library:Notify("Invalid config Name (empty)", 2)
                        return
                    end

                    local Success, Error = self:Save(Name)
                    if not Success then
                        self.Library:Notify("Failed to create config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Created config %q", Name))
                    self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    self.Library.Options.SaveManager_ConfigList:SetValue(nil)
                end)

                section:AddDivider()

                section:AddDropdown("SaveManager_ConfigList", { Text = "Config List", Values = self:RefreshConfigList(), AllowNull = true })
                section:AddButton("Load config", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:Load(Name)
                    if not Success then
                        self.Library:Notify("Failed to load config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Loaded config %q", Name))
                end)
                section:AddButton("Overwrite config", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:Save(Name)
                    if not Success then
                        self.Library:Notify("Failed to overwrite config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Overwrote config %q", Name))
                end)

                section:AddButton("Delete config", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:Delete(Name)
                    if not Success then
                        self.Library:Notify("Failed to delete config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Deleted config %q", Name))
                    self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    self.Library.Options.SaveManager_ConfigList:SetValue(nil)
                end)

                section:AddButton("Refresh List", function()
                    self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    self.Library.Options.SaveManager_ConfigList:SetValue(nil)
                end)

                section:AddButton("Set as autoload", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:SaveAutoloadConfig(Name)
                    if not Success then
                        self.Library:Notify("Failed to set autoload config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Set %q to auto load", Name))
                    self.AutoloadConfigLabel:SetText("Current autoload config: " .. Name)
                end)
                section:AddButton("Reset autoload", function()
                    local Success, Error = self:DeleteAutoLoadConfig()
                    if not Success then
                        self.Library:Notify("Failed to set autoload config: " .. Error)
                        return
                    end

                    self.Library:Notify("Set autoload to None")
                    self.AutoloadConfigLabel:SetText("Current autoload config: None")
                end)

                self.AutoloadConfigLabel = section:AddLabel("Current autoload config: " .. self:GetAutoloadConfig(), true)
                self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
            end

            SaveManager:BuildFolderTree()
        end

        return SaveManager
    end,

 	["ExecutorFunctions"] = {
		["isrenderobj"] = IsFunction(isrenderobj) or function()
            return true
        end,

        ["newcclosure"] = IsFunction(newcclosure) or function(Closure)
			return Closure
		end,

        ["hookmetamethod"] = IsFunction(hookmetamethod),
        ["getnamecallmethod"] = IsFunction(getnamecallmethod),

        ["getgc"] = IsFunction(getgc),

        ["getupvalues"] = IsFunction(getupvalues) or IsFunction(debug.getupvalues),
        ["getupvalue"] = IsFunction(getupvalue) or IsFunction(debug.getupvalue),

        ["getsenv"] = IsFunction(getsenv),
        ["getconnections"] = IsFunction(getconnections)
	}
})]=]

print('test')
local NikoletoScripts = {
	["Start"] = Context["Start"],
	["Version"] = Context["Version"],
	["LoadScript"] = Context["LoadScript"],
    ["ExecutorName"] = IsFunction(identifyexecutor) or IsFunction(getexecutorname) or function()
        return "Unknown"
    end,

	["ConnectionManager"] = ConnectionManager,
    ["ServiceManager"] = ServiceManager,
	["DrawingManager"] = (function()
        local DrawingManager = setmetatable({}, {
            __call = function(_,DrawingType, Properties)
                local DrawingObject = Drawing.new(DrawingType)
                if Properties then
                    for Property, Value in next, Properties do
                        DrawingObject[Property] = Value
                    end
                end
                return DrawingObject
            end
        })

        function DrawingManager:Remove(DrawingObject)
            pcall(function()
                DrawingObject:Remove()
            end)
        end

        return DrawingManager
    end)(),
	["ThreadManager"] = (function()
        local ThreadManager = {Threads = {}}

        function ThreadManager:Start(Name, Callback, Interval)
            if self.Threads[Name] then
                return
            end

            local IsRunning = true
            self.Threads[Name] = {
                Kill = function()
                    IsRunning = false
                end
            }

            task.spawn(function()
                while IsRunning do
                    Callback()
                    task.wait(Interval)
                end
            end)
        end

        function ThreadManager:Stop(Name)
            local Thread = self.Threads[Name]
            if Thread then
                Thread.Kill()
                self.Threads[Name] = nil
            end
        end

        function ThreadManager:Exists(Name)
            return self.Threads[Name] ~= nil
        end

        function ThreadManager:Shutdown()
            for _,Thread in self.Threads do
                Thread.Kill()
            end
            table.clear(self.Threads)
        end

        return ThreadManager
    end)(),
	["FileManager"] = FileManager,
	["RunService"] = RunService,
	["Utils"] = Utils,
    ["UI"] = (function()
        local UserInputService = ServiceManager.UserInputService
        local SoundService = ServiceManager.SoundService
        local TweenService = ServiceManager.TweenService
        local TextService = ServiceManager.TextService
        local CoreGui = ServiceManager.CoreGui
        local Players = ServiceManager.Players

        local setclipboard = IsFunction(setclipboard) or IsFunction(writeclipboard)
        local Create = Utils.Create

        local LocalPlayer = Players.LocalPlayer
        local Mouse = LocalPlayer:GetMouse()

        local Labels = {}
        local Buttons = {}
        local Toggles = {}
        local Options = {}
        local Tooltips = {}

        local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
        local CustomImageManager = {}
        local CustomImageManagerAssets = {
            TransparencyTexture = {
                RobloxId = 139785960036434,
                Path = "Obsidian/assets/TransparencyTexture.png",
                URL = BaseURL .. "assets/TransparencyTexture.png",

                Id = nil,
            },

            SaturationMap = {
                RobloxId = 4155801252,
                Path = "Obsidian/assets/SaturationMap.png",
                URL = BaseURL .. "assets/SaturationMap.png",

                Id = nil,
            },
        }
        do
            local function RecursiveCreatePath(Path, IsFile)
                if not FileManager then
                    return
                end

                local Segments = Path:split("/")
                local TraversedPath = ""

                if IsFile then
                    table.remove(Segments, #Segments)
                end

                for _,Segment in ipairs(Segments) do
                    FileManager:CreateFolder(TraversedPath .. Segment)
                    TraversedPath = TraversedPath .. Segment .. "/"
                end

                return TraversedPath
            end

            function CustomImageManager.AddAsset(AssetName, RobloxAssetId, URL, ForceRedownload)
                if CustomImageManagerAssets[AssetName] ~= nil then
                    error(string.format("Asset %q already exists", AssetName))
                end

                assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

                CustomImageManagerAssets[AssetName] = {
                    RobloxId = RobloxAssetId,
                    Path = string.format("Obsidian/custom_assets/%s", AssetName),
                    URL = URL,

                    Id = nil,
                }

                CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
            end

            function CustomImageManager.GetAsset(AssetName)
                if not CustomImageManagerAssets[AssetName] then
                    return nil
                end

                local AssetData = CustomImageManagerAssets[AssetName]
                if AssetData.Id then
                    return AssetData.Id
                end

                local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)
                AssetData.Id = AssetID
                return AssetID
            end

            function CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
                if not FileManager then
                    return
                end

                local AssetData = CustomImageManagerAssets[AssetName]
                RecursiveCreatePath(AssetData.Path, true)

                if ForceRedownload ~= true and FileManager:Exists(AssetData.Path) then
                    return true, nil
                end

                FileManager:Write(AssetData.Path, game:HttpGet(AssetData.URL))
            end

            for AssetName,_ in CustomImageManagerAssets do
                CustomImageManager.DownloadAsset(AssetName)
            end
        end

        local Library = {
            LocalPlayer = LocalPlayer,
            DevicePlatform = nil,
            IsMobile = false,
            IsRobloxFocused = true,

            ScreenGui = nil,

            SearchText = "",
            Searching = false,
            GlobalSearch = true,
            LastSearchTab = nil,

            ActiveTab = nil,
            Tabs = {},
            TabButtons = {},
            DependencyBoxes = {},

            KeybindFrame = nil,
            KeybindContainer = nil,
            KeybindToggles = {},

            Notifications = {},

            ToggleKeybind = Enum.KeyCode.RightShift,

            BaseTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            TabTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            SliderTweenInfo = TweenInfo.new(0.025, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

            Toggled = false,
            Unloaded = false,

            Labels = Labels,
            Buttons = Buttons,
            Toggles = Toggles,
            Options = Options,

            NotifySide = "Right",
            ForceCheckbox = false,
            ShowToggleFrameInKeybinds = true,
            NotifyOnError = false,

            CantDragForced = false,

            Signals = {},
            UnloadSignals = {},

            OriginalMinSize = Vector2.new(480, 360),
            MinSize = Vector2.new(480, 360),
            DPIScale = 1,
            CornerRadius = 6,

            IsLightTheme = false,
            Scheme = {
                BackgroundColor = Color3.fromRGB(15, 15, 15),
                MainColor = Color3.fromRGB(25, 25, 25),
                AccentColor = Color3.fromRGB(125, 85, 255),
                OutlineColor = Color3.fromRGB(40, 40, 40),
                FontColor = Color3.new(1, 1, 1),
                Font = Font.fromEnum(Enum.Font.Code),

                RedColor = Color3.fromRGB(255, 50, 50),
                DarkColor = Color3.new(0, 0, 0),
                WhiteColor = Color3.new(1, 1, 1),
            },

            Registry = {},
            Scales = {},

            ImageManager = CustomImageManager,
        }

        local Templates = {
            Frame = {
                BorderSizePixel = 0,
            },
            ImageLabel = {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            },
            ImageButton = {
                AutoButtonColor = false,
                BorderSizePixel = 0,
            },
            ScrollingFrame = {
                BorderSizePixel = 0,
            },
            TextLabel = {
                BorderSizePixel = 0,
                FontFace = "Font",
                RichText = true,
                TextColor3 = "FontColor",
            },
            TextButton = {
                AutoButtonColor = false,
                BorderSizePixel = 0,
                FontFace = "Font",
                RichText = true,
                TextColor3 = "FontColor",
            },
            TextBox = {
                BorderSizePixel = 0,
                FontFace = "Font",
                PlaceholderColor3 = function()
                    local H, S, V = Library.Scheme.FontColor:ToHSV()
                    return Color3.fromHSV(H, S, V / 2)
                end,
                Text = "",
                TextColor3 = "FontColor",
            },
            UIListLayout = {
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
            UIStroke = {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            },

            Window = {
                Title = "KAT.lol",
                Footer = "v" .. Context["Version"] .. " | discord.gg/DwRT2nH93D",
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.fromOffset(1000, 520),
                IconSize = UDim2.fromOffset(30, 30),
                Center = true,
                Resizable = true,
                SearchbarSize = UDim2.fromScale(1, 1),
                GlobalSearch = true,
                CornerRadius = 6,
                NotifySide = "Right",
                Font = Enum.Font.Code,
                ToggleKeybind = Enum.KeyCode.RightShift,
                MobileButtonsSide = "Left"
            },
            Toggle = {
                Text = "Toggle",
                Default = false,

                Callback = function() end,
                Changed = function() end,

                Risky = false,
                Disabled = false,
                Visible = true,
            },
            Input = {
                Text = "Input",
                Default = "",
                Finished = false,
                Numeric = false,
                ClearTextOnFocus = true,
                Placeholder = "",
                AllowEmpty = true,
                EmptyReset = "---",

                Callback = function() end,
                Changed = function() end,

                Disabled = false,
                Visible = true,
            },
            Slider = {
                Text = "Slider",
                Default = 0,
                Min = 0,
                Max = 100,
                Rounding = 0,

                Prefix = "",
                Suffix = "",

                Callback = function() end,
                Changed = function() end,

                Disabled = false,
                Visible = true,
            },
            Dropdown = {
                Values = {},
                DisabledValues = {},
                Multi = false,
                MaxVisibleDropdownItems = 8,

                Callback = function() end,
                Changed = function() end,

                Disabled = false,
                Visible = true,
            },
            Viewport = {
                Object = nil,
                Camera = nil,
                Clone = true,
                AutoFocus = true,
                Interactive = false,
                Height = 200,
                Visible = true,
            },
            Image = {
                Image = "",
                Transparency = 0,
                BackgroundTransparency = 0,
                Color = Color3.new(1, 1, 1),
                RectOffset = Vector2.zero,
                RectSize = Vector2.zero,
                ScaleType = Enum.ScaleType.Fit,
                Height = 200,
                Visible = true,
            },
            Video = {
                Video = "",
                Looped = false,
                Playing = false,
                Volume = 1,
                Height = 200,
                Visible = true,
            },
            UIPassthrough = {
                Instance = nil,
                Height = 24,
                Visible = true,
            },

            KeyPicker = {
                Text = "KeyPicker",
                Default = "None",
                DefaultModifiers = {},
                Mode = "Toggle",
                Modes = { "Always", "Toggle", "Hold" },
                SyncToggleState = false,

                Callback = function() end,
                ChangedCallback = function() end,
                Changed = function() end,
                Clicked = function() end,
            },
            ColorPicker = {
                Default = Color3.new(1, 1, 1),

                Callback = function() end,
                Changed = function() end,
            },
        }

        local Places = {
            Bottom = { 0, 1 },
            Right = { 1, 0 },
        }
        local Sizes = {
            Left = { 0.5, 1 },
            Right = { 0.5, 1 },
        }

        local SchemeReplaceAlias = {
            RedColor = "Red",
            WhiteColor = "White",
            DarkColor = "Dark"
        }

        local SchemeAlias = {
            Red = "RedColor",
            White = "WhiteColor",
            Dark = "DarkColor"
        }

        local function GetSchemeValue(Index)
            if not Index then
                return nil
            end

            local ReplaceAliasIndex = SchemeReplaceAlias[Index]
            if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
                Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
                Library.Scheme[ReplaceAliasIndex] = nil

                return Library.Scheme[Index]
            end

            local AliasIndex = SchemeAlias[Index]
            if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
                warn(string.format("Scheme Value %q is deprecated, please use %q instead.", Index, AliasIndex))
                return Library.Scheme[AliasIndex]
            end

            return Library.Scheme[Index]
        end

        local function WaitForEvent(Event, Timeout, Condition)
            local Bindable = Create("BindableEvent")
            local Connection = Event:Once(function(...)
                if not Condition or typeof(Condition) == "function" and Condition(...) then
                    Bindable:Fire(true)
                else
                    Bindable:Fire(false)
                end
            end)
            task.delay(Timeout, function()
                Connection:Disconnect()
                Bindable:Fire(false)
            end)

            local Result = Bindable.Event:Wait()
            Bindable:Destroy()

            return Result
        end

        local function IsMouseInput(Input, IncludeM2)
            return Input.UserInputType == Enum.UserInputType.MouseButton1
                or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
                or Input.UserInputType == Enum.UserInputType.Touch
        end
        local function IsClickInput(Input, IncludeM2)
            return IsMouseInput(Input, IncludeM2)
                and Input.UserInputState == Enum.UserInputState.Begin
                and Library.IsRobloxFocused
        end
        local function IsHoverInput(Input)
            return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
                and Input.UserInputState == Enum.UserInputState.Change
        end
        local function IsDragInput(Input, IncludeM2)
            return IsMouseInput(Input, IncludeM2)
                and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
                and Library.IsRobloxFocused
        end

        local function GetTableSize(Table)
            local Size = 0

            for _, _ in Table do
                Size += 1
            end

            return Size
        end
        local function StopTween(Tween)
            if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
                return
            end

            Tween:Cancel()
        end
        local function Trim(Text)
            return Text:match("^%s*(.-)%s*$")
        end
        local function Round(Value, Rounding)
            assert(Rounding >= 0, "Invalid rounding number.")

            if Rounding == 0 then
                return math.floor(Value)
            end

            return tonumber(string.format("%." .. Rounding .. "f", Value))
        end

        local function GetPlayers()
            local PlayerList = Players:GetPlayers()

            local Idx = table.find(PlayerList, LocalPlayer)
            if Idx then
                table.remove(PlayerList, Idx)
            end

            table.sort(PlayerList, function(Player1, Player2)
                return Player1.Name:lower() < Player2.Name:lower()
            end)

            return PlayerList
        end

        function Library:UpdateDependencyBoxes()
            for _, Depbox in Library.DependencyBoxes do
                Depbox:Update(true)
            end

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        local function CheckDepbox(Box, Search)
            local VisibleElements = 0

            for _, ElementInfo in Box.Elements do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    local Visible = false

                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements += 1
                    end

                    continue
                end

                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in Box.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements += CheckDepbox(Depbox, Search)
            end

            Box.Holder.Visible = VisibleElements > 0
            return VisibleElements
        end
        local function RestoreDepbox(Box)
            for _, ElementInfo in Box.Elements do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            Box:Resize()
            Box.Holder.Visible = true

            for _, Depbox in Box.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end
        end

        local function ApplySearchToTab(Tab, Search)
            if not Tab then
                return
            end

            local HasVisible = false

            for _, Groupbox in Tab.Groupboxes do
                local VisibleElements = 0

                for _, ElementInfo in Groupbox.Elements do
                    if ElementInfo.Type == "Divider" then
                        ElementInfo.Holder.Visible = false
                        continue
                    elseif ElementInfo.SubButton then
                        local Visible = false

                        if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                            Visible = true
                        else
                            ElementInfo.Base.Visible = false
                        end
                        if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                            Visible = true
                        else
                            ElementInfo.SubButton.Base.Visible = false
                        end
                        ElementInfo.Holder.Visible = Visible
                        if Visible then
                            VisibleElements += 1
                        end

                        continue
                    end

                    if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        ElementInfo.Holder.Visible = true
                        VisibleElements += 1
                    else
                        ElementInfo.Holder.Visible = false
                    end
                end

                for _, Depbox in Groupbox.DependencyBoxes do
                    if not Depbox.Visible then
                        continue
                    end

                    VisibleElements += CheckDepbox(Depbox, Search)
                end

                if VisibleElements > 0 then
                    Groupbox:Resize()
                    HasVisible = true
                end
                Groupbox.BoxHolder.Visible = VisibleElements > 0
            end

            for _, Tabbox in Tab.Tabboxes do
                local VisibleTabs = 0
                local VisibleElements = {}

                for _, SubTab in Tabbox.Tabs do
                    VisibleElements[SubTab] = 0

                    for _, ElementInfo in SubTab.Elements do
                        if ElementInfo.Type == "Divider" then
                            ElementInfo.Holder.Visible = false
                            continue
                        elseif ElementInfo.SubButton then
                            local Visible = false

                            if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                                Visible = true
                            else
                                ElementInfo.Base.Visible = false
                            end
                            if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                                Visible = true
                            else
                                ElementInfo.SubButton.Base.Visible = false
                            end
                            ElementInfo.Holder.Visible = Visible
                            if Visible then
                                VisibleElements[SubTab] += 1
                            end

                            continue
                        end

                        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                            ElementInfo.Holder.Visible = true
                            VisibleElements[SubTab] += 1
                        else
                            ElementInfo.Holder.Visible = false
                        end
                    end

                    for _, Depbox in SubTab.DependencyBoxes do
                        if not Depbox.Visible then
                            continue
                        end

                        VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
                    end
                end

                for SubTab, Visible in VisibleElements do
                    SubTab.ButtonHolder.Visible = Visible > 0
                    if Visible > 0 then
                        VisibleTabs += 1
                        HasVisible = true

                        if Tabbox.ActiveTab == SubTab then
                            SubTab:Resize()
                        elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                            SubTab:Show()
                        end
                    end
                end

                Tabbox.BoxHolder.Visible = VisibleTabs > 0
            end

            return HasVisible
        end
        local function ResetTab(Tab)
            if not Tab then
                return
            end

            for _, Groupbox in Tab.Groupboxes do
                for _, ElementInfo in Groupbox.Elements do
                    ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                    if ElementInfo.SubButton then
                        ElementInfo.Base.Visible = ElementInfo.Visible
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end

                for _, Depbox in Groupbox.DependencyBoxes do
                    if not Depbox.Visible then
                        continue
                    end

                    RestoreDepbox(Depbox)
                end

                Groupbox:Resize()
                Groupbox.BoxHolder.Visible = true
            end

            for _, Tabbox in Tab.Tabboxes do
                for _, SubTab in Tabbox.Tabs do
                    for _, ElementInfo in SubTab.Elements do
                        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                        if ElementInfo.SubButton then
                            ElementInfo.Base.Visible = ElementInfo.Visible
                            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                        end
                    end

                    for _, Depbox in SubTab.DependencyBoxes do
                        if not Depbox.Visible then
                            continue
                        end

                        RestoreDepbox(Depbox)
                    end

                    SubTab.ButtonHolder.Visible = true
                end

                if Tabbox.ActiveTab then
                    Tabbox.ActiveTab:Resize()
                end
                Tabbox.BoxHolder.Visible = true
            end
        end

        function Library:UpdateSearch(SearchText)
            Library.SearchText = SearchText

            local TabsToReset = {}

            if Library.GlobalSearch then
                for _, Tab in Library.Tabs do
                    if typeof(Tab) == "table" and not Tab.IsKeyTab then
                        table.insert(TabsToReset, Tab)
                    end
                end
            elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
                table.insert(TabsToReset, Library.LastSearchTab)
            end

            for _, Tab in ipairs(TabsToReset) do
                ResetTab(Tab)
            end

            local Search = SearchText:lower()
            if Trim(Search) == "" then
                Library.Searching = false
                Library.LastSearchTab = nil
                return
            end
            if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
                Library.Searching = false
                Library.LastSearchTab = nil
                return
            end

            Library.Searching = true

            local TabsToSearch = {}

            if Library.GlobalSearch then
                TabsToSearch = TabsToReset
                if #TabsToSearch == 0 then
                    for _, Tab in Library.Tabs do
                        if typeof(Tab) == "table" and not Tab.IsKeyTab then
                            table.insert(TabsToSearch, Tab)
                        end
                    end
                end
            elseif Library.ActiveTab then
                table.insert(TabsToSearch, Library.ActiveTab)
            end

            local FirstVisibleTab = nil
            local ActiveHasVisible = false

            for _, Tab in ipairs(TabsToSearch) do
                local HasVisible = ApplySearchToTab(Tab, Search)
                if HasVisible then
                    if not FirstVisibleTab then
                        FirstVisibleTab = Tab
                    end
                    if Tab == Library.ActiveTab then
                        ActiveHasVisible = true
                    end
                end
            end

            if Library.GlobalSearch then
                if ActiveHasVisible and Library.ActiveTab then
                    Library.ActiveTab:RefreshSides()
                elseif FirstVisibleTab then
                    local SearchMarker = SearchText
                    task.defer(function()
                        if Library.SearchText ~= SearchMarker then
                            return
                        end

                        if Library.ActiveTab ~= FirstVisibleTab then
                            FirstVisibleTab:Show()
                        end
                    end)
                end
                Library.LastSearchTab = nil
            else
                Library.LastSearchTab = Library.ActiveTab
            end
        end

        function Library:AddToRegistry(Instance, Properties)
            Library.Registry[Instance] = Properties
        end

        function Library:RemoveFromRegistry(Instance)
            Library.Registry[Instance] = nil
        end

        function Library:UpdateColorsUsingRegistry()
            for Instance, Properties in Library.Registry do
                for Property, Index in Properties do
                    local SchemeValue = GetSchemeValue(Index)

                    if SchemeValue or typeof(Index) == "function" then
                        Instance[Property] = SchemeValue or Index()
                    end
                end
            end
        end

        function Library:SetDPIScale(DPIScale)
            Library.DPIScale = DPIScale / 100
            Library.MinSize = Library.OriginalMinSize * Library.DPIScale

            for _, UIScale in Library.Scales do
                UIScale.Scale = Library.DPIScale
            end

            for _, Option in Options do
                if Option.Type == "Dropdown" then
                    Option:RecalculateListSize()
                end
            end

            for _, Notification in Library.Notifications do
                Notification:Resize()
            end
        end

        function Library:GiveSignal(Connection)
            local ConnectionType = typeof(Connection)
            if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
                table.insert(Library.Signals, Connection)
            end

            return Connection
        end

        function IsValidCustomIcon(Icon)
            return typeof(Icon) == "string" and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
        end
        local FetchIcons, Icons = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()
        end)

        function Library:GetIcon(IconName)
            if not FetchIcons then
                return
            end

            local Success, Icon = pcall(Icons.GetAsset, IconName)
            if not Success then
                return
            end
            return Icon
        end

        function Library:GetCustomIcon(IconName)
            if not IsValidCustomIcon(IconName) then
                return Library:GetIcon(IconName)
            else
                return {
                    Url = IconName,
                    ImageRectOffset = Vector2.zero,
                    ImageRectSize = Vector2.zero,
                    Custom = true,
                }
            end
        end

        function Library:Validate(Table, Template)
            if typeof(Table) ~= "table" then
                return Template
            end

            for k, v in Template do
                if typeof(k) == "number" then
                    continue
                end

                if typeof(v) == "table" then
                    Table[k] = Library:Validate(Table[k], v)
                elseif Table[k] == nil then
                    Table[k] = v
                end
            end

            return Table
        end

        local function FillInstance(Table, Instance)
            local ThemeProperties = Library.Registry[Instance] or {}

            for key, value in Table do
                if ThemeProperties[key] then
                    ThemeProperties[key] = nil
                
                elseif key ~= "Text" then
                    local SchemeValue = GetSchemeValue(value)

                    if SchemeValue or typeof(value) == "function" then
                        ThemeProperties[key] = value
                        value = SchemeValue or value()
                    end
                end

                Instance[key] = value
            end

            if GetTableSize(ThemeProperties) > 0 then
                Library.Registry[Instance] = ThemeProperties
            end
        end

        local function New(ClassName, Properties)
            local Instance = Create(ClassName)

            if Templates[ClassName] then
                FillInstance(Templates[ClassName], Instance)
            end
            FillInstance(Properties, Instance)

            if Properties["Parent"] and not Properties["ZIndex"] then
                pcall(function()
                    Instance.ZIndex = Properties.Parent.ZIndex
                end)
            end

            return Instance
        end

        local function SafeParentUI(Instance, Parent)
            local Success, _error = pcall(function()
                if not Parent then
                    Parent = CoreGui
                end

                local DestinationParent
                if typeof(Parent) == "function" then
                    DestinationParent = Parent()
                else
                    DestinationParent = Parent
                end

                Instance.Parent = DestinationParent
            end)

            if not (Success and Instance.Parent) then
                Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
            end
        end

        local function ParentUI(UI, SkipHiddenUI)
            if SkipHiddenUI then
                SafeParentUI(UI, CoreGui)
                return
            end

            SafeParentUI(UI, gethui)
        end

        local function GetRandomString()
            local Output = ""
            for _ = 2, 25 do
                Output = Output .. string.char(math.random(1, 250))
            end
            
            return Output
        end

        local ScreenGui = New("ScreenGui", {
            Name = "ns__Obsidian|" .. GetRandomString(),
            DisplayOrder = 999,
            ResetOnSpawn = false,
        })
        ParentUI(ScreenGui)
        Library.ScreenGui = ScreenGui
        ScreenGui.DescendantRemoving:Connect(function(Instance)
            Library:RemoveFromRegistry(Instance)
        end)

        local ModalElement = New("TextButton", {
            BackgroundTransparency = 1,
            Modal = false,
            Size = UDim2.fromScale(0, 0),
            AnchorPoint = Vector2.zero,
            Text = "",
            ZIndex = -999,
            Parent = ScreenGui,
        })

        local NotificationArea
        local NotificationList
        do
            NotificationArea = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -6, 0, 6),
                Size = UDim2.new(0, 300, 1, -6),
                Parent = ScreenGui,
            })
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = NotificationArea,
                })
            )

            NotificationList = New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 8),
                Parent = NotificationArea,
            })
        end

        function Library:GetBetterColor(Color, Add)
            Add = Add * (Library.IsLightTheme and -4 or 2)
            return Color3.fromRGB(
                math.clamp(Color.R * 255 + Add, 0, 255),
                math.clamp(Color.G * 255 + Add, 0, 255),
                math.clamp(Color.B * 255 + Add, 0, 255)
            )
        end

        function Library:GetLighterColor(Color)
            local H, S, V = Color:ToHSV()
            return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
        end

        function Library:GetDarkerColor(Color)
            local H, S, V = Color:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end

        function Library:GetKeyString(KeyCode: Enum.KeyCode)
            if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
                return string.char(KeyCode.Value)
            end

            return KeyCode.Name
        end

        function Library:GetTextBounds(Text, Font: Font, Size, Width): (number, number)
            local Params = Create("GetTextBoundsParams", nil, {
                Text = Text,
                RichText = true,
                Font = Font,
                Size = Size,
                Width = Width or workspace.CurrentCamera.ViewportSize.X - 32
            })

            local Bounds = TextService:GetTextBoundsAsync(Params)
            return Bounds.X, Bounds.Y
        end

        function Library:MouseIsOverFrame(Frame, Mouse)
            local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
            return Mouse.X >= AbsPos.X
                and Mouse.X <= AbsPos.X + AbsSize.X
                and Mouse.Y >= AbsPos.Y
                and Mouse.Y <= AbsPos.Y + AbsSize.Y
        end

        function Library:SafeCallback(Func, ...)
            if not (Func and typeof(Func) == "function") then
                return
            end

            local Result = table.pack(xpcall(Func, function(Error)
                task.defer(error, debug.traceback(Error, 2))
                if Library.NotifyOnError then
                    Library:Notify(Error)
                end

                return Error
            end, ...))

            if not Result[1] then
                return nil
            end

            return table.unpack(Result, 2, Result.n)
        end

        function Library:MakeDraggable(UI, DragFrame, IgnoreToggled, IsMainWindow)
            local StartPos
            local FramePos
            local Dragging = false
            local Changed
            DragFrame.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
                    return
                end

                StartPos = Input.Position
                FramePos = UI.Position
                Dragging = true

                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState ~= Enum.UserInputState.End then
                        return
                    end

                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end
                end)
            end)
            Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
                if
                    (not IgnoreToggled and not Library.Toggled)
                    or (IsMainWindow and Library.CantDragForced)
                    or not (ScreenGui and ScreenGui.Parent)
                then
                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    return
                end

                if Dragging and IsHoverInput(Input) then
                    local Delta = Input.Position - StartPos
                    UI.Position =
                        UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
                end
            end))
        end

        function Library:MakeResizable(UI, DragFrame, Callback)
            local StartPos
            local FrameSize
            local Dragging = false
            local Changed

            DragFrame.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                StartPos = Input.Position
                FrameSize = UI.Size
                Dragging = true

                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState ~= Enum.UserInputState.End then
                        return
                    end

                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end
                end)
            end)

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input)
                if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    return
                end

                if Dragging and IsHoverInput(Input) then
                    local Delta = Input.Position - StartPos
                    UI.Size = UDim2.new(
                        FrameSize.X.Scale,
                        math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                        FrameSize.Y.Scale,
                        math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
                    )
                    if Callback then
                        Library:SafeCallback(Callback)
                    end
                end
            end))
        end

        function Library:MakeCover(Holder, Place)
            local Pos = Places[Place] or { 0, 0 }
            local Size = Sizes[Place] or { 1, 0.5 }

            local Cover = New("Frame", {
                AnchorPoint = Vector2.new(Pos[1], Pos[2]),
                BackgroundColor3 = Holder.BackgroundColor3,
                Position = UDim2.fromScale(Pos[1], Pos[2]),
                Size = UDim2.fromScale(Size[1], Size[2]),
                Parent = Holder,
            })

            return Cover
        end

        function Library:MakeLine(Frame, Info)
            local Line = New("Frame", {
                AnchorPoint = Info.AnchorPoint or Vector2.zero,
                BackgroundColor3 = "OutlineColor",
                Position = Info.Position,
                Size = Info.Size,
                ZIndex = Info.ZIndex or Frame.ZIndex,
                Parent = Frame,
            })

            return Line
        end

        function Library:AddOutline(Frame)
            local OutlineStroke = New("UIStroke", {
                Color = "OutlineColor",
                Thickness = 1,
                ZIndex = 2,
                Parent = Frame,
            })
            local ShadowStroke = New("UIStroke", {
                Color = "DarkColor",
                Thickness = 1.5,
                ZIndex = 1,
                Parent = Frame,
            })
            return OutlineStroke, ShadowStroke
        end

        function Library:AddBlank(Frame, Size)
            return New("Frame", {
                BackgroundTransparency = 1,
                Size = Size or UDim2.fromScale(0, 0),
                Parent = Frame,
            })
        end

        function Library:AddDraggableLabel(Text)
            local Table = {}

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromOffset(0, 0),
                Position = UDim2.fromOffset(6, 6),
                Text = Text,
                TextSize = 15,
                ZIndex = 10,
                Parent = ScreenGui,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Label,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 6),
                Parent = Label,
            })
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = Label,
                })
            )
            Library:AddOutline(Label)

            Library:MakeDraggable(Label, Label, true)

            Table.Label = Label

            function Table:SetText(Text)
                Label.Text = Text
            end

            function Table:SetVisible(Visible)
                Label.Visible = Visible
            end

            return Table
        end

        function Library:AddDraggableButton(Text, Func, ExcludeScaling)
            local Table = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(6, 6),
                TextSize = 16,
                ZIndex = 10,
                Parent = ScreenGui,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Button,
            })
            if not ExcludeScaling then
                table.insert(
                    Library.Scales,
                    New("UIScale", {
                        Parent = Button,
                    })
                )
            end
            Library:AddOutline(Button)

            Button.MouseButton1Click:Connect(function()
                Library:SafeCallback(Func, Table)
            end)
            Library:MakeDraggable(Button, Button, true)

            Table.Button = Button

            function Table:SetText(Text)
                local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

                Button.Text = Text
                Button.Size = UDim2.fromOffset(X * 2, Y * 2)
            end
            Table:SetText(Text)

            return Table
        end

        function Library:AddDraggableMenu(Name)
            local Holder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.fromOffset(0, 0),
                ZIndex = 10,
                Parent = ScreenGui,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Holder,
            })
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = Holder,
                })
            )
            Library:AddOutline(Holder)

            Library:MakeLine(Holder, {
                Position = UDim2.fromOffset(0, 34),
                Size = UDim2.new(1, 0, 0, 1),
            })

            local Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                Text = Name,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = Label,
            })

            local Container = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 35),
                Size = UDim2.new(1, 0, 1, -35),
                Parent = Holder,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 7),
                Parent = Container,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = Container,
            })

            Library:MakeDraggable(Holder, Label, true)
            return Holder, Container
        end

        local CurrentMenu
        function Library:AddContextMenu(Holder,  Size, Offset, List, ActiveCallback)
            local Menu
            if List then
                Menu = New("ScrollingFrame", {
                    AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    BackgroundColor3 = "BackgroundColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    CanvasSize = UDim2.fromOffset(0, 0),
                    ScrollBarImageColor3 = "OutlineColor",
                    ScrollBarThickness = List == 2 and 2 or 0,
                    Size = typeof(Size) == "function" and Size() or Size,
                    TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    Visible = false,
                    ZIndex = 10,
                    Parent = ScreenGui,
                })
            else
                Menu = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Size = typeof(Size) == "function" and Size() or Size,
                    Visible = false,
                    ZIndex = 10,
                    Parent = ScreenGui,
                })
            end
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = Menu,
                })
            )

            local Table = {
                Active = false,
                Holder = Holder,
                Menu = Menu,
                List = nil,
                Signal = nil,

                Size = Size,
            }

            if List then
                Table.List = New("UIListLayout", {
                    Parent = Menu,
                })
            end

            function Table:Open()
                if CurrentMenu == Table then
                    return
                elseif CurrentMenu then
                    CurrentMenu:Close()
                end

                CurrentMenu = Table
                Table.Active = true

                if typeof(Offset) == "function" then
                    Menu.Position = UDim2.fromOffset(
                        math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                        math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                    )
                else
                    Menu.Position = UDim2.fromOffset(
                        math.floor(Holder.AbsolutePosition.X + Offset[1]),
                        math.floor(Holder.AbsolutePosition.Y + Offset[2])
                    )
                end
                Menu.Size = typeof(Table.Size) == "function" and Table.Size() or Table.Size
                if typeof(ActiveCallback) == "function" then
                    Library:SafeCallback(ActiveCallback, true)
                end

                Menu.Visible = true

                Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                    if typeof(Offset) == "function" then
                        Menu.Position = UDim2.fromOffset(
                            math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                            math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                        )
                    else
                        Menu.Position = UDim2.fromOffset(
                            math.floor(Holder.AbsolutePosition.X + Offset[1]),
                            math.floor(Holder.AbsolutePosition.Y + Offset[2])
                        )
                    end
                end)
            end

            function Table:Close()
                if CurrentMenu ~= Table then
                    return
                end
                Menu.Visible = false

                if Table.Signal then
                    Table.Signal:Disconnect()
                    Table.Signal = nil
                end
                Table.Active = false
                CurrentMenu = nil
                if typeof(ActiveCallback) == "function" then
                    Library:SafeCallback(ActiveCallback, false)
                end
            end

            function Table:Toggle()
                if Table.Active then
                    Table:Close()
                else
                    Table:Open()
                end
            end

            function Table:SetSize(Size)
                Table.Size = Size
                Menu.Size = typeof(Size) == "function" and Size() or Size
            end

            return Table
        end

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if IsClickInput(Input, true) then
                local Location = Input.Position

                if
                    CurrentMenu
                    and not (
                        Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                        or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
                    )
                then
                    CurrentMenu:Close()
                end
            end
        end))

        local TooltipLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            TextSize = 14,
            TextWrapped = true,
            Visible = false,
            ZIndex = 20,
            Parent = ScreenGui,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 2),
            Parent = TooltipLabel,
        })
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = TooltipLabel,
            })
        )
        TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if Library.Unloaded then
                return
            end

            local X, _ = Library:GetTextBounds(
                TooltipLabel.Text,
                TooltipLabel.FontFace,
                TooltipLabel.TextSize,
                (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale
            )

            TooltipLabel.Size = UDim2.fromOffset(X + 8)
        end)

        local CurrentHoverInstance
        function Library:AddTooltip(InfoStr, DisabledInfoStr, HoverInstance)
            local TooltipTable = {
                Disabled = false,
                Hovering = false,
                Signals = {},
            }

            local function DoHover()
                if
                    CurrentHoverInstance == HoverInstance
                    or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
                    or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
                    or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
                then
                    return
                end
                CurrentHoverInstance = HoverInstance

                TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
                TooltipLabel.Visible = true

                while
                    Library.Toggled
                    and Library:MouseIsOverFrame(HoverInstance, Mouse)
                    and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
                do
                    TooltipLabel.Position = UDim2.fromOffset(
                        Mouse.X + 14,
                        Mouse.Y + 12
                    )

                    RunService.RenderSteppedWait()
                end

                TooltipLabel.Visible = false
                CurrentHoverInstance = nil
            end

            local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
                local ConnectionType = typeof(Connection)
                if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
                    table.insert(TooltipTable.Signals, Connection)
                end

                return Connection
            end

            GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
            GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
            GiveSignal(HoverInstance.MouseLeave:Connect(function()
                if CurrentHoverInstance ~= HoverInstance then
                    return
                end

                TooltipLabel.Visible = false
                CurrentHoverInstance = nil
            end))

            function TooltipTable:Destroy()
                for Index = #TooltipTable.Signals, 1, -1 do
                    local Connection = table.remove(TooltipTable.Signals, Index)
                    if Connection and Connection.Connected then
                        Connection:Disconnect()
                    end
                end

                if CurrentHoverInstance == HoverInstance then
                    if TooltipLabel then
                        TooltipLabel.Visible = false
                    end

                    CurrentHoverInstance = nil
                end
            end

            table.insert(Tooltips, TooltipLabel)
            return TooltipTable
        end

        function Library:OnUnload(Callback)
            table.insert(Library.UnloadSignals, Callback)
        end

        function Library:Unload()
            for Index = #Library.Signals, 1, -1 do
                local Connection = table.remove(Library.Signals, Index)
                if Connection and Connection.Connected then
                    Connection:Disconnect()
                end
            end

            for _, Callback in Library.UnloadSignals do
                Library:SafeCallback(Callback)
            end

            for _, Tooltip in Tooltips do
                Library:SafeCallback(Tooltip.Destroy, Tooltip)
            end

            Library.Unloaded = true
            ScreenGui:Destroy()
        end

        local CheckIcon = Library:GetIcon("check")
        local ArrowIcon = Library:GetIcon("chevron-up")
        local ResizeIcon = Library:GetIcon("move-diagonal-2")
        local KeyIcon = Library:GetIcon("key")
        local MoveIcon = Library:GetIcon("move")

        function Library:SetIconModule(module)
            FetchIcons = true
            Icons = module

            CheckIcon = Library:GetIcon("check")
            ArrowIcon = Library:GetIcon("chevron-up")
            ResizeIcon = Library:GetIcon("move-diagonal-2")
            KeyIcon = Library:GetIcon("key")
            MoveIcon = Library:GetIcon("move")
        end

        local BaseAddons = {}
        do
            local Funcs = {}

            function Funcs:AddKeyPicker(Idx, Info)
                Info = Library:Validate(Info, Templates.KeyPicker)

                local ParentObj = self
                local ToggleLabel = ParentObj.TextLabel

                local KeyPicker = {
                    Text = Info.Text,
                    Value = Info.Default,
                    Modifiers = Info.DefaultModifiers,
                    DisplayValue = Info.Default,

                    Toggled = false,
                    Mode = Info.Mode,
                    SyncToggleState = Info.SyncToggleState,

                    Callback = Info.Callback,
                    ChangedCallback = Info.ChangedCallback,
                    Changed = Info.Changed,
                    Clicked = Info.Clicked,

                    Type = "KeyPicker",
                }

                if KeyPicker.Mode == "Press" then
                    assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

                    KeyPicker.SyncToggleState = false
                    Info.Modes = { "Press" }
                    Info.Mode = "Press"
                end

                if KeyPicker.SyncToggleState then
                    Info.Modes = { "Toggle", "Hold" }

                    if not table.find(Info.Modes, Info.Mode) then
                        Info.Mode = "Toggle"
                    end
                end

                local Picking = false

                local SpecialKeys = {
                    ["MB1"] = Enum.UserInputType.MouseButton1,
                    ["MB2"] = Enum.UserInputType.MouseButton2,
                    ["MB3"] = Enum.UserInputType.MouseButton3,
                }

                local SpecialKeysInput = {
                    [Enum.UserInputType.MouseButton1] = "MB1",
                    [Enum.UserInputType.MouseButton2] = "MB2",
                    [Enum.UserInputType.MouseButton3] = "MB3",
                }

                local Modifiers = {
                    ["LAlt"] = Enum.KeyCode.LeftAlt,
                    ["RAlt"] = Enum.KeyCode.RightAlt,

                    ["LCtrl"] = Enum.KeyCode.LeftControl,
                    ["RCtrl"] = Enum.KeyCode.RightControl,

                    ["LShift"] = Enum.KeyCode.LeftShift,
                    ["RShift"] = Enum.KeyCode.RightShift,

                    ["Tab"] = Enum.KeyCode.Tab,
                    ["CapsLock"] = Enum.KeyCode.CapsLock,
                }

                local ModifiersInput = {
                    [Enum.KeyCode.LeftAlt] = "LAlt",
                    [Enum.KeyCode.RightAlt] = "RAlt",

                    [Enum.KeyCode.LeftControl] = "LCtrl",
                    [Enum.KeyCode.RightControl] = "RCtrl",

                    [Enum.KeyCode.LeftShift] = "LShift",
                    [Enum.KeyCode.RightShift] = "RShift",

                    [Enum.KeyCode.Tab] = "Tab",
                    [Enum.KeyCode.CapsLock] = "CapsLock",
                }

                local IsModifierInput = function(Input)
                    return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
                end

                local GetActiveModifiers = function()
                    local ActiveModifiers = {}

                    for Name, Input in Modifiers do
                        if table.find(ActiveModifiers, Name) then
                            continue
                        end
                        if not UserInputService:IsKeyDown(Input) then
                            continue
                        end

                        table.insert(ActiveModifiers, Name)
                    end

                    return ActiveModifiers
                end

                local AreModifiersHeld = function(Required)
                    if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                        return true
                    end

                    local ActiveModifiers = GetActiveModifiers()
                    local Holding = true

                    for _, Name in Required do
                        if table.find(ActiveModifiers, Name) then
                            continue
                        end

                        Holding = false
                        break
                    end

                    return Holding
                end

                local IsInputDown = function(Input)
                    if not Input then
                        return false
                    end

                    if SpecialKeysInput[Input.UserInputType] ~= nil then
                        return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                            and not UserInputService:GetFocusedTextBox()
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
                    else
                        return false
                    end
                end

                local ConvertToInputModifiers = function(CurrentModifiers)
                    local InputModifiers = {}

                    for _, name in CurrentModifiers do
                        table.insert(InputModifiers, Modifiers[name])
                    end

                    return InputModifiers
                end

                local VerifyModifiers = function(CurrentModifiers)
                    if typeof(CurrentModifiers) ~= "table" then
                        return {}
                    end

                    local ValidModifiers = {}

                    for _, name in CurrentModifiers do
                        if not Modifiers[name] then
                            continue
                        end

                        table.insert(ValidModifiers, name)
                    end

                    return ValidModifiers
                end

                KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers)

                local Picker = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Size = UDim2.fromOffset(18, 18),
                    Text = KeyPicker.Value,
                    TextSize = 14,
                    Parent = ToggleLabel,
                })

                local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
                do
                    local Holder = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 16),
                        Text = "",
                        Visible = not Info.NoUI,
                        Parent = Library.KeybindContainer,
                    })

                    local Label = New("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(0, 1),
                        Text = "",
                        TextSize = 14,
                        TextTransparency = 0.5,
                        Parent = Holder,
                    })

                    local Checkbox = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "MainColor",
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.fromOffset(14, 14),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Parent = Holder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = Checkbox,
                    })
                    New("UIStroke", {
                        Color = "OutlineColor",
                        Parent = Checkbox,
                    })

                    local CheckImage = New("ImageLabel", {
                        Image = CheckIcon and CheckIcon.Url or "",
                        ImageColor3 = "FontColor",
                        ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                        ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                        ImageTransparency = 1,
                        Position = UDim2.fromOffset(2, 2),
                        Size = UDim2.new(1, -4, 1, -4),
                        Parent = Checkbox,
                    })

                    function KeybindsToggle:Display(State)
                        Label.TextTransparency = State and 0 or 0.5
                        CheckImage.ImageTransparency = State and 0 or 1
                    end

                    function KeybindsToggle:SetText(Text)
                        Label.Text = Text
                    end

                    function KeybindsToggle:SetVisibility(Visibility)
                        Holder.Visible = Visibility
                    end

                    function KeybindsToggle:SetNormal(Normal)
                        KeybindsToggle.Normal = Normal

                        Holder.Active = not Normal
                        Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22, 0)
                        Checkbox.Visible = not Normal
                    end

                    KeyPicker.DoClick = function(...) end
                    Holder.MouseButton1Click:Connect(function()
                        if KeybindsToggle.Normal then
                            return
                        end

                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                    end)

                    KeybindsToggle.Holder = Holder
                    KeybindsToggle.Label = Label
                    KeybindsToggle.Checkbox = Checkbox
                    KeybindsToggle.Loaded = true
                    table.insert(Library.KeybindToggles, KeybindsToggle)
                end

                local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
                    return { Picker.AbsoluteSize.X + 1.5, 0.5 }
                end, 1)
                KeyPicker.Menu = MenuTable

                local ModeButtons = {}
                for _, Mode in Info.Modes do
                    local ModeButton = {}

                    local Button = New("TextButton", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 21),
                        Text = Mode,
                        TextSize = 14,
                        TextTransparency = 0.5,
                        Parent = MenuTable.Menu,
                    })

                    function ModeButton:Select()
                        for _, Button in ModeButtons do
                            Button:Deselect()
                        end

                        KeyPicker.Mode = Mode

                        Button.BackgroundTransparency = 0
                        Button.TextTransparency = 0

                        MenuTable:Close()
                    end

                    function ModeButton:Deselect()
                        KeyPicker.Mode = nil

                        Button.BackgroundTransparency = 1
                        Button.TextTransparency = 0.5
                    end

                    Button.MouseButton1Click:Connect(function()
                        ModeButton:Select()
                    end)

                    if KeyPicker.Mode == Mode then
                        ModeButton:Select()
                    end

                    ModeButtons[Mode] = ModeButton
                end

                function KeyPicker:Display(PickerText)
                    if Library.Unloaded then
                        return
                    end

                    local X, Y = Library:GetTextBounds(
                        PickerText or KeyPicker.DisplayValue,
                        Picker.FontFace,
                        Picker.TextSize,
                        ToggleLabel.AbsoluteSize.X
                    )
                    Picker.Text = PickerText or KeyPicker.DisplayValue
                    TweenService:Create(Picker, Library.BaseTweenInfo, {
                        Size = UDim2.fromOffset((X + 9), (Y + 4))
                    }):Play()
                end

                function KeyPicker:Update()
                    KeyPicker:Display()

                    if Info.NoUI then
                        return
                    end

                    if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                        KeybindsToggle:SetVisibility(false)
                        return
                    end

                    local State = KeyPicker:GetState()
                    local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

                    if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                        ParentObj:SetValue(State)
                    end

                    if KeybindsToggle.Loaded then
                        if ShowToggle then
                            KeybindsToggle:SetNormal(false)
                        else
                            KeybindsToggle:SetNormal(true)
                        end

                        KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                        KeybindsToggle:SetVisibility(true)
                        KeybindsToggle:Display(State)
                    end
                end

                function KeyPicker:GetState()
                    if KeyPicker.Mode == "Always" then
                        return true
                    elseif KeyPicker.Mode == "Hold" then
                        local Key = KeyPicker.Value
                        if Key == "None" then
                            return false
                        end

                        if not AreModifiersHeld(KeyPicker.Modifiers) then
                            return false
                        end

                        if SpecialKeys[Key] ~= nil then
                            return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                                and not UserInputService:GetFocusedTextBox()
                        else
                            return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                        end
                    else
                        return KeyPicker.Toggled
                    end
                end

                function KeyPicker:OnChanged(Func)
                    KeyPicker.Changed = Func
                end

                function KeyPicker:OnClick(Func)
                    KeyPicker.Clicked = Func
                end

                function KeyPicker:DoClick()
                    if KeyPicker.Mode == "Press" then
                        if KeyPicker.Toggled and Info.WaitForCallback == true then
                            return
                        end

                        KeyPicker.Toggled = true
                    end

                    Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
                    Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

                    if KeyPicker.Mode == "Press" then
                        KeyPicker.Toggled = false
                    end
                end

                function KeyPicker:SetValue(Data)
                    local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

                    local IsKeyValid, UserInputType = pcall(function()
                        if Key == "None" then
                            Key = nil
                            return nil
                        end

                        if SpecialKeys[Key] == nil then
                            return Enum.KeyCode[Key]
                        end

                        return SpecialKeys[Key]
                    end)

                    if Key == nil then
                        KeyPicker.Value = "None"
                    elseif IsKeyValid then
                        KeyPicker.Value = Key
                    else
                        KeyPicker.Value = "Unknown"
                    end

                    KeyPicker.Modifiers =
                        VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
                    KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                        then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                        else KeyPicker.Value

                    if ModeButtons[Mode] then
                        ModeButtons[Mode]:Select()
                    end

                    local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
                    Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
                    Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)

                    KeyPicker:Update()
                end

                function KeyPicker:SetText(Text)
                    KeybindsToggle:SetText(Text)
                    KeyPicker:Update()
                end

                Picker.MouseButton1Click:Connect(function()
                    if Picking then
                        return
                    end

                    Picking = true

                    Picker.Text = "..."
                    Picker.Size = UDim2.fromOffset(29, 18)

                    local Input
                    local ActiveModifiers = {}

                    local GetInput = function()
                        Input = UserInputService.InputBegan:Wait()
                        return UserInputService:GetFocusedTextBox() ~= nil
                    end

                    repeat task.wait()
                        Picker.Text = "..."
                        Picker.Size = UDim2.fromOffset(29, 18)

                        if GetInput() then
                            Picking = false
                            KeyPicker:Update()
                            return
                        end

                        if Input.KeyCode == Enum.KeyCode.Escape then
                            break
                        end

                        if IsModifierInput(Input) then
                            local StopLoop = false

                            repeat
                                task.wait()
                                if UserInputService:IsKeyDown(Input.KeyCode) then
                                    task.wait(0.075)

                                    if UserInputService:IsKeyDown(Input.KeyCode) then
                                        if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                            ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                            KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                        end

                                        if GetInput() then
                                            StopLoop = true
                                            break
                                        end

                                        if Input.KeyCode == Enum.KeyCode.Escape then
                                            break
                                        end

                                        if not IsModifierInput(Input) then
                                            break
                                        end
                                    else
                                        if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                            break
                                        end
                                    end
                                end
                            until false

                            if StopLoop then
                                Picking = false
                                KeyPicker:Update()
                                return
                            end
                        end

                        break
                    until false

                    local Key = "Unknown"
                    if SpecialKeysInput[Input.UserInputType] ~= nil then
                        Key = SpecialKeysInput[Input.UserInputType]
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
                    end

                    ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

                    KeyPicker.Toggled = false
                    KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

                    repeat
                        task.wait()
                    until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
                    Picking = false
                end)
                Picker.MouseButton2Click:Connect(MenuTable.Toggle)

                Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
                    if Library.Unloaded then
                        return
                    end

                    if KeyPicker.Mode == "Always"
                        or KeyPicker.Value == "Unknown"
                        or KeyPicker.Value == "None"
                        or Picking
                        or UserInputService:GetFocusedTextBox()
                    then
                        return
                    end

                    local Key = KeyPicker.Value
                    local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
                    local HoldingKey = false

                    if
                        Key
                        and HoldingModifiers == true
                        and (
                            SpecialKeysInput[Input.UserInputType] == Key
                            or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                        )
                    then
                        HoldingKey = true
                    end

                    if KeyPicker.Mode == "Toggle" then
                        if HoldingKey then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    elseif KeyPicker.Mode == "Press" then
                        if HoldingKey then
                            KeyPicker:DoClick()
                        end
                    end

                    KeyPicker:Update()
                end))

                Library:GiveSignal(UserInputService.InputEnded:Connect(function()
                    if Library.Unloaded then
                        return
                    end

                    if
                        KeyPicker.Value == "Unknown"
                        or KeyPicker.Value == "None"
                        or Picking
                        or UserInputService:GetFocusedTextBox()
                    then
                        return
                    end

                    KeyPicker:Update()
                end))

                KeyPicker:Update()

                if ParentObj.Addons then
                    table.insert(ParentObj.Addons, KeyPicker)
                end

                KeyPicker.Default = KeyPicker.Value
                KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

                Options[Idx] = KeyPicker

                return self
            end

            local HueSequenceTable = {}
            for Hue = 0, 1, 0.1 do
                table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
            end
            function Funcs:AddColorPicker(Idx, Info)
                Info = Library:Validate(Info, Templates.ColorPicker)

                local ParentObj = self
                local ToggleLabel = ParentObj.TextLabel

                local ColorPicker = {
                    Value = Info.Default,

                    Transparency = Info.Transparency or 0,
                    Title = Info.Title,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Type = "ColorPicker",
                }
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

                local Holder = New("TextButton", {
                    BackgroundColor3 = ColorPicker.Value,
                    BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
                    BorderSizePixel = 1,
                    Size = UDim2.fromOffset(18, 18),
                    Text = "",
                    Parent = ToggleLabel,
                })

                local HolderTransparency = New("ImageLabel", {
                    Image = "rbxassetid://139785960036434",
                    ImageTransparency = (1 - ColorPicker.Transparency),
                    ScaleType = Enum.ScaleType.Tile,
                    Size = UDim2.fromScale(1, 1),
                    TileSize = UDim2.fromOffset(9, 9),
                    Parent = Holder,
                })

                local ColorMenu = Library:AddContextMenu(
                    Holder,
                    UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
                    function()
                        return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
                    end,
                    1
                )
                ColorMenu.List.Padding = UDim.new(0, 8)
                ColorPicker.ColorMenu = ColorMenu

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 6),
                    Parent = ColorMenu.Menu,
                })

                if typeof(ColorPicker.Title) == "string" then
                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 8),
                        Text = ColorPicker.Title,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = ColorMenu.Menu,
                    })
                end

                local ColorHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 200),
                    Parent = ColorMenu.Menu,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 6),
                    Parent = ColorHolder,
                })

                local SatVipMap = New("ImageButton", {
                    BackgroundColor3 = ColorPicker.Value,
                    Image = "rbxassetid://4155801252",
                    Size = UDim2.fromOffset(200, 200),
                    Parent = ColorHolder,
                })

                local SatVibCursor = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "WhiteColor",
                    Size = UDim2.fromOffset(6, 6),
                    Parent = SatVipMap,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SatVibCursor,
                })
                New("UIStroke", {
                    Color = "DarkColor",
                    Parent = SatVibCursor,
                })

                local HueSelector = New("TextButton", {
                    Size = UDim2.fromOffset(16, 200),
                    Text = "",
                    Parent = ColorHolder,
                })
                New("UIGradient", {
                    Color = ColorSequence.new(HueSequenceTable),
                    Rotation = 90,
                    Parent = HueSelector,
                })

                local HueCursor = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = "WhiteColor",
                    BorderColor3 = "DarkColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0.5, ColorPicker.Hue),
                    Size = UDim2.new(1, 2, 0, 1),
                    Parent = HueSelector,
                })

                local TransparencySelector, TransparencyColor, TransparencyCursor
                if Info.Transparency then
                    TransparencySelector = New("ImageButton", {
                        Image = "rbxassetid://139785960036434",
                        ScaleType = Enum.ScaleType.Tile,
                        Size = UDim2.fromOffset(16, 200),
                        TileSize = UDim2.fromOffset(8, 8),
                        Parent = ColorHolder,
                    })

                    TransparencyColor = New("Frame", {
                        BackgroundColor3 = ColorPicker.Value,
                        Size = UDim2.fromScale(1, 1),
                        Parent = TransparencySelector,
                    })
                    New("UIGradient", {
                        Rotation = 90,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Parent = TransparencyColor,
                    })

                    TransparencyCursor = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = "WhiteColor",
                        BorderColor3 = "DarkColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                        Size = UDim2.new(1, 2, 0, 1),
                        Parent = TransparencySelector,
                    })
                end

                local InfoHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ColorMenu.Menu,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDim.new(0, 8),
                    Parent = InfoHolder,
                })

                local HueBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    ClearTextOnFocus = false,
                    Size = UDim2.fromScale(1, 1),
                    Text = "#??????",
                    TextSize = 14,
                    Parent = InfoHolder,
                })

                local RgbBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    ClearTextOnFocus = false,
                    Size = UDim2.fromScale(1, 1),
                    Text = "?, ?, ?",
                    TextSize = 14,
                    Parent = InfoHolder,
                })

                local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
                    return { Holder.AbsoluteSize.X + 1.5, 0.5 }
                end, 1)
                ColorPicker.ContextMenu = ContextMenu
                do
                    local function CreateButton(Text, Func)
                        local Button = New("TextButton", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 21),
                            Text = Text,
                            TextSize = 14,
                            Parent = ContextMenu.Menu,
                        })

                        Button.MouseButton1Click:Connect(function()
                            Library:SafeCallback(Func)
                            ContextMenu:Close()
                        end)
                    end

                    CreateButton("Copy color", function()
                        Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
                    end)

                    ColorPicker.SetValueRGB = function(...) end
                    CreateButton("Paste color", function()
                        ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
                    end)

                    if setclipboard then
                        CreateButton("Copy Hex", function()
                            setclipboard(tostring(ColorPicker.Value:ToHex()))
                        end)
                        CreateButton("Copy RGB", function()
                            setclipboard(table.concat({
                                math.floor(ColorPicker.Value.R * 255),
                                math.floor(ColorPicker.Value.G * 255),
                                math.floor(ColorPicker.Value.B * 255),
                            }, ", "))
                        end)
                    end
                end

                function ColorPicker:SetHSVFromRGB(Color)
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
                end

                function ColorPicker:Display()
                    if Library.Unloaded then
                        return
                    end

                    ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

                    Holder.BackgroundColor3 = ColorPicker.Value
                    Holder.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
                    HolderTransparency.ImageTransparency = (1 - ColorPicker.Transparency)

                    SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
                    if TransparencyColor then
                        TransparencyColor.BackgroundColor3 = ColorPicker.Value
                    end

                    TweenService:Create(SatVibCursor, Library.BaseTweenInfo, {
                        Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
                    }):Play()

                    TweenService:Create(HueCursor, Library.BaseTweenInfo, {
                        Position = UDim2.fromScale(0.5, ColorPicker.Hue)
                    }):Play()

                    if TransparencyCursor then
                        TweenService:Create(TransparencyCursor, Library.BaseTweenInfo, {
                            Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
                        }):Play()
                    end

                    HueBox.Text = "#" .. ColorPicker.Value:ToHex()
                    RgbBox.Text = table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", ")
                end

                function ColorPicker:Update()
                    ColorPicker:Display()

                    Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
                    Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
                end

                function ColorPicker:OnChanged(Func)
                    ColorPicker.Changed = Func
                end

                function ColorPicker:SetValue(HSV, Transparency)
                    if typeof(HSV) == "Color3" then
                        ColorPicker:SetValueRGB(HSV, Transparency)
                        return
                    end

                    local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
                    ColorPicker.Transparency = Info.Transparency and Transparency or 0
                    ColorPicker:SetHSVFromRGB(Color)
                    ColorPicker:Update()
                end

                function ColorPicker:SetValueRGB(Color, Transparency)
                    ColorPicker.Transparency = Info.Transparency and Transparency or 0
                    ColorPicker:SetHSVFromRGB(Color)
                    ColorPicker:Update()
                end

                Holder.MouseButton1Click:Connect(ColorMenu.Toggle)
                Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

                SatVipMap.InputBegan:Connect(function(Input)
                    while IsDragInput(Input) do
                        local MinX = SatVipMap.AbsolutePosition.X
                        local MaxX = MinX + SatVipMap.AbsoluteSize.X
                        local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                        local MinY = SatVipMap.AbsolutePosition.Y
                        local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                        local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                        local OldSat = ColorPicker.Sat
                        local OldVib = ColorPicker.Vib
                        ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                        ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                        if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                            ColorPicker:Update()
                        end

                        RunService.RenderSteppedWait()
                    end
                end)
                HueSelector.InputBegan:Connect(function(Input)
                    while IsDragInput(Input) do
                        local Min = HueSelector.AbsolutePosition.Y
                        local Max = Min + HueSelector.AbsoluteSize.Y
                        local Location = math.clamp(Mouse.Y, Min, Max)

                        local OldHue = ColorPicker.Hue
                        ColorPicker.Hue = (Location - Min) / (Max - Min)

                        if ColorPicker.Hue ~= OldHue then
                            ColorPicker:Update()
                        end

                        RunService.RenderSteppedWait()
                    end
                end)
                if TransparencySelector then
                    TransparencySelector.InputBegan:Connect(function(Input)
                        while IsDragInput(Input) do
                            local Min = TransparencySelector.AbsolutePosition.Y
                            local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                            local Location = math.clamp(Mouse.Y, Min, Max)

                            local OldTransparency = ColorPicker.Transparency
                            ColorPicker.Transparency = (Location - Min) / (Max - Min)

                            if ColorPicker.Transparency ~= OldTransparency then
                                ColorPicker:Update()
                            end

                            RunService.RenderSteppedWait()
                        end
                    end)
                end

                HueBox.FocusLost:Connect(function(Enter)
                    if not Enter then
                        return
                    end

                    local Success, Color = pcall(Color3.fromHex, HueBox.Text)
                    if Success and typeof(Color) == "Color3" then
                        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
                    end

                    ColorPicker:Update()
                end)
                RgbBox.FocusLost:Connect(function(Enter)
                    if not Enter then
                        return
                    end

                    local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
                    if R and G and B then
                        ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
                    end

                    ColorPicker:Update()
                end)

                ColorPicker:Display()

                if ParentObj.Addons then
                    table.insert(ParentObj.Addons, ColorPicker)
                end

                ColorPicker.Default = ColorPicker.Value

                Options[Idx] = ColorPicker

                return self
            end

            BaseAddons.__index = Funcs
            BaseAddons.__namecall = function(_, Key, ...)
                return Funcs[Key](...)
            end
        end

        local BaseGroupbox = {}
        do
            local Funcs = {}

            function Funcs:AddDivider(Text)
                local Groupbox = self
                local Container = Groupbox.Container

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.new(1, 0, 0, 0),
                    Parent = Container,
                })

                if Text then
                    local TextLabel = New("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0),
                        Text = Text,
                        TextSize = 14,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Parent = Holder,
                    })

                    local X,_ = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    local SizeX = X // 2 + 10

                    New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.new(0.5, -SizeX, 0, 2),
                        Parent = Holder,
                    })
                    New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(1, 0.5),
                        Size = UDim2.new(0.5, -SizeX, 0, 2),
                        Parent = Holder,
                    })
                else
                    New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.new(1, 0, 0, 2),
                        Parent = Holder,
                    })
                end

                Groupbox:Resize()

                table.insert(Groupbox.Elements, {
                    Holder = Holder,
                    Type = "Divider",
                })
            end

            function Funcs:AddLabel(...)
                local Data = {}
                local Addons = {}

                local First = select(1, ...)
                local Second = select(2, ...)

                if typeof(First) == "table" or typeof(Second) == "table" then
                    local Params = typeof(First) == "table" and First or Second

                    Data.Text = Params.Text or ""
                    Data.DoesWrap = Params.DoesWrap or false
                    Data.Size = Params.Size or 14
                    Data.Visible = Params.Visible or true
                    Data.Idx = typeof(Second) == "table" and First or nil
                else
                    Data.Text = First or ""
                    Data.DoesWrap = Second or false
                    Data.Size = 14
                    Data.Visible = true
                    Data.Idx = select(3, ...) or nil
                end

                local Groupbox = self
                local Container = Groupbox.Container

                local Label = {
                    Text = Data.Text,
                    DoesWrap = Data.DoesWrap,

                    Addons = Addons,

                    Visible = Data.Visible,
                    Type = "Label",
                }

                local TextLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = Label.Text,
                    TextSize = Data.Size,
                    TextWrapped = Label.DoesWrap,
                    TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
                    Parent = Container,
                })

                function Label:SetVisible(Visible)
                    Label.Visible = Visible

                    TextLabel.Visible = Label.Visible
                    Groupbox:Resize()
                end

                function Label:SetText(Text)
                    Label.Text = Text
                    TextLabel.Text = Text

                    if Label.DoesWrap then
                        local _, Y =
                            Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                        TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
                    end

                    Groupbox:Resize()
                end

                if Label.DoesWrap then
                    local _, Y =
                        Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                    local Last = TextLabel.AbsoluteSize
                    TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        if TextLabel.AbsoluteSize == Last then
                            return
                        end

                        local _, Y =
                            Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                        TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                        Last = TextLabel.AbsoluteSize
                        Groupbox:Resize()
                    end)
                else
                    New("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        Padding = UDim.new(0, 6),
                        Parent = TextLabel,
                    })
                end

                Groupbox:Resize()

                Label.TextLabel = TextLabel
                Label.Container = Container
                if not Data.DoesWrap then
                    setmetatable(Label, BaseAddons)
                end

                Label.Holder = TextLabel
                table.insert(Groupbox.Elements, Label)

                if Data.Idx then
                    Labels[Data.Idx] = Label
                else
                    table.insert(Labels, Label)
                end

                return Label
            end

            function Funcs:AddButton(...)
                local function GetInfo(...)
                    local Info = {}

                    local First = select(1, ...)
                    local Second = select(2, ...)

                    if typeof(First) == "table" or typeof(Second) == "table" then
                        local Params = typeof(First) == "table" and First or Second

                        Info.Text = Params.Text or ""
                        Info.Func = Params.Func or Params.Callback or function() end
                        Info.DoubleClick = Params.DoubleClick

                        Info.Tooltip = Params.Tooltip
                        Info.DisabledTooltip = Params.DisabledTooltip

                        Info.Risky = Params.Risky or false
                        Info.Disabled = Params.Disabled or false
                        Info.Visible = Params.Visible or true
                        Info.Idx = typeof(Second) == "table" and First or nil
                    else
                        Info.Text = First or ""
                        Info.Func = Second or function() end
                        Info.DoubleClick = false

                        Info.Tooltip = nil
                        Info.DisabledTooltip = nil

                        Info.Risky = false
                        Info.Disabled = false
                        Info.Visible = true
                        Info.Idx = select(3, ...) or nil
                    end

                    return Info
                end
                local Info = GetInfo(...)

                local Groupbox = self
                local Container = Groupbox.Container

                local Button = {
                    Text = Info.Text,
                    Func = Info.Func,
                    DoubleClick = Info.DoubleClick,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Risky = Info.Risky,
                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Tween = nil,
                    Type = "Button",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Parent = Container,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDim.new(0, 9),
                    Parent = Holder,
                })

                local function CreateButton(Button)
                    local Base = New("TextButton", {
                        Active = not Button.Disabled,
                        BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                        Size = UDim2.fromScale(1, 1),
                        Text = Button.Text,
                        TextSize = 14,
                        TextTransparency = 0.4,
                        Visible = Button.Visible,
                        Parent = Holder,
                    })

                    local Stroke = New("UIStroke", {
                        Color = "OutlineColor",
                        Transparency = Button.Disabled and 0.5 or 0,
                        Parent = Base,
                    })

                    return Base, Stroke
                end

                local function InitEvents(Button)
                    Button.Base.MouseEnter:Connect(function()
                        if Button.Disabled then
                            return
                        end

                        Button.Tween = TweenService:Create(Button.Base, Library.TabTweenInfo, {
                            TextTransparency = 0,
                        })
                        Button.Tween:Play()
                    end)
                    Button.Base.MouseLeave:Connect(function()
                        if Button.Disabled then
                            return
                        end

                        Button.Tween = TweenService:Create(Button.Base, Library.TabTweenInfo, {
                            TextTransparency = 0.4,
                        })
                        Button.Tween:Play()
                    end)

                    Button.Base.MouseButton1Click:Connect(function()
                        if Button.Disabled or Button.Locked then
                            return
                        end

                        if Button.DoubleClick then
                            Button.Locked = true

                            Button.Base.Text = "Are you sure?"
                            Button.Base.TextColor3 = Library.Scheme.AccentColor
                            Library.Registry[Button.Base].TextColor3 = "AccentColor"

                            local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                            Button.Base.Text = Button.Text
                            Button.Base.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                            Library.Registry[Button.Base].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                            if Clicked then
                                Library:SafeCallback(Button.Func)
                            end

                            RunService.RenderSteppedWait()
                            Button.Locked = false
                            return
                        end

                        Library:SafeCallback(Button.Func)
                    end)
                end

                Button.Base, Button.Stroke = CreateButton(Button)
                InitEvents(Button)

                function Button:AddButton(...)
                    local Info = GetInfo(...)

                    local SubButton = {
                        Text = Info.Text,
                        Func = Info.Func,
                        DoubleClick = Info.DoubleClick,

                        Tooltip = Info.Tooltip,
                        DisabledTooltip = Info.DisabledTooltip,
                        TooltipTable = nil,

                        Risky = Info.Risky,
                        Disabled = Info.Disabled,
                        Visible = Info.Visible,

                        Tween = nil,
                        Type = "SubButton",
                    }

                    Button.SubButton = SubButton
                    SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
                    InitEvents(SubButton)

                    function SubButton:UpdateColors()
                        if Library.Unloaded then
                            return
                        end

                        StopTween(SubButton.Tween)

                        SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                            or Library.Scheme.MainColor
                        SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                        SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                        Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                            or "MainColor"
                    end

                    function SubButton:SetDisabled(Disabled)
                        SubButton.Disabled = Disabled

                        if SubButton.TooltipTable then
                            SubButton.TooltipTable.Disabled = SubButton.Disabled
                        end

                        SubButton.Base.Active = not SubButton.Disabled
                        SubButton:UpdateColors()
                    end

                    function SubButton:SetVisible(Visible)
                        SubButton.Visible = Visible

                        SubButton.Base.Visible = SubButton.Visible
                        Groupbox:Resize()
                    end

                    function SubButton:SetText(Text)
                        SubButton.Text = Text
                        SubButton.Base.Text = Text
                    end

                    if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                        SubButton.TooltipTable =
                            Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                        SubButton.TooltipTable.Disabled = SubButton.Disabled
                    end

                    if SubButton.Risky then
                        SubButton.Base.TextColor3 = Library.Scheme.RedColor
                        Library.Registry[SubButton.Base].TextColor3 = "RedColor"
                    end

                    SubButton:UpdateColors()

                    if Info.Idx then
                        Buttons[Info.Idx] = SubButton
                    else
                        table.insert(Buttons, SubButton)
                    end

                    return SubButton
                end

                function Button:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    StopTween(Button.Tween)

                    Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                        or Library.Scheme.MainColor
                    Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
                    Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

                    Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
                end

                function Button:SetDisabled(Disabled)
                    Button.Disabled = Disabled

                    if Button.TooltipTable then
                        Button.TooltipTable.Disabled = Button.Disabled
                    end

                    Button.Base.Active = not Button.Disabled
                    Button:UpdateColors()
                end

                function Button:SetVisible(Visible)
                    Button.Visible = Visible

                    Holder.Visible = Button.Visible
                    Groupbox:Resize()
                end

                function Button:SetText(Text)
                    Button.Text = Text
                    Button.Base.Text = Text
                end

                if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
                    Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
                    Button.TooltipTable.Disabled = Button.Disabled
                end

                if Button.Risky then
                    Button.Base.TextColor3 = Library.Scheme.RedColor
                    Library.Registry[Button.Base].TextColor3 = "RedColor"
                end

                Button:UpdateColors()
                Groupbox:Resize()

                Button.Holder = Holder
                table.insert(Groupbox.Elements, Button)

                if Info.Idx then
                    Buttons[Info.Idx] = Button
                else
                    table.insert(Buttons, Button)
                end

                return Button
            end

            function Funcs:AddCheckbox(Idx, Info)
                Info = Library:Validate(Info, Templates.Toggle)

                local Groupbox = self
                local Container = Groupbox.Container

                local Toggle = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Risky = Info.Risky,
                    Disabled = Info.Disabled,
                    Visible = Info.Visible,
                    Addons = {},

                    Type = "Toggle",
                }

                local Button = New("TextButton", {
                    Active = not Toggle.Disabled,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = "",
                    Visible = Toggle.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(26, 0),
                    Size = UDim2.new(1, -26, 1, 0),
                    Text = Toggle.Text,
                    TextSize = 14,
                    TextTransparency = 0.4,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Button,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 6),
                    Parent = Label,
                })

                local Checkbox = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = Button,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Checkbox,
                })

                local CheckboxStroke = New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = Checkbox,
                })

                local CheckImage = New("ImageLabel", {
                    Image = CheckIcon and CheckIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 1,
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Checkbox,
                })

                function Toggle:UpdateColors()
                    Toggle:Display()
                end

                function Toggle:Display()
                    if Library.Unloaded then
                        return
                    end

                    CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

                    if Toggle.Disabled then
                        Label.TextTransparency = 0.8
                        CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                        Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                        Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                        return
                    end

                    TweenService:Create(Label, Library.BaseTweenInfo, {
                        TextTransparency = Toggle.Value and 0 or 0.4,
                    }):Play()
                    TweenService:Create(CheckImage, Library.BaseTweenInfo, {
                        ImageTransparency = Toggle.Value and 0 or 1,
                    }):Play()

                    Checkbox.BackgroundColor3 = Library.Scheme.MainColor
                    Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
                end

                function Toggle:OnChanged(Func)
                    Toggle.Changed = Func
                end

                function Toggle:SetValue(Value)
                    if Toggle.Disabled then
                        return
                    end

                    Toggle.Value = Value
                    Toggle:Display()

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon.Toggled = Toggle.Value
                            Addon:Update()
                        end
                    end

                    Library:UpdateDependencyBoxes()
                    Library:SafeCallback(Toggle.Callback, Toggle.Value)
                    Library:SafeCallback(Toggle.Changed, Toggle.Value)
                end

                function Toggle:SetDisabled(Disabled)
                    Toggle.Disabled = Disabled

                    if Toggle.TooltipTable then
                        Toggle.TooltipTable.Disabled = Toggle.Disabled
                    end

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon:Update()
                        end
                    end

                    Button.Active = not Toggle.Disabled
                    Toggle:Display()
                end

                function Toggle:SetVisible(Visible)
                    Toggle.Visible = Visible

                    Button.Visible = Toggle.Visible
                    Groupbox:Resize()
                end

                function Toggle:SetText(Text)
                    Toggle.Text = Text
                    Label.Text = Text
                end

                Button.MouseButton1Click:Connect(function()
                    if Toggle.Disabled then
                        return
                    end

                    Toggle:SetValue(not Toggle.Value)
                end)

                if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
                    Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
                    Toggle.TooltipTable.Disabled = Toggle.Disabled
                end

                if Toggle.Risky then
                    Label.TextColor3 = Library.Scheme.RedColor
                    Library.Registry[Label].TextColor3 = "RedColor"
                end

                Toggle:Display()
                Groupbox:Resize()

                Toggle.TextLabel = Label
                Toggle.Container = Container
                setmetatable(Toggle, BaseAddons)

                Toggle.Holder = Button
                table.insert(Groupbox.Elements, Toggle)

                Toggle.Default = Toggle.Value

                Toggles[Idx] = Toggle

                return Toggle
            end

            function Funcs:AddToggle(Idx, Info)
                if Library.ForceCheckbox then
                    return Funcs.AddCheckbox(self, Idx, Info)
                end

                Info = Library:Validate(Info, Templates.Toggle)

                local Groupbox = self
                local Container = Groupbox.Container

                local Toggle = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Risky = Info.Risky,
                    Disabled = Info.Disabled,
                    Visible = Info.Visible,
                    Addons = {},

                    Type = "Toggle",
                }

                local Button = New("TextButton", {
                    Active = not Toggle.Disabled,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = "",
                    Visible = Toggle.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -40, 1, 0),
                    Text = Toggle.Text,
                    TextSize = 14,
                    TextTransparency = 0.4,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Button,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDim.new(0, 6),
                    Parent = Label,
                })

                local Switch = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromScale(1, 0),
                    Size = UDim2.fromOffset(32, 18),
                    Parent = Button,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = Switch,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 2),
                    PaddingLeft = UDim.new(0, 2),
                    PaddingRight = UDim.new(0, 2),
                    PaddingTop = UDim.new(0, 2),
                    Parent = Switch,
                })
                local SwitchStroke = New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = Switch,
                })

                local Ball = New("Frame", {
                    BackgroundColor3 = "FontColor",
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = Switch,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = Ball,
                })

                function Toggle:UpdateColors()
                    Toggle:Display()
                end

                function Toggle:Display()
                    if Library.Unloaded then
                        return
                    end

                    local Offset = Toggle.Value and 1 or 0

                    Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
                    SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

                    Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
                    SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

                    Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
                    Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

                    if Toggle.Disabled then
                        Label.TextTransparency = 0.8
                        Ball.AnchorPoint = Vector2.new(Offset, 0)
                        Ball.Position = UDim2.fromScale(Offset, 0)

                        Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                        Library.Registry[Ball].BackgroundColor3 = function()
                            return Library:GetDarkerColor(Library.Scheme.FontColor)
                        end

                        return
                    end

                    TweenService:Create(Label, Library.BaseTweenInfo, {
                        TextTransparency = Toggle.Value and 0 or 0.4,
                    }):Play()
                    TweenService:Create(Ball, Library.BaseTweenInfo, {
                        AnchorPoint = Vector2.new(Offset, 0),
                        Position = UDim2.fromScale(Offset, 0),
                    }):Play()

                    Ball.BackgroundColor3 = Library.Scheme.FontColor
                    Library.Registry[Ball].BackgroundColor3 = "FontColor"
                end

                function Toggle:OnChanged(Func)
                    Toggle.Changed = Func
                end

                function Toggle:SetValue(Value)
                    if Toggle.Disabled then
                        return
                    end

                    Toggle.Value = Value
                    Toggle:Display()

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon.Toggled = Toggle.Value
                            Addon:Update()
                        end
                    end

                    Library:UpdateDependencyBoxes()
                    Library:SafeCallback(Toggle.Callback, Toggle.Value)
                    Library:SafeCallback(Toggle.Changed, Toggle.Value)
                end

                function Toggle:SetDisabled(Disabled)
                    Toggle.Disabled = Disabled

                    if Toggle.TooltipTable then
                        Toggle.TooltipTable.Disabled = Toggle.Disabled
                    end

                    for _, Addon in Toggle.Addons do
                        if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                            Addon:Update()
                        end
                    end

                    Button.Active = not Toggle.Disabled
                    Toggle:Display()
                end

                function Toggle:SetVisible(Visible)
                    Toggle.Visible = Visible

                    Button.Visible = Toggle.Visible
                    Groupbox:Resize()
                end

                function Toggle:SetText(Text)
                    Toggle.Text = Text
                    Label.Text = Text
                end

                Button.MouseButton1Click:Connect(function()
                    if Toggle.Disabled then
                        return
                    end

                    Toggle:SetValue(not Toggle.Value)
                end)

                if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
                    Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
                    Toggle.TooltipTable.Disabled = Toggle.Disabled
                end

                if Toggle.Risky then
                    Label.TextColor3 = Library.Scheme.RedColor
                    Library.Registry[Label].TextColor3 = "RedColor"
                end

                Toggle:Display()
                Groupbox:Resize()

                Toggle.TextLabel = Label
                Toggle.Container = Container
                setmetatable(Toggle, BaseAddons)

                Toggle.Holder = Button
                table.insert(Groupbox.Elements, Toggle)

                Toggle.Default = Toggle.Value

                Toggles[Idx] = Toggle

                return Toggle
            end

            function Funcs:AddInput(Idx, Info)
                Info = Library:Validate(Info, Templates.Input)

                local Groupbox = self
                local Container = Groupbox.Container

                local Input = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Finished = Info.Finished,
                    Numeric = Info.Numeric,
                    ClearTextOnFocus = Info.ClearTextOnFocus,
                    Placeholder = Info.Placeholder,
                    AllowEmpty = Info.AllowEmpty,
                    EmptyReset = Info.EmptyReset,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Type = "Input",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 39),
                    Visible = Input.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = Input.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                local Box = New("TextBox", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
                    PlaceholderText = Input.Placeholder,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Input.Value,
                    TextEditable = not Input.Disabled,
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                function Input:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    Label.TextTransparency = Input.Disabled and 0.8 or 0
                    Box.TextTransparency = Input.Disabled and 0.8 or 0
                end

                function Input:OnChanged(Func)
                    Input.Changed = Func
                end

                function Input:SetValue(Text)
                    if not Input.AllowEmpty and Trim(Text) == "" then
                        Text = Input.EmptyReset
                    end

                    if Info.MaxLength and #Text > Info.MaxLength then
                        Text = Text:sub(1, Info.MaxLength)
                    end

                    if Input.Numeric then
                        if #tostring(Text) > 0 and not tonumber(Text) then
                            Text = Input.Value
                        end
                    end

                    Input.Value = Text
                    Box.Text = Text

                    if not Input.Disabled then
                        Library:SafeCallback(Input.Callback, Input.Value)
                        Library:SafeCallback(Input.Changed, Input.Value)
                    end
                end

                function Input:SetDisabled(Disabled)
                    Input.Disabled = Disabled

                    if Input.TooltipTable then
                        Input.TooltipTable.Disabled = Input.Disabled
                    end

                    Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
                    Box.TextEditable = not Input.Disabled
                    Input:UpdateColors()
                end

                function Input:SetVisible(Visible)
                    Input.Visible = Visible

                    Holder.Visible = Input.Visible
                    Groupbox:Resize()
                end

                function Input:SetText(Text)
                    Input.Text = Text
                    Label.Text = Text
                end

                if Input.Finished then
                    Box.FocusLost:Connect(function(Enter)
                        if not Enter then
                            return
                        end

                        Input:SetValue(Box.Text)
                    end)
                else
                    Box:GetPropertyChangedSignal("Text"):Connect(function()
                        if Box.Text == Input.Value then
                            return
                        end

                        Input:SetValue(Box.Text)
                    end)
                end

                if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
                    Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
                    Input.TooltipTable.Disabled = Input.Disabled
                end

                Groupbox:Resize()

                Input.Holder = Holder
                table.insert(Groupbox.Elements, Input)

                Input.Default = Input.Value

                Options[Idx] = Input

                return Input
            end

            function Funcs:AddSlider(Idx, Info)
                Info = Library:Validate(Info, Templates.Slider)

                local Groupbox = self
                local Container = Groupbox.Container

                local Slider = {
                    Text = Info.Text,
                    Value = Info.Default,

                    Min = Info.Min,
                    Max = Info.Max,

                    Prefix = Info.Prefix,
                    Suffix = Info.Suffix,
                    Compact = Info.Compact,
                    Rounding = Info.Rounding,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Type = "Slider",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Compact and 13 or 31),
                    Visible = Slider.Visible,
                    Parent = Container,
                })

                local SliderLabel
                if not Info.Compact then
                    SliderLabel = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Text = Slider.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = Holder,
                    })
                end

                local Bar = New("TextButton", {
                    Active = not Slider.Disabled,
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 13),
                    Text = "",
                    Parent = Holder,
                })

                local DisplayLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    TextSize = 14,
                    ZIndex = 2,
                    Parent = Bar,
                })
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    Color = "DarkColor",
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    Parent = DisplayLabel,
                })

                local Fill = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    Size = UDim2.fromScale(0.5, 1),
                    Parent = Bar,
                })

                function Slider:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    if SliderLabel then
                        SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
                    end
                    DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

                    Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
                    Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
                end

                function Slider:Display()
                    if Library.Unloaded then
                        return
                    end

                    local CustomDisplayText = nil
                    if Info.FormatDisplayValue then
                        CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
                    end

                    if CustomDisplayText then
                        DisplayLabel.Text = tostring(CustomDisplayText)
                    else
                        if Info.Compact then
                            DisplayLabel.Text =
                                string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                        elseif Info.HideMax then
                            DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                        else
                            DisplayLabel.Text = string.format(
                                "%s%s%s/%s%s%s",
                                Slider.Prefix,
                                Slider.Value,
                                Slider.Suffix,
                                Slider.Prefix,
                                Slider.Max,
                                Slider.Suffix
                            )
                        end
                    end

                    local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
                    TweenService:Create(Fill, Library.SliderTweenInfo, {
                        Size = UDim2.fromScale(X, 1)
                    }):Play()
                end

                function Slider:OnChanged(Func)
                    Slider.Changed = Func
                end

                function Slider:SetMax(Value)
                    assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

                    Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
                    Slider.Max = Value
                    Slider:Display()
                end

                function Slider:SetMin(Value)
                    assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

                    Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
                    Slider.Min = Value
                    Slider:Display()
                end

                function Slider:SetValue(Str)
                    if Slider.Disabled then
                        return
                    end

                    local Num = tonumber(Str)
                    if not Num or Num == Slider.Value then
                        return
                    end

                    Num = math.clamp(Num, Slider.Min, Slider.Max)

                    Slider.Value = Num
                    Slider:Display()

                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                function Slider:SetDisabled(Disabled)
                    Slider.Disabled = Disabled

                    if Slider.TooltipTable then
                        Slider.TooltipTable.Disabled = Slider.Disabled
                    end

                    Bar.Active = not Slider.Disabled
                    Slider:UpdateColors()
                end

                function Slider:SetVisible(Visible)
                    Slider.Visible = Visible

                    Holder.Visible = Slider.Visible
                    Groupbox:Resize()
                end

                function Slider:SetText(Text)
                    Slider.Text = Text
                    if SliderLabel then
                        SliderLabel.Text = Text
                        return
                    end
                    Slider:Display()
                end

                function Slider:SetPrefix(Prefix)
                    Slider.Prefix = Prefix
                    Slider:Display()
                end

                function Slider:SetSuffix(Suffix)
                    Slider.Suffix = Suffix
                    Slider:Display()
                end

                Bar.InputBegan:Connect(function(Input)
                    if not IsClickInput(Input) or Slider.Disabled then
                        return
                    end

                    for _, Side in Library.ActiveTab.Sides do
                        Side.ScrollingEnabled = false
                    end

                    while IsDragInput(Input) do
                        local Location = Mouse.X
                        local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                        local OldValue = Slider.Value
                        Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                        Slider:Display()
                        if Slider.Value ~= OldValue then
                            Library:SafeCallback(Slider.Callback, Slider.Value)
                            Library:SafeCallback(Slider.Changed, Slider.Value)
                        end

                        RunService.RenderSteppedWait()
                    end

                    for _, Side in Library.ActiveTab.Sides do
                        Side.ScrollingEnabled = true
                    end
                end)

                if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
                    Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
                    Slider.TooltipTable.Disabled = Slider.Disabled
                end

                Slider:UpdateColors()
                Slider:Display()
                Groupbox:Resize()

                Slider.Holder = Holder
                table.insert(Groupbox.Elements, Slider)

                Slider.Default = Slider.Value

                Options[Idx] = Slider

                return Slider
            end

            function Funcs:AddDropdown(Idx, Info)
                Info = Library:Validate(Info, Templates.Dropdown)

                local Groupbox = self
                local Container = Groupbox.Container

                if Info.SpecialType == "Player" then
                    Info.Values = GetPlayers()
                    Info.AllowNull = true
                end

                local Dropdown = {
                    Text = typeof(Info.Text) == "string" and Info.Text or nil,
                    Value = Info.Multi and {} or nil,
                    Values = Info.Values,
                    DisabledValues = Info.DisabledValues,
                    Multi = Info.Multi,

                    SpecialType = Info.SpecialType,
                    ExcludeLocalPlayer = Info.ExcludeLocalPlayer,

                    Tooltip = Info.Tooltip,
                    DisabledTooltip = Info.DisabledTooltip,
                    TooltipTable = nil,

                    Callback = Info.Callback,
                    Changed = Info.Changed,

                    Disabled = Info.Disabled,
                    Visible = Info.Visible,

                    Type = "Dropdown",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Dropdown.Text and 39 or 21),
                    Visible = Dropdown.Visible,
                    Parent = Container,
                })

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = Dropdown.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Visible = not not Info.Text,
                    Parent = Holder,
                })

                local Display = New("TextButton", {
                    Active = not Dropdown.Disabled,
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = "---",
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 4),
                    Parent = Display,
                })

                local ArrowImage = New("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Image = ArrowIcon and ArrowIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromScale(1, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = Display,
                })

                local SearchBox
                if Info.Searchable then
                    SearchBox = New("TextBox", {
                        BackgroundTransparency = 1,
                        PlaceholderText = "Search...",
                        Position = UDim2.fromOffset(-8, 0),
                        Size = UDim2.new(1, -12, 1, 0),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Visible = false,
                        Parent = Display,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        Parent = SearchBox,
                    })
                end

                local MenuTable = Library:AddContextMenu(
                    Display,
                    function()
                        return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, 0)
                    end,
                    function()
                        return { 0.5, Display.AbsoluteSize.Y + 1.5 }
                    end,
                    2,
                    function(Active)
                        Display.TextTransparency = (Active and SearchBox) and 1 or 0
                        ArrowImage.ImageTransparency = Active and 0 or 0.5
                        ArrowImage.Rotation = Active and 180 or 0
                        if SearchBox then
                            SearchBox.Text = ""
                            SearchBox.Visible = Active
                        end
                    end
                )
                Dropdown.Menu = MenuTable

                function Dropdown:RecalculateListSize(Count)
                    local Y = math.clamp((Count or GetTableSize(Dropdown.Values)) * 21, 0, Info.MaxVisibleDropdownItems * 21)

                    MenuTable:SetSize(function()
                        return UDim2.fromOffset(Display.AbsoluteSize.X / Library.DPIScale, Y)
                    end)
                end

                function Dropdown:UpdateColors()
                    if Library.Unloaded then
                        return
                    end

                    Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
                    Display.TextTransparency = Dropdown.Disabled and 0.8 or 0
                    ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
                end

                function Dropdown:Display()
                    if Library.Unloaded then
                        return
                    end

                    local Str = ""

                    if Info.Multi then
                        for _, Value in Dropdown.Values do
                            if Dropdown.Value[Value] then
                                Str = Str .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value)) .. ", "
                            end
                        end

                        Str = Str:sub(1, #Str - 2)
                    else
                        Str = Dropdown.Value and tostring(Dropdown.Value) or ""
                        if Str ~= "" and Info.FormatDisplayValue then
                            Str = tostring(Info.FormatDisplayValue(Str))
                        end
                    end

                    if #Str > 25 then
                        Str = Str:sub(1, 22) .. "..."
                    end

                    Display.Text = (Str == "" and "---" or Str)
                end

                function Dropdown:OnChanged(Func)
                    Dropdown.Changed = Func
                end

                function Dropdown:GetActiveValues()
                    if Info.Multi then
                        local Table = {}

                        for Value,_ in Dropdown.Value do
                            table.insert(Table, Value)
                        end

                        return Table
                    end

                    return Dropdown.Value and 1 or 0
                end

                local Buttons = {}
                function Dropdown:BuildDropdownList()
                    local Values = Dropdown.Values
                    local DisabledValues = Dropdown.DisabledValues

                    for Button, _ in Buttons do
                        Button:Destroy()
                    end
                    table.clear(Buttons)

                    local Count = 0
                    for _, Value in Values do
                        if SearchBox and not tostring(Value):lower():match(SearchBox.Text:lower()) then
                            continue
                        end

                        Count += 1
                        local IsDisabled = table.find(DisabledValues, Value)
                        local Table = {}

                        local Button = New("TextButton", {
                            BackgroundColor3 = "MainColor",
                            BackgroundTransparency = 1,
                            LayoutOrder = IsDisabled and 1 or 0,
                            Size = UDim2.new(1, 0, 0, 21),
                            Text = tostring(Value),
                            TextSize = 14,
                            TextTransparency = 0.5,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = MenuTable.Menu,
                        })
                        New("UIPadding", {
                            PaddingLeft = UDim.new(0, 7),
                            PaddingRight = UDim.new(0, 7),
                            Parent = Button,
                        })

                        local Selected
                        if Info.Multi then
                            Selected = Dropdown.Value[Value]
                        else
                            Selected = Dropdown.Value == Value
                        end

                        function Table:UpdateButton()
                            if Info.Multi then
                                Selected = Dropdown.Value[Value]
                            else
                                Selected = Dropdown.Value == Value
                            end

                            Button.BackgroundTransparency = Selected and 0 or 1
                            Button.TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.5
                        end

                        if not IsDisabled then
                            Button.MouseButton1Click:Connect(function()
                                local Try = not Selected

                                if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                                    Selected = Try
                                    if Info.Multi then
                                        Dropdown.Value[Value] = Selected and true or nil
                                    else
                                        Dropdown.Value = Selected and Value or nil
                                    end

                                    for _, OtherButton in Buttons do
                                        OtherButton:UpdateButton()
                                    end
                                end

                                Table:UpdateButton()
                                Dropdown:Display()

                                Library:UpdateDependencyBoxes()
                                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                            end)
                        end

                        Table:UpdateButton()
                        Dropdown:Display()

                        Buttons[Button] = Table
                    end

                    Dropdown:RecalculateListSize(Count)
                end

                function Dropdown:SetValue(Value)
                    if Info.Multi then
                        local Table = {}

                        for Val, Active in Value or {} do
                            if typeof(Active) ~= "boolean" then
                                Table[Active] = true
                            elseif Active and table.find(Dropdown.Values, Val) then
                                Table[Val] = true
                            end
                        end

                        Dropdown.Value = Table
                    else
                        if table.find(Dropdown.Values, Value) then
                            Dropdown.Value = Value
                        elseif not Value then
                            Dropdown.Value = nil
                        end
                    end

                    Dropdown:Display()
                    for _, Button in Buttons do
                        Button:UpdateButton()
                    end

                    if not Dropdown.Disabled then
                        Library:UpdateDependencyBoxes()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                    end
                end

                function Dropdown:SetValues(Values)
                    Dropdown.Values = Values
                    Dropdown:BuildDropdownList()
                end

                function Dropdown:AddValues(Values)
                    if typeof(Values) == "table" then
                        for _, val in Values do
                            table.insert(Dropdown.Values, val)
                        end
                    elseif typeof(Values) == "string" then
                        table.insert(Dropdown.Values, Values)
                    else
                        return
                    end

                    Dropdown:BuildDropdownList()
                end

                function Dropdown:SetDisabledValues(DisabledValues)
                    Dropdown.DisabledValues = DisabledValues
                    Dropdown:BuildDropdownList()
                end

                function Dropdown:AddDisabledValues(DisabledValues)
                    if typeof(DisabledValues) == "table" then
                        for _, val in DisabledValues do
                            table.insert(Dropdown.DisabledValues, val)
                        end
                    elseif typeof(DisabledValues) == "string" then
                        table.insert(Dropdown.DisabledValues, DisabledValues)
                    else
                        return
                    end

                    Dropdown:BuildDropdownList()
                end

                function Dropdown:SetDisabled(Disabled)
                    Dropdown.Disabled = Disabled

                    if Dropdown.TooltipTable then
                        Dropdown.TooltipTable.Disabled = Dropdown.Disabled
                    end

                    MenuTable:Close()
                    Display.Active = not Dropdown.Disabled
                    Dropdown:UpdateColors()
                end

                function Dropdown:SetVisible(Visible)
                    Dropdown.Visible = Visible

                    Holder.Visible = Dropdown.Visible
                    Groupbox:Resize()
                end

                function Dropdown:SetText(Text)
                    Dropdown.Text = Text
                    Holder.Size = UDim2.new(1, 0, 0, Text and 39 or 21)

                    Label.Text = Text and Text or ""
                    Label.Visible = not not Text
                end

                Display.MouseButton1Click:Connect(function()
                    if Dropdown.Disabled then
                        return
                    end

                    MenuTable:Toggle()
                end)

                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
                end

                local Defaults = {}
                if typeof(Info.Default) == "string" then
                    local Index = table.find(Dropdown.Values, Info.Default)
                    if Index then
                        table.insert(Defaults, Index)
                    end
                elseif typeof(Info.Default) == "table" then
                    for _, Value in next, Info.Default do
                        local Index = table.find(Dropdown.Values, Value)
                        if Index then
                            table.insert(Defaults, Index)
                        end
                    end
                elseif Dropdown.Values[Info.Default] ~= nil then
                    table.insert(Defaults, Info.Default)
                end

                if next(Defaults) then
                    for i = 1, #Defaults do
                        local Index = Defaults[i]
                        if Info.Multi then
                            Dropdown.Value[Dropdown.Values[Index]] = true
                        else
                            Dropdown.Value = Dropdown.Values[Index]
                        end

                        if not Info.Multi then
                            break
                        end
                    end
                end

                if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
                    Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
                    Dropdown.TooltipTable.Disabled = Dropdown.Disabled
                end

                Dropdown:UpdateColors()
                Dropdown:Display()
                Dropdown:BuildDropdownList()
                Groupbox:Resize()

                Dropdown.Holder = Holder
                table.insert(Groupbox.Elements, Dropdown)

                Dropdown.Default = Defaults
                Dropdown.DefaultValues = Dropdown.Values

                Options[Idx] = Dropdown

                return Dropdown
            end

            function Funcs:AddViewport(Idx, Info)
                Info = Library:Validate(Info, Templates.Viewport)

                local Groupbox = self
                local Container = Groupbox.Container

                local Dragging, Pinching = false, false
                local LastMousePos, LastPinchDist = nil, 0

                local ViewportObject = Info.Object
                if Info.Clone and typeof(Info.Object) == "Instance" then
                    if Info.Object.Archivable then
                        ViewportObject = ViewportObject:Clone()
                    else
                        Info.Object.Archivable = true
                        ViewportObject = ViewportObject:Clone()
                        Info.Object.Archivable = false
                    end
                end

                local Viewport = {
                    Object = ViewportObject,
                    Camera = if not Info.Camera then
                        Create("Camera")
                    else Info.Camera,
                    Interactive = Info.Interactive,
                    AutoFocus = Info.AutoFocus,
                    Visible = Info.Visible,
                    Type = "Viewport",
                }

                assert(
                    typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
                    "Instance must be a BasePart or Model."
                )

                assert(
                    typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
                    "Camera must be a valid Camera instance."
                )

                local function GetModelSize(model)
                    if model:IsA("BasePart") then
                        return model.Size
                    end

                    return select(2, model:GetBoundingBox())
                end

                local function FocusCamera()
                    local ModelSize = GetModelSize(Viewport.Object)
                    local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
                    local CameraDistance = MaxExtent * 2
                    local ModelPosition = Viewport.Object:GetPivot().Position

                    Viewport.Camera.CFrame =
                        CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
                end

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Viewport.Visible,
                    Parent = Container,
                })

                local Box = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 1),
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                local ViewportFrame = New("ViewportFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Parent = Box,
                    CurrentCamera = Viewport.Camera,
                    Active = Viewport.Interactive,
                })

                ViewportFrame.MouseEnter:Connect(function()
                    if not Viewport.Interactive then
                        return
                    end

                    for _, Side in Groupbox.Tab.Sides do
                        Side.ScrollingEnabled = false
                    end
                end)

                ViewportFrame.MouseLeave:Connect(function()
                    if not Viewport.Interactive then
                        return
                    end

                    for _, Side in Groupbox.Tab.Sides do
                        Side.ScrollingEnabled = true
                    end
                end)

                ViewportFrame.InputBegan:Connect(function(input)
                    if not Viewport.Interactive then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Dragging = true
                        LastMousePos = input.Position
                    elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                        Dragging = true
                        LastMousePos = input.Position
                    end
                end)

                Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                    if Library.Unloaded then
                        return
                    end

                    if not Viewport.Interactive then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Dragging = false
                    elseif input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = false
                    end
                end))

                Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                    if Library.Unloaded then
                        return
                    end

                    if not Viewport.Interactive or not Dragging or Pinching then
                        return
                    end

                    if
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        local MouseDelta = input.Position - LastMousePos
                        LastMousePos = input.Position

                        local Position = Viewport.Object:GetPivot().Position
                        local Camera = Viewport.Camera

                        local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                        Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                        local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                        local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                        if PitchedCFrame.UpVector.Y > 0.1 then
                            Camera.CFrame = PitchedCFrame
                        end
                    end
                end))

                ViewportFrame.InputChanged:Connect(function(input)
                    if not Viewport.Interactive then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseWheel then
                        local ZoomAmount = input.Position.Z * 2
                        Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
                    end
                end)

                Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
                    if Library.Unloaded then
                        return
                    end

                    if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                        return
                    end

                    if state == Enum.UserInputState.Begin then
                        Pinching = true
                        Dragging = false
                        LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
                    elseif state == Enum.UserInputState.Change then
                        local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                        local delta = (currentDist - LastPinchDist) * 0.1
                        LastPinchDist = currentDist
                        Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
                    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                        Pinching = false
                    end
                end))

                Viewport.Object.Parent = ViewportFrame
                if Viewport.AutoFocus then
                    FocusCamera()
                end

                function Viewport:SetObject(Object, Clone)
                    assert(Object, "Object cannot be nil.")

                    if Clone then
                        Object = Object:Clone()
                    end

                    if Viewport.Object then
                        Viewport.Object:Destroy()
                    end

                    Viewport.Object = Object
                    Viewport.Object.Parent = ViewportFrame

                    Groupbox:Resize()
                end

                function Viewport:SetHeight(Height)
                    assert(Height > 0, "Height must be greater than 0.")

                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Viewport:Focus()
                    if not Viewport.Object then
                        return
                    end

                    FocusCamera()
                end

                function Viewport:SetCamera(Camera)
                    assert(
                        Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                        "Camera must be a valid Camera instance."
                    )

                    Viewport.Camera = Camera
                    ViewportFrame.CurrentCamera = Camera
                end

                function Viewport:SetInteractive(Interactive)
                    Viewport.Interactive = Interactive
                    ViewportFrame.Active = Interactive
                end

                function Viewport:SetVisible(Visible)
                    Viewport.Visible = Visible

                    Holder.Visible = Viewport.Visible
                    Groupbox:Resize()
                end

                Groupbox:Resize()

                Viewport.Holder = Holder
                table.insert(Groupbox.Elements, Viewport)

                Options[Idx] = Viewport

                return Viewport
            end

            function Funcs:AddImage(Idx, Info)
                Info = Library:Validate(Info, Templates.Image)

                local Groupbox = self
                local Container = Groupbox.Container

                local Image = {
                    Image = Info.Image,
                    Color = Info.Color,
                    RectOffset = Info.RectOffset,
                    RectSize = Info.RectSize,
                    Height = Info.Height,
                    ScaleType = Info.ScaleType,
                    Transparency = Info.Transparency,
                    BackgroundTransparency = Info.BackgroundTransparency,

                    Visible = Info.Visible,
                    Type = "Image",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Image.Visible,
                    Parent = Container,
                })

                local Box = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    BackgroundTransparency = Image.BackgroundTransparency,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 1),
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                local ImageProperties = {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Image = Image.Image,
                    ImageTransparency = Image.Transparency,
                    ImageColor3 = Image.Color,
                    ImageRectOffset = Image.RectOffset,
                    ImageRectSize = Image.RectSize,
                    ScaleType = Image.ScaleType,
                    Parent = Box,
                }

                local Icon = Library:GetCustomIcon(ImageProperties.Image)
                assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

                ImageProperties.Image = Icon.Url
                ImageProperties.ImageRectOffset = Icon.ImageRectOffset
                ImageProperties.ImageRectSize = Icon.ImageRectSize

                local ImageLabel = New("ImageLabel", ImageProperties)

                function Image:SetHeight(Height)
                    assert(Height > 0, "Height must be greater than 0.")

                    Image.Height = Height
                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Image:SetImage(NewImage)
                    assert(typeof(NewImage) == "string", "Image must be a string.")

                    local Icon = Library:GetCustomIcon(NewImage)
                    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

                    NewImage = Icon.Url
                    Image.RectOffset = Icon.ImageRectOffset
                    Image.RectSize = Icon.ImageRectSize

                    ImageLabel.Image = NewImage
                    Image.Image = NewImage
                end

                function Image:SetColor(Color)
                    assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

                    ImageLabel.ImageColor3 = Color
                    Image.Color = Color
                end

                function Image:SetRectOffset(RectOffset)
                    assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

                    ImageLabel.ImageRectOffset = RectOffset
                    Image.RectOffset = RectOffset
                end

                function Image:SetRectSize(RectSize)
                    assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

                    ImageLabel.ImageRectSize = RectSize
                    Image.RectSize = RectSize
                end

                function Image:SetScaleType(ScaleType: Enum.ScaleType)
                    assert(
                        typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                        "ScaleType must be a valid Enum.ScaleType."
                    )

                    ImageLabel.ScaleType = ScaleType
                    Image.ScaleType = ScaleType
                end

                function Image:SetTransparency(Transparency)
                    assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
                    assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

                    ImageLabel.ImageTransparency = Transparency
                    Image.Transparency = Transparency
                end

                function Image:SetVisible(Visible)
                    Image.Visible = Visible

                    Holder.Visible = Image.Visible
                    Groupbox:Resize()
                end

                Groupbox:Resize()

                Image.Holder = Holder
                table.insert(Groupbox.Elements, Image)

                Options[Idx] = Image

                return Image
            end

            function Funcs:AddVideo(Idx, Info)
                Info = Library:Validate(Info, Templates.Video)

                local Groupbox = self
                local Container = Groupbox.Container

                local Video = {
                    Video = Info.Video,
                    Looped = Info.Looped,
                    Playing = Info.Playing,
                    Volume = Info.Volume,
                    Height = Info.Height,
                    Visible = Info.Visible,

                    Type = "Video",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Video.Visible,
                    Parent = Container,
                })

                local Box = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "MainColor",
                    BorderColor3 = "OutlineColor",
                    BorderSizePixel = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.fromScale(1, 1),
                    Parent = Holder,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 4),
                    Parent = Box,
                })

                local VideoFrameInstance = New("VideoFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Video = Video.Video,
                    Looped = Video.Looped,
                    Volume = Video.Volume,
                    Parent = Box,
                })

                VideoFrameInstance.Playing = Video.Playing

                function Video:SetHeight(Height)
                    assert(Height > 0, "Height must be greater than 0.")

                    Video.Height = Height
                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Video:SetVideo(NewVideo)
                    assert(typeof(NewVideo) == "string", "Video must be a string.")

                    VideoFrameInstance.Video = NewVideo
                    Video.Video = NewVideo
                end

                function Video:SetLooped(Looped)
                    assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

                    VideoFrameInstance.Looped = Looped
                    Video.Looped = Looped
                end

                function Video:SetVolume(Volume)
                    assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

                    VideoFrameInstance.Volume = Volume
                    Video.Volume = Volume
                end

                function Video:SetPlaying(Playing)
                    assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

                    VideoFrameInstance.Playing = Playing
                    Video.Playing = Playing
                end

                function Video:Play()
                    VideoFrameInstance.Playing = true
                    Video.Playing = true
                end

                function Video:Pause()
                    VideoFrameInstance.Playing = false
                    Video.Playing = false
                end

                function Video:SetVisible(Visible)
                    Video.Visible = Visible

                    Holder.Visible = Video.Visible
                    Groupbox:Resize()
                end

                Groupbox:Resize()

                Video.Holder = Holder
                Video.VideoFrame = VideoFrameInstance
                table.insert(Groupbox.Elements, Video)

                Options[Idx] = Video

                return Video
            end

            function Funcs:AddUIPassthrough(Idx, Info)
                Info = Library:Validate(Info, Templates.UIPassthrough)

                local Groupbox = self
                local Container = Groupbox.Container

                assert(Info.Instance, "Instance must be provided.")
                assert(
                    typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
                    "Instance must inherit from GuiBase2d."
                )
                assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

                local Passthrough = {
                    Instance = Info.Instance,
                    Height = Info.Height,
                    Visible = Info.Visible,

                    Type = "UIPassthrough",
                }

                local Holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Info.Height),
                    Visible = Passthrough.Visible,
                    Parent = Container,
                })

                Passthrough.Instance.Parent = Holder

                Groupbox:Resize()

                function Passthrough:SetHeight(Height)
                    assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

                    Passthrough.Height = Height
                    Holder.Size = UDim2.new(1, 0, 0, Height)
                    Groupbox:Resize()
                end

                function Passthrough:SetInstance(Instance)
                    assert(Instance, "Instance must be provided.")
                    assert(
                        typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                        "Instance must inherit from GuiBase2d."
                    )

                    if Passthrough.Instance then
                        Passthrough.Instance.Parent = nil
                    end

                    Passthrough.Instance = Instance
                    Passthrough.Instance.Parent = Holder
                end

                function Passthrough:SetVisible(Visible)
                    Passthrough.Visible = Visible

                    Holder.Visible = Passthrough.Visible
                    Groupbox:Resize()
                end

                Passthrough.Holder = Holder
                table.insert(Groupbox.Elements, Passthrough)

                Options[Idx] = Passthrough

                return Passthrough
            end

            function Funcs:AddDependencyBox()
                local Groupbox = self
                local Container = Groupbox.Container

                local DepboxContainer
                local DepboxList

                do
                    DepboxContainer = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Visible = false,
                        Parent = Container,
                    })

                    DepboxList = New("UIListLayout", {
                        Padding = UDim.new(0, 8),
                        Parent = DepboxContainer,
                    })
                end

                local Depbox = {
                    Visible = false,
                    Dependencies = {},

                    Holder = DepboxContainer,
                    Container = DepboxContainer,

                    Elements = {},
                    DependencyBoxes = {},
                }

                function Depbox:Resize()
                    DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y / Library.DPIScale)
                    Groupbox:Resize()
                end

                function Depbox:Update(CancelSearch)
                    for _, Dependency in Depbox.Dependencies do
                        local Element = Dependency[1]
                        local Value = Dependency[2]

                        if Element.Type == "Toggle" and Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        elseif Element.Type == "Dropdown" then
                            if typeof(Element.Value) == "table" then
                                if not Element.Value[Value] then
                                    DepboxContainer.Visible = false
                                    Depbox.Visible = false
                                    return
                                end
                            else
                                if Element.Value ~= Value then
                                    DepboxContainer.Visible = false
                                    Depbox.Visible = false
                                    return
                                end
                            end
                        end
                    end

                    Depbox.Visible = true
                    DepboxContainer.Visible = true
                    if not Library.Searching then
                        task.defer(function()
                            Depbox:Resize()
                        end)
                    elseif not CancelSearch then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if not Depbox.Visible then
                        return
                    end

                    Depbox:Resize()
                end)

                function Depbox:SetupDependencies(Dependencies)
                    for _, Dependency in Dependencies do
                        assert(typeof(Dependency) == "table", "Dependency should be a table.")
                        assert(Dependency[1] ~= nil, "Dependency is missing element.")
                        assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
                    end

                    Depbox.Dependencies = Dependencies
                    Depbox:Update()
                end

                DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
                    Depbox:Resize()
                end)

                setmetatable(Depbox, BaseGroupbox)

                table.insert(Groupbox.DependencyBoxes, Depbox)
                table.insert(Library.DependencyBoxes, Depbox)

                return Depbox
            end

            function Funcs:AddDependencyGroupbox()
                local Groupbox = self
                local Tab = Groupbox.Tab
                local BoxHolder = Groupbox.BoxHolder

                local DepGroupboxContainer
                local DepGroupboxList

                do
                    DepGroupboxContainer = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Size = UDim2.fromScale(1, 0),
                        Visible = false,
                        Parent = BoxHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius),
                        Parent = DepGroupboxContainer,
                    })
                    Library:AddOutline(DepGroupboxContainer)

                    DepGroupboxList = New("UIListLayout", {
                        Padding = UDim.new(0, 8),
                        Parent = DepGroupboxContainer,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 7),
                        PaddingLeft = UDim.new(0, 7),
                        PaddingRight = UDim.new(0, 7),
                        PaddingTop = UDim.new(0, 7),
                        Parent = DepGroupboxContainer,
                    })
                end

                local DepGroupbox = {
                    Visible = false,
                    Dependencies = {},

                    BoxHolder = BoxHolder,
                    Holder = DepGroupboxContainer,
                    Container = DepGroupboxContainer,

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function DepGroupbox:Resize()
                    DepGroupboxContainer.Size = UDim2.new(1, 0, 0, (DepGroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
                end

                function DepGroupbox:Update(CancelSearch)
                    for _, Dependency in DepGroupbox.Dependencies do
                        local Element = Dependency[1]
                        local Value = Dependency[2]

                        if Element.Type == "Toggle" and Element.Value ~= Value then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        elseif Element.Type == "Dropdown" then
                            if typeof(Element.Value) == "table" then
                                if not Element.Value[Value] then
                                    DepGroupboxContainer.Visible = false
                                    DepGroupbox.Visible = false
                                    return
                                end
                            else
                                if Element.Value ~= Value then
                                    DepGroupboxContainer.Visible = false
                                    DepGroupbox.Visible = false
                                    return
                                end
                            end
                        end
                    end

                    DepGroupbox.Visible = true
                    if not Library.Searching then
                        DepGroupboxContainer.Visible = true
                        DepGroupbox:Resize()
                    elseif not CancelSearch then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                function DepGroupbox:SetupDependencies(Dependencies)
                    for _, Dependency in Dependencies do
                        assert(typeof(Dependency) == "table", "Dependency should be a table.")
                        assert(Dependency[1] ~= nil, "Dependency is missing element.")
                        assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
                    end

                    DepGroupbox.Dependencies = Dependencies
                    DepGroupbox:Update()
                end

                setmetatable(DepGroupbox, BaseGroupbox)

                table.insert(Tab.DependencyGroupboxes, DepGroupbox)
                table.insert(Library.DependencyBoxes, DepGroupbox)

                return DepGroupbox
            end

            BaseGroupbox.__index = Funcs
            BaseGroupbox.__namecall = function(_, Key, ...)
                return Funcs[Key](...)
            end
        end

        function Library:SetFont(FontFace)
            if typeof(FontFace) == "EnumItem" then
                FontFace = Font.fromEnum(FontFace)
            end

            Library.Scheme.Font = FontFace
            Library:UpdateColorsUsingRegistry()
        end

        function Library:SetNotifySide(Side)
            Library.NotifySide = Side

            if Side:lower() == "left" then
                NotificationArea.AnchorPoint = Vector2.new(0, 0)
                NotificationArea.Position = UDim2.fromOffset(6, 6)
                NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
            else
                NotificationArea.AnchorPoint = Vector2.new(1, 0)
                NotificationArea.Position = UDim2.new(1, -6, 0, 6)
                NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
            end
        end

        function Library:Notify(...)
            local Data = {}
            local Info = select(1, ...)

            if typeof(Info) == "table" then
                Data.Title = tostring(Info.Title)
                Data.Description = tostring(Info.Description)
                Data.Time = Info.Time or 5
                Data.SoundId = Info.SoundId
                Data.Steps = Info.Steps
                Data.Persist = Info.Persist
            else
                Data.Description = tostring(Info)
                Data.Time = select(2, ...) or 5
                Data.SoundId = select(3, ...)
            end
            Data.Destroyed = false

            local DeletedInstance = false
            local DeleteConnection = nil
            if typeof(Data.Time) == "Instance" then
                DeleteConnection = Data.Time.Destroying:Connect(function()
                    DeletedInstance = true

                    DeleteConnection:Disconnect()
                    DeleteConnection = nil
                end)
            end

            local FakeBackground = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = NotificationArea,
            })

            local Holder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = "MainColor",
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
                Size = UDim2.fromScale(1, 1),
                ZIndex = 5,
                Parent = FakeBackground,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Holder,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 4),
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                Parent = Holder,
            })
            Library:AddOutline(Holder)

            local Title
            local Desc
            local TitleX = 0
            local DescX = 0

            local TimerFill

            if Data.Title then
                Title = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0, 0),
                    Text = Data.Title,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = Holder,
                })
            end

            if Data.Description then
                Desc = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0, 0),
                    Text = Data.Description,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = Holder,
                })
            end

            function Data:Resize()
                if Title then
                    local X, Y =
                        Library:GetTextBounds(Title.Text, Title.FontFace, Title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24)
                    Title.Size = UDim2.fromOffset(0, Y)
                    TitleX = X
                end

                if Desc then
                    local X, Y =
                        Library:GetTextBounds(Desc.Text, Desc.FontFace, Desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24)
                    Desc.Size = UDim2.fromOffset(0, Y)
                    DescX = X
                end

                FakeBackground.Size = UDim2.fromOffset(math.max(TitleX, DescX) + 24, 0)
            end

            function Data:ChangeTitle(Text)
                if Title then
                    Data.Title = tostring(Text)
                    Title.Text = Data.Title
                    Data:Resize()
                end
            end

            function Data:ChangeDescription(Text)
                if Desc then
                    Data.Description = tostring(Text)
                    Desc.Text = Data.Description
                    Data:Resize()
                end
            end

            function Data:ChangeStep(NewStep)
                if TimerFill and Data.Steps then
                    NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
                    TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
                end
            end

            function Data:Destroy()
                Data.Destroyed = true

                if typeof(Data.Time) == "Instance" then
                    pcall(Data.Time.Destroy, Data.Time)
                end

                if DeleteConnection then
                    DeleteConnection:Disconnect()
                end

                TweenService
                    :Create(Holder, Library.NotifyTweenInfo, {
                        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
                    })
                    :Play()

                task.delay(Library.NotifyTweenInfo.Time, function()
                    Library.Notifications[FakeBackground] = nil
                    FakeBackground:Destroy()
                end)
            end

            Data:Resize()

            local TimerHolder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 7),
                Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
                Parent = Holder,
            })
            local TimerBar = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromOffset(0, 3),
                Size = UDim2.new(1, 0, 0, 2),
                Parent = TimerHolder,
            })
            TimerFill = New("Frame", {
                BackgroundColor3 = "AccentColor",
                Size = UDim2.fromScale(1, 1),
                Parent = TimerBar,
            })

            if typeof(Data.Time) == "Instance" then
                TimerFill.Size = UDim2.fromScale(0, 1)
            end
            if Data.SoundId then
                local SoundId = Data.SoundId
                if typeof(SoundId) == "number" then
                    SoundId = string.format("rbxassetid://%d", SoundId)
                end

                New("Sound", {
                    SoundId = SoundId,
                    Volume = 3,
                    PlayOnRemove = true,
                    Parent = SoundService,
                }):Destroy()
            end

            Library.Notifications[FakeBackground] = Data

            FakeBackground.Visible = true
            TweenService:Create(Holder, Library.NotifyTweenInfo, {
                Position = UDim2.fromOffset(0, 0),
            }):Play()

            task.delay(Library.NotifyTweenInfo.Time, function()
                if Data.Persist then
                    return
                elseif typeof(Data.Time) == "Instance" then
                    repeat
                        task.wait()
                    until DeletedInstance or Data.Destroyed
                else
                    TweenService
                        :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                            Size = UDim2.fromScale(0, 1),
                        })
                        :Play()
                    task.wait(Data.Time)
                end

                if not Data.Destroyed then
                    Data:Destroy()
                end
            end)

            return Data
        end

        function Library:CreateWindow(WindowInfo)
            WindowInfo = Library:Validate(WindowInfo, Templates.Window)
            local ViewportSize = workspace.CurrentCamera.ViewportSize

            local MaxX = ViewportSize.X - 64
            local MaxY = ViewportSize.Y - 64

            Library.OriginalMinSize =
                Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
            Library.MinSize = Library.OriginalMinSize

            WindowInfo.Size = UDim2.fromOffset(
                math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
                math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
            )
            if typeof(WindowInfo.Font) == "EnumItem" then
                WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
            end
            WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)

            Library.CornerRadius = WindowInfo.CornerRadius
            Library:SetNotifySide(WindowInfo.NotifySide)
            Library.Scheme.Font = WindowInfo.Font
            Library.ToggleKeybind = WindowInfo.ToggleKeybind
            Library.GlobalSearch = WindowInfo.GlobalSearch

            local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
            local MainFrame
            local DividerLine
            local TitleHolder
            local WindowTitle
            local WindowIcon
            local RightWrapper
            local SearchBox
            local CurrentTabInfo
            local CurrentTabLabel
            local CurrentTabDescription
            local ResizeButton
            local Tabs
            local Container

            local InitialLeftWidth = math.ceil(WindowInfo.Size.X.Offset * 0.3)
            local LastExpandedWidth = InitialLeftWidth

            do
                Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
                Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
                Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
                Library.KeybindFrame.Visible = false

                MainFrame = New("TextButton", {
                    BackgroundColor3 = function()
                        return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
                    end,
                    Name = "Main",
                    Text = "",
                    Position = WindowInfo.Position,
                    Size = WindowInfo.Size,
                    Visible = false,
                    Parent = ScreenGui,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = MainFrame,
                })
                table.insert(
                    Library.Scales,
                    New("UIScale", {
                        Parent = MainFrame,
                    })
                )
                Library:AddOutline(MainFrame)
                Library:MakeLine(MainFrame, {
                    Position = UDim2.fromOffset(0, 48),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                DividerLine = New("Frame", {
                    BackgroundColor3 = "OutlineColor",
                    Position = UDim2.fromOffset(InitialLeftWidth, 0),
                    Size = UDim2.new(0, 1, 1, -21),
                    Parent = MainFrame,
                })

                if WindowInfo.BackgroundImage then
                    New("ImageLabel", {
                        Image = WindowInfo.BackgroundImage,
                        Position = UDim2.fromScale(0, 0),
                        Size = UDim2.fromScale(1, 1),
                        ScaleType = Enum.ScaleType.Stretch,
                        ZIndex = 999,
                        BackgroundTransparency = 1,
                        ImageTransparency = 0.75,
                        Parent = MainFrame,
                    })
                end

                if WindowInfo.Center then
                    MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
                end

                local TopBar = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 48),
                    Parent = MainFrame,
                })
                Library:MakeDraggable(MainFrame, TopBar, false, true)

                TitleHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, InitialLeftWidth, 1, 0),
                    Parent = TopBar,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                    Parent = TitleHolder,
                })

                if WindowInfo.Icon then
                    WindowIcon = New("ImageLabel", {
                        Image = if tonumber(WindowInfo.Icon)
                            then string.format("rbxassetid://%d", WindowInfo.Icon)
                            else WindowInfo.Icon,
                        Size = WindowInfo.IconSize,
                        Parent = TitleHolder,
                    })
                else
                    WindowIcon = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = WindowInfo.IconSize,
                        Text = WindowInfo.Title:sub(1, 1),
                        TextScaled = true,
                        Visible = false,
                        Parent = TitleHolder,
                    })
                end

                local X = Library:GetTextBounds(
                    WindowInfo.Title,
                    Library.Scheme.Font,
                    20,
                    TitleHolder.AbsoluteSize.X - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0) - 12
                )
                WindowTitle = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, X, 1, 0),
                    Text = WindowInfo.Title,
                    TextSize = 20,
                    Parent = TitleHolder,
                })

                RightWrapper = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -49, 0.5, 0),
                    Size = UDim2.new(1, -InitialLeftWidth - 57 - 1, 1, -16),
                    Parent = TopBar,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = RightWrapper,
                })

                CurrentTabInfo = New("Frame", {
                    Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
                    Visible = false,
                    BackgroundTransparency = 1,
                    Parent = RightWrapper,
                })

                New("UIFlexItem", {
                    FlexMode = Enum.UIFlexMode.Grow,
                    Parent = CurrentTabInfo,
                })

                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Parent = CurrentTabInfo,
                })

                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 8),
                    Parent = CurrentTabInfo,
                })

                CurrentTabLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = "",
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = CurrentTabInfo,
                })

                CurrentTabDescription = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = "",
                    TextWrapped = true,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTransparency = 0.5,
                    Parent = CurrentTabInfo,
                })

                SearchBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    PlaceholderText = "Search",
                    Size = WindowInfo.SearchbarSize,
                    TextScaled = true,
                    Visible = not (WindowInfo.DisableSearch or false),
                    Parent = RightWrapper,
                })
                New("UIFlexItem", {
                    FlexMode = Enum.UIFlexMode.Shrink,
                    Parent = SearchBox,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = SearchBox,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 8),
                    Parent = SearchBox,
                })
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = SearchBox,
                })

                local SearchIcon = Library:GetIcon("search")
                if SearchIcon then
                    New("ImageLabel", {
                        Image = SearchIcon.Url,
                        ImageColor3 = "FontColor",
                        ImageRectOffset = SearchIcon.ImageRectOffset,
                        ImageRectSize = SearchIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = UDim2.fromScale(1, 1),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Parent = SearchBox,
                    })
                end

                if MoveIcon then
                    New("ImageLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Image = MoveIcon.Url,
                        ImageColor3 = "OutlineColor",
                        ImageRectOffset = MoveIcon.ImageRectOffset,
                        ImageRectSize = MoveIcon.ImageRectSize,
                        Position = UDim2.new(1, -10, 0.5, 0),
                        Size = UDim2.fromOffset(28, 28),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Parent = TopBar,
                    })
                end

                Library:MakeLine(MainFrame, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, -20),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BottomBar = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0, 1),
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = MainFrame,
                })

                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = WindowInfo.Footer,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    Parent = BottomBar,
                })

                if WindowInfo.Resizable then
                    ResizeButton = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -WindowInfo.CornerRadius / 4, 0, 0),
                        Size = UDim2.fromScale(1, 1),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Text = "",
                        Parent = BottomBar,
                    })

                    Library:MakeResizable(MainFrame, ResizeButton, function()
                        for _, Tab in Library.Tabs do
                            Tab:Resize(true)
                        end
                    end)
                end

                New("ImageLabel", {
                    Image = ResizeIcon and ResizeIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = ResizeButton,
                })

                Tabs = New("ScrollingFrame", {
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = "BackgroundColor",
                    CanvasSize = UDim2.fromScale(0, 0),
                    Position = UDim2.fromOffset(0, 49),
                    ScrollBarThickness = 0,
                    Size = UDim2.new(0, InitialLeftWidth, 1, -70),
                    Parent = MainFrame,
                })
                New("UIListLayout", {
                    Parent = Tabs,
                })

                Container = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = function()
                        return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
                    end,
                    Name = "Container",
                    Position = UDim2.new(1, 0, 0, 49),
                    Size = UDim2.new(1, -InitialLeftWidth - 1, 1, -70),
                    Parent = MainFrame,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 0),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 0),
                    Parent = Container,
                })
            end

            local Window = {}

            function Window:ChangeTitle(title)
                assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

                WindowTitle.Text = title
                WindowInfo.Title = title
            end

            function Window:ShowTabInfo(Name, Description)
                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end
                CurrentTabInfo.Visible = true
            end
            function Window:HideTabInfo()
                CurrentTabInfo.Visible = false
                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(1, 1)
                end
            end

            function Window:AddTab(...)
                local Name = nil
                local Icon = nil
                local Description = nil

                if select("#", ...) == 1 and typeof(...) == "table" then
                    local Info = select(1, ...)
                    Name = Info.Name or "Tab"
                    Icon = Info.Icon
                    Description = Info.Description
                else
                    Name = select(1, ...)
                    Icon = select(2, ...)
                    Description = select(3, ...)
                end

                local TabButton: TextButton
                local TabLabel
                local TabIcon

                local TabContainer
                local TabLeft
                local TabRight

                Icon = Library:GetCustomIcon(Icon)
                do
                    TabButton = New("TextButton", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        Text = "",
                        Parent = Tabs,
                    })
                    local ButtonPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 11),
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        PaddingTop = UDim.new(0, 11),
                        Parent = TabButton,
                    })

                    TabLabel = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(30, 0),
                        Size = UDim2.new(1, -30, 1, 0),
                        Text = Name,
                        TextSize = 16,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Visible = true,
                        Parent = TabButton,
                    })

                    if Icon then
                        TabIcon = New("ImageLabel", {
                            Image = Icon.Url,
                            ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                            ImageRectOffset = Icon.ImageRectOffset,
                            ImageRectSize = Icon.ImageRectSize,
                            ImageTransparency = 0.5,
                            ScaleType = Enum.ScaleType.Fit,
                            Size = UDim2.fromScale(1, 1),
                            SizeConstraint = Enum.SizeConstraint.RelativeYY,
                            Parent = TabButton,
                        })
                    end

                    table.insert(Library.TabButtons, {
                        Label = TabLabel,
                        Padding = ButtonPadding,
                        Icon = TabIcon,
                    })

                    TabContainer = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Visible = false,
                        Parent = Container,
                    })

                    TabLeft = New("ScrollingFrame", {
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2.fromScale(0, 0),
                        ScrollBarImageTransparency = 1,
                        ScrollBarThickness = 0,
                        Size = UDim2.new(0.5, -3, 1, 0),
                        Parent = TabContainer,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        Parent = TabLeft,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 2),
                        PaddingLeft = UDim.new(0, 2),
                        PaddingRight = UDim.new(0, 2),
                        PaddingTop = UDim.new(0, 2),
                        Parent = TabLeft,
                    })
                    do
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = -1,
                            Parent = TabLeft,
                        })
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = 1,
                            Parent = TabLeft,
                        })
                    end

                    TabRight = New("ScrollingFrame", {
                        AnchorPoint = Vector2.new(1, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2.fromScale(0, 0),
                        Position = UDim2.fromScale(1, 0),
                        ScrollBarImageTransparency = 1,
                        ScrollBarThickness = 0,
                        Size = UDim2.new(0.5, -3, 1, 0),
                        Parent = TabContainer,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        Parent = TabRight,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 2),
                        PaddingLeft = UDim.new(0, 2),
                        PaddingRight = UDim.new(0, 2),
                        PaddingTop = UDim.new(0, 2),
                        Parent = TabRight,
                    })
                    do
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = -1,
                            Parent = TabRight,
                        })
                        New("Frame", {
                            BackgroundTransparency = 1,
                            LayoutOrder = 1,
                            Parent = TabRight,
                        })
                    end
                end

                local WarningBoxHolder = New("Frame", {
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 7),
                    Size = UDim2.fromScale(1, 0),
                    Visible = false,
                    Parent = TabContainer,
                })

                local WarningBox
                local WarningBoxOutline
                local WarningBoxShadowOutline
                local WarningBoxScrollingFrame
                local WarningTitle
                local WarningStroke
                local WarningText
                do
                    WarningBox = New("Frame", {
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.fromOffset(2, 0),
                        Size = UDim2.new(1, -5, 0, 0),
                        Parent = WarningBoxHolder,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = WarningBox,
                    })
                    WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)

                    WarningBoxScrollingFrame = New("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.fromScale(1, 1),
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        ScrollBarThickness = 3,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        Parent = WarningBox,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 6),
                        PaddingRight = UDim.new(0, 6),
                        PaddingTop = UDim.new(0, 4),
                        Parent = WarningBoxScrollingFrame,
                    })

                    WarningTitle = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -4, 0, 14),
                        Text = "",
                        TextColor3 = Color3.fromRGB(255, 50, 50),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = WarningBoxScrollingFrame,
                    })

                    WarningStroke = New("UIStroke", {
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        Color = Color3.fromRGB(169, 0, 0),
                        LineJoinMode = Enum.LineJoinMode.Miter,
                        Parent = WarningTitle,
                    })

                    WarningText = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(0, 16),
                        Size = UDim2.new(1, -4, 0, 0),
                        Text = "",
                        TextSize = 14,
                        TextWrapped = true,
                        Parent = WarningBoxScrollingFrame,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                    })

                    New("UIStroke", {
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        Color = "DarkColor",
                        LineJoinMode = Enum.LineJoinMode.Miter,
                        Parent = WarningText,
                    })
                end

                local Tab = {
                    Groupboxes = {},
                    Tabboxes = {},
                    DependencyGroupboxes = {},
                    Sides = {
                        TabLeft,
                        TabRight,
                    },
                    WarningBox = {
                        IsNormal = false,
                        LockSize = false,
                        Visible = false,
                        Title = "WARNING",
                        Text = "",
                    },
                }

                function Tab:UpdateWarningBox(Info)
                    if typeof(Info.IsNormal) == "boolean" then
                        Tab.WarningBox.IsNormal = Info.IsNormal
                    end
                    if typeof(Info.LockSize) == "boolean" then
                        Tab.WarningBox.LockSize = Info.LockSize
                    end
                    if typeof(Info.Visible) == "boolean" then
                        Tab.WarningBox.Visible = Info.Visible
                    end
                    if typeof(Info.Title) == "string" then
                        Tab.WarningBox.Title = Info.Title
                    end
                    if typeof(Info.Text) == "string" then
                        Tab.WarningBox.Text = Info.Text
                    end

                    WarningBoxHolder.Visible = Tab.WarningBox.Visible
                    WarningTitle.Text = Tab.WarningBox.Title
                    WarningText.Text = Tab.WarningBox.Text
                    Tab:Resize(true)

                    WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
                        or Color3.fromRGB(127, 0, 0)

                    WarningBoxShadowOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor
                        or Color3.fromRGB(85, 0, 0)
                    WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                        or Color3.fromRGB(255, 50, 50)

                    WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                        or Color3.fromRGB(255, 50, 50)
                    WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                        or Color3.fromRGB(169, 0, 0)

                    if not Library.Registry[WarningBox] then
                        Library:AddToRegistry(WarningBox, {})
                    end
                    if not Library.Registry[WarningBoxShadowOutline] then
                        Library:AddToRegistry(WarningBoxShadowOutline, {})
                    end
                    if not Library.Registry[WarningBoxOutline] then
                        Library:AddToRegistry(WarningBoxOutline, {})
                    end
                    if not Library.Registry[WarningTitle] then
                        Library:AddToRegistry(WarningTitle, {})
                    end
                    if not Library.Registry[WarningStroke] then
                        Library:AddToRegistry(WarningStroke, {})
                    end

                    Library.Registry[WarningBox].BackgroundColor3 = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
                    end

                    Library.Registry[WarningBoxShadowOutline].Color = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor or Color3.fromRGB(85, 0, 0)
                    end

                    Library.Registry[WarningBoxOutline].Color = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
                    end

                    Library.Registry[WarningTitle].TextColor3 = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
                    end

                    Library.Registry[WarningStroke].Color = function()
                        return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
                    end
                end

                function Tab:RefreshSides()
                    local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
                    for _, Side in Tab.Sides do
                        Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
                        Side.Size = UDim2.new(0.5, -3, 1, -Offset)
                    end
                end

                function Tab:Resize(ResizeWarningBox)
                    if ResizeWarningBox then
                        local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                        local _, YText = Library:GetTextBounds(
                            WarningText.Text,
                            Library.Scheme.Font,
                            WarningText.TextSize,
                            WarningText.AbsoluteSize.X
                        )

                        local YBox = 24 + YText
                        if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                            WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                            YBox = MaximumSize
                        else
                            WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                        end

                        WarningText.Size = UDim2.new(1, -4, 0, YText)
                        WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
                    end

                    Tab:RefreshSides()
                end

                function Tab:AddGroupbox(Info)
                    local BoxHolder = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0),
                        Parent = Info.Side == 1 and TabLeft or TabRight,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 6),
                        Parent = BoxHolder,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = BoxHolder,
                    })

                    local GroupboxHolder
                    local GroupboxLabel

                    local GroupboxContainer
                    local GroupboxList

                    do
                        GroupboxHolder = New("Frame", {
                            BackgroundColor3 = "BackgroundColor",
                            Size = UDim2.fromScale(1, 0),
                            Parent = BoxHolder,
                        })
                        New("UICorner", {
                            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                            Parent = GroupboxHolder,
                        })
                        Library:AddOutline(GroupboxHolder)

                        Library:MakeLine(GroupboxHolder, {
                            Position = UDim2.fromOffset(0, 34),
                            Size = UDim2.new(1, 0, 0, 1),
                        })

                        local BoxIcon = Library:GetCustomIcon(Info.IconName)
                        if BoxIcon then
                            New("ImageLabel", {
                                Image = BoxIcon.Url,
                                ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                                ImageRectOffset = BoxIcon.ImageRectOffset,
                                ImageRectSize = BoxIcon.ImageRectSize,
                                Position = UDim2.fromOffset(6, 6),
                                Size = UDim2.fromOffset(22, 22),
                                Parent = GroupboxHolder,
                            })
                        end

                        GroupboxLabel = New("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                            Size = UDim2.new(1, 0, 0, 34),
                            Text = Info.Name,
                            TextSize = 15,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = GroupboxHolder,
                        })
                        New("UIPadding", {
                            PaddingLeft = UDim.new(0, 12),
                            PaddingRight = UDim.new(0, 12),
                            Parent = GroupboxLabel,
                        })

                        GroupboxContainer = New("Frame", {
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(0, 35),
                            Size = UDim2.new(1, 0, 1, -35),
                            Parent = GroupboxHolder,
                        })

                        GroupboxList = New("UIListLayout", {
                            Padding = UDim.new(0, 8),
                            Parent = GroupboxContainer,
                        })
                        New("UIPadding", {
                            PaddingBottom = UDim.new(0, 7),
                            PaddingLeft = UDim.new(0, 7),
                            PaddingRight = UDim.new(0, 7),
                            PaddingTop = UDim.new(0, 7),
                            Parent = GroupboxContainer,
                        })
                    end

                    local Groupbox = {
                        BoxHolder = BoxHolder,
                        Holder = GroupboxHolder,
                        Container = GroupboxContainer,

                        Tab = Tab,
                        DependencyBoxes = {},
                        Elements = {},
                    }

                    function Groupbox:Resize()
                        GroupboxHolder.Size = UDim2.new(1, 0, 0, (GroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                    end

                    setmetatable(Groupbox, BaseGroupbox)

                    Groupbox:Resize()
                    Tab.Groupboxes[Info.Name] = Groupbox

                    return Groupbox
                end

                function Tab:AddLeftGroupbox(Name, IconName)
                    return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName })
                end

                function Tab:AddRightGroupbox(Name, IconName)
                    return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName })
                end

                function Tab:AddTabbox(Info)
                    local BoxHolder = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0),
                        Parent = Info.Side == 1 and TabLeft or TabRight,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 6),
                        Parent = BoxHolder,
                    })
                    New("UIPadding", {
                        PaddingBottom = UDim.new(0, 4),
                        PaddingTop = UDim.new(0, 4),
                        Parent = BoxHolder,
                    })

                    local TabboxHolder
                    local TabboxButtons

                    do
                        TabboxHolder = New("Frame", {
                            BackgroundColor3 = "BackgroundColor",
                            Size = UDim2.fromScale(1, 0),
                            Parent = BoxHolder,
                        })
                        New("UICorner", {
                            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                            Parent = TabboxHolder,
                        })
                        Library:AddOutline(TabboxHolder)

                        TabboxButtons = New("Frame", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 34),
                            Parent = TabboxHolder,
                        })
                        New("UIListLayout", {
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalFlex = Enum.UIFlexAlignment.Fill,
                            Parent = TabboxButtons,
                        })
                    end

                    local Tabbox = {
                        ActiveTab = nil,

                        BoxHolder = BoxHolder,
                        Holder = TabboxHolder,
                        Tabs = {},
                    }

                    function Tabbox:AddTab(Name)
                        local Button = New("TextButton", {
                            BackgroundColor3 = "MainColor",
                            BackgroundTransparency = 0,
                            Size = UDim2.fromOffset(0, 34),
                            Text = Name,
                            TextSize = 15,
                            TextTransparency = 0.5,
                            Parent = TabboxButtons,
                        })

                        local Line = Library:MakeLine(Button, {
                            AnchorPoint = Vector2.new(0, 1),
                            Position = UDim2.new(0, 0, 1, 1),
                            Size = UDim2.new(1, 0, 0, 1),
                        })

                        local Container = New("Frame", {
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(0, 35),
                            Size = UDim2.new(1, 0, 1, -35),
                            Visible = false,
                            Parent = TabboxHolder,
                        })
                        local List = New("UIListLayout", {
                            Padding = UDim.new(0, 8),
                            Parent = Container,
                        })
                        New("UIPadding", {
                            PaddingBottom = UDim.new(0, 7),
                            PaddingLeft = UDim.new(0, 7),
                            PaddingRight = UDim.new(0, 7),
                            PaddingTop = UDim.new(0, 7),
                            Parent = Container,
                        })

                        local Tab = {
                            ButtonHolder = Button,
                            Container = Container,

                            Tab = Tab,
                            Elements = {},
                            DependencyBoxes = {},
                        }

                        function Tab:Show()
                            if Tabbox.ActiveTab then
                                Tabbox.ActiveTab:Hide()
                            end

                            Button.BackgroundTransparency = 1
                            Button.TextTransparency = 0
                            Line.Visible = false

                            Container.Visible = true

                            Tabbox.ActiveTab = Tab
                            Tab:Resize()
                        end

                        function Tab:Hide()
                            Button.BackgroundTransparency = 0
                            Button.TextTransparency = 0.5
                            Line.Visible = true
                            Container.Visible = false

                            Tabbox.ActiveTab = nil
                        end

                        function Tab:Resize()
                            if Tabbox.ActiveTab ~= Tab then
                                return
                            end

                            TabboxHolder.Size = UDim2.new(1, 0, 0, (List.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                        end

                        if not Tabbox.ActiveTab then
                            Tab:Show()
                        end

                        Button.MouseButton1Click:Connect(Tab.Show)

                        setmetatable(Tab, BaseGroupbox)

                        Tabbox.Tabs[Name] = Tab

                        return Tab
                    end

                    if Info.Name then
                        Tab.Tabboxes[Info.Name] = Tabbox
                    else
                        table.insert(Tab.Tabboxes, Tabbox)
                    end

                    return Tabbox
                end

                function Tab:AddLeftTabbox(Name)
                    return Tab:AddTabbox({ Side = 1, Name = Name })
                end

                function Tab:AddRightTabbox(Name)
                    return Tab:AddTabbox({ Side = 2, Name = Name })
                end

                function Tab:Hover(Hovering)
                    if Library.ActiveTab == Tab then
                        return
                    end

                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = Hovering and 0.25 or 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = Hovering and 0.25 or 0.5,
                        }):Play()
                    end
                end

                function Tab:Show()
                    if Library.ActiveTab then
                        Library.ActiveTab:Hide()
                    end

                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 0,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0,
                        }):Play()
                    end

                    if Description then
                        Window:ShowTabInfo(Name, Description)
                    end

                    TabContainer.Visible = true
                    Tab:RefreshSides()

                    Library.ActiveTab = Tab

                    if Library.Searching then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                function Tab:Hide()
                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 1,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0.5,
                        }):Play()
                    end
                    TabContainer.Visible = false

                    Window:HideTabInfo()

                    Library.ActiveTab = nil
                end

                if not Library.ActiveTab then
                    Tab:Show()
                end

                TabButton.MouseEnter:Connect(function()
                    Tab:Hover(true)
                end)
                TabButton.MouseLeave:Connect(function()
                    Tab:Hover(false)
                end)
                TabButton.MouseButton1Click:Connect(Tab.Show)

                Library.Tabs[Name] = Tab

                return Tab
            end

            function Window:AddKeyTab(...)
                local Name = nil
                local Icon = nil
                local Description = nil

                if select("#", ...) == 1 and typeof(...) == "table" then
                    local Info = select(1, ...)
                    Name = Info.Name or "Tab"
                    Icon = Info.Icon
                    Description = Info.Description
                else
                    Name = select(1, ...) or "Tab"
                    Icon = select(2, ...)
                    Description = select(3, ...)
                end

                Icon = Icon or "key"

                local TabButton: TextButton
                local TabLabel
                local TabIcon

                local TabContainer

                Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
                do
                    TabButton = New("TextButton", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        Text = "",
                        Parent = Tabs,
                    })
                    local ButtonPadding = New("UIPadding", {
                        PaddingBottom = UDim.new(0, 11),
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        PaddingTop = UDim.new(0, 11),
                        Parent = TabButton,
                    })

                    TabLabel = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(30, 0),
                        Size = UDim2.new(1, -30, 1, 0),
                        Text = Name,
                        TextSize = 16,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Visible = true,
                        Parent = TabButton,
                    })

                    if Icon then
                        TabIcon = New("ImageLabel", {
                            Image = Icon.Url,
                            ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                            ImageRectOffset = Icon.ImageRectOffset,
                            ImageRectSize = Icon.ImageRectSize,
                            ImageTransparency = 0.5,
                            Size = UDim2.fromScale(1, 1),
                            SizeConstraint = Enum.SizeConstraint.RelativeYY,
                            Parent = TabButton,
                        })
                    end

                    table.insert(Library.TabButtons, {
                        Label = TabLabel,
                        Padding = ButtonPadding,
                        Icon = TabIcon,
                    })

                    TabContainer = New("ScrollingFrame", {
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2.fromScale(0, 0),
                        ScrollBarThickness = 0,
                        Size = UDim2.fromScale(1, 1),
                        Visible = false,
                        Parent = Container,
                    })
                    New("UIListLayout", {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 8),
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Parent = TabContainer,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 1),
                        PaddingRight = UDim.new(0, 1),
                        Parent = TabContainer,
                    })
                end

                local Tab = {
                    Elements = {},
                    IsKeyTab = true,
                }

                function Tab:AddKeyBox(Callback)
                    assert(typeof(Callback) == "function", "Callback must be a function")

                    local Holder = New("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.75, 0, 0, 21),
                        Parent = TabContainer,
                    })

                    local Box = New("TextBox", {
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        PlaceholderText = "Key",
                        Size = UDim2.new(1, -71, 1, 0),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = Holder,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8),
                        Parent = Box,
                    })

                    local Button = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundColor3 = "MainColor",
                        BorderColor3 = "OutlineColor",
                        BorderSizePixel = 1,
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.new(0, 63, 1, 0),
                        Text = "Execute",
                        TextSize = 14,
                        Parent = Holder,
                    })

                    Button.InputBegan:Connect(function(Input)
                        if not IsClickInput(Input) then
                            return
                        end

                        if not Library:MouseIsOverFrame(Button, Input.Position) then
                            return
                        end

                        Callback(Box.Text)
                    end)
                end

                function Tab:RefreshSides() end
                function Tab:Resize() end

                function Tab:Hover(Hovering)
                    if Library.ActiveTab == Tab then
                        return
                    end

                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = Hovering and 0.25 or 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = Hovering and 0.25 or 0.5,
                        }):Play()
                    end
                end

                function Tab:Show()
                    if Library.ActiveTab then
                        Library.ActiveTab:Hide()
                    end

                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 0,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0,
                        }):Play()
                    end
                    TabContainer.Visible = true

                    if Description then
                        Window:ShowTabInfo(Name, Description)
                    end

                    Tab:RefreshSides()

                    Library.ActiveTab = Tab

                    if Library.Searching then
                        Library:UpdateSearch(Library.SearchText)
                    end
                end

                function Tab:Hide()
                    TweenService:Create(TabButton, Library.TabTweenInfo, {
                        BackgroundTransparency = 1,
                    }):Play()
                    TweenService:Create(TabLabel, Library.TabTweenInfo, {
                        TextTransparency = 0.5,
                    }):Play()
                    if TabIcon then
                        TweenService:Create(TabIcon, Library.TabTweenInfo, {
                            ImageTransparency = 0.5,
                        }):Play()
                    end
                    TabContainer.Visible = false

                    Window:HideTabInfo()

                    Library.ActiveTab = nil
                end

                if not Library.ActiveTab then
                    Tab:Show()
                end

                TabButton.MouseEnter:Connect(function()
                    Tab:Hover(true)
                end)
                TabButton.MouseLeave:Connect(function()
                    Tab:Hover(false)
                end)
                TabButton.MouseButton1Click:Connect(Tab.Show)

                Tab.Container = TabContainer
                setmetatable(Tab, BaseGroupbox)

                Library.Tabs[Name] = Tab
                return Tab
            end

            function Library:Toggle(Value)
                if typeof(Value) == "boolean" then
                    Library.Toggled = Value
                else
                    Library.Toggled = not Library.Toggled
                end

                MainFrame.Visible = Library.Toggled
                ModalElement.Modal = Library.Toggled

                if Library.Toggled and not Library.IsMobile then
                    local OldMouseIconEnabled = UserInputService.MouseIconEnabled
                    ConnectionManager:Connect("ForceMouseIconEnabled", RunService.RenderStepped(function()
                        if Library.Toggled and ScreenGui and ScreenGui.Parent then
                            UserInputService.MouseIconEnabled = true
                        else
                            UserInputService.MouseIconEnabled = OldMouseIconEnabled
                            ConnectionManager:Disconnect("ForceMouseIconEnabled")
                        end
                    end))
                elseif not Library.Toggled then
                    TooltipLabel.Visible = false

                    for _, Option in Library.Options do
                        if Option.Type == "ColorPicker" then
                            Option.ColorMenu:Close()
                            Option.ContextMenu:Close()
                        elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                            Option.Menu:Close()
                        end
                    end
                end
            end

            if Library.IsMobile then
                local ToggleButton = Library:AddDraggableButton("Toggle", function()
                    Library:Toggle()
                end, true)

                local LockButton = Library:AddDraggableButton("Lock", function(self)
                    Library.CantDragForced = not Library.CantDragForced
                    self:SetText(Library.CantDragForced and "Unlock" or "Lock")
                end, true)

                if WindowInfo.MobileButtonsSide == "Right" then
                    ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)
                    ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)

                    LockButton.Button.Position = UDim2.new(1, -6, 0, 46)
                    LockButton.Button.AnchorPoint = Vector2.new(1, 0)
                else
                    LockButton.Button.Position = UDim2.fromOffset(6, 46)
                end
            end

            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                Library:UpdateSearch(SearchBox.Text)
            end)

            Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
                if Library.Unloaded then
                    return
                end

                if UserInputService:GetFocusedTextBox() then
                    return
                end

                if (typeof(Library.ToggleKeybind) == "table"  and Library.ToggleKeybind.Type == "KeyPicker"
                    and Input.KeyCode.Name == Library.ToggleKeybind.Value
                ) or Input.KeyCode == Library.ToggleKeybind then
                    Library.Toggle()
                end
            end))

            Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
                Library.IsRobloxFocused = true
            end))
            Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
                Library.IsRobloxFocused = false
            end))

            return Window
        end

        local function OnPlayerChange()
            if Library.Unloaded then
                return
            end

            for _,Dropdown in Options do
                if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
                    Dropdown:SetValues(GetPlayers())
                end
            end
        end

        Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
        Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

        return Library
    end)(),

    GetThemeManager = function()
        local ThemeManager = {}
        do
            local ThemeFields = {"FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor"}
            ThemeManager.Folder = "NikoletoScripts/KAT.lol"

            ThemeManager.Library = nil
            ThemeManager.AppliedToTab = false
            ThemeManager.BuiltInThemes = {
                ["Default"] = {
                    1,
                    { FontColor = "f0f5ff", MainColor = "11161e", AccentColor = "00bfff", BackgroundColor = "090c11", OutlineColor = "2f3d52" },
                },
                ["Neverlose"] = {
                    19,
                    { FontColor = "f0f5ff", MainColor = "121923", AccentColor = "00c6ff", BackgroundColor = "0a0f15", OutlineColor = "324154" },
                },
                ["BBot"] = {
                    2,
                    { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" },
                },
                ["Fatality"] = {
                    3,
                    { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" },
                },
                ["Jester"] = {
                    4,
                    { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" },
                },
                ["Mint"] = {
                    5,
                    { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" },
                },
                ["Tokyo Night"] = {
                    6,
                    { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" },
                },
                ["Ubuntu"] = {
                    7,
                    { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" },
                },
                ["Quartz"] = {
                    8,
                    { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" },
                },
                ["Nord"] = {
                    9,
                    { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" },
                },
                ["Dracula"] = {
                    10,
                    { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" },
                },
                ["Monokai"] = {
                    11,
                    { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e" },
                },
                ["Gruvbox"] = {
                    12,
                    { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945" },
                },
                ["Solarized"] = {
                    13,
                    { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75" },
                },
                ["Catppuccin"] = {
                    14,
                    { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268" },
                },
                ["One Dark"] = {
                    15,
                    { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370" },
                },
                ["Cyberpunk"] = {
                    16,
                    { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e" },
                },
                ["Oceanic Next"] = {
                    17,
                    { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46" },
                },
                ["Material"] = {
                    18,
                    { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242" },
                }
            }

            function ThemeManager:SetLibrary(library)
                self.Library = library
            end

            function ThemeManager:GetPaths()
                local Paths = {}

                local Parts = self.Folder:split("/")
                for Index = 1, #Parts do
                    Paths[#Paths + 1] = table.concat(Parts, "/", 1, Index)
                end

                Paths[#Paths + 1] = self.Folder .. "/Themes"

                return Paths
            end

            function ThemeManager:BuildFolderTree()
                local Paths = self:GetPaths()

                for i = 1, #Paths do
                    local str = Paths[i]
                    if FileManager:IsFolder(str) then
                        continue
                    end
                    FileManager:CreateFolder(str)
                end
            end

            function ThemeManager:CheckFolderTree()
                if FileManager:IsFolder(self.Folder) then
                    return
                end
                self:BuildFolderTree()

                task.wait(0.1)
            end

            function ThemeManager:ApplyTheme(theme)
                local customThemeData = self:GetCustomTheme(theme)
                local Data = customThemeData or self.BuiltInThemes[theme]

                if not Data then
                    return
                end

                local scheme = Data[2]
                for Index, val in pairs(customThemeData or scheme) do
                    if Index == "VideoLink" then
                        continue
                    elseif Index == "FontFace" then
                        self.Library:SetFont(Enum.Font[val])

                        if self.Library.Options[Index] then
                            self.Library.Options[Index]:SetValue(val)
                        end
                    else
                        self.Library.Scheme[Index] = Color3.fromHex(val)

                        if self.Library.Options[Index] then
                            self.Library.Options[Index]:SetValueRGB(Color3.fromHex(val))
                        end
                    end
                end

                self:ThemeUpdate()
            end

            function ThemeManager:ThemeUpdate()
                for i,Field in ThemeFields do
                    if self.Library.Options and self.Library.Options[Field] then
                        self.Library.Scheme[Field] = self.Library.Options[Field].Value
                    end
                end

                self.Library:UpdateColorsUsingRegistry()
            end

            function ThemeManager:GetCustomTheme(File)
                local Path = self.Folder .. "/Themes/" .. File .. ".json"
                return FileManager:Exists(Path) and FileManager:ReadJSON(Path) or nil
            end

            function ThemeManager:LoadDefault()
                local theme = "Default"
                local content = FileManager:Read(self.Folder .. "/Themes/default.txt")

                local isDefault = true
                if content then
                    if self.BuiltInThemes[content] then
                        theme = content
                    elseif self:GetCustomTheme(content) then
                        theme = content
                        isDefault = false
                    end
                elseif self.BuiltInThemes[self.DefaultTheme] then
                    theme = self.DefaultTheme
                end

                if isDefault then
                    self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
                else
                    self:ApplyTheme(theme)
                end
            end

            function ThemeManager:SaveDefault(theme)
                FileManager:Write(self.Folder .. "/Themes/default.txt", theme)
            end

            function ThemeManager:SetDefaultTheme(theme)
                assert(self.Library, "Must set ThemeManager.Library first!")
                assert(not self.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")

                local FinalTheme = {}
                local LibraryScheme = {}
                for _,Field in ThemeFields do
                    if typeof(theme[Field]) == "Color3" then
                        FinalTheme[Field] = "#" .. theme[Field]:ToHex()
                        LibraryScheme[Field] = theme[Field]

                    elseif typeof(theme[Field]) == "string" then
                        FinalTheme[Field] = if theme[Field]:sub(1, 1) == "#" then theme[Field] else ("#" .. theme[Field])
                        LibraryScheme[Field] = Color3.fromHex(theme[Field])

                    else
                        FinalTheme[Field] = ThemeManager.BuiltInThemes["Default"][2][Field]
                        LibraryScheme[Field] = Color3.fromHex(ThemeManager.BuiltInThemes["Default"][2][Field])
                    end
                end

                if typeof(theme["FontFace"]) == "EnumItem" then
                    FinalTheme["FontFace"] = theme["FontFace"].Name
                    LibraryScheme["Font"] = Font.fromEnum(theme["FontFace"])

                elseif typeof(theme["FontFace"]) == "string" then
                    FinalTheme["FontFace"] = theme["FontFace"]
                    LibraryScheme["Font"] = Font.fromEnum(Enum.Font[theme["FontFace"]])

                else
                    FinalTheme["FontFace"] = "Code"
                    LibraryScheme["Font"] = Font.fromEnum(Enum.Font.Code)
                end

                for _,Field in { "RedColor", "DarkColor", "WhiteColor" } do
                    LibraryScheme[Field] = self.Library.Scheme[Field]
                end

                self.Library.Scheme = LibraryScheme
                self.BuiltInThemes["Default"] = { 1, FinalTheme }

                self.Library:UpdateColorsUsingRegistry()
            end

            function ThemeManager:SaveCustomTheme(File)
                if File:gsub(" ", "") == "" then
                    self.Library:Notify("Invalid File Name for theme (empty)", 3)
                    return
                end

                local theme = {}
                for _,Field in ThemeFields do
                    theme[Field] = self.Library.Options[Field].Value:ToHex()
                end
                theme["FontFace"] = self.Library.Options["FontFace"].Value

                FileManager:WriteJSON(self.Folder .. "/Themes/" .. File .. ".json", theme)
            end

            function ThemeManager:Delete(Name)
                if not Name then
                    return false, "no config File is selected"
                end

                local File = self.Folder .. "/Themes/" .. Name .. ".json"
                if not FileManager:Exist(File) then
                    return false, "invalid File"
                end

                FileManager:DeleteFile(File)
                return true
            end

            function ThemeManager:ReloadCustomThemes()
                local List = FileManager:List(self.Folder .. "/Themes")

                local Out = {}
                for i = 1, #List do
                    local File = List[i]
                    if File:sub(-5) == ".json" then
                        local Start = File:find(".json", 1, true)
                        local Position = Start

                        local Char = File:sub(Position, Position)
                        while Char ~= "/" and Char ~= "\\" and Char ~= "" do
                            Position += 1
                            Char = File:sub(Position, Position)
                        end

                        if Char == "/" or Char == "\\" then
                            table.insert(Out, File:sub(Position + 1, Start - 1))
                        end
                    end
                end

                return Out
            end

            function ThemeManager:CreateThemeManager(Groupbox)
                Groupbox:AddLabel("Background color"):AddColorPicker("BackgroundColor", { Default = self.Library.Scheme.BackgroundColor })
                Groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = self.Library.Scheme.MainColor })
                Groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.Scheme.AccentColor })
                Groupbox:AddLabel("Outline color"):AddColorPicker("OutlineColor", { Default = self.Library.Scheme.OutlineColor })
                Groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = self.Library.Scheme.FontColor })
                Groupbox:AddDropdown("FontFace", {
                    Text = "Font Face",
                    Default = "Code",
                    Values = {"BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans"},
                })

                local ThemesArray = {}
                for Name, Theme in pairs(self.BuiltInThemes) do
                    table.insert(ThemesArray, Name)
                end

                table.sort(ThemesArray, function(A, B)
                    return self.BuiltInThemes[A][1] < self.BuiltInThemes[B][1]
                end)

                Groupbox:AddDivider()

                Groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme List", Values = ThemesArray, Default = 1 })
                Groupbox:AddButton("Set as default", function()
                    self:SaveDefault(self.Library.Options.ThemeManager_ThemeList.Value)
                    self.Library:Notify(
                        string.format("Set default theme to %q", self.Library.Options.ThemeManager_ThemeList.Value)
                    )
                end)

                self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
                    self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
                end)

                Groupbox:AddDivider()

                Groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme Name" })
                Groupbox:AddButton("Create theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeName.Value

                    if Name:gsub(" ", "") == "" then
                        self.Library:Notify("Invalid theme Name (empty)", 2)
                        return
                    end

                    self:SaveCustomTheme(Name)

                    self.Library:Notify(string.format("Created theme %q", Name))
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)

                Groupbox:AddDivider()

                Groupbox:AddDropdown(
                    "ThemeManager_CustomThemeList",
                    { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 }
                )
                Groupbox:AddButton("Load theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeList.Value

                    self:ApplyTheme(Name)
                    self.Library:Notify(string.format("Loaded theme %q", Name))
                end)
                Groupbox:AddButton("Overwrite theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeList.Value

                    self:SaveCustomTheme(Name)
                    self.Library:Notify(string.format("Overwrote config %q", Name))
                end)
                Groupbox:AddButton("Delete theme", function()
                    local Name = self.Library.Options.ThemeManager_CustomThemeList.Value

                    local Success, Error = self:Delete(Name)
                    if not Success then
                        self.Library:Notify("Failed to delete theme: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Deleted theme %q", Name))
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)
                Groupbox:AddButton("Refresh List", function()
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)
                Groupbox:AddButton("Set as default", function()
                    if
                        self.Library.Options.ThemeManager_CustomThemeList.Value ~= nil
                        and self.Library.Options.ThemeManager_CustomThemeList.Value ~= ""
                    then
                        self:SaveDefault(self.Library.Options.ThemeManager_CustomThemeList.Value)
                        self.Library:Notify(
                            string.format("Set default theme to %q", self.Library.Options.ThemeManager_CustomThemeList.Value)
                        )
                    end
                end)
                Groupbox:AddButton("Reset default", function()
                    FileManager:DeleteFile(self.Folder .. "/Themes/default.txt")
                    self.Library:Notify("Set default theme to nothing")
                    self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                end)

                self:LoadDefault()
                self.AppliedToTab = true

                local function UpdateTheme()
                    self:ThemeUpdate()
                end

                self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
                self.Library.Options.MainColor:OnChanged(UpdateTheme)
                self.Library.Options.AccentColor:OnChanged(UpdateTheme)
                self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
                self.Library.Options.FontColor:OnChanged(UpdateTheme)
                self.Library.Options.FontFace:OnChanged(function(Value)
                    self.Library:SetFont(Enum.Font[Value])
                    self.Library:UpdateColorsUsingRegistry()
                end)
            end

            function ThemeManager:CreateGroupBox(tab)
                assert(self.Library, "Must set ThemeManager.Library first!")
                return tab:AddLeftGroupbox("Themes", "paintbrush")
            end

            function ThemeManager:ApplyToTab(tab)
                assert(self.Library, "Must set ThemeManager.Library first!")
                local Groupbox = self:CreateGroupBox(tab)
                self:CreateThemeManager(Groupbox)
            end

            function ThemeManager:ApplyToGroupbox(Groupbox)
                assert(self.Library, "Must set ThemeManager.Library first!")
                self:CreateThemeManager(Groupbox)
            end

            ThemeManager:BuildFolderTree()
        end

        return ThemeManager
    end,

    GetSaveManager = function()
        local SaveManager = {} do
            SaveManager.Folder = "NikoletoScripts/KAT.lol"
            SaveManager.Ignore = {}
            SaveManager.Library = nil
            SaveManager.Parser = {
                Toggle = {
                    Save = function(Index, Object)
                        return { Type = "Toggle", Index = Index, value = Object.Value }
                    end,
                    Load = function(Index, Data)
                        local Object = SaveManager.Library.Toggles[Index]
                        if Object and Object.Value ~= Data.value then
                            Object:SetValue(Data.value)
                        end
                    end,
                },
                Slider = {
                    Save = function(Index, Object)
                        return { Type = "Slider", Index = Index, value = tostring(Object.Value) }
                    end,
                    Load = function(Index, Data)
                        local Object = SaveManager.Library.Options[Index]
                        if Object and Object.Value ~= Data.value then
                            Object:SetValue(Data.value)
                        end
                    end,
                },
                Dropdown = {
                    Save = function(Index, Object)
                        return { Type = "Dropdown", Index = Index, value = Object.Value, multi = Object.Multi }
                    end,
                    Load = function(Index, Data)
                        local object = SaveManager.Library.Options[Index]
                        if object and object.Value ~= Data.value then
                            object:SetValue(Data.value)
                        end
                    end,
                },
                ColorPicker = {
                    Save = function(Index, Object)
                        return { Type = "ColorPicker", Index = Index, value = Object.Value:ToHex(), transparency = Object.Transparency }
                    end,
                    Load = function(Index, Data)
                        if SaveManager.Library.Options[Index] then
                            SaveManager.Library.Options[Index]:SetValueRGB(Color3.fromHex(Data.value), Data.transparency)
                        end
                    end,
                },
                KeyPicker = {
                    Save = function(Index, Object)
                        return { Type = "KeyPicker", Index = Index, mode = Object.Mode, key = Object.Value, modifiers = Object.Modifiers }
                    end,
                    Load = function(Index, Data)
                        if SaveManager.Library.Options[Index] then
                            SaveManager.Library.Options[Index]:SetValue({ Data.key, Data.mode, Data.modifiers })
                        end
                    end,
                },
                Input = {
                    Save = function(Index, Object)
                        return { Type = "Input", Index = Index, text = Object.Value }
                    end,
                    Load = function(Index, Data)
                        local Object = SaveManager.Library.Options[Index]
                        if Object and Object.Value ~= Data.text and type(Data.text) == "string" then
                            SaveManager.Library.Options[Index]:SetValue(Data)
                        end
                    end,
                },
            }

            function SaveManager:SetLibrary(library)
                self.Library = library
            end

            function SaveManager:IgnoreThemeSettings()
                self:SetIgnoreIndexes({
                    "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "FontFace",
                    "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
                })
            end

            function SaveManager:GetPaths()
                local Paths = {}

                local Parts = self.Folder:split("/")
                for Index = 1, #Parts do
                    local Path = table.concat(Parts, "/", 1, Index)
                    if not table.find(Paths, Path) then
                        Paths[#Paths + 1] = Path
                    end
                end

                Paths[#Paths + 1] = self.Folder .. "/Themes"
                Paths[#Paths + 1] = self.Folder .. "/Settings"
                return Paths
            end

            function SaveManager:BuildFolderTree()
                local Paths = self:GetPaths()
                for Index = 1, #Paths do
                    local String = Paths[Index]
                    if FileManager:IsFolder(String) then
                        continue
                    end
                    FileManager:CreateFolder(String)
                end
            end

            function SaveManager:CheckFolderTree()
                if FileManager:IsFolder(self.Folder) then
                    return
                end
                SaveManager:BuildFolderTree()
                task.wait(0.1)
            end

            function SaveManager:SetIgnoreIndexes(List)
                for _,Key in next, List do
                    self.Ignore[Key] = true
                end
            end

            function SaveManager:Save(Name)
                if not Name then
                    return false, "no config File is selected"
                end

                SaveManager:CheckFolderTree()
                local Objects = {}

                for Index, Toggle in pairs(self.Library.Toggles) do
                    if not Toggle.Type or not self.Parser[Toggle.Type] or self.Ignore[Index] then
                        continue
                    end
                    table.insert(Objects, self.Parser[Toggle.Type].Save(Index, Toggle))
                end

                for Index, Option in pairs(self.Library.Options) do
                    if not Option.Type or not self.Parser[Option.Type] or self.Ignore[Index] then
                        continue
                    end
                    table.insert(Objects, self.Parser[Option.Type].Save(Index, Option))
                end

                FileManager:WriteJSON(self.Folder .. "/Settings/" .. Name .. ".json", {Objects = Objects})
                return true
            end

            function SaveManager:Load(Name)
                if not Name then
                    return false, "no config File is selected"
                end
                SaveManager:CheckFolderTree()

                local Decoded = FileManager:ReadJSON(self.Folder .. "/Settings/" .. Name .. ".json")
                if not Decoded then
                    return false
                end

                for _,Option in pairs(Decoded.Objects) do
                    if not Option.Type or not self.Parser[Option.Type] or self.Ignore[Option.Index] then
                        continue
                    end
                    task.spawn(self.Parser[Option.Type].Load, Option.Index, Option)
                end

                return true
            end

            function SaveManager:Delete(Name)
                if not Name then
                    return false, "no config File is selected"
                end

                FileManager:DeleteFile(self.Folder .. "/Settings/" .. Name .. ".json")
                return true
            end

            function SaveManager:RefreshConfigList()
                local Success, Data = pcall(function()
                    SaveManager:CheckFolderTree()

                    local List = FileManager:List(self.Folder .. "/Settings")
                    local Out = {}

                    if type(List) ~= "table" then
                        List = {}
                    end

                    for Index = 1, #List do
                        local File = List[Index]
                        if File:sub(-5) == ".json" then
                            local Start = File:find(".json", 1, true)
                            local Position = Start

                            local Char = File:sub(Position, Position)
                            while Char ~= "/" and Char ~= "\\" and Char ~= "" do
                                Position -= 1
                                Char = File:sub(Position, Position)
                            end

                            if Char == "/" or Char == "\\" then
                                table.insert(Out, File:sub(Position + 1, Start - 1))
                            end
                        end
                    end

                    return Out
                end)

                if not Success then
                    if self.Library then
                        self.Library:Notify("Failed to load config List: " .. tostring(Data))
                    else
                        warn("Failed to load config List: " .. tostring(Data))
                    end

                    return {}
                end

                return Data
            end

            function SaveManager:GetAutoloadConfig()
                SaveManager:CheckFolderTree()

                local AutoLoadPath = self.Folder .. "/Settings/autoload.txt"
                if FileManager:IsFile(AutoLoadPath) then
                    return FileManager:Read(AutoLoadPath) or "None"
                end

                return "None"
            end

            function SaveManager:LoadAutoloadConfig()
                SaveManager:CheckFolderTree()
                local AutoLoadPath = self.Folder .. "/Settings/autoload.txt"
                if FileManager:IsFile(AutoLoadPath) then
                    local Name = FileManager:Read(AutoLoadPath)

                    local Success, Error = self:Load(Name)
                    if not Success then
                        self.Library:Notify("Failed to load autoload config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Auto loaded config %q", Name))
                end
            end

            function SaveManager:SaveAutoloadConfig(Name)
                SaveManager:CheckFolderTree()
                FileManager:Write(self.Folder .. "/Settings/autoload.txt", Name)
                return true, ""
            end

            function SaveManager:DeleteAutoLoadConfig()
                SaveManager:CheckFolderTree()
                FileManager:DeleteFile(self.Folder .. "/Settings/autoload.txt")
                return true, ""
            end

            function SaveManager:BuildConfigSection(tab)
                assert(self.Library, "Must set SaveManager.Library")

                local section = tab:AddRightGroupbox("Configuration", "folder-cog")

                section:AddInput("SaveManager_ConfigName",    { Text = "Config Name" })
                section:AddButton("Create config", function()
                    local Name = self.Library.Options.SaveManager_ConfigName.Value

                    if Name:gsub(" ", "") == "" then
                        self.Library:Notify("Invalid config Name (empty)", 2)
                        return
                    end

                    local Success, Error = self:Save(Name)
                    if not Success then
                        self.Library:Notify("Failed to create config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Created config %q", Name))
                    self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    self.Library.Options.SaveManager_ConfigList:SetValue(nil)
                end)

                section:AddDivider()

                section:AddDropdown("SaveManager_ConfigList", { Text = "Config List", Values = self:RefreshConfigList(), AllowNull = true })
                section:AddButton("Load config", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:Load(Name)
                    if not Success then
                        self.Library:Notify("Failed to load config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Loaded config %q", Name))
                end)
                section:AddButton("Overwrite config", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:Save(Name)
                    if not Success then
                        self.Library:Notify("Failed to overwrite config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Overwrote config %q", Name))
                end)

                section:AddButton("Delete config", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:Delete(Name)
                    if not Success then
                        self.Library:Notify("Failed to delete config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Deleted config %q", Name))
                    self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    self.Library.Options.SaveManager_ConfigList:SetValue(nil)
                end)

                section:AddButton("Refresh List", function()
                    self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                    self.Library.Options.SaveManager_ConfigList:SetValue(nil)
                end)

                section:AddButton("Set as autoload", function()
                    local Name = self.Library.Options.SaveManager_ConfigList.Value

                    local Success, Error = self:SaveAutoloadConfig(Name)
                    if not Success then
                        self.Library:Notify("Failed to set autoload config: " .. Error)
                        return
                    end

                    self.Library:Notify(string.format("Set %q to auto load", Name))
                    self.AutoloadConfigLabel:SetText("Current autoload config: " .. Name)
                end)
                section:AddButton("Reset autoload", function()
                    local Success, Error = self:DeleteAutoLoadConfig()
                    if not Success then
                        self.Library:Notify("Failed to set autoload config: " .. Error)
                        return
                    end

                    self.Library:Notify("Set autoload to None")
                    self.AutoloadConfigLabel:SetText("Current autoload config: None")
                end)

                self.AutoloadConfigLabel = section:AddLabel("Current autoload config: " .. self:GetAutoloadConfig(), true)
                self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
            end

            SaveManager:BuildFolderTree()
        end

        return SaveManager
    end,

 	["ExecutorFunctions"] = {
		["isrenderobj"] = IsFunction(isrenderobj) or function()
            return true
        end,

        ["newcclosure"] = IsFunction(newcclosure) or function(Closure)
			return Closure
		end,

        ["hookmetamethod"] = IsFunction(hookmetamethod),
        ["getnamecallmethod"] = IsFunction(getnamecallmethod),

        ["getgc"] = IsFunction(getgc),

        ["getupvalues"] = IsFunction(getupvalues) or IsFunction(debug.getupvalues),
        ["getupvalue"] = IsFunction(getupvalue) or IsFunction(debug.getupvalue),

        ["getsenv"] = IsFunction(getsenv),
        ["getconnections"] = IsFunction(getconnections)
	}
}--(...)
if type(NikoletoScripts) ~= "table" then
    error("[KAT.lol/src/Main.luau | ERROR]: Argument must be a table.", 2)
end

local Running = true

local ConnectionManager = NikoletoScripts.ConnectionManager
local ServiceManager = NikoletoScripts.ServiceManager
local DrawingManager = NikoletoScripts.DrawingManager
local ThreadManager = NikoletoScripts.ThreadManager
local FileManager = NikoletoScripts.FileManager
local RunService = NikoletoScripts.RunService
local Utils = NikoletoScripts.Utils
local UI = NikoletoScripts.UI
local Window = Utils.CreateWindow(UI)

local GenerateGUID = Utils.GenerateGUID
local SetEnabled = Utils.SetEnabled
local Create = Utils.Create
local GetDistanceSquared = Utils.GetDistanceSquared

local ExecutorName = NikoletoScripts.ExecutorName()
local ExecutorFunctions = NikoletoScripts.ExecutorFunctions

local isrenderobj = ExecutorFunctions.isrenderobj
local newcclosure = ExecutorFunctions.newcclosure

local hookmetamethod = (not ExecutorName:lower():find("solara")) and ExecutorFunctions.hookmetamethod
local getnamecallmethod = ExecutorFunctions.getnamecallmethod
local getgc = ExecutorFunctions.getgc

local GetGunState = ExecutorFunctions.getupvalues
if not GetGunState then
	local getupvalue = ExecutorFunctions.getupvalue
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

local getsenv = ExecutorFunctions.getsenv
local getconnections = ExecutorFunctions.getconnections

local MarketplaceService = ServiceManager.MarketplaceService
local ReplicatedStorage = ServiceManager.ReplicatedStorage
local UserInputService = ServiceManager.UserInputService
local HttpService = ServiceManager.HttpService
local Lighting = ServiceManager.Lighting
local Players = ServiceManager.Players
local CoreGui = ServiceManager.CoreGui
local Teams = ServiceManager.Teams

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

	Target = nil,
	AimPart = "Root",

	StickyAim = true,

	FOVCircle = {
		Enabled = false,
		Filled = false,
		Transparency = 1,
		Thickness = 1,
		Radius = 50,
		Color = Color3.fromRGB(255, 255, 255),
		Position = "Mouse"
	},

	ShakeOffset = 0,

	ForceFieldCheck = false,
	WallCheck = false,
	TeamCheck = false,
	DeadCheck = false,

	StopOnCheck = true,

	SmoothnessOffset = 0
}

local SilentAimbot = {
	Scale = false,
	Enabled = false,

	AimPart = "Root",

	FOVCircle = {
		Enabled = false,
		Filled = false,
		Transparency = 1,
		Thickness = 1,
		Radius = 50,
		Color = Color3.fromRGB(255, 255, 255),
		Position = "Mouse"
	},

	ForceFieldCheck = true,
	WallCheck = true,
	TeamCheck = false,
	DeadCheck= true
}

local TriggerBot = {
	Scale = false,
	Enabled = false,

	Target = nil,

	ForceFieldCheck = true,
	TeamCheck = false,
	DeadCheck = true,
	WallCheck = true,
	RevolverOnly = false,

	TriggerDelay = 0.1,
	MaxDistance = 2500,
}

local AimbotFOVCircles = {
	Target = DrawingManager("Circle", {
		Color = Aimbot.FOVCircle.Color,
		Filled = Aimbot.FOVCircle.Filled,
		Thickness = Aimbot.FOVCircle.Thickness,
		Radius = Aimbot.FOVCircle.Radius,
		Visible = false
	}),
	Silent = DrawingManager("Circle", {
		Color = SilentAimbot.FOVCircle.Color,
		Filled = SilentAimbot.FOVCircle.Filled,
		Thickness = SilentAimbot.FOVCircle.Thickness,
		Radius = SilentAimbot.FOVCircle.Radius,
		Visible = false
	})
}

local RageBot = {
	TargetCache = nil,
	TargetPart = nil,

	LastAttackTime = 0,
	IsAttacking = false,

	Scale = false,
	Weapon = "Knife",
	AimPart = "Head",
	MultiTarget = true,

	ForceFieldCheck = true,
	WallCheck = true,
	TeamCheck = false,

	CustomTargetList = {},
	MaxDistance = 2500,
}

local RageBotTargets = {}
local RageBotArguments = {zSign = 1}

local HitConfiguration = {
	Scale = false,

	Marker = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		Lifetime = 1,
		Scale = 1,
		Style = "Broken X",
		CenterDot = false,
		FadeIn = false,
		FadeOut = false,
	},

	Log = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		UseColor = false,
		Duration = 1,
	},

	Sound = {
		Enabled = false,
		Selected = "Osu",
		Volume = 5
	},

	SavedHealth = {},
	SavedPositions = {},
	Connections = {},
	PendingHits = {}
}
local HitMarkerDirections = {
	Vector2.new(-1, -1), Vector2.new( 1, -1),
	Vector2.new(-1,  1), Vector2.new( 1,  1)
}

local HitSounds = {
	Sounds = {
		Osu = "7172607676",
		Pop = "102822111971881",
		MLG = "109817519733426",
		Metal = "8917041751",
		Neverlose = "18391691942",
		["Jet Set Radio"] = "97113622160405",
		["TF2 Critical"] = "8255306220",
		["TF2 Alternative"] = "2868331684",
		["TF2 Frying Pan"] = "18922477538",
		["Bad Business Headshot"] = "9368845024"
	},
	Folder = Create("Folder", CoreGui)
}

local AntiAim = {
	Scale = false,
	Enabled = false,
	Mode = "None",
	SpinBot = 1
}

local LocalHighlight = {
	Enabled = false,
	Color = Color3.fromRGB(255, 255, 255),
	Transparency = 0
}

local ChinaHat = {
    ChinaHatTrail = nil,
    Color = Color3.fromRGB(255, 0, 0),
    Scale = Vector3.new(3, 0.6, 3),
    ChinaHatTrailSize = Vector3.new(3, 0.7, 3),
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
	FillColor = Color3.fromRGB(255, 255, 255),
	OutlineColor = Color3.fromRGB(255, 255, 255),
	FillTransparency = 0.5,
	OutlineTransparency = 0
}

local HeadTagESP, TagBuffer = {
	Enabled = false,
	Color = Color3.fromRGB(255, 255, 255),
	Transparency = 1,
	Position = "Top"
}, table.create(7)

local TracerESP = {
	Enabled = false,
	Color = Color3.fromRGB(255, 255, 255),
	Type = "Locked",
	Part = "Root",
	Transparency = 1
}

local BoxESP, BoxPointScreen, BoxPointOnScreen, Box3DOffsets, Box3DEdges = {
	Box2D = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		Filled = false,
		Transparency = 1
	},
	Box3D = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = 1
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
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 1,
	Transparency = 1
}

local World = {
	OldExposureCompensation = Lighting.ExposureCompensation,
	OldAmbient = Lighting.Ambient,
	OldOutdoorAmbient = Lighting.OutdoorAmbient,
	OldCameraFOV = nil
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

	Cache.Root = Cache.HumanoidRootPart

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
		HeadTagDropdown = Options.HeadTagOptions
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
					AimPart = math.random(1, 2) == 1 and Cache.Root or Cache.Head

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

local AimbotTab = Tabs.AimbotTab
local SilentAimbotTab = Tabs.SilentAimbotTab

local TriggerBotMain = Tab.TriggerBotMain
local TriggerBotChecks = Tabs.TriggerBotChecks

local AntiAimTab = Tabs.AntiAimTab
local MovementTab = Tabs.MovementTab

local LocalCharacterTab = Tabs.LocalCharacterTab

local VisualsTab = Tabs.VisualsTab
local LightingTab = Tabs.LightingTab

local WeaponsTab = Tabs.WeaponsTab
local WeaponsViewTab = Tabs.WeaponsViewTab

local RageBotTab = Tabs.RageBotTab
local HitConfigurationTab = Tabs.HitConfigurationTab

local SettingsTab = Tabs.SettingsTab

AimbotTab:AddToggle("AimbotMasterSwitch", {
	Text = "Toggle Aimbot",
	Default = Aimbot.Toggled,
	Callback = function(Value)
		Aimbot.Toggled = Value
		if not Value then
			StopAimbot()
			Toggles.AimbotFOVCircle:SetValue(false)
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
AimbotDependencyBox:SetupDependencies({{Toggles.AimbotMasterSwitch, true}})

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
		AimbotFOVCircles.Target.Transparency = 1 - Options.AimbotFOVCircleColor.Transparency
	end,
})

local AimbotFOVDependencyBox = AimbotTab:AddDependencyBox()
AimbotFOVDependencyBox:SetupDependencies({{Toggles.AimbotFOVCircle, true}})

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
				Toggles.SilentAimbotFOVCircle:SetValue(false)
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
	SilentAimbotDependencyBox:SetupDependencies({{Toggles.SilentAimbotMasterSwitch, true}})

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
			AimbotFOVCircles.Silent.Transparency = 1 - Options.SilentAimbotFOVCircleColor.Transparency
		end
	})

	local SilentAimbotFOVCircleDependencyBox = SilentAimbotTab:AddDependencyBox()
	SilentAimbotFOVCircleDependencyBox:SetupDependencies({{Toggles.SilentAimbotFOVCircle, true}})

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
				for _,Toggle in next, RageBot.Weapon == "Knife" and {Toggles.ForceThrow, Toggles.RapidThrow} or {--[[Toggles.InfiniteAmmo]} do
					Toggle:SetValue(false)
					Toggle:SetDisabled(true)
				end
			else
				for _,Toggle in next, {--[[Toggles.InfiniteAmmo, ]]Toggles.ForceThrow, Toggles.RapidThrow} do
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
	RageBotDependencyBox:SetupDependencies({{Toggles.RageBot, true}})

	--[[RageBotDependencyBox:AddDropdown("RageBotWeapon", {
		Text = "RageBot Weapon",
		Values = {"Knife", "Revolver [BETA]"},
		Default = 1,
		Callback = function(Value)
			if Value == "Knife" then
				for Index, Toggle in next, {Toggles.ForceThrow, Toggles.RapidThrow} do
					Toggle:SetValue(false)
					Toggle:SetDisabled(true)
				end
				Toggles.InfiniteAmmo:SetDisabled(false)
			else
				Toggles.InfiniteAmmo:SetValue(false)
				Toggles.InfiniteAmmo:SetDisabled(true)
				Toggles.ForceThrow:SetDisabled(false)
				Toggles.RapidThrow:SetDisabled(false)
			end

			if Toggles.RageBotMultiTarget then
				if Value ~= "Knife" then
					Toggles.RageBotMultiTarget:SetValue(false)
					Toggles.RageBotMultiTarget:SetDisabled(true)
				else
					Toggles.RageBotMultiTarget:SetDisabled(false)
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
HitConfigurationDependencyBox:SetupDependencies({{Toggles.AimbotHitMasterSwitch, true}})
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
		Toggles.AimbotHitMarkerCenterDot:SetDisabled(Value == "Classic X" or Value == "Plus")
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
	TriggerBotDependencyBox:SetupDependencies({{Toggles.TriggerBot, true}})
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

		local Slider = Options.JumpMultiplierSlider
		ConnectionManager:Connect("JumpMultiplier", RunService.Heartbeat(function()
			if not LocalHumanoid then
				return
			end

			local JumpMultiplier = Slider.Value
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
		LocalHighlight.Transparency = Options.HighlightColor.Transparency
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
					Scale = ChinaHat.Scale
				})

                ChinaHat.ChinaHatTrail = CurrentHat
            end

            CurrentHat.CFrame = LocalHead.CFrame * ChinaHatCFrameOffset
            CurrentHat.Color = ChinaHat.Color
            CurrentHat.Size = ChinaHat.ChinaHatTrailSize
            CurrentHat.Velocity = Vector3.zero
        end))
    end
}):AddColorPicker("ChinaHatColor", {
	Default = ChinaHat.Color,
	Transparency = nil,
	Callback = function(Color)
		ChinaHat.Color = Color
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

			local LocalTransparencyModifier = Options.LocalTransparencyModificationSlider.Value
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
VisualsDependencyBox:SetupDependencies({{Toggles.ESPMasterSwitch, true}})
VisualsDependencyBox:AddToggle("ESPDynamicRefreshRate", {
	Text = "Dynamic Refresh Rate",
	Tooltip = "Updates ESP depending on your FPS",
	Default = ESPDynamicRefreshRate,
	Callback = function(Value)
		ESPDynamicRefreshRate = Value
		Options.ESPRefreshRate:SetDisabled(Value)
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
		ChamESP.FillTransparency = Options.ChamFillColor.Transparency

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
		ChamESP.OutlineTransparency = Options.ChamOutlineColor.Transparency

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
		HeadTagESP.Transparency = 1 - Options.HeadTagColor.Transparency

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
		TracerESP.Transparency = 1 - Options.TracerColor.Transparency

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
		BoxESP.Box2D.Transparency = 1 - Options.2DBoxColor.Transparency

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
		BoxESP.Box3D.Transparency = 1 - Options.3DBoxColor.Transparency

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
		SkeletonESP.Transparency = 1 - Options.SkeletonColor.Transparency

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
		Options.ExposureCompensationSlider:SetValue(World.OldExposureCompensation)
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
		Options.AmbientColor:SetValue(World.OldAmbient)
	end
})
LightingTab:AddLabel("Change Outdoor Ambient"):AddColorPicker("OutdoorAmbientColor", {
	Default = World.OldOutdoorAmbient,
	Transparency = nil,
	Callback = function(Color)
		Lighting.OutdoorAmbient = Color
	end
})
LightingTab:AddButton({
	Text = "Save Current Outdoor Ambient as Original",
	Func = function()
		World.OldOutdoorAmbient = Lighting.OutdoorAmbient
	end
})
LightingTab:AddButton({
	Text = "Restore Original Outdoor Ambient",
	Func = function()
		Lighting.OutdoorAmbient = World.OldOutdoorAmbient
		Options.OutdoorAmbientColor:SetValue(World.OldOutdoorAmbient)
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
			local Toggle = Camera and Toggles.FOVModification
			if not Toggle then
				return
			end

			if Toggle.Value then
				Camera.FieldOfView = Options.FOVAmountSlider.Value
			end
		end))
	end
})
local WeaponsViewDependencyBox = WeaponsViewTab:AddDependencyBox()
WeaponsViewDependencyBox:SetupDependencies({{Toggles.FOVModification, true}})
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
UI.ToggleKeybind = Options.MenuKeybind
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
		NikoletoScripts.LoadScript("Loader.lua", "Main.luau")
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

print("[KAT.lol/src/Main.luau | INFO]: Successfully loaded KAT.lol in", tick() - NikoletoScripts.Start .. "s")
if Errors > 0 then
	warn("[nikoletoscripts/KAT.lol]:", Errors, "Module Errors were found. Script will continue to function.")
end

ThreadManager:Start("DiscordNotifier", function()
	if not Toggles.DisableDiscordNotification.Value then
		UI:Notify({
			Title = "[[ KAT.lol ]]",
			Description = "Friendly reminder to join the Discord Server for updates! [discord.gg/DwRT2nH93D]\nYou can disable this notification in Settings.",
			Time = 25
		})
	end
end, 60)

print("end of init")
