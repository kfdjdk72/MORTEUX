--[=[
    
    ██╗  ██╗ ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗
    ██║  ██║██╔═══██╗██╔══██╗██║╚══███╔╝██╔═══██╗████╗  ██║
    ███████║██║   ██║██████╔╝██║  ███╔╝ ██║   ██║██╔██╗ ██║
    ██╔══██║██║   ██║██╔══██╗██║ ███╔╝  ██║   ██║██║╚██╗██║
    ██║  ██║╚██████╔╝██║  ██║██║███████╗╚██████╔╝██║ ╚████║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

                    H O R I Z O N   H U B
                       OPEN SOURCE PROJECT

    ────────────────────────────────────────────────────────

    ORIGINAL PROJECT : HORIZON HUB
    RELEASE TYPE     : OPEN SOURCE
    ATTRIBUTION      : PLEASE PRESERVE THE ORIGINAL CREDITS

    This script is released to the community by Horizon Hub.
    Built with dedication. Shared for the community.

    You are welcome to study, learn from, and modify this code
    in accordance with the terms of the applicable license.

    Please give credit to Horizon Hub when redistributing
    or publishing modified versions of this project.

    ────────────────────────────────────────────────────────

                    HORIZON HUB © 2026
                  BUILT DIFFERENT. BUILT TO LAST.

]=]

local WindUI = nil
local WindUIOk = pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not WindUIOk or not WindUI then warn("Syniox Hub: WindUI failed to load, check your internet connection."); return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local Red = Color3.fromHex("#FF4040")
local Orange = Color3.fromHex("#FF8C00")
local Green = Color3.fromHex("#10C550")
local Blue = Color3.fromHex("#3B9EFF")
local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Grey = Color3.fromHex("#A0A0A0")
local White = Color3.fromHex("#FFFFFF")

local notificationsEnabled = true
local showEffects = true
local effectSize = 3

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function notify(title, content, icon, duration)
    if not notificationsEnabled then return end
    WindUI:Notify({
        Title = title,
        Content = content,
        Icon = icon or "solar:bell-bold",
        Duration = duration or 3,
    })
end

pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" then return end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

local breaker = {
    active = false,
    mode = "FAST",
    power = 1,
    totalBones = 0,
    maxDamage = 0,
    dps = 0
}

local modeSettings = {
    ["FAST"] = { vel = 150, int = 0.3, cnt = 1 },
    ["POWER"] = { vel = 350, int = 1, cnt = 1 },
    ["COMBO"] = { vel = 200, int = 0.15, cnt = 5 }
}

local function createEffect(pos)
    if not showEffects then return end
    local p = Instance.new("Part")
    p.Size = Vector3.new(0.5, 0.5, 0.5)
    p.Position = pos
    p.Anchored = true
    p.CanCollide = false
    p.Material = Enum.Material.Neon
    p.Color = Color3.fromRGB(220, 38, 38)
    p.Transparency = 0.3
    p.Parent = workspace
    task.spawn(function()
        task.wait(0.5)
        pcall(function() p:Destroy() end)
    end)
    pcall(function()
        TweenService:Create(p, TweenInfo.new(0.5), { Size = Vector3.new(effectSize, effectSize, effectSize), Transparency = 1 }):Play()
    end)
end

local function performHit()
    local root = getRoot()
    if not root then return end
    local settings = modeSettings[breaker.mode]
    if not settings then return end
    local velocity = settings.vel * breaker.power
    local ray = Ray.new(root.Position, root.CFrame.LookVector * 20)
    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, { LocalPlayer.Character })
    if hit then
        createEffect(pos)
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(100000, 100000, 100000)
        bv.Velocity = root.CFrame.LookVector * velocity
        bv.Parent = root
        Debris:AddItem(bv, 0.1)
        breaker.totalBones = breaker.totalBones + 1
        if velocity > breaker.maxDamage then
            breaker.maxDamage = math.floor(velocity)
        end
    end
