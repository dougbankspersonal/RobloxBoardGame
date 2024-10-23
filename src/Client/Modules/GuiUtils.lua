--[[
    GuiUtils is a collection of utility functions for creating common/consistent GUI elements.
    It is used by the client to create the UI for the game.

    FIXME(dbanks) Right now these elements are fugly/bare bones functional.  We want to go thru
    and make them nice.
    Also I expect there will be a lot of custom/shared widgets here, so we might want to split this
    into multiple files, add a subdir for "common gui elements" and dump it all in there, etc.
]]

local GuiUtils = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local TweenHandling = require(RobloxBoardGameClient.Modules.TweenHandling)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)

local Cryo = require(ReplicatedStorage.Cryo)

local globalLayoutOrder = 0

export type InstanceOptions = {
    [string]: any,
}

local function applyInstanceOptions(instance: Instance, opt_defaultOptions: InstanceOptions?, opt_instanceOptions: InstanceOptions?)
    assert(instance, "Should have instance")
    local defaultOptions = opt_defaultOptions or {}
    local instanceOptions = opt_instanceOptions or {}

    Utils.debugPrint("GuiUtils", "applyInstanceOptions: defaultOptions = ", defaultOptions)
    Utils.debugPrint("GuiUtils", "applyInstanceOptions: instanceOptions = ", instanceOptions)

    local finalOptions = Cryo.Dictionary.join(defaultOptions, instanceOptions)

    for key, value in pairs(finalOptions) do
        -- Note: I could pcall this to make it not die if you use a bad property name but I'd rather things fail so
        -- you notice something is wrong.
        instance[key] = value
    end
end

local function updateButtonWhenActiveChanges(button: GuiButton, onActive: (GuiObject) -> nil, onInactive: (GuiObject) -> nil)
    assert(button, "Should have a button")

    button.Changed:Connect(function(propertyName)
        if propertyName == "Active" then
            if button.Active then
                onActive(button)
                button.AutoButtonColor = true
            else
                onInactive(button)
                button.AutoButtonColor = false
            end
        end
    end)
end

local function removeInactiveOverlay(parent: Frame)
    local overlay = parent:FindFirstChild(GuiConstants.inactiveOverlayName)
    if overlay then
        overlay:Destroy()
    end
end

local function addInactiveOverlay(parent: Frame)
    local overlay = parent:FindFirstChild(GuiConstants.inactiveOverlayName)
    if not overlay then
        overlay = Instance.new("Frame")
        overlay.Name = GuiConstants.inactiveOverlayName
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.Position = UDim2.fromScale(0.5, 0.5)
        overlay.AnchorPoint = Vector2.new(0.5, 0.5)
        overlay.BackgroundColor3 = Color3.new(1, 1, 1)
        overlay.BackgroundTransparency = 0.5
        overlay.Parent = parent
        overlay.ZIndex = GuiConstants.itemLabelOverlayZIndex
        overlay.BorderSizePixel = 0
        GuiUtils.addCorner(overlay)
    end
    return overlay
end

 function GuiUtils.addFrameInContainer (parent: Frame, name: string, opt_frameOptions: InstanceOptions?, opt_containerOptions: InstanceOptions?): (Frame, Frame)
    local container = Instance.new("Frame")
    applyInstanceOptions(container, {
        Name = GuiConstants.frameContainerName,
        Parent = parent,
        AutomaticSize = Enum.AutomaticSize.XY,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
    }, opt_containerOptions)

    local frame = Instance.new("Frame")

    local instanceOptions = {
        Name = name,
        Parent = container,
        BorderSizePixel = 0,
    }
    applyInstanceOptions(frame, instanceOptions, opt_frameOptions)

    GuiUtils.addCorner(frame)

    return container, frame
end

 function GuiUtils.getMainScreenGui(): ScreenGui
    local localPlayer = Players.LocalPlayer
    local mainScreenGui = localPlayer:FindFirstChild("MainScreenGui", true)
    assert(mainScreenGui, "Should have a mainScreenGui")
    return mainScreenGui
end

 function GuiUtils.getUberBackground (): Frame
    local mainScreenGui = GuiUtils.getMainScreenGui()
    local uberBackground = mainScreenGui:FindFirstChild(GuiConstants.uberBackgroundName, true)
    assert(uberBackground, "Should have a uberBackground")
    return uberBackground
end

 function GuiUtils.getMainFrame (): Frame?
    local mainScreenGui = GuiUtils.getMainScreenGui()
    local mainFrame = mainScreenGui:FindFirstChild(GuiConstants.mainFrameName, true)
    assert(mainFrame, "Should have a mainFrame")
    return mainFrame
end

 function GuiUtils.getContainingScrollingFrame (): Frame?
    local mainScreenGui = GuiUtils.getMainScreenGui()
    local containingScrollingFrameName = mainScreenGui:FindFirstChild(GuiConstants.containingScrollingFrameName, true)
    assert(containingScrollingFrameName, "Should have a containingScrollingFrameName")
    return containingScrollingFrameName
end

 function GuiUtils.italicize (text: string): string
    return "<i>" .. text .. "</i>"
end

 function GuiUtils.bold (text: string): string
    return "<b>" .. text .. "</b>"
end

function GuiUtils.addUIPadding(guiObject: GuiObject, opt_instanceOptions: InstanceOptions?): UIPadding
    local uiPadding = Instance.new("UIPadding")

    applyInstanceOptions(uiPadding, {
        Parent = guiObject,
        Name = "UniformPadding",
        PaddingLeft = GuiConstants.standardPadding,
        PaddingRight = GuiConstants.standardPadding,
        PaddingTop = GuiConstants.standardPadding,
        PaddingBottom = GuiConstants.standardPadding,
    }, opt_instanceOptions)

    return uiPadding
end

 function GuiUtils.addStandardMainFramePadding(frame: Frame): UIPadding
    return GuiUtils.addUIPadding(frame, {
        PaddingLeft = GuiConstants.mainFrameToContentPadding,
        PaddingRight = GuiConstants.mainFrameToContentPadding,
        PaddingTop = GuiConstants.mainFrameToContentPadding,
        PaddingBottom = GuiConstants.mainFrameToContentPadding,
    })
