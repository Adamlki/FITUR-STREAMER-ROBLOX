local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")


local CONFIG_FEATURES = {
    "Jail", "UnJail", "Smite", "Explode", "Rocket", "RocketBom",
    "PunchLeft", "PunchRight", "PunchForward", "PunchBack",
    "Beatdown", "Slim", "SpinCam", "Drunk"
}

local CONFIG_INSTANT_FEATURES = {
    Smite = true, 
    Explode = true, 
    Rocket = true, 
    RocketBom = true,
    PunchLeft = true, 
    PunchRight = true, 
    PunchForward = true, 
    PunchBack = true
}

local CONFIG_HUD_TIMERS = {
    JailTime = "🔒 Jail",
    SlimTime = "🕴️ Slim",
    DrunkTime = "🥴 Drunk",
    BeatdownTime = "👊 Beatdown",
    SpinCamTime = "🌀 SpinCam",
    RocketTime = "🚀 Rocket",
    RocketBomTime = "🚀💣 Rocket+Bom"
}

local CONFIG_COLORS = {
    bg = Color3.fromRGB(25, 25, 25),
    itemBg = Color3.fromRGB(40, 40, 40),
    text = Color3.fromRGB(240, 240, 240),
    textMuted = Color3.fromRGB(150, 150, 150),
    btnRed = Color3.fromRGB(200, 60, 60),
}


table.sort(CONFIG_FEATURES)

local savedConfigs = {}
for _, feature in ipairs(CONFIG_FEATURES) do
    savedConfigs[feature] = {}
end

local currentSelectedFeature = CONFIG_FEATURES[1]

local loadedFeatures = {}
local featuresFolder = script.Parent:FindFirstChild("StreamerFeatures")
if featuresFolder then
    for _, module in ipairs(featuresFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local success, feature = pcall(require, module)
            if success and type(feature) == "table" then
                loadedFeatures[module.Name] = feature
            end
        end
    end
end

local function setupTimers()
    for timerName, _ in pairs(CONFIG_HUD_TIMERS) do
        local t = player:FindFirstChild(timerName)
        if not t then
            t = Instance.new("NumberValue")
            t.Name = timerName
            t.Value = 0
            t.Parent = player
        end
    end
end
setupTimers()

player.CharacterAdded:Connect(function()
    for _, obj in ipairs(player:GetChildren()) do
        if obj:IsA("NumberValue") and string.find(obj.Name, "Time") then
            obj.Value = 0
        end
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    for _, featureModule in pairs(loadedFeatures) do
        if type(featureModule.Update) == "function" then
            featureModule.Update(deltaTime)
        end
    end
end)

local function tween(obj, goal, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local ScreenGui = PlayerGui:WaitForChild("StreamerGui")
local Blur = Lighting:WaitForChild("StreamerProBlur")

local FrameBtn = ScreenGui:WaitForChild("FrameBtn")
local ToggleBtn = FrameBtn:WaitForChild("ToggleBtn")
local MainWindow = ScreenGui:WaitForChild("MainWindow")
local MainWindowGroup = MainWindow:WaitForChild("MainWindowGroup")
local TitleBar = MainWindowGroup:WaitForChild("TitleBar")
local CloseBtn = TitleBar:WaitForChild("CloseBtn")
local Body = MainWindowGroup:WaitForChild("Body")
local Sidebar = Body:WaitForChild("Sidebar")
local Content = Body:WaitForChild("Content")
local ContentHeader = Content:WaitForChild("ContentHeader")
local ContentScroll = Content:WaitForChild("ContentScroll")
local HudContainer = ScreenGui:WaitForChild("HudContainer")

local SidebarBtnTemplate = Sidebar:WaitForChild("SidebarBtnTemplate")
local ShortcutRowTemplate = ContentScroll:WaitForChild("ShortcutRowTemplate")
local AddContainerTemplate = ContentScroll:WaitForChild("AddContainerTemplate")
local TestContainerTemplate = ContentScroll:WaitForChild("TestContainerTemplate")
local TimerTemplate = HudContainer:WaitForChild("TimerTemplate")
local mainStroke = MainWindow:WaitForChild("MainStroke")

MainWindow.Visible = false
MainWindow.BackgroundTransparency = 1
MainWindowGroup.GroupTransparency = 1
mainStroke.Transparency = 1


CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {TextColor3 = CONFIG_COLORS.btnRed}, 0.15) end)
CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {TextColor3 = CONFIG_COLORS.textMuted}, 0.15) end)

