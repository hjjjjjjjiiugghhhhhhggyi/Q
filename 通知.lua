local rs = cloneref(game:GetService("RunService"))
local ts = cloneref(game:GetService("TweenService"))
local ps = cloneref(game:GetService("Players"))
local tsService = cloneref(game:GetService("TextService"))

local gethui = gethui or function()
    return cloneref and cloneref(game:GetService("CoreGui"))
end

local containerGui = nil
local function getContainer()
    if containerGui and containerGui.Parent then
        return containerGui
    end
    containerGui = Instance.new("ScreenGui")
    containerGui.Name = "NotificationUI"
    containerGui.Parent = (rs:IsStudio() and ps.LocalPlayer.PlayerGui) or gethui()
    containerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    containerGui.ResetOnSpawn = false

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = containerGui
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)

    local padding = Instance.new("UIPadding")
    padding.Parent = containerGui
    padding.PaddingBottom = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)

    return containerGui
end

local function object(class, properties)
    local localObject = Instance.new(class)
    pcall(function()
        localObject.BorderSizePixel = 0
        localObject.BackgroundColor3 = Color3.fromRGB(255,255,255)
        localObject.AutoButtonColor = false
    end)
    for property, value in next, properties do
        localObject[property] = value
    end
    local methods = {}
    function methods:object(class, properties)
        if not properties["Parent"] then
            properties.Parent = localObject
        end
        return object(class, properties)
    end
    function methods:round(radius)
        radius = radius or 4
        object("UICorner", { Parent = localObject, CornerRadius = UDim.new(0, radius) })
        return methods
    end
    function methods:tween(mutations)
        ts:Create(localObject, TweenInfo.new(0.25), mutations):Play()
    end
    methods.AbsoluteObject = localObject
    return setmetatable(methods, {
        __index = function(_, k) return localObject[k] end,
        __newindex = function(_, k, v) localObject[k] = v end,
    })
end

local notifications = {
    theme = "dark",
    colorSchemes = {
        dark = {
            Main = Color3.fromRGB(40, 40, 45),
            Secondary = Color3.fromRGB(30, 30, 35),
            Icon = Color3.fromRGB(255, 255, 255),
            Text = Color3.fromRGB(255, 255, 255),
            SecondaryText = Color3.fromRGB(200, 200, 200),
            Accept = Color3.fromRGB(96, 205, 255),
            Dismiss = Color3.fromRGB(60, 60, 65)
        }
    }
}