end

local lastHit = tick()
local dmgCount = 0
local lastDmgCheck = tick()
local connection = nil

local function autoLoop()
    if not breaker.active then return end
    if not getRoot() then return end
    local now = tick()
    local settings = modeSettings[breaker.mode]
    if not settings then return end
    if now - lastHit >= settings.int then
        for i = 1, settings.cnt do
            performHit()
            if settings.cnt > 1 then task.wait(0.05) end
        end
        lastHit = now
        dmgCount = dmgCount + 1
    end
    if now - lastDmgCheck >= 1 then
        breaker.dps = dmgCount
        dmgCount = 0
        lastDmgCheck = now
    end
end

local function startFarm()
    if not breaker.active then
        breaker.active = true
        if connection then pcall(function() connection:Disconnect() end) end
        connection = RunService.Heartbeat:Connect(autoLoop)
    end
end

local function stopFarm()
    if breaker.active then
        breaker.active = false
        if connection then
            pcall(function() connection:Disconnect() end)
            connection = nil
        end
    end
end

local posLockActive = false
local lockedCFrame = nil
local posLockConn = nil

local Window = WindUI:CreateWindow({
    Title = "Syniox Hub",
    SubTitle = "Bone Breaker Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Folder = "SynioxHub",
    Theme = "Midnight",
    Themeable = { Background = false },
    HidePanelBackground = true,
    NewElements = false,
    HideSearchBar = false,
    Icon = "solar:shield-check-bold-duotone",
    Topbar = { Height = 44, ButtonsType = "Default" },
    OpenButton = {
        Title = "Syniox Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 1.15,
        Color = ColorSequence.new(
            Color3.fromHex("#FF6B6B"),
            Color3.fromHex("#FF8E53")
        ),
    },
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({
                Title = "Profile",
                Content = LocalPlayer.DisplayName .. " | @" .. LocalPlayer.Name,
                Icon = "solar:user-bold",
                Duration = 3,
            })
        end,
    },
})

pcall(function() Window:SetPanelBackground(false) end)

Window:Tag({ Title = "v1.2", Icon = "solar:tag-bold", Color = Purple, Border = true })

local fpsTag = Window:Tag({ Title = "FPS: --", Icon = "solar:cpu-bolt-bold", Color = Green, Border = true })
local pingTag = Window:Tag({ Title = "Ping: --ms", Icon = "solar:radar-bold", Color = Yellow, Border = true })

Window:Tag({ Title = "Premium Quality", Icon = "solar:shield-check-bold", Color = Purple, Border = true })

task.spawn(function()
    while true do
        task.wait(1)
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        local ok, ping = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        fpsTag:SetTitle("FPS: " .. fps)
        pingTag:SetTitle("Ping: " .. (ok and math.floor(ping) or "??") .. "ms")
    end
end)

local FarmSection = Window:Section({ Title = "Farm" })
local TeleportSection = Window:Section({ Title = "Teleport" })
local InterfaceSection = Window:Section({ Title = "Interface" })
local SettingsSection = Window:Section({ Title = "Settings" })

local StrikeTab = FarmSection:Tab({
    Title = "Auto Strike",
    Desc = "Core bone breaker automation",
    Icon = "solar:bone-broken-bold",
    IconColor = Red,
    IconShape = "Square",
    Border = true,
})

StrikeTab:Paragraph({
    Title = "Bone Breaker Strike Center",
    Desc = "Choose a strike mode, tune your power, then start farming. Every hit uses forward velocity impact.",
    Image = "solar:bone-broken-bold",
    ImageSize = 36,
})

StrikeTab:Space()