local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function openWindow()
    MainWindow.Visible = true
    MainWindow.Size = UDim2.new(0, 600, 0, 400)
    MainWindowGroup.GroupTransparency = 1
    mainStroke.Transparency = 1
    
    tween(Blur, {Size = 15}, 0.3)
    TweenService:Create(MainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 650, 0, 450)}):Play()
    tween(MainWindow, {BackgroundTransparency = 0.1}, 0.3)
    tween(MainWindowGroup, {GroupTransparency = 0}, 0.3)
    tween(mainStroke, {Transparency = 0}, 0.3)
end

local function closeWindow()
    tween(Blur, {Size = 0}, 0.3)
    tween(MainWindow, {BackgroundTransparency = 1}, 0.2)
    tween(MainWindowGroup, {GroupTransparency = 1}, 0.2)
    tween(mainStroke, {Transparency = 1}, 0.2)
    TweenService:Create(MainWindow, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 600, 0, 400)}):Play()
    task.delay(0.2, function()
        MainWindow.Visible = false
    end)
end

ToggleBtn.MouseButton1Click:Connect(function()
    if MainWindow.Visible and MainWindowGroup.GroupTransparency == 0 then
        closeWindow()
    else
        openWindow()
    end
end)
CloseBtn.MouseButton1Click:Connect(closeWindow)

local renderContent