end

 function GuiUtils.addUIGradient(frame:Frame, colorSequence: ColorSequence, opt_instanceOptions: InstanceOptions?): UIGradient
    local uiGradient = Instance.new("UIGradient")
    local instanceOptions = {
        Parent = frame,
        Color = colorSequence,
        Rotation = 90,
    }

    applyInstanceOptions(uiGradient, instanceOptions, opt_instanceOptions)
end

 function GuiUtils.centerInParent(guiObject: GuiObject)
    guiObject.Position = UDim2.fromScale(0.5, 0.5)
    guiObject.AnchorPoint = Vector2.new(0.5, 0.5)
end

function GuiUtils.getCanvasPositionYToShowBottomOfVerticalScroll(scrollingFrame: ScrollingFrame): number
    local canvasSize = scrollingFrame.AbsoluteCanvasSize
    local frameHeight = scrollingFrame.AbsoluteSize.Y
    assert(typeof(frameHeight) == "number", "Should have number frameHeight")
    local canvasHeight = canvasSize.Y
    assert(typeof(canvasHeight) == "number", "Should have number canvasHeight")
    -- "CanvasPosition" is the location in the canvas that appears at the top left of the
    -- scrolling frame.
    -- If canvasFrame height is less than absolute canvas size, we can't scroll: just return 0.
    if canvasHeight <= frameHeight then
        return 0
    end
    -- we want the canvas height, less the height of the frame.
    return canvasHeight - frameHeight
end

function GuiUtils.scrollingFrameIsScrolledToBottom(scrollingFrame: ScrollingFrame): boolean
    local canvasSize = scrollingFrame.AbsoluteCanvasSize
    local frameSize = scrollingFrame.AbsoluteSize
    local canvasHeight = canvasSize.Y
    local frameHeight = frameSize.Y

    -- if canvas is shorter than frame, we are at the bottom.
    if canvasHeight <= frameHeight then
        return true
    end

    local canvasPosition = scrollingFrame.CanvasPosition
    local canvasY = canvasPosition.Y
    -- if canvas position is s.t. position + frameHeigth = canvasHeight, we are at the bottom.
    if canvasY + frameHeight == canvasHeight then
        return true
    end
    return false
end

 function GuiUtils.getNextLayoutOrder(parent:Instance): number
    local layoutOrder
    local nextLayourOrder = parent:FindFirstChild(GuiConstants.layoutOrderGeneratorName)
    if nextLayourOrder then
        layoutOrder = nextLayourOrder.Value
        nextLayourOrder.Value = nextLayourOrder.Value + 1
    else
        layoutOrder = globalLayoutOrder
        globalLayoutOrder = globalLayoutOrder + 1
    end
    return layoutOrder
end

 function GuiUtils.addLayoutOrderGenerator(parent:Instance)
    local layoutOrderGenerator = Instance.new("IntValue")
    layoutOrderGenerator.Parent = parent
    layoutOrderGenerator.Value = 0
    layoutOrderGenerator.Name = GuiConstants.layoutOrderGeneratorName
end