function notifications:notify(options)
    local theme = self.colorSchemes[notifications.theme]
    local hasButtons = not not (options.Accept or options.Dismiss)
    options.Title = options.Title or "Notification"

    if not hasButtons then
        options.Length = options.Length or 3
    end

    local paddingLeft = 60
    local contentWidth = 400 - paddingLeft - 15 
    local function getTextSize(text, fontSize, font)
        return tsService:GetTextSize(text, fontSize, font, Vector2.new(contentWidth, 1000))
    end

    local titleSize = getTextSize(options.Title, 18, Enum.Font.SourceSansSemibold)
    local descSize = nil
    if options.Description then
        descSize = getTextSize(options.Description, 18, Enum.Font.SourceSans)
    end

    local titleHeight = 28
    local descHeight = descSize and math.max(descSize.Y, 18) or 0
    local buttonsHeight = hasButtons and 44 or 0
    local totalHeight = titleHeight + descHeight + buttonsHeight + 20

    local finalHeight = math.max(totalHeight, hasButtons and 100 or 56)
    local finalWidth = 400
    local neededWidth = math.max(titleSize.X + 70, descSize and descSize.X + 70 or 0, 230)
    finalWidth = math.clamp(neededWidth, 230, 400)

    local mainFrame = object("Frame", {
        Size = UDim2.fromOffset(finalWidth, finalHeight),
        Position = UDim2.new(1, -20, 1, -10),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = theme.Main,
        Visible = false,
        BackgroundTransparency = 1,
        Parent = getContainer()
    }):round()

    local content = mainFrame:object("Frame", {
        Size = UDim2.new(1, 0, 1, hasButtons and -44 or 0),
        BackgroundTransparency = 1
    })

    local icon = content:object("ImageLabel", {
        Image = "rbxassetid://123416041901566",
        BackgroundTransparency = 1,
        ImageColor3 = theme.Icon,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 15, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        ImageTransparency = 1
    })
    if options.Icon then
        local iconStr = tostring(options.Icon)
        if iconStr:match("^%d+$") then
            icon.Image = "rbxassetid://" .. iconStr
        elseif iconStr:match("^https?://") then
            icon.Image = iconStr
        end
    end

    local title = content:object("TextLabel", {
        TextColor3 = theme.Text,
        Font = Enum.Font.SourceSansSemibold,
        TextSize = 18,
        Position = UDim2.new(0, 60, 0, 10),
        Size = UDim2.new(1, -70, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Text = options.Title,
        RichText = true,
        TextTransparency = 1
    })

    local description = nil
    if options.Description then
        description = content:object("TextLabel", {
            TextColor3 = theme.SecondaryText,
            Font = Enum.Font.SourceSans,
            TextSize = 18,
            Position = UDim2.new(0, 60, 0, 32),
            Size = UDim2.new(1, -70, 0, descHeight),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Text = options.Description,
            TextWrapped = true,
            RichText = true,
            TextTransparency = 1
        })
    end

    local buttonContainer = nil
    if hasButtons then
        buttonContainer = mainFrame:object("Frame", {
            Size = UDim2.new(1, 0, 0, 44),
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            BackgroundColor3 = theme.Secondary,
            BackgroundTransparency = 1
        }):round()
    end

    local acceptBtn, dismissBtn = nil, nil
    if options.Accept then
        options.Accept.Callback = options.Accept.Callback or function() end
        acceptBtn = buttonContainer:object("TextButton", {
            Size = UDim2.new(0, 100, 0.5, 0),
            BackgroundColor3 = theme.Accept,
            TextColor3 = theme.Text,
            Font = Enum.Font.SourceSans,
            TextSize = 18,
            Text = options.Accept.Text or "Yes",
            BackgroundTransparency = 1,
            TextTransparency = 1
        }):round()
    end
    if options.Dismiss then
        options.Dismiss.Callback = options.Dismiss.Callback or function() end
        dismissBtn = buttonContainer:object("TextButton", {
            Size = UDim2.new(0, 100, 0.5, 0),
            BackgroundColor3 = theme.Dismiss,
            TextColor3 = theme.Text,
            Font = Enum.Font.SourceSans,
            TextSize = 18,
            Text = options.Dismiss.Text or "No",
            BackgroundTransparency = 1,
            TextTransparency = 1
        }):round()
    end

    local maxBtnWidth = finalWidth * 0.4
    if acceptBtn then
        local btnWidth = math.min(acceptBtn.TextBounds.X + 20, maxBtnWidth)
        acceptBtn.Size = UDim2.fromOffset(btnWidth, 22)
    end
    if dismissBtn then
        local btnWidth = math.min(dismissBtn.TextBounds.X + 20, maxBtnWidth)
        dismissBtn.Size = UDim2.fromOffset(btnWidth, 22)
    end

    if acceptBtn and dismissBtn then
        local totalBtnWidth = acceptBtn.AbsoluteSize.X + dismissBtn.AbsoluteSize.X + 10
        local startX = (finalWidth - totalBtnWidth) / 2
        acceptBtn.Position = UDim2.new(0, startX, 0.5, 0)
        acceptBtn.AnchorPoint = Vector2.new(0, 0.5)
        dismissBtn.Position = UDim2.new(0, startX + acceptBtn.AbsoluteSize.X + 10, 0.5, 0)
        dismissBtn.AnchorPoint = Vector2.new(0, 0.5)
    elseif acceptBtn then
        acceptBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
        acceptBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    elseif dismissBtn then
        dismissBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
        dismissBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    local closing = false
    local closeFunc
    closeFunc = function()
        if closing then return end
        closing = true
        task.spawn(function()
            icon:tween{ImageTransparency = 1}
            title:tween{TextTransparency = 1}
            if description then description:tween{TextTransparency = 1} end
            if acceptBtn then acceptBtn:tween{BackgroundTransparency = 1, TextTransparency = 1} end
            if dismissBtn then dismissBtn:tween{BackgroundTransparency = 1, TextTransparency = 1} end
            task.wait(0.15)
            if buttonContainer then buttonContainer:tween{BackgroundTransparency = 1} end
            task.wait(0.1)
            mainFrame:tween{BackgroundTransparency = 1}
            task.wait(0.2)
            mainFrame.AbsoluteObject:Destroy()
        end)
    end

    if acceptBtn then
        acceptBtn.MouseButton1Click:Connect(function()
            options.Accept.Callback()
            closeFunc()
        end)
    end
    if dismissBtn then
        dismissBtn.MouseButton1Click:Connect(function()
            options.Dismiss.Callback()
            closeFunc()
        end)
    end

    mainFrame.Visible = true
    task.spawn(function()
        mainFrame:tween{BackgroundTransparency = 0.5}
        task.wait(0.1)
        if buttonContainer then buttonContainer:tween{BackgroundTransparency = 0.5} end
        task.wait(0.15)
        icon:tween{ImageTransparency = 0}
        title:tween{TextTransparency = 0}
        if description then description:tween{TextTransparency = 0} end
        if acceptBtn then acceptBtn:tween{BackgroundTransparency = 0.5, TextTransparency = 0} end
        if dismissBtn then dismissBtn:tween{BackgroundTransparency = 0.5, TextTransparency = 0} end

        if not hasButtons and options.Length then
            task.wait(options.Length)
            if not closing then closeFunc() end
        end
    end)
end

function notifications:notification(options) self:notify(options) end
function notifications:message(options) self:notify(options) end

local function notify(...)
    local args = {...}
    task.spawn(function()
        local options = {}
        if #args == 1 and type(args[1]) == "table" then
            options = args[1]
        elseif #args == 3 then
            options.Title = tostring(args[1])
            options.Description = tostring(args[2])
            options.Length = tonumber(args[3]) or 3
        elseif #args == 2 then
            options.Title = tostring(args[1])
            options.Description = tostring(args[2])
        elseif #args == 1 then
            options.Description = tostring(args[1])
        end
        notifications:notify(options)
    end)
end

getgenv().notify = notify
return notify