local ModeSection = StrikeTab:Section({
    Title = "Strike Mode",
    Desc = "Select how the breaker hits. Each mode has unique velocity and interval.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

local intervalPara = ModeSection:Paragraph({
    Title = "Current Interval",
    Desc = "Interval: 0.3 sec | Hits per cycle: 1",
    Image = "solar:clock-circle-bold",
    ImageSize = 28,
})

ModeSection:Space()

local modeDropdown = ModeSection:Dropdown({
    Flag = "StrikeMode",
    Title = "Strike Mode",
    Desc = "FAST many hits, POWER max damage, COMBO hit series.",
    Icon = "solar:target-bold",
    IconColor = Red,
    Values = { "FAST", "POWER", "COMBO" },
    Value = "FAST",
    Callback = function(val)
        breaker.mode = val
        local s = modeSettings[val]
        if s and intervalPara and intervalPara.SetDesc then
            intervalPara:SetDesc("Interval: " .. tostring(s.int) .. " sec | Hits per cycle: " .. tostring(s.cnt))
        end
        notify("Strike Mode", "Mode set to " .. tostring(val), "solar:target-bold")
    end,
})

ModeSection:Space()

ModeSection:Toggle({
    Flag = "ShowHitEffects",
    Title = "Show Hit Effects",
    Desc = "Display neon impact effect on every successful hit.",
    Icon = "solar:stars-bold",
    IconColor = Yellow,
    Type = "Checkbox",
    Value = true,
    Callback = function(state)
        showEffects = state
        notify("Effects", state and "Hit effects enabled." or "Hit effects disabled.", "solar:stars-bold")
    end,
})

StrikeTab:Space()

local PowerSection = StrikeTab:Section({
    Title = "Strike Power",
    Desc = "Fine tune velocity multiplier and visual impact size.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

PowerSection:Slider({
    Flag = "StrikePower",
    Title = "Strike Power",
    Desc = "Velocity multiplier from 10 percent to 200 percent.",
    Icon = "solar:bolt-bold",
    IconColor = Orange,
    IsTooltip = true,
    IsTextbox = true,
    Icons = { From = "sfsymbols:sunMinFill", To = "sfsymbols:sunMaxFill" },
    Step = 1,
    Value = { Min = 10, Max = 200, Default = 100 },
    Callback = function(v)
        breaker.power = v / 100
        notify("Strike Power", "Power set to " .. tostring(v) .. "%", "solar:bolt-bold")
    end,
})

PowerSection:Space()

PowerSection:Slider({
    Flag = "EffectSize",
    Title = "Effect Size",
    Desc = "Size of the neon impact effect on hit.",
    Icon = "solar:maximize-bold",
    IconColor = Purple,
    IsTooltip = true,
    IsTextbox = true,
    Icons = { From = "sfsymbols:sunMinFill", To = "sfsymbols:sunMaxFill" },
    Step = 1,
    Value = { Min = 1, Max = 10, Default = 3 },
    Callback = function(v)
        effectSize = v
        notify("Effect Size", "Effect size set to " .. tostring(v), "solar:maximize-bold")
    end,
})

StrikeTab:Space()

local ControlSection = StrikeTab:Section({
    Title = "Automation Control",
    Desc = "Start, stop, and automate the bone breaking loop.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

ControlSection:Toggle({
    Flag = "AutoStrike",
    Title = "Auto Strike",
    Desc = "Automatically perform strikes using the selected mode.",
    Icon = "solar:play-bold",
    IconColor = Green,
    Value = false,
    Callback = function(state)
        if state then
            startFarm()
            notify("Auto Strike", "Auto strike enabled on " .. breaker.mode .. " mode.", "solar:play-bold")
        else
            stopFarm()
            notify("Auto Strike", "Auto strike disabled.", "solar:stop-bold")
        end
    end,
})

ControlSection:Space()

ControlSection:Toggle({
    Flag = "AutoFarmSync",
    Title = "Auto Farm Sync",
    Desc = "Secondary automation mirror for config saving.",
    Icon = "solar:refresh-bold",
    IconColor = Orange,
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            startFarm()
            notify("Auto Farm", "Auto farm sync enabled.", "solar:refresh-bold")
        else
            stopFarm()
            notify("Auto Farm", "Auto farm sync disabled.", "solar:refresh-bold")
        end
    end,
})

StrikeTab:Space()

local StrikeGroup = StrikeTab:Group({})

StrikeGroup:Button({
    Title = "Start",
    Desc = "Start the strike loop.",
    Icon = "solar:play-circle-bold",
    IconColor = Green,
    Color = Green,
    Justify = "Center",
    Callback = function()
        startFarm()
        notify("Strike", "Strike loop started.", "solar:play-circle-bold")
    end,
})

StrikeGroup:Space()

StrikeGroup:Button({
    Title = "Stop",
    Desc = "Stop the strike loop.",
    Icon = "solar:stop-circle-bold",
    IconColor = Red,
    Color = Red,
    Justify = "Center",
    Callback = function()
        stopFarm()
        notify("Strike", "Strike loop stopped.", "solar:stop-circle-bold")
    end,
})

StrikeTab:Space()

local ManualGroup = StrikeTab:Group({})

ManualGroup:Button({
    Title = "Single Hit",
    Desc = "Perform one manual strike now.",
    Icon = "solar:sledgehammer-bold",
    IconColor = Yellow,
    Color = Orange,
    Justify = "Center",
    Callback = function()
        performHit()
        notify("Manual Hit", "Single strike executed.", "solar:sledgehammer-bold")
    end,
})

ManualGroup:Space()

ManualGroup:Button({
    Title = "Reset Counters",
    Desc = "Reset bones, max velocity and hits per second.",
    Icon = "solar:restart-bold",
    IconColor = Grey,
    Color = Grey,
    Justify = "Center",
    Callback = function()
        breaker.totalBones = 0
        breaker.maxDamage = 0
        breaker.dps = 0
        notify("Statistics", "All counters reset.", "solar:restart-bold")
    end,
})

local StatsTab = FarmSection:Tab({
    Title = "Statistics",
    Desc = "Live bones and damage tracking",
    Icon = "solar:chart-bold",
    IconColor = Yellow,
    IconShape = "Square",
    Border = true,
})

StatsTab:Paragraph({
    Title = "Live Breaker Statistics",
    Desc = "Real time tracking of broken bones, hits per second, and maximum velocity.",
    Image = "solar:chart-bold",
    ImageSize = 36,
})

StatsTab:Space()

local LiveSection = StatsTab:Section({
    Title = "Live Counters",
    Desc = "Values update automatically every 0.2 seconds.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

local statsPara = LiveSection:Paragraph({
    Title = "Breaker Overview",
    Desc = "Broken: 0 | Hits/sec: 0 | Max Vel: 0",
    Image = "solar:pulse-bold",
    ImageSize = 28,
})

LiveSection:Space()

LiveSection:Paragraph({
    Title = "Session Info",
    Desc = "Mode: FAST | Power: 100% | Status: Idle",
    Image = "solar:info-circle-bold",
    ImageSize = 28,
})

local sessionPara = LiveSection:Paragraph({
    Title = "Session Time",
    Desc = "00:00:00",
    Image = "solar:clock-circle-bold",
    ImageSize = 28,
})

task.spawn(function()
    local startTime = tick()
    while true do
        task.wait(0.2)
        pcall(function()
            if statsPara and statsPara.SetDesc then
                statsPara:SetDesc("Broken: " .. tostring(breaker.totalBones) .. " | Hits/sec: " .. tostring(breaker.dps) .. " | Max Vel: " .. tostring(breaker.maxDamage))
            end
            local e = math.floor(tick() - startTime)
            local h = math.floor(e / 3600)
            local m = math.floor((e % 3600) / 60)
            local s = e % 60
            if sessionPara and sessionPara.SetDesc then
                sessionPara:SetDesc(string.format("%02d:%02d:%02d", h, m, s))
            end
        end)
    end
end)

StatsTab:Space()

local DetailSection = StatsTab:Section({
    Title = "Detailed View",
    Desc = "Individual stat toggles for focused monitoring.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

DetailSection:Toggle({
    Flag = "ShowBrokenCount",
    Title = "Track Broken Bones",
    Desc = "Include broken bone count in live updates.",
    Icon = "solar:bone-bold",
    IconColor = Red,
    Type = "Checkbox",
    Value = true,
    Callback = function(state)
        notify("Statistics", state and "Broken bone tracking on." or "Broken bone tracking off.", "solar:bone-bold")
    end,
})

DetailSection:Space()

DetailSection:Toggle({
    Flag = "TrackVelocity",
    Title = "Track Max Velocity",
    Desc = "Include maximum velocity in live updates.",
    Icon = "solar:rocket-bold",
    IconColor = Blue,
    Type = "Checkbox",
    Value = true,
    Callback = function(state)
        notify("Statistics", state and "Velocity tracking on." or "Velocity tracking off.", "solar:rocket-bold")
    end,
})

StatsTab:Space()

local StatsGroup = StatsTab:Group({})

StatsGroup:Button({
    Title = "Copy Stats",
    Desc = "Copy current stats to clipboard.",
    Icon = "solar:copy-bold",
    IconColor = Blue,
    Color = Blue,
    Justify = "Center",
    Callback = function()
        local text = "Broken: " .. breaker.totalBones .. " | Hits/sec: " .. breaker.dps .. " | Max Vel: " .. breaker.maxDamage
        if setclipboard then setclipboard(text) end
        notify("Statistics", "Stats copied: " .. text, "solar:copy-bold")
    end,
})

StatsGroup:Space()

StatsGroup:Button({
    Title = "Reset Stats",
    Desc = "Clear all statistic counters.",
    Icon = "solar:trash-bin-2-bold",
    IconColor = Orange,
    Color = Orange,
    Justify = "Center",
    Callback = function()
        breaker.totalBones = 0
        breaker.maxDamage = 0
        breaker.dps = 0
        notify("Statistics", "Statistics cleared.", "solar:trash-bin-2-bold")
    end,
})

local MovementTab = TeleportSection:Tab({
    Title = "Movement",
    Desc = "Dash and position utilities",
    Icon = "solar:map-point-bold",
    IconColor = Blue,
    IconShape = "Square",
    Border = true,
})

MovementTab:Paragraph({
    Title = "Movement Utilities",
    Desc = "Forward dash, upward boost, and position lock to control your breaker character.",
    Image = "solar:map-point-bold",
    ImageSize = 36,
})

MovementTab:Space()

local DashSection = MovementTab:Section({
    Title = "Dash Controls",
    Desc = "Manual velocity bursts using the same physics as auto strikes.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

DashSection:Slider({
    Flag = "DashPower",
    Title = "Dash Power",
    Desc = "Velocity used by manual dash buttons.",
    Icon = "solar:running-bold",
    IconColor = Blue,
    IsTooltip = true,
    IsTextbox = true,
    Icons = { From = "sfsymbols:sunMinFill", To = "sfsymbols:sunMaxFill" },
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v)
        notify("Dash Power", "Dash power set to " .. tostring(v), "solar:running-bold")
    end,
})

MovementTab:Space()

local DashGroup = MovementTab:Group({})

DashGroup:Button({
    Title = "Forward Dash",
    Desc = "Dash forward with breaker velocity.",
    Icon = "solar:arrow-right-bold",
    IconColor = Blue,
    Color = Blue,
    Justify = "Center",
    Callback = function()
        local root = getRoot()
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(100000, 100000, 100000)
            bv.Velocity = root.CFrame.LookVector * (150 * breaker.power)
            bv.Parent = root
            Debris:AddItem(bv, 0.15)
            notify("Dash", "Forward dash executed.", "solar:arrow-right-bold")
        else
            notify("Dash", "No character found.", "solar:close-circle-bold")
        end
    end,
})

DashGroup:Space()

DashGroup:Button({
    Title = "Upward Boost",
    Desc = "Boost upward for better fall impact.",
    Icon = "solar:arrow-up-bold",
    IconColor = Purple,
    Color = Purple,
    Justify = "Center",
    Callback = function()
        local root = getRoot()
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(100000, 100000, 100000)
            bv.Velocity = Vector3.new(0, 200 * breaker.power, 0)
            bv.Parent = root
            Debris:AddItem(bv, 0.15)
            notify("Boost", "Upward boost executed.", "solar:arrow-up-bold")
        else
            notify("Boost", "No character found.", "solar:close-circle-bold")
        end
    end,
})

MovementTab:Space()

local LockSection = MovementTab:Section({
    Title = "Position Lock",
    Desc = "Lock your character in place or reset physics state.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

LockSection:Toggle({
    Flag = "PositionLock",
    Title = "Enable Position Lock",
    Desc = "Locks your HumanoidRootPart at its current position.",
    Icon = "solar:lock-bold",
    IconColor = Purple,
    Value = false,
    Callback = function(state)
        posLockActive = state
        if state then
            local hrp = getHRP()
            if hrp then
                lockedCFrame = hrp.CFrame
                if posLockConn then pcall(function() posLockConn:Disconnect() end) end
                posLockConn = RunService.Heartbeat:Connect(function()
                    local h = getHRP()
                    if h and lockedCFrame then
                        h.CFrame = lockedCFrame
                    end
                end)
                notify("Position Lock", "Your position is now locked.", "solar:lock-bold")
            else
                notify("Position Lock", "No character found.", "solar:close-circle-bold")
            end
        else
            if posLockConn then
                pcall(function() posLockConn:Disconnect() end)
                posLockConn = nil
            end
            lockedCFrame = nil
            notify("Position Lock", "Position lock released.", "solar:lock-keyhole-bold")
        end
    end,
})

LockSection:Space()

local LockGroup = MovementTab:Group({})

LockGroup:Button({
    Title = "Stop Velocity",
    Desc = "Clear all velocity from your character.",
    Icon = "solar:stop-bold",
    IconColor = Green,
    Color = Green,
    Justify = "Center",
    Callback = function()
        local root = getRoot()
        if root then
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
            notify("Physics", "Velocity cleared.", "solar:stop-bold")
        end
    end,
})

LockGroup:Space()

LockGroup:Button({
    Title = "Respawn",
    Desc = "Respawn your character safely.",
    Icon = "solar:refresh-bold",
    IconColor = Red,
    Color = Red,
    Justify = "Center",
    Callback = function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
            notify("Respawn", "Respawning character.", "solar:refresh-bold")
        else
            notify("Respawn", "No humanoid found.", "solar:close-circle-bold")
        end
    end,
})

local ConfigTab = InterfaceSection:Tab({
    Title = "Config",
    Desc = "Save, load and delete configs",
    Icon = "solar:folder-with-files-bold",
    IconColor = Grey,
    IconShape = "Square",
    Border = true,
})

ConfigTab:Paragraph({
    Title = "Configuration Manager",
    Desc = "Save your current settings, load a saved config, or delete configs you no longer need.",
    Image = "solar:folder-with-files-bold",
    ImageSize = 36,
})

ConfigTab:Space()

local CfgSection = ConfigTab:Section({
    Title = "Save and Load",
    Desc = "Manage named configuration profiles.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

local ConfigManager = Window.ConfigManager
local ConfigName = "default"

local ConfigNameInput = CfgSection:Input({
    Flag = "ConfigName",
    Title = "Config Name",
    Desc = "Name for the config file.",
    Icon = "solar:pen-bold",
    IconColor = White,
    Placeholder = "Enter config name...",
    Value = "default",
    Callback = function(value)
        ConfigName = value
    end,
})

ConfigTab:Space()

local AllConfigs = {}
if ConfigManager and ConfigManager.AllConfigs then
    pcall(function() AllConfigs = ConfigManager:AllConfigs() or {} end)
end
local DefaultConfigValue = (#AllConfigs > 0 and table.find(AllConfigs, ConfigName)) and ConfigName or nil

local AllConfigsDropdown = CfgSection:Dropdown({
    Flag = "SelectedConfig",
    Title = "Saved Configs",
    Desc = "Select an existing config to load or delete.",
    Icon = "solar:folder-open-bold",
    IconColor = Yellow,
    Values = AllConfigs,
    Value = DefaultConfigValue,
    Callback = function(value)
        ConfigName = value
        if ConfigNameInput and ConfigNameInput.Set then
            ConfigNameInput:Set(value)
        end
        notify("Config", "Selected config: " .. tostring(value), "solar:folder-open-bold")
    end,
})

ConfigTab:Space()

local ActionGroup = ConfigTab:Group({})

ActionGroup:Button({
    Title = "Save",
    Desc = "Save current settings.",
    Icon = "solar:diskette-bold",
    IconColor = Green,
    Color = Green,
    Justify = "Center",
    Callback = function()
        if ConfigManager then
            pcall(function()
                local cfg = ConfigManager:Config(ConfigName)
                if cfg then
                    Window.CurrentConfig = cfg
                    cfg:Save()
                    notify("Config Saved", "'" .. ConfigName .. "' has been saved.", "solar:diskette-bold")
                    if AllConfigsDropdown and AllConfigsDropdown.Refresh then
                        local configs = {}
                        pcall(function() configs = ConfigManager:AllConfigs() or {} end)
                        AllConfigsDropdown:Refresh(configs)
                    end
                end
            end)
        else
            notify("Config", "ConfigManager not available.", "solar:info-circle-bold")
        end
    end,
})

ActionGroup:Space()

ActionGroup:Button({
    Title = "Load",
    Desc = "Load selected config.",
    Icon = "solar:import-bold",
    IconColor = Blue,
    Color = Blue,
    Justify = "Center",
    Callback = function()
        if ConfigManager then
            pcall(function()
                local cfg = ConfigManager:Config(ConfigName)
                if cfg then
                    Window.CurrentConfig = cfg
                    cfg:Load()
                    notify("Config Loaded", "'" .. ConfigName .. "' has been loaded.", "solar:import-bold")
                end
            end)
        else
            notify("Config", "ConfigManager not available.", "solar:info-circle-bold")
        end
    end,
})

ActionGroup:Space()

ActionGroup:Button({
    Title = "Delete",
    Desc = "Delete selected config.",
    Icon = "solar:trash-bin-2-bold",
    IconColor = Red,
    Color = Red,
    Justify = "Center",
    Callback = function()
        if ConfigManager then
            pcall(function()
                local cfg = nil
                if ConfigManager.GetConfig then
                    cfg = ConfigManager:GetConfig(ConfigName)
                elseif ConfigManager.Config then
                    cfg = ConfigManager:Config(ConfigName)
                end
                if cfg and cfg.Delete then
                    cfg:Delete()
                    notify("Config Deleted", "'" .. ConfigName .. "' has been deleted.", "solar:trash-bin-2-bold")
                    if AllConfigsDropdown and AllConfigsDropdown.Refresh then
                        local configs = {}
                        pcall(function() configs = ConfigManager:AllConfigs() or {} end)
                        AllConfigsDropdown:Refresh(configs)
                    end
                else
                    notify("Config", "Config '" .. ConfigName .. "' not found.", "solar:info-circle-bold")
                end
            end)
        else
            notify("Config", "ConfigManager not available.", "solar:info-circle-bold")
        end
    end,
})

ConfigTab:Space()

CfgSection:Button({
    Title = "Reset to Default",
    Desc = "Reset config name and reload defaults.",
    Icon = "solar:restart-bold",
    IconColor = Orange,
    Color = Orange,
    Justify = "Center",
    Callback = function()
        ConfigName = "default"
        if ConfigNameInput and ConfigNameInput.Set then ConfigNameInput:Set("default") end
        notify("Config", "Config name reset to default.", "solar:restart-bold")
    end,
})

local SettingsTab = SettingsSection:Tab({
    Title = "Settings",
    Desc = "Keybinds and hub options",
    Icon = "solar:tuning-2-bold",
    IconColor = Purple,
    IconShape = "Square",
    Border = true,
})

SettingsTab:Paragraph({
    Title = "Hub Settings",
    Desc = "Configure toggle key, notifications, anti AFK, and hub lifecycle options.",
    Image = "solar:tuning-2-bold",
    ImageSize = 36,
})

SettingsTab:Space()

local KeybindSection = SettingsTab:Section({
    Title = "Keybinds",
    Desc = "Set the key to toggle the hub open and closed.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

KeybindSection:Keybind({
    Flag = "MenuKeybind",
    Title = "Toggle Hub",
    Desc = "Press this key to show or hide the hub.",
    Icon = "solar:keyboard-bold",
    IconColor = Blue,
    Value = "RightShift",
    Callback = function(v)
        local ok, code = pcall(function() return Enum.KeyCode[v] end)
        if ok and code then
            Window:SetToggleKey(code)
            notify("Keybind", "Toggle key set to " .. tostring(v), "solar:keyboard-bold")
        end
    end,
})

SettingsTab:Space()

local MiscSection = SettingsTab:Section({
    Title = "Miscellaneous",
    Desc = "Additional hub options and safety features.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

MiscSection:Toggle({
    Flag = "NotificationsEnabled",
    Title = "Notifications",
    Desc = "Enable or disable all hub notifications.",
    Icon = "solar:bell-bold",
    IconColor = Yellow,
    Type = "Checkbox",
    Value = true,
    Callback = function(state)
        notificationsEnabled = state
        if state then
            notify("Notifications", "Notifications enabled.", "solar:bell-bold")
        end
    end,
})

MiscSection:Space()

MiscSection:Toggle({
    Flag = "AutoStartFeatures",
    Title = "Auto Start Features",
    Desc = "Automatically enable last used features on load.",
    Icon = "solar:play-circle-bold",
    IconColor = Green,
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        notify("Auto Start", state and "Auto start enabled." or "Auto start disabled.", "solar:play-circle-bold")
    end,
})

MiscSection:Space()

local AntiAFKConn = nil
MiscSection:Toggle({
    Flag = "AntiAFK",
    Title = "Anti AFK",
    Desc = "Prevents kick for inactivity using VirtualUser.",
    Icon = "solar:user-check-bold",
    IconColor = Green,
    Value = false,
    Callback = function(state)
        if state then
            local VirtualUser = game:GetService("VirtualUser")
            AntiAFKConn = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end)
            notify("Anti AFK", "Anti AFK enabled.", "solar:user-check-bold")
        else
            if AntiAFKConn then
                pcall(function() AntiAFKConn:Disconnect() end)
                AntiAFKConn = nil
            end
            notify("Anti AFK", "Anti AFK disabled.", "solar:user-check-bold")
        end
    end,
})

SettingsTab:Space()

local HubGroup = SettingsTab:Group({})

HubGroup:Button({
    Title = "Save Settings",
    Desc = "Persist current settings to config.",
    Icon = "solar:diskette-bold",
    IconColor = Green,
    Color = Green,
    Justify = "Center",
    Callback = function()
        if ConfigManager then
            pcall(function()
                local cfg = ConfigManager:Config(ConfigName)
                if cfg then
                    Window.CurrentConfig = cfg
                    cfg:Save()
                end
            end)
        end
        notify("Settings", "Settings saved.", "solar:diskette-bold")
    end,
})

HubGroup:Space()

HubGroup:Button({
    Title = "Close Hub",
    Desc = "Close the Syniox Hub window.",
    Icon = "solar:close-circle-bold",
    IconColor = Red,
    Color = Red,
    Justify = "