local sidebarBtns = {}
for _, feat in ipairs(CONFIG_FEATURES) do
    local btn = SidebarBtnTemplate:Clone()
    btn.Name = feat
    btn.Text = "  " .. feat
    btn.Visible = true
    btn.Parent = Sidebar
    
    local strokeObj = btn:FindFirstChild("ActiveStroke")
    sidebarBtns[feat] = {Btn = btn, Stroke = strokeObj}
    
    local baseBg = btn.BackgroundColor3
    local hoverBg = Color3.fromRGB(baseBg.R*255 + 20, baseBg.G*255 + 20, baseBg.B*255 + 20)
    
    btn.MouseEnter:Connect(function()
        if currentSelectedFeature ~= feat then
            tween(btn, {BackgroundColor3 = hoverBg}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentSelectedFeature ~= feat then
            tween(btn, {BackgroundColor3 = baseBg}, 0.15)
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        for k, v in pairs(sidebarBtns) do
            v.Btn.TextColor3 = CONFIG_COLORS.textMuted
            v.Btn.BackgroundColor3 = baseBg
            if v.Stroke then v.Stroke.Thickness = 0 end
        end
        tween(btn, {BackgroundColor3 = CONFIG_COLORS.bg}, 0.15)
        btn.TextColor3 = CONFIG_COLORS.text
        if strokeObj then strokeObj.Thickness = 1 end
        currentSelectedFeature = feat
        renderContent()
    end)
end
Sidebar.CanvasSize = UDim2.new(0, 0, 0, #CONFIG_FEATURES * 40)

function renderContent()
    if not currentSelectedFeature then return end
    ContentHeader.Text = currentSelectedFeature .. " Shortcuts"
    
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if not child:IsA("UIListLayout") and child.Name ~= "ShortcutRowTemplate" and child.Name ~= "AddContainerTemplate" and child.Name ~= "TestContainerTemplate" then
            child:Destroy()
        end
    end
    
    local isInstant = CONFIG_INSTANT_FEATURES[currentSelectedFeature]
    local configs = savedConfigs[currentSelectedFeature]
    
    for i, cfg in ipairs(configs) do
        local row = ShortcutRowTemplate:Clone()
        row.Name = "Row_" .. i
        row.Visible = true
        row.Parent = ContentScroll
        
        row.LblKey.Text = "Key: " .. cfg.shortcut
        row.LblTime.Text = "Val: " .. cfg.time
        
        if isInstant then 
            row.LblTime.Visible = false 
            row.LblKey.Size = UDim2.new(0.7, 0, 1, 0)
        end
        
        local delBtn = row:WaitForChild("DelBtn")
        delBtn.MouseButton1Click:Connect(function()
            table.remove(savedConfigs[currentSelectedFeature], i)
            renderContent()
        end)
    end
    
    local addContainer = AddContainerTemplate:Clone()
    addContainer.Name = "AddContainer"
    addContainer.Visible = true
    addContainer.Parent = ContentScroll
    
    local boxKey = addContainer.BoxKey
    local boxTime = addContainer.BoxTime
    local saveBtn = addContainer.SaveBtn
    
    if isInstant then 
        boxTime.Visible = false 
        boxKey.Size = UDim2.new(1, -20, 0, 35)
    end
    
    saveBtn.MouseEnter:Connect(function() tween(saveBtn, {Size = UDim2.new(1, -18, 0, 37), Position = UDim2.new(0, 9, 0, 84)}, 0.1) end)
    saveBtn.MouseLeave:Connect(function() tween(saveBtn, {Size = UDim2.new(1, -20, 0, 35), Position = UDim2.new(0, 10, 0, 85)}, 0.1) end)
    
    saveBtn.MouseButton1Click:Connect(function()
        local k = string.upper(boxKey.Text)
        local t = boxTime.Text
        if k ~= "" then
            table.insert(savedConfigs[currentSelectedFeature], {shortcut = k, time = t})
            renderContent()
        end
    end)
    
    local testContainer = TestContainerTemplate:Clone()
    testContainer.Name = "TestContainer"
    testContainer.Visible = true
    testContainer.Parent = ContentScroll
    
    local boxTestTime = testContainer.BoxTestTime
    local runTestBtn = testContainer.RunTestBtn
    
    if isInstant then 
        boxTestTime.Visible = false 
        runTestBtn.Size = UDim2.new(1, -20, 0, 35)
        runTestBtn.Position = UDim2.new(0, 10, 0, 45)
    end
    
    local originalSize = runTestBtn.Size
    local originalPos = runTestBtn.Position
    local hoverSize = isInstant and UDim2.new(1, -18, 0, 37) or UDim2.new(1, -148, 0, 37)
    local hoverPos = isInstant and UDim2.new(0, 9, 0, 44) or UDim2.new(0, 139, 0, 44)
    
    runTestBtn.MouseEnter:Connect(function() tween(runTestBtn, {Size = hoverSize, Position = hoverPos}, 0.1) end)
    runTestBtn.MouseLeave:Connect(function() tween(runTestBtn, {Size = originalSize, Position = originalPos}, 0.1) end)
    
    runTestBtn.MouseButton1Click:Connect(function()
        local featureModule = loadedFeatures[currentSelectedFeature]
        if featureModule and type(featureModule.Trigger) == "function" then
            local testVal = tonumber(boxTestTime.Text) or 5
            featureModule.Trigger(player, testVal)
        end
    end)
    
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, (#configs * 55) + 140 + 105)
end

if sidebarBtns[CONFIG_FEATURES[1]] then
    sidebarBtns[CONFIG_FEATURES[1]].Btn.TextColor3 = CONFIG_COLORS.text
    sidebarBtns[CONFIG_FEATURES[1]].Btn.BackgroundColor3 = CONFIG_COLORS.bg
    local s = sidebarBtns[CONFIG_FEATURES[1]].Stroke
    if s then s.Thickness = 1 end
    renderContent()
end

local activeTimerFrames = {}

local function updateHudTimer(name, value)
    local frame = activeTimerFrames[name]
    if value > 0 then
        if not frame then
            frame = TimerTemplate:Clone()
            frame.Name = name
            frame.Visible = true
            frame.Size = UDim2.new(0, 0, 0, 35)
            frame.Parent = HudContainer
            
            frame.TimeLbl.Text = name .. ": " .. tostring(math.ceil(value)) .. "s"
            
            activeTimerFrames[name] = frame
            tween(frame, {Size = UDim2.new(1, 0, 0, 35)}, 0.3)
        else
            frame.TimeLbl.Text = name .. ": " .. tostring(math.ceil(value)) .. "s"
        end
    else
        if frame then
            activeTimerFrames[name] = nil
            tween(frame, {Size = UDim2.new(0, 0, 0, 35), BackgroundTransparency = 1}, 0.2)
            task.delay(0.2, function() frame:Destroy() end)
        end
    end
end

local function attachToValue(valName, displayPrefix)
    task.spawn(function()
        local val = nil
        while not val do
            val = player:FindFirstChild(valName)
            task.wait(0.5)
        end
        val.Changed:Connect(function(newVal)
            updateHudTimer(displayPrefix, newVal)
        end)
        if val.Value > 0 then
            updateHudTimer(displayPrefix, val.Value)
        end
    end)
end

for valName, displayPrefix in pairs(CONFIG_HUD_TIMERS) do
    attachToValue(valName, displayPrefix)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local pressedName = string.upper(input.KeyCode.Name)
        local pressedString = ""
        pcall(function()
            pressedString = string.upper(UserInputService:GetStringForKeyCode(input.KeyCode))
        end)
        
        for featureName, configs in pairs(savedConfigs) do
            for _, config in ipairs(configs) do
                if config.shortcut ~= "" then
                    local sc = string.upper(config.shortcut)
                    if sc == pressedName or sc == pressedString then
                        local featureModule = loadedFeatures[featureName]
                        if featureModule and type(featureModule.Trigger) == "function" then
                            featureModule.Trigger(player, tonumber(config.time) or 5)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- ADMIN PANEL LOGIC
-- ==========================================
local FrameBtn2 = ScreenGui:WaitForChild("FrameBtn")
local AdminBtn = FrameBtn2:WaitForChild("AdminBtn")
local AdminWindow = ScreenGui:WaitForChild("AdminWindow")
local AdminWindowGroup = AdminWindow:WaitForChild("AdminWindowGroup")
local AdminTitleBar = AdminWindowGroup:WaitForChild("AdminTitleBar")
local AdminCloseBtn = AdminTitleBar:WaitForChild("AdminCloseBtn")
local AdminBody = AdminWindowGroup:WaitForChild("AdminBody")
local AdminSidebar = AdminBody:WaitForChild("AdminSidebar")
local TabGrant = AdminSidebar:WaitForChild("TabGrant")
local TabActive = AdminSidebar:WaitForChild("TabActive")

local AdminContent = AdminBody:WaitForChild("AdminContent")
local ViewGrant = AdminContent:WaitForChild("ViewGrant")
local ViewActive = AdminContent:WaitForChild("ViewActive")

local SearchBox = ViewGrant:WaitForChild("SearchBox")
local SearchBtn = ViewGrant:WaitForChild("SearchBtn")
local ProfileFrame = ViewGrant:WaitForChild("ProfileFrame")
local AvatarImg = ProfileFrame:WaitForChild("AvatarImg")
local NameLbl = ProfileFrame:WaitForChild("NameLbl")
local UserLbl = ProfileFrame:WaitForChild("UserLbl")
local DurationGrid = ViewGrant:WaitForChild("DurationGrid")
local CustomDurBox = DurationGrid:WaitForChild("CustomDurBox")
local GrantBtn = ViewGrant:WaitForChild("GrantBtn")

local ActiveScroll = ViewActive:WaitForChild("ActiveScroll")
local ActiveTemplate = ActiveScroll:WaitForChild("ActiveTemplate")

local AdminFunc = ReplicatedStorage:WaitForChild("StreamerProAdminFunction", 5)
local AccessEvent = ReplicatedStorage:WaitForChild("StreamerProAccessEvent", 5)

-- Initial Status
if AccessEvent then
    AccessEvent.OnClientEvent:Connect(function(hasAccess, isAdmin)
        ToggleBtn.Visible = hasAccess
        if not hasAccess and MainWindow.Visible then closeWindow() end
        
        AdminBtn.Visible = isAdmin
        if not isAdmin and AdminWindow.Visible then
            AdminWindow.Visible = false
        end
    end)
end

-- Open / Close Admin
local function openAdminWindow()
    AdminWindow.Visible = true
    AdminWindow.Size = UDim2.new(0, 650, 0, 450)
    AdminWindowGroup.GroupTransparency = 1
    
    tween(Blur, {Size = 15}, 0.3)
    TweenService:Create(AdminWindow, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 700, 0, 500)}):Play()
    tween(AdminWindow, {BackgroundTransparency = 0.1}, 0.3)
    tween(AdminWindowGroup, {GroupTransparency = 0}, 0.3)
end

local function closeAdminWindow()
    if not MainWindow.Visible then tween(Blur, {Size = 0}, 0.3) end
    tween(AdminWindow, {BackgroundTransparency = 1}, 0.2)
    tween(AdminWindowGroup, {GroupTransparency = 1}, 0.2)
    TweenService:Create(AdminWindow, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 650, 0, 450)}):Play()
    task.delay(0.2, function()
        AdminWindow.Visible = false
    end)