-- Make a text label, standardized look & feel.
 function GuiUtils.addTextLabel(parent: Instance, text: string, opt_instanceOptions: InstanceOptions?): TextLabel
    local textLabel = Instance.new("TextLabel")

    applyInstanceOptions(textLabel, {
        Name = GuiConstants.textLabelName,
        Parent = parent,
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromScale(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Text = text,
        TextSize = GuiConstants.textLabelFontSize,
        Font = GuiConstants.defaultFont,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        LayoutOrder = GuiUtils.getNextLayoutOrder(parent),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, opt_instanceOptions)

    return textLabel
end

-- Make a text box, standardized look & feel.
 function GuiUtils.addTextBox(parent: Instance, opt_instanceOptions: InstanceOptions?): TextBox
    local textBox = Instance.new("TextBox")

    GuiUtils.addUIPadding(textBox)
    GuiUtils.addCorner(textBox)

    applyInstanceOptions(textBox, {
        Name = GuiConstants.textBoxName,
        Parent = parent,
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromScale(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = GuiConstants.textBoxFontSize,
        BorderSizePixel = 0,
        BackgroundTransparency = 0,
        BackgroundColor3 = Color3.new(0.8, 0.8, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, opt_instanceOptions)

    return textBox
end

export type CheckboxOptions = {
    cornerRadius: UDim?,
    mark: string?,
    onOnly: boolean?,
}

local updateCheckboxLook = function(checkbox: TextButton, isOn: boolean)
    local stringValue = checkbox:FindFirstChildWhichIsA("StringValue")
    assert(stringValue, "Should have stringValue")

    if isOn then
        checkbox.Text = stringValue.Value
    else
        checkbox.Text = ""
    end
end

local toggleCheckbox = function(checkbox: TextButton, callback: (boolean))
    assert(checkbox, "Should have checkbox")
    assert(callback, "Should have callback")

    local isOn = (checkbox.Text ~= "")
    isOn = not isOn
    updateCheckboxLook(checkbox, isOn)
    callback(isOn)
end

 function GuiUtils.addCheckbox(parent:Frame, startValue: boolean, callback: (boolean), opt_checkboxOptions: CheckboxOptions?, opt_instanceOptions: InstanceOptions?)
    local checkboxOptions = opt_checkboxOptions or {}

    local mark = checkboxOptions.mark or GuiConstants.checkMarkString

    local checkbox = Instance.new("TextButton")
    local stringValue = Instance.new("StringValue")
    stringValue.Parent = checkbox
    stringValue.Value = mark

    applyInstanceOptions(checkbox, {
        Name = GuiConstants.checkboxName,
        Parent = parent,
        Size = UDim2.fromOffset(GuiConstants.checkboxSize, GuiConstants.checkboxSize),
        Position = UDim2.fromScale(0, 0),
        TextSize = 20,
        BorderSizePixel = 2,
        BackgroundColor3 = Color3.new(0.8, 0.8, 1),
        AutoButtonColor = true,
        Active = true,
    }, opt_instanceOptions)

    updateCheckboxLook(checkbox, startValue)

    GuiUtils.addCorner(checkbox, {
        CornerRadius = checkboxOptions.cornerRadius,
    })

    checkbox.Activated:Connect(function()
        if checkboxOptions.onOnly then
            if checkbox.Text == "" then
                toggleCheckbox(checkbox, callback)
            end
        else
            toggleCheckbox(checkbox, callback)
        end
    end)

    return checkbox
end

 function GuiUtils.addRadioButtonFamily(parent: Frame, options: {string}, startValue: number, callback: (number))
    local allButtonsStack = Instance.new("Frame")
    allButtonsStack.BackgroundTransparency = 1
    allButtonsStack.AutomaticSize = Enum.AutomaticSize.XY
    allButtonsStack.BorderSizePixel = 0
    allButtonsStack.Size = UDim2.fromScale(0, 0)
    allButtonsStack.Parent = parent
    allButtonsStack.Name = "AllButtonsStack"

    local currentValue = startValue

    GuiUtils.addUIListLayout(allButtonsStack, {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    })

    local radioButtons = {}

    local radioButtonCheckboxOptions = {
        cornerRadius = UDim.new(0.5, 0),
        mark = GuiConstants.bulletString,
        onOnly = true,
    } :: CheckboxOptions


    for index, option in options do
        local buttonWithLabelFrame = Instance.new("Frame")
        buttonWithLabelFrame.BackgroundTransparency = 1
        buttonWithLabelFrame.AutomaticSize = Enum.AutomaticSize.XY
        buttonWithLabelFrame.BorderSizePixel = 0
        buttonWithLabelFrame.Size = UDim2.fromScale(0, 0)
        buttonWithLabelFrame.Parent = allButtonsStack
        buttonWithLabelFrame.Name = "ButtonWithLabelFrame"

        GuiUtils.addUIListLayout(buttonWithLabelFrame, {
            FillDirection = Enum.FillDirection.Horizontal,
        })

        local instanceOptions = {
            Name = "RadioButton_" .. index,
        }

        local radioButton = GuiUtils.addCheckbox(buttonWithLabelFrame, index == startValue, function(checked: boolean)

            if checked then
                if currentValue ~= index then
                    currentValue = index
                    callback(index)
                    -- Unset everyone else.
                    for otherIndex, otherRadioButton in radioButtons do
                        if otherIndex ~= index then
                            otherRadioButton.Text = ""
                        end
                    end
                end
            end
        end, radioButtonCheckboxOptions, instanceOptions)
        table.insert(radioButtons, radioButton)

        GuiUtils.addTextLabel(buttonWithLabelFrame, option, {
            TextSize = GuiConstants.radioButtonLabelFontSize,
            AutomaticSize = Enum.AutomaticSize.XY,
            RichText = true,
        })
    end
end


-- Conveniencce for adding ui list layout.
-- Defaults to vertical fill direction, vertical align center, horizontal align left.
-- This can be overridden with options.
-- Defaults to center/center.
 function GuiUtils.addUIListLayout(frame: Frame, opt_instanceOptions: InstanceOptions?) : UIListLayout
    local uiListLayout = Instance.new("UIListLayout")

    applyInstanceOptions(uiListLayout, {
        Name = "UIListLayout",
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = frame,
        Padding = GuiConstants.defaultUIListLayoutPadding,
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, opt_instanceOptions)

    return uiListLayout
end

-- Make a row spanning the screen left to right.
-- Give it a layout order so it sorts properly with other rows.
-- Also has layout order generator so kids naturally sort properly.
 function GuiUtils.addRow(parent:Instance,
        rowName: string): GuiObject
    assert(parent, "Should have a parent")
    assert(rowName, "Should have a rowName")

    -- Row uses scale for width.  That's a problem if ancecstor is autosized x and everyone in between in scale sizing.
    local walker = parent
    local nameHistory = {}
    while true do
        if walker == nil then
            break
        end
        if walker.ClassName == "ScreenGui" then
            break
        end
        table.insert(nameHistory, walker.Name)
        if GuiUtils.isAutosizingInX(walker) then
            -- bad
            local badNameHistory = table.concat(nameHistory, " -> ")
            assert(false, "Row has ancestor with autosize X and all scale in between: " .. badNameHistory)
        end
        if walker.Size.X.Scale == 0 then
            -- Things are good.
            break
        end
        -- Check the parent.
        walker = walker.Parent
    end

    local row = Instance.new("Frame")
    row.Name = rowName
    row.Parent = parent
    row.Size = UDim2.new(1, 0, 0, 0)
    row.Position = UDim2.fromScale(0, 0)
    row.BorderSizePixel = 0
    row.LayoutOrder = GuiUtils.getNextLayoutOrder(parent)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1.0

    -- Rows usually contain ordered list of widgets, add a layout order generator.
    GuiUtils.addLayoutOrderGenerator(row)

    return row
end


function GuiUtils.addCorner(parent: Frame, opt_instanceOptions: InstanceOptions?): UICorner
    local uiCorner = Instance.new("UICorner")

    applyInstanceOptions(uiCorner, {
        Parent = parent,
        CornerRadius = UDim.new(0, GuiConstants.standardCornerSize),
    }, opt_instanceOptions)

    return uiCorner
end

function GuiUtils.addTextButtonInContainer(parent: Frame, name: string, opt_buttonOptions: InstanceOptions?, opt_containerOptions: InstanceOptions?): (Frame, TextButton)
    local container = Instance.new("Frame")
    applyInstanceOptions(container, {
        Parent = parent,
        Name = GuiConstants.textButtonContainerName,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = GuiUtils.getNextLayoutOrder(parent),
    }, opt_containerOptions)

    local textButton = Instance.new("TextButton")
    GuiUtils.addCorner(textButton)

    local buttonOptions = {
        Text = "",
        Name = name,
        Parent = container,
        Font = GuiConstants.defaultFont,
        TextColor3 = GuiConstants.buttonTextColor,
        BackgroundColor3 = GuiConstants.buttonBackgroundColor,
        BorderSizePixel = 1,
    }
    applyInstanceOptions(textButton, buttonOptions, opt_buttonOptions)

    -- Add active/inactive logic.
    updateButtonWhenActiveChanges(textButton, function(_)
        removeInactiveOverlay(container)
    end, function(_)
        addInactiveOverlay(container)
    end)

    return container, textButton
end

-- Make a button with common look & feel.
 function GuiUtils.addStandardTextButtonInContainer(parent: Instance, text: string, callback: () -> (), opt_buttonOptions: InstanceOptions?, opt_containerOptions: InstanceOptions?): (Frame, Instance)
    local container, textButton = GuiUtils.addTextButtonInContainer(parent, GuiConstants.textButtonName, {
        Text = text,
    }, opt_containerOptions)

    applyInstanceOptions(textButton, {
        Size = UDim2.fromOffset(0, GuiConstants.textButtonHeight),
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 14,
        AutoButtonColor = true,
        Active = true,
    }, opt_buttonOptions)

    textButton.Activated:Connect(function()
        if not textButton.Active then
            return
        end
        callback()
    end)

    GuiUtils.addUIPadding(textButton, {
        PaddingRight = GuiConstants.buttonInternalSidePadding,
        PaddingLeft = GuiConstants.buttonInternalSidePadding,
        PaddingTop = GuiConstants.noPadding,
        PaddingBottom = GuiConstants.noPadding,
    })

    return container, textButton
end

 function GuiUtils.getGameName(gameId: CommonTypes.GameId): string?
    local gameDetails = GameDetails.getGameDetails(gameId)
    if gameDetails then
        return gameDetails.name
    else
        return nil
    end
end

-- An "item" is a user or a game.
-- We have a standard notion of size/style for an image for an item.
 function GuiUtils.addItemImage(parent: GuiObject, opt_instanceOptions: InstanceOptions?): ImageLabel
    assert(parent, "Should have parent")
    local imageLabel = Instance.new("ImageLabel")

    applyInstanceOptions(imageLabel, {
        Name = GuiConstants.itemImageName,
        ScaleType = Enum.ScaleType.Fit,
        BackgroundTransparency = 0,
        BackgroundColor3 = GuiConstants.imageBackgroundColor,
        Parent = parent,
        ZIndex = GuiConstants.itemLabelImageZIndex,
    }, opt_instanceOptions)

    return imageLabel
end

-- An "item" is a user or a game.
-- We have a standard notion of size/style for a text label for an item.
 function GuiUtils.addItemTextLabel(parent:GuiObject, opt_instanceOptions: InstanceOptions?): TextLabel
    local incomingInstanceOptions = opt_instanceOptions or {}
    local instanceOptions = {
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Name = GuiConstants.itemTextName,
        ZIndex = GuiConstants.itemLabelTextZIndex,
        TextColor3 = GuiConstants.widgetTextColor,
        AutomaticSize = Enum.AutomaticSize.None,
        TextYAlignment = Enum.TextYAlignment.Center,
    }
    local finalInstanceOptions = Cryo.Dictionary.join(instanceOptions, incomingInstanceOptions)

    local userTextLabel = GuiUtils.addTextLabel(parent, "", finalInstanceOptions)

    return userTextLabel
end

 function GuiUtils.addImageOverTextLabel(frame: GuiObject): (ImageLabel, TextLabel)
    assert(frame, "Should have parent")

    GuiUtils.addUIListLayout(frame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = GuiConstants.noPadding,
    })
    GuiUtils.addUIPadding(frame)

    local imageLabel = GuiUtils.addItemImage(frame, {
        LayoutOrder = 1,
    })
    local textLabel = GuiUtils.addItemTextLabel(frame, {
        LayoutOrder = 2,
    })

    return imageLabel, textLabel
end

-- We want to have the set of widgets correspond 1-1 with the given ids.
-- Which widgets need to be removed?
local function getWidgetContainersOut(widetContainers: {Instance}, itemIds: {number}): {Instance}
    local widgetContainersOut = {} :: {Instance}
    for _, widgetContainer in widetContainers do
        local widgetContainerItemIdIntValue = widgetContainer:WaitForChild("ItemId")
        assert(widgetContainerItemIdIntValue, "Should have an widgetContainerItemId")
        local widgetInItems = false
        for _, itemId in itemIds do
            if widgetContainerItemIdIntValue.Value == itemId then
                widgetInItems = true
                break
            end
        end
        if not widgetInItems then
            table.insert(widgetContainersOut, widgetContainer)
        end
    end
    return widgetContainersOut
end

-- We want to have the set of widgets correspond 1-1 with the given ids.
-- Which ids have no widgets yet?
local function getItemIdsIn(widgetContainers: {Instance}, itemIds: {number}): {number}
    local itemIdsIn = {}
    for _, itemId in itemIds do
        local itemInWidgets = false
        for _, widgetContainer in widgetContainers do
            local widgetContainerItemIdIntValue = widgetContainer:WaitForChild("ItemId")
            assert(widgetContainerItemIdIntValue, "Should have a widgetContainerItemId")
            if itemId == widgetContainerItemIdIntValue.Value then
                itemInWidgets = true
                break
            end
        end
        if not itemInWidgets then
            table.insert(itemIdsIn, itemId)
        end
    end
    return itemIdsIn
end

-- Construct the name of a widget container.  All widget containers have
-- a child "itemType" string value and a child "itemId" number value.
-- <type, id> should be globally unique.
-- Name is just "WidgetContainer_<type>_<id>
 function GuiUtils.constructWidgetContainerName(itemType: string, itemId: number): string
    assert(itemType, "Should have a itemType")
    assert(itemId, "Should have a itemId")
    return "WidgetContainer_" .. itemType .. "_" .. tostring(itemId)
end

-- If this thing is a proper widget container, what should it's name be?
-- WidgetContainer_<type>_<id>
-- If something is missing just return nil.
 function GuiUtils.getExpectedWidgetContainerName(widgetContainer: Instance): string?
    if not widgetContainer then
        return nil
    end
    local itemType = widgetContainer:FindFirstChild("ItemType")
    if not itemType then
        return nil
    end
    local itemId = widgetContainer:FindFirstChild("ItemId")
    if not itemId then
        return nil
    end
    return GuiUtils.constructWidgetContainerName(itemType.Value, itemId.Value)
end

-- All WidgetContainers have names of the form "WidgetContainer_ItemType_ItemId".
 function GuiUtils.isAWidgetContainer(instance: Instance): boolean
    if not instance:IsA("Frame") then
        return false
    end
    local expectedName = GuiUtils.getExpectedWidgetContainerName(instance)
    if not expectedName then
            return false
    end
    return expectedName == instance.Name
end

-- We are tweening a widgetContainer, we keep track of tween in some table.
-- We want a unique key for the tween: just use the type plus id of the
-- widgetContainer.
local function makeTweenKey(widgetContainer: Instance): string
    assert(widgetContainer, "Should have a widgetContainer")
    assert(GuiUtils.isAWidgetContainer(widgetContainer), "Should be a widgetContainer")
    local itemType = widgetContainer:WaitForChild("ItemType")
    local itemId = widgetContainer:WaitForChild("ItemId")
    return "Tween_" .. itemType.Value .. "_" .. tostring(itemId.Value)
end

local collectWidgetContainers = function(parent: GuiObject): {GuiObject}
    assert(parent, "Should have a parent")
    local widgetContainers = {} :: {GuiObject}
    local allKids = parent:GetChildren()
    for _, kid in allKids do
        if GuiUtils.isAWidgetContainer(kid) then
            table.insert(widgetContainers, kid)
        end
    end
    return widgetContainers
end

local collectWidgetsTweeningOut = function(parent: GuiObject): {GuiObject}
    assert(parent, "Should have a parent")
    local deadMeatFrames = {} :: {GuiObject}
    local allKids = parent:GetChildren()
    for _, kid in allKids do
        if kid.Name == GuiConstants.deadMeatTweeningOutName then
            table.insert(deadMeatFrames, kid)
        end
    end
    return deadMeatFrames
end

 function GuiUtils.updateNilWidgetContainer(parentFrame: Frame, renderEmptyList: (Frame) -> nil, cleanupEmptyList: (Frame) -> nil)
    -- How many non-nil widget containers, or guys tweening out?
    assert(parentFrame, "Should have a parentFrame")
    local widgetContainers = collectWidgetContainers(parentFrame)
    local widgetsTweeningOut = collectWidgetsTweeningOut(parentFrame)

    if #widgetContainers == 0 and #widgetsTweeningOut == 0 then
        renderEmptyList(parentFrame)
    else
        cleanupEmptyList(parentFrame)
    end
end

-- Any WidgetContainer has a type (e.g. "game button") and an id, unique within the type.
-- We have a parent frame with zero or more WidgetContainer children, all the same type.
-- We have a new/updated list of itemIds within the same type.
-- We want to make sure widgets in row match new set of ids.
-- Update the parent to remove/add widgets so the widgets match the incoming list of things.
-- Return a list of any tweens we created so we can murder them later if we need to.
-- If "skipTweens" is true, just slap things in there, no tweens.
 function GuiUtils.updateWidgetContainerChildren(parentFrame:Frame,
        itemIds:{number},
        makeWidgetContainerForItem: (Instance, number) -> Instance,
        renderEmptyList: (Frame) -> nil,
        cleanupEmptyList: (Frame) -> nil,
        skipTweens: boolean)
    local tweensToKill = {} :: TweenHandling.TweensToKill
    assert(parentFrame, "parentFrame should exist")
    -- Get all the existing widgets containers.
    local widgetContainers = collectWidgetContainers(parentFrame)

    -- Figure out which widgets need to go, and what new widgets we need.
    local widgetContainersOut = getWidgetContainersOut(widgetContainers, itemIds)
    local itemIdsIn = getItemIdsIn(widgetContainers, itemIds)

    if skipTweens then
        -- Remove the old, add the new.
        for _, widgetContainer in widgetContainersOut do
            widgetContainer:Destroy()
        end
        for _, itemId in itemIdsIn do
            local itemWidgetContainer = makeWidgetContainerForItem(parentFrame, itemId)
            assert(itemWidgetContainer, "Should have widgetContainer")
            -- It is required that the widget container has an int value child with
            -- name "ItemId" and value equal to itemId.
            assert(itemWidgetContainer.ItemId, "WidgetContainer should have an ItemId")
            assert(itemWidgetContainer.ItemId.Value == itemId, "WidgetContainer.ItemId.Value should be itemId")

            GuiUtils.addUIScale(itemWidgetContainer)
        end

        GuiUtils.updateNilWidgetContainer(parentFrame, renderEmptyList, cleanupEmptyList)
    else
        local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
        -- Tween out unused widgets.
        for _, widgetContainer in widgetContainersOut do
            local uiScale = widgetContainer:FindFirstChild("UIScale")
            if not uiScale then
                GuiUtils.addUIScale(widgetContainer)
            end
            local tween = TweenService:Create(uiScale, tweenInfo, {Scale = 0})
            local key = makeTweenKey(widgetContainer)
            -- Cancel any existing tweens on this fool.
            TweenHandling.cancelTween(key)

            tweensToKill[key] = tween

            -- Rename them so we don't find them again and re-tween.
            widgetContainer.Name = GuiConstants.deadMeatTweeningOutName

            tween.Completed:Connect(function(_)
                widgetContainer:Destroy()
                GuiUtils.updateNilWidgetContainer(parentFrame, renderEmptyList, cleanupEmptyList)
            end)
            tween:Play()
        end

        for _, itemId in itemIdsIn do
            local itemWidgetContainer = makeWidgetContainerForItem(parentFrame, itemId)
            assert(itemWidgetContainer, "Should have widgetContainer")
            -- It is required that the widget container has an int value child with
            -- name "ItemId" and value equal to itemId.
            assert(itemWidgetContainer.ItemId, "WidgetContainer should have an ItemId")
            assert(itemWidgetContainer.ItemId.Value == itemId, "WidgetContainer.ItemId.Value should be itemId")

            GuiUtils.addUIScale(itemWidgetContainer)

            local tween = TweenService:Create(itemWidgetContainer.UIScale, tweenInfo, {Scale = 1})
            local key = makeTweenKey(itemWidgetContainer)
            tweensToKill[key] = tween

            tween:Play()
        end
    end

    -- store the tweens.
    TweenHandling.saveTweens(tweensToKill)

    GuiUtils.updateNilWidgetContainer(parentFrame, renderEmptyList, cleanupEmptyList)
end

local genericIdGenerator = 0

 function GuiUtils.getNameFromUserWidgetContainer(widgetContainer: Instance): string?
    assert(widgetContainer, "Should have a widgetContainer")
    assert(GuiUtils.isAWidgetContainer(widgetContainer), "Should be a widgetContainer")

    local textLabel = widgetContainer:FindFirstChildWhichIsA("TextLabel", true)
    if not textLabel then
        return nil
    end
    return textLabel.Text
end

 function GuiUtils.removeNullStaticWidget(parent:Instance)
    if parent:FindFirstChild(GuiConstants.nullStaticWidgetName) then
        parent:FindFirstChild(GuiConstants.nullStaticWidgetName):Destroy()
    end
end

-- Make standard "nothing there" indicator.
-- Idempotent: will remove old/previous one if present.
 function GuiUtils.addNullStaticWidget(parent: Instance, message: string, opt_instanceOptions: InstanceOptions?): Frame
    -- Make sure old label is gone.
    GuiUtils.removeNullStaticWidget(parent)

    local instanceOptions = {
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = true,
        TextWrapped = true,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.None,
        TextColor3 = GuiConstants.widgetTextColor,
        Name = GuiConstants.nullStaticWidgetName,
    }

    local textLabel = GuiUtils.addTextLabel(parent, message)
    applyInstanceOptions(textLabel, instanceOptions, opt_instanceOptions)
    GuiUtils.addCorner(textLabel)
    GuiUtils.addUIPadding(textLabel)

    return textLabel
end

 function GuiUtils.makeWidgetContainer(parent:GuiObject, widgetType: string, opt_itemId: number?): GuiObject
    assert(parent, "Should have a parent")
    assert(widgetType, "Should have a widgetType")

    local itemId
    if opt_itemId then
        itemId = opt_itemId
    else
        itemId = genericIdGenerator
        genericIdGenerator = genericIdGenerator + 1
    end

    local widgetContainer = Instance.new("Frame")
    widgetContainer.Parent = parent
    widgetContainer.Size = UDim2.fromOffset(0, 0)
    widgetContainer.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
    widgetContainer.BorderSizePixel = 0
    widgetContainer.Name = GuiUtils.constructWidgetContainerName(widgetType, itemId)
    widgetContainer.LayoutOrder = GuiUtils.getNextLayoutOrder(parent)
    widgetContainer.AutomaticSize = Enum.AutomaticSize.XY
    widgetContainer.BackgroundTransparency = 1

    local intValue = Instance.new("IntValue")
    intValue.Value = itemId
    intValue.Parent = widgetContainer
    intValue.Name = "ItemId"

    local stringValue = Instance.new("StringValue")
    stringValue.Value = widgetType
    stringValue.Parent = widgetContainer
    stringValue.Name = "ItemType"

    return widgetContainer
end

 function GuiUtils.updateTextLabel(textLabel: TextLabel, text: string): boolean
    assert(textLabel, "Should have a textLabel")
    if textLabel.Text == text then
        return false
    end
    textLabel.Text = text
    return true
end

 function GuiUtils.getOptionValue(gameOption: CommonTypes.GameOption, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions): string?
    -- Does this particular option have a non-default value?
    local opt_nonDefaultGameOption = nonDefaultGameOptions[gameOption.gameOptionId]

    if opt_nonDefaultGameOption then
        -- Yes it does.  How we write about the value turns on whether the option is a bool or has variants.
        if gameOption.opt_variants then
            -- This is a variant option: the value of the non-default option is an index.
            assert(typeof(opt_nonDefaultGameOption) == "number", "Should have a number")
            local variant = gameOption.opt_variants[opt_nonDefaultGameOption]
            assert(variant, "Should have a variant")
            return variant.name
        end

        -- It's a bool.
        assert(typeof(opt_nonDefaultGameOption) == "boolean", "Should have a boolean")
        if opt_nonDefaultGameOption then
            return "Yes"
        else
            return "No"
        end
    end

    -- We are using default value.
    -- For variants, it's the first.
    if gameOption.opt_variants then
        assert(#gameOption.opt_variants > 0, "Should have at least one variant")
        local variant = gameOption.opt_variants[1]
        assert(variant, "Should have a variant")
        return variant.name
    end

    -- It's a bool, and default is "off"/"no"
    return "No"
end

 function GuiUtils.getGameOptionsStrings(gameId: CommonTypes.GameId, opt_nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions?): {string}
    local gameDetails = GameDetails.getGameDetails(gameId)

    local retVal = {}

    -- Game doesn't even have options: nothing to say.
    if not gameDetails.gameOptions then
        return retVal
    end

    local nonDefaultGameOptions = opt_nonDefaultGameOptions or {}

    for _, gameOption in gameDetails.gameOptions do
        local optionValue = GuiUtils.getOptionValue(gameOption, nonDefaultGameOptions)
        assert(optionValue, "Should have an optionValue")

        local optionName = gameOption.name
        assert(optionName, "Should have an optionName")
        local optionString = optionName .. ": " .. optionValue

        table.insert(retVal, optionString)
    end

    return retVal
end

function GuiUtils.getTableSizeString(gameDetails: CommonTypes.GameDetails): string
    return tostring(gameDetails.minPlayers) .. " - " .. tostring(gameDetails.maxPlayers) .. " players"
end

function GuiUtils.isAutosizingInX(guiObject: GuiObject): boolean
    assert(guiObject, "Should have a guiObject")
    return guiObject.AutomaticSize == Enum.AutomaticSize.XY or guiObject.AutomaticSize == Enum.AutomaticSize.X
end

function GuiUtils.autoSizeXUpToLimit(guiObject: GuiObject, limit: number)
    assert(guiObject, "Should have a guiObject")
    assert(limit, "Should have a limit")
    assert(GuiUtils.isAutosizingInX(guiObject), "Should have an automatic size of XY or X")

    guiObject.PropertyChanged:Connect(function(propertyName)
        if not propertyName == "AbsoluteSize" then
            return
        end
        if not GuiUtils.isAutosizingInX(guiObject) then
            return
        end
        local width = guiObject.AbsoluteSize.X
        if width > limit then
            if guiObject.AutomaticSize == Enum.AutomaticSize.XY then
                guiObject.AutomaticSize = Enum.AutomaticSize.Y
            else
                guiObject.AutomaticSize = Enum.AutomaticSize.None
            end
            local size = guiObject.Size
            local newSize = UDim2.fromOffset(limit, size.Y.Offset)
            guiObject.Size = newSize
        end
    end)
end

function GuiUtils.addGridLayout(parent:Frame, opt_instanceOptions: InstanceOptions?): UIGridLayout
    local uiGridLayout = Instance.new("UIGridLayout")
    GuiUtils.applyInstanceOptions(uiGridLayout, {
        Parent = parent,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Name = GuiConstants.uiGridLayoutName,
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellPadding = GuiConstants.cellPadding,
    }, opt_instanceOptions)
end

function GuiUtils.addScrollingItemGrid(parent:GuiObject, scrollingFrameName: string, itemSize: UDim2, numRows: number): ScrollingFrame
    local scrollingDirection
    local automaticCanvasSize
    if numRows > 1 then
        scrollingDirection = Enum.ScrollingDirection.Y
        automaticCanvasSize = Enum.AutomaticSize.Y
    else
        scrollingDirection = Enum.ScrollingDirection.X
        automaticCanvasSize = Enum.AutomaticSize.X
    end

    local scrollingFrame = GuiUtils.addStandardScrollingFrame(parent)
    scrollingFrame.ScrollingDirection = scrollingDirection
    scrollingFrame.AutomaticCanvasSize = automaticCanvasSize
    scrollingFrame.Name = scrollingFrameName
    scrollingFrame.AutomaticSize = Enum.AutomaticSize.None
    scrollingFrame.LayoutOrder = GuiUtils.getNextLayoutOrder(parent)

    GuiUtils.addUIPadding(scrollingFrame)

    local cellHeight = itemSize.Y.Offset
    Utils.debugPrint("Layout", "scrollingFrame = " , scrollingFrame)
    Utils.debugPrint("Layout", "parent = " , parent)
    Utils.debugPrint("Layout", "cellHeight = " , cellHeight)
    local totalHeight = numRows * cellHeight
    Utils.debugPrint("Layout", "totalHeight = " , totalHeight)

    if numRows > 1 then
        GuiUtils.addGridLayout(scrollingFrame, {
            CellSize = itemSize,
        })
    else
        totalHeight += GuiConstants.scrollBarThickness
        GuiUtils.addUIListLayout(scrollingFrame, {
            FillDirection = Enum.FillDirection.Horizontal,
            Wraps = false,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        })
    end

    scrollingFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    Utils.debugPrint("Layout", "scrollingFrame.Size = " , scrollingFrame.Size)

    if numRows > 1 then
        -- Fixed width, autosize height.
        scrollingFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
    else
        -- Fixed height, autosize width.
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end

    return scrollingFrame
end

function GuiUtils.getRightHandContentOffset(labelWidth: number): number
    return GuiConstants.labelToRightSideContentPaddingPx + labelWidth
end

-- Make a row.
-- On the left row has a text label.
-- On the right, row has whatever was handed in as rightHandContent.
function GuiUtils.addLabeledRow(parent: GuiObject, rowName: string, labelText: string, rightHandContentMaker: (GuiObject) -> GuiObject): GuiObject
    local row = GuiUtils.addRow(parent, rowName)
    GuiUtils.addUIListLayout(row, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = GuiConstants.labelToRightSideContentPadding,
    })

    local textLabel = GuiUtils.addTextLabel(row, labelText, {
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.fromScale(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        LayoutOrder = 1,
        Name = GuiConstants.labeledRowTextLabelName,
    })

    local rightHandContentOffset = GuiUtils.getRightHandContentOffset(textLabel.AbsoluteSize.X)
    local rightHandContent = rightHandContentMaker(row)
    assert(rightHandContent.Name == GuiConstants.rightHandContentName, "Should have rightHandContentName")
    rightHandContent.LayoutOrder = 2
    rightHandContent.Size = UDim2.new(1, -rightHandContentOffset, rightHandContent.Size.Y.Scale, rightHandContent.Size.Y.Offset)

    return row
end

function GuiUtils.alignLabeledRows(rows: {GuiObject})
    local maxWidth = 0
    for _, row in rows do
        local textLabel = row:FindFirstChild(GuiConstants.labeledRowTextLabelName)
        assert(textLabel, "Should have a textLabel")
        local width = textLabel.AbsoluteSize.X
        if width > maxWidth then
            maxWidth = width
        end
    end

    -- Set them all to max width and adjust the row content accordingly.
    for _, row in rows do
        local textLabel = row:FindFirstChild(GuiConstants.labeledRowTextLabelName)
        assert(textLabel, "Should have a textLabel")
        textLabel.Size = UDim2.fromOffset(maxWidth, textLabel.AbsoluteSize.Y)
        textLabel.AutomaticSize = Enum.AutomaticSize.None
        local rightHandContent = row:FindFirstChild(GuiConstants.rightHandContentName)
        assert(rightHandContent, "Should have a rightHandContent")
        assert(rightHandContent.AutomaticSize == Enum.AutomaticSize.None, "Should have Enum.AutomaticSize.None")
        local rightHandContentOffset = GuiUtils.getRightHandContentOffset(maxWidth)
        rightHandContent.Size = UDim2.new(1, -rightHandContentOffset, 0, rightHandContent.AbsoluteSize.Y)
    end
end

function GuiUtils.addStandardScrollingFrame(parent: Frame): ScrollingFrame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Parent = parent
    scrollingFrame.ScrollBarImageColor3 = GuiConstants.scrollBarColor
    scrollingFrame.ScrollBarImageTransparency = GuiConstants.scrollBarTransparency
    scrollingFrame.BackgroundColor3 = GuiConstants.scrollBackgroundColor
    scrollingFrame.BackgroundTransparency = 0
    scrollingFrame.ScrollBarThickness = GuiConstants.scrollBarThickness

    return scrollingFrame
end

function setBooleanValue(parent:Instance, name: string, value: boolean)
    local booleanValue = parent:FindFirstChild(name)
    if not booleanValue then
        booleanValue = Instance.new("BoolValue")
        booleanValue.Name = name
        booleanValue.Parent = parent
    end
    booleanValue.Value = value
end

function getBooleanValue(parent:Instance, name: string)
    local booleanValue = parent:FindFirstChild(name)
    assert(booleanValue, "Should have a booleanValue")
    return booleanValue.Value
end

-- Give scrolling frame the following logic:
-- If content is added to the bottom, and the user is scrolled to the bottom, then
-- tween the scroll bar to the new bottom.
-- Otherwise just slap it in there.
-- Either way hit the callback once the content is fully in there.
function GuiUtils.addSlideOutEffectToScrollingFrame(scrollingFrame:ScrollingFrame, opt_callback: ()->()?)
    -- Some sanity checks for this to work properly.
    assert(scrollingFrame.CanvasSize.Y.Scale == 0, "CanvasSize.Y.Scale should be 0")
    assert(scrollingFrame.AutomaticCanvasSize == Enum.AutomaticSize.Y, "AutomaticCanvasSize should be Y")

    -- were we at the bottom of the scrolling frame?
    local isAtBottom = GuiUtils.scrollingFrameIsScrolledToBottom(scrollingFrame)
    setBooleanValue(scrollingFrame, "IsAtBottom", isAtBottom)
    setBooleanValue(scrollingFrame, "IsBusy", false)

    export type CanvasPosition = {
        wasAtBottom: boolean,
        newTargetCanvasPosition: Vector2,
    }
    local canvasStatusQueue = {} :: {CanvasPosition}

    local function enqueuePossibleSizeChangeResponse(targetCanvasPosition: Vector2, wasAtBottom: boolean)
        table.insert(canvasStatusQueue, {
            wasAtBottom = wasAtBottom,
            newTargetCanvasPosition = targetCanvasPosition,
        })
    end

    local function maybeConsumeFromQueue()
        Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 001")
        -- Nothing in queue, no.
        if #canvasStatusQueue == 0 then
            return
        end

        Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 002")
        -- Busy, no.
        local isBusy = getBooleanValue(scrollingFrame, "IsBusy")
        if isBusy then
            return
        end

        Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 003")
        -- Remove the next target from the queue.
        local canvasStatus = table.remove(canvasStatusQueue, 1)

        -- Are we right now at the bottom of the scroll widget?
        -- Do we need a slide-in effect?

        Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 004")
        -- If target position matches current position, no.
        -- If we were not scrolled to bottom, no.
        local canSkipTweening = false
        Utils.debugPrint("MessageLog", "scrollingFrame.CanvasPosition = ", scrollingFrame.CanvasPosition)
        Utils.debugPrint("MessageLog", "canvasStatus.newTargetCanvasPosition = ", canvasStatus.newTargetCanvasPosition)

        if canvasStatus.newTargetCanvasPosition == scrollingFrame.CanvasPosition then
            Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 004.001")
            canSkipTweening = true
        elseif canvasStatus.wasAtBottom == false then
            Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 004.002")
            canSkipTweening = true
        end

        Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 005")
        -- If we can skip tweening:
        --   No changes to canvas pos.
        --   Hit the callback.
        --   Try to consume again.
        if canSkipTweening then
            if opt_callback then
                opt_callback()
            end
            maybeConsumeFromQueue()
            return
        end

        Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 006")
        -- Otherwise we are busy until the tween is done.
        setBooleanValue(scrollingFrame, "IsBusy", true)

        -- Wait here too?
        task.spawn(function()
            task.wait()
            -- Use slide out effect to get to target position.
            local movementTweenInfo = TweenInfo.new(GuiConstants.scrollingFrameSlideTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
            local t1 = TweenService:Create(scrollingFrame, movementTweenInfo, {CanvasPosition = canvasStatus.newTargetCanvasPosition})
            t1.Completed:Connect(function()
                Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 007")
                -- When the tween is done:
                -- 1. We are no longer busy.
                -- 2. Hit the callback: yes we did slide out.
                setBooleanValue(scrollingFrame, "IsBusy", false)
                if opt_callback then
                    opt_callback()
                end
                maybeConsumeFromQueue()
            end)
            Utils.debugPrint("MessageLog", "maybeConsumeFromQueue: 008")
            t1:Play()
        end)
    end

    scrollingFrame.ChildAdded:Connect(function(instance:Instance)
        Utils.debugPrint("MessageLog", "ChildAdded 001")

        -- A new gui object has been added to scrolling frame.
        -- If the user us not at the bottom of the sceen, fine, nothing to do.
        -- But maybe the user is scrolled to bottom and new content is offscreen.
        -- In that case, we want to "slide down" to show the new content.
        --
        -- This is further complicated by enqueuing logic: if a blast of new items come in
        -- all at once we don't want things to get janky.

        -- Not a gui object, don't care.
        if not instance:IsA("GuiObject") then
            return
        end

        -- Before waiting, ask: was scroll widget scrolled to bottom?
        local wasAtBottom = GuiUtils.scrollingFrameIsScrolledToBottom(scrollingFrame)

        task.spawn(function()
            task.wait()

            -- Figure out where we want the canvas to go.
            local absoluteCanvasSize = scrollingFrame.AbsoluteCanvasSize
            local scrollingFrameAbsoluteSize = scrollingFrame.AbsoluteSize

            local targetCanvasPositionY = absoluteCanvasSize.Y - scrollingFrameAbsoluteSize.Y
            local targetCanvasPosition = Vector2.new(0, targetCanvasPositionY)

            Utils.debugPrint("MessageLog", "ChildAdded absoluteCanvasSize = ", absoluteCanvasSize)
            Utils.debugPrint("MessageLog", "ChildAdded scrollingFrameAbsoluteSize = ", scrollingFrameAbsoluteSize)
            Utils.debugPrint("MessageLog", "ChildAdded targetCanvasPositionY = ", targetCanvasPositionY)
            Utils.debugPrint("MessageLog", "ChildAdded targetCanvasPosition = ", targetCanvasPosition)

            enqueuePossibleSizeChangeResponse(targetCanvasPosition, wasAtBottom)
            maybeConsumeFromQueue()
        end)
    end)
end


function GuiUtils.destroyGuiObjectChildren(parent: Instance)
    local children = parent:GetChildren()
    for _, child in pairs(children) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

function GuiUtils.addUIScale(parent: Instance)
    local uiScale = Instance.new("UIScale")
    uiScale.Name = "UIScale"
    uiScale.Parent = parent
    uiScale.Scale = 1
end

return GuiUtils