end

AdminBtn.MouseButton1Click:Connect(function()
    if AdminWindow.Visible then closeAdminWindow() else openAdminWindow() end
end)
AdminCloseBtn.MouseButton1Click:Connect(closeAdminWindow)



-- Dragging Admin Window
local adminDragging, adminDragStart, adminStartPos
AdminTitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        adminDragging = true
        adminDragStart = input.Position
        adminStartPos = AdminWindow.Position
        
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then 
                adminDragging = false
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and adminDragging then
        local delta = input.Position - adminDragStart
        AdminWindow.Position = UDim2.new(adminStartPos.X.Scale, adminStartPos.X.Offset + delta.X, adminStartPos.Y.Scale, adminStartPos.Y.Offset + delta.Y)
    end
end)

-- Tabs Logic
local function loadActiveStreamers()
    for _, child in ipairs(ActiveScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "ActiveTemplate" then
            child:Destroy()
        end
    end
    
    if not AdminFunc then return end
    local res = AdminFunc:InvokeServer("GetActiveStreamers")
    if res and res.success then
        for _, entry in ipairs(res.data) do
            local item = ActiveTemplate:Clone()
            item.Name = "Entry_" .. tostring(entry.UserId)
            item.Visible = true
            item.Thumb.Image = entry.Thumb or "rbxasset://textures/ui/GuiImagePlaceholder.png"
            item.NameLbl.Text = entry.Username
            item.ExpLbl.Text = "Expires: " .. (entry.ExpString or "Unknown")
            item.Parent = ActiveScroll
            
            item.DelBtn.MouseButton1Click:Connect(function()
                item.DelBtn.Text = "..."
                local r2 = AdminFunc:InvokeServer("RevokeAccess", {UserId = entry.UserId})
                if r2 and r2.success then
                    item:Destroy()
                else
                    item.DelBtn.Text = "DEL"
                end
            end)
        end
        ActiveScroll.CanvasSize = UDim2.new(0, 0, 0, #res.data * 70)
    end
end

local function switchTab(tabName)
    TabGrant.BackgroundColor3 = CONFIG_COLORS.bg
    TabGrant.TextColor3 = CONFIG_COLORS.textMuted
    TabGrant.ActiveStroke.Thickness = 0
    TabActive.BackgroundColor3 = CONFIG_COLORS.bg
    TabActive.TextColor3 = CONFIG_COLORS.textMuted
    TabActive.ActiveStroke.Thickness = 0
    
    if tabName == "Grant" then
        TabGrant.BackgroundColor3 = CONFIG_COLORS.itemBg
        TabGrant.TextColor3 = CONFIG_COLORS.text
        TabGrant.ActiveStroke.Thickness = 2
        ViewGrant.Visible = true
        ViewActive.Visible = false
    else
        TabActive.BackgroundColor3 = CONFIG_COLORS.itemBg
        TabActive.TextColor3 = CONFIG_COLORS.text
        TabActive.ActiveStroke.Thickness = 2
        ViewGrant.Visible = false
        ViewActive.Visible = true
        loadActiveStreamers()
    end
end

TabGrant.MouseButton1Click:Connect(function() switchTab("Grant") end)
TabActive.MouseButton1Click:Connect(function() switchTab("Active") end)

-- Search Player Logic
local selectedUserId = nil
local selectedUsername = nil

SearchBtn.MouseButton1Click:Connect(function()
    local q = SearchBox.Text
    if q == "" then return end
    
    SearchBtn.Text = "..."
    if not AdminFunc then return end
    local res = AdminFunc:InvokeServer("SearchPlayer", {Username = q})
    SearchBtn.Text = "🔍 Search"
    
    if res and res.success then
        selectedUserId = res.data.UserId
        selectedUsername = res.data.Name
        AvatarImg.Image = res.data.Thumb
        NameLbl.Text = res.data.DisplayName
        UserLbl.Text = "@" .. res.data.Name
    else
        NameLbl.Text = "Not Found!"
        UserLbl.Text = ""
        AvatarImg.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        selectedUserId = nil
    end
end)

-- Grant Duration Selection
local selectedDurationDays = 1

local function updateDurBtns(activeBtn)
    for _, b in ipairs(DurationGrid:GetChildren()) do
        if b:IsA("TextButton") then
            b.BackgroundColor3 = CONFIG_COLORS.bg
            b.ActiveStroke.Thickness = 0
        end
    end
    if CustomDurBox then CustomDurBox.ActiveStroke.Thickness = 0 end
    
    if activeBtn then
        activeBtn.BackgroundColor3 = CONFIG_COLORS.itemBg
        activeBtn.ActiveStroke.Thickness = 2
    end
end

DurationGrid.Btn1D.MouseButton1Click:Connect(function() selectedDurationDays = 1; updateDurBtns(DurationGrid.Btn1D) end)
DurationGrid.Btn3D.MouseButton1Click:Connect(function() selectedDurationDays = 3; updateDurBtns(DurationGrid.Btn3D) end)
DurationGrid.Btn1M.MouseButton1Click:Connect(function() selectedDurationDays = 30; updateDurBtns(DurationGrid.Btn1M) end)
DurationGrid.Btn4M.MouseButton1Click:Connect(function() selectedDurationDays = 120; updateDurBtns(DurationGrid.Btn4M) end)
DurationGrid.BtnPerm.MouseButton1Click:Connect(function() selectedDurationDays = -1; updateDurBtns(DurationGrid.BtnPerm) end)

CustomDurBox.FocusLost:Connect(function()
    local v = tonumber(CustomDurBox.Text)
    if v and v > 0 then
        selectedDurationDays = v
        updateDurBtns(nil)
        CustomDurBox.ActiveStroke.Thickness = 2
    else
        CustomDurBox.Text = ""
    end
end)

updateDurBtns(DurationGrid.Btn1D) -- default

GrantBtn.MouseButton1Click:Connect(function()
    if not selectedUserId then return end
    GrantBtn.Text = "Wait..."
    if not AdminFunc then return end
    local res = AdminFunc:InvokeServer("GrantAccess", {
        UserId = selectedUserId,
        Username = selectedUsername,
        DurationDays = selectedDurationDays
    })
    GrantBtn.Text = res and res.success and "SUCCESS!" or "FAILED"
    task.wait(1.5)
    GrantBtn.Text = "GRANT ACCESS"
end)
