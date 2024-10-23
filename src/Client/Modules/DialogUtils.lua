-- Logic for dialogs.
-- Dialogs are a "stack": if you put up a new one while old is present, new one supercedes the old.
-- When new is cleared you will see the old again.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)
local TweenService = game:GetService("TweenService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)

local DialogUtils = {}

local dialogIdGen = 0
local backgroundTransparencyWhenVisible = 0.5

local currentBackgroundTweenOut = nil
local currentBackgroundTweenIn = nil

export type DialogId = number

export type DialogFrameWithId = {
    frame: Frame,
    dialogId: DialogId,
}

local dialogFrameWithIdStack = {} :: {DialogFrameWithId}

export type DialogButtonConfig = {
    text: string,
    callback: (() -> ())?,
}

export type DialogConfig = {
    title: string,
    description: string,
    dialogButtonConfigs: {DialogButtonConfig}?,
    makeCustomDialogContent: ((number, Frame) -> nil)?,
}

function DialogUtils.getDialogBackground(): Frame?
    local mainScreenGui = GuiUtils.getMainScreenGui()
    assert(mainScreenGui, "ScreenGui not found")
    return mainScreenGui:FindFirstChild(GuiConstants.dialogBackgroundName, true)
end

local function hideDialogBackground()
    local dialogBackground = DialogUtils.getDialogBackground()
    assert(dialogBackground, "DialogBackground not found")

    -- If we are already tweening out: done.
    if currentBackgroundTweenOut then
        return
    end

    -- If we are tweening background in, allow that to proceed: some new dialog needs it.
    if currentBackgroundTweenIn then
        return
    end

    local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
    local tweenOut = TweenService:Create(dialogBackground, tweenInfo, {BackgroundTransparency = 1})
    currentBackgroundTweenOut = tweenOut
    tweenOut.Completed:Connect(function()
        local db = DialogUtils.getDialogBackground()
        if db then
            db.Visible = false
        end

        if currentBackgroundTweenOut == tweenOut then
            currentBackgroundTweenOut = nil
        end
    end)

    tweenOut:Play()
end

function DialogUtils.cleanupDialog(dialogId: DialogId)
    Utils.debugPrint("Analytics", "cleanupDialog called, stack trace = ", debug.traceback())

    assert(dialogId, "dialogId should be provided")
    -- Already gone, forget it.
    local dialogFrame = DialogUtils.getDialogById(dialogId)
    if not dialogFrame then
        return
    end

    -- Remove from stack.
    dialogFrameWithIdStack = Cryo.List.map(dialogFrameWithIdStack, function(dfwi: DialogFrameWithId)
        if dfwi.dialogId ~= dialogId then
            return dfwi
        end
        return nil
    end)

    -- Tween it out then destroy it.
    local uiScale = dialogFrame:FindFirstChild("UIScale")
    local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
    local tweenOut = TweenService:Create(uiScale, tweenInfo, {Scale = 0})
    tweenOut.Completed:Connect(function()
        dialogFrame:Destroy()
    end)
    tweenOut:Play()

    -- if stack is now empty, hide the background.
    if #dialogFrameWithIdStack == 0 then
        hideDialogBackground()
    else
        -- Top item in the stack is now visible.
        dialogFrameWithIdStack[#dialogFrameWithIdStack].frame.Visible = true
    end
end

local function addCancelButton(dialogFrame: Frame, dialogId: DialogId)
    assert(dialogFrame, "dialogFrame should be provided")
    assert(dialogId, "dialogId should be provided")

    local cancelButton = Instance.new("ImageButton")
    cancelButton.Parent = dialogFrame
    cancelButton.ZIndex = 2
    cancelButton.Size = UDim2.fromOffset(GuiConstants.redXSize, GuiConstants.redXSize)
    cancelButton.Position = UDim2.new(1, -GuiConstants.redXSize - GuiConstants.redXMargin, 0, GuiConstants.redXMargin)
    cancelButton.Image = GuiConstants.redXImage
    cancelButton.BackgroundTransparency = 1
    cancelButton.Activated:Connect(function()
        DialogUtils.cleanupDialog(dialogId)
    end)
end


--[[
Get or make the dialog background. It is a big translucent square covering
the whole screen.  It soaks up clicks so you can't click on anything else.
]]
local function getOrMakeDialogBackground()
    local dialogBackground = DialogUtils.getDialogBackground()
    if dialogBackground then
        return dialogBackground
    end

    local mainScreenGui = GuiUtils.getMainScreenGui()
    -- Dialog background is a button so it soaks up clicks.
    dialogBackground = Instance.new("TextButton")
    dialogBackground.Position = UDim2.fromOffset(0, GuiConstants.robloxTopBarBottomPaddingPx)
    dialogBackground.Size = UDim2.new(1, 0, 1, -GuiConstants.robloxTopBarBottomPaddingPx)
    dialogBackground.BackgroundColor3 = Color3.new(0, 0, 0)
    dialogBackground.BackgroundTransparency = backgroundTransparencyWhenVisible
    dialogBackground.Parent = mainScreenGui
    dialogBackground.Name = GuiConstants.dialogBackgroundName
    dialogBackground.ZIndex = GuiConstants.dialogBackgroundZIndex
    dialogBackground.AutomaticSize = Enum.AutomaticSize.XY
    dialogBackground.Text = ""
    dialogBackground.AutoButtonColor = false
    return dialogBackground
end

--[[
Make the dialogFrame itself.
]]
local function makeDialogFrame(dialogBackground: Frame, dialogId: DialogId): Frame
    assert(dialogBackground, "dialogBackground should be provided")
    local dialogFrame = Instance.new("Frame")
    dialogFrame.Size = UDim2.fromScale(0, 0)
    dialogFrame.AutomaticSize = Enum.AutomaticSize.XY
    dialogFrame.Position = UDim2.fromScale(0.5, 0.5)
    dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dialogFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    dialogFrame.Parent = dialogBackground
    dialogFrame.Name = GuiConstants.dialogName
    dialogFrame.BorderSizePixel = 0
    dialogFrame.ZIndex = GuiConstants.dialogZIndex + dialogId
    GuiUtils.addCorner(dialogFrame)

    -- Add a ui scale underneath.
    GuiUtils.addUIScale(dialogFrame)

    return dialogFrame
end

--[[
Almost everything in dialog should be laid out top to bottom with a UI List layout.
But there's the red cancel button in upper right corner, not part of layout flow.
So children of dialogFrame are that button and a dialogContentFrame, which holds the
meat of the dialog.
This makes the dialogContentFrame.
]]
local function makeDialogContentFrame(dialogFrame: Frame): ScrollingFrame
    assert(dialogFrame, "dialogFrame should be provided")
    local dialogContentFrame = GuiUtils.addStandardScrollingFrame(dialogFrame)
    dialogContentFrame.Name = GuiConstants.dialogContentFrameName
    dialogContentFrame.Position = UDim2.fromScale(0, 0)
    dialogContentFrame.BorderSizePixel = 0
    dialogContentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    dialogContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dialogContentFrame.CanvasSize = UDim2.fromScale(0, 0)
    dialogContentFrame.ZIndex = 0
    dialogContentFrame.BackgroundColor3 = Color3.new(0.9, 0.9, 1)

    -- By default dialog is sized to be a little smaller than screen.
    -- If a dialog has makeCustomDialogContent, that function can re-size dialogContentFrame as needed.
    -- If there's just buttons, we resize after buttons have been added.
    -- Note we can't use a UDim2 with scale because this is a child of dialogFrame, which is
    -- Autosized: scale children of autosize parents don't work.
    dialogContentFrame.AutomaticSize = Enum.AutomaticSize.None
    local mainScreenGui = GuiUtils.getMainScreenGui()
    local mainScreenGuiWidth = mainScreenGui.AbsoluteSize.X
    local mainScreenGuiHeight = mainScreenGui.AbsoluteSize.Y
    dialogContentFrame.Size = UDim2.fromOffset(mainScreenGuiWidth - 2 * GuiConstants.screenToDialogPaddingPx,
        mainScreenGuiHeight - 2 * GuiConstants.screenToDialogPaddingPx)

    GuiUtils.addLayoutOrderGenerator(dialogContentFrame)

    GuiUtils.addUIPadding(dialogContentFrame, {
        PaddingLeft = GuiConstants.dialogToContentPadding,
        PaddingRight = GuiConstants.dialogToContentPadding,
        PaddingTop = GuiConstants.dialogToContentPadding,
        PaddingBottom = GuiConstants.dialogToContentPadding,
    })

    GuiUtils.addUIListLayout(dialogContentFrame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = GuiConstants.betweenRowPadding,
    })
    return dialogContentFrame
end

local function getConfigsByHeading(dialogButtonConfigs: {DialogButtonConfig}): {[string]: {DialogButtonConfig}}
    local configsByHeading = {} :: {[string]: {DialogButtonConfig}}
    for _, dialogButtonConfig in ipairs(dialogButtonConfigs) do
        local heading = dialogButtonConfig.heading or ""
        if not configsByHeading[heading] then
            configsByHeading[heading] = {}
        end
        table.insert(configsByHeading[heading], dialogButtonConfig)
    end
    return configsByHeading
end


local function applyConfigsWithHeading(dialogId: DialogId, dialogContentFrame: Frame, heading: string, dialogButtonConfigs: {DialogButtonConfig}, isFirst: boolean)
    -- For each config-with-heading:

    -- First, if heading is non-empty, add a heading.
    assert(heading, "heading should be provided")
    if heading ~= "" then
        GuiUtils.addTextLabel(dialogContentFrame, GuiUtils.bold(heading), {
            RichText = true,
            AutomaticSize = Enum.AutomaticSize.XY,
            LayoutOrder = GuiUtils.getNextLayoutOrder(dialogContentFrame),
            Name = GuiConstants.dialogHeadingTextLabel,
        })
    end

    -- Then a row that will contain the buttons.
    local dialogControlsRow = GuiUtils.addRow(dialogContentFrame, GuiConstants.dialogControlsName)
    -- button lay out left to right, wrapping if needed.
    GuiUtils.addUIListLayout(dialogControlsRow, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = GuiConstants.betweenButtonPadding,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Wraps = true,
    })

    Utils.debugPrint("Layout", "configsForHeading = ", dialogButtonConfigs)
    for _, dialogButtonConfig in ipairs(dialogButtonConfigs) do
        -- Should be properly configured.
        assert(dialogButtonConfig.text, "Should have text")

        local _, button = GuiUtils.addStandardTextButtonInContainer(dialogControlsRow, dialogButtonConfig.text, function()
            Utils.debugPrint("Mocks", "button clicked")
            -- Destroy the dialog.
            DialogUtils.cleanupDialog(dialogId)
            -- Hit callback if provided.
            Utils.debugPrint("Mocks", "dialogButtonConfig.callback = ", dialogButtonConfig.callback)
            if dialogButtonConfig.callback then
                dialogButtonConfig.callback()
            end
        end, {
            AutomaticSize = Enum.AutomaticSize.None,
            Size = UDim2.fromOffset(GuiConstants.dialogButtonWidth, GuiConstants.dialogButtonHeight),
        })

        if not button.TextFits then
            button.TextScaled = true
        end
    end

    if not isFirst then
        GuiUtils.addUIPadding(dialogControlsRow, {
            PaddingTop = GuiConstants.betweenRowPadding,
            PaddingBottom = GuiConstants.noPadding,
            PaddingLeft = GuiConstants.noPadding,
            PaddingRight = GuiConstants.noPadding,
        })
    end
end

local function applyDialogButtonConfigs(dialogId: DialogId, dialogContentFrame: Frame, dialogButtonConfigs: {DialogButtonConfig})
    assert(dialogContentFrame, "dialogContentFrame should be provided")
    assert(dialogButtonConfigs, "dialogButtonConfigs should be provided")

    local configsByHeading = getConfigsByHeading(dialogButtonConfigs)

    local isFirst = true
    for heading, configsForHeading in pairs(configsByHeading) do
        applyConfigsWithHeading(dialogId, dialogContentFrame, heading, configsForHeading, isFirst)
        isFirst = false
    end
end

--[[
Have dialog background appear with a tweening effect.
Cancel any existing 'tween out' that might be going on.
]]
local function tweenInDialogBackground(dialogBackground: Frame)
    -- If we are tweening it out, kill that.
    if currentBackgroundTweenOut then
        currentBackgroundTweenOut:Cancel()
        currentBackgroundTweenOut = nil
    end

        -- If background is not currently visible, tween it in.
    if not dialogBackground.Visible then
        -- If we are already tweening it in, don't add another one.
        if not currentBackgroundTweenIn then
            dialogBackground.BackgroundTransparency = 1

            dialogBackground.Visible = true
            local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
            local tweenIn = TweenService:Create(dialogBackground, tweenInfo, {BackgroundTransparency = backgroundTransparencyWhenVisible})
            currentBackgroundTweenIn = tweenIn
            tweenIn.Completed:Connect(function()
                if currentBackgroundTweenIn == tweenIn then
                    currentBackgroundTweenIn = nil
                end
            end)
            tweenIn:Play()
        end
    end
end

local function addTitleAndDescription(dialogContentFrame: Frame, dialogConfig: DialogConfig)
    assert(dialogContentFrame, "dialogContentFrame should be provided")
    assert(dialogConfig, "dialogConfig should be provided")

    local title = GuiUtils.addTextLabel(dialogContentFrame, GuiUtils.bold(dialogConfig.title), {
        RichText = true,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, GuiConstants.dialogTitleHeight),
        Name = GuiConstants.dialogTitleTextLabel,
    })
    title.TextSize = GuiConstants.dialogTitleFontSize

    GuiUtils.addTextLabel(dialogContentFrame, GuiUtils.italicize(dialogConfig.description), {
        RichText = true,
        TextWrapped = true,
        Name = GuiConstants.dialogDescriptionTextLabel,
    })
end

local function updateStackAndTweenIn(dialogFrame:Frame, dialogId: DialogId)
    -- Anyone already in the stack is now invisible.
    for _, dialogFrameWithId in ipairs(dialogFrameWithIdStack) do
        dialogFrameWithId.frame.Visible = false
    end

    -- Add it to the stack.
    local dialogFrameWithId = {
        frame = dialogFrame,
        dialogId = dialogId,
    } :: DialogFrameWithId
    table.insert(dialogFrameWithIdStack, dialogFrameWithId)

    -- Tween it in.
    local uiScale = dialogFrame:FindFirstChild("UIScale")
    uiScale.Scale = 0
    local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
    local tweenIn = TweenService:Create(uiScale, tweenInfo, {Scale = 1})
    tweenIn:Play()
end

--[[
Dialog is currently scaled to flood fill the screen, mod some padding.
In X: Dialog should expand to fit content, but no wider than the screen.
In Y: Dialog should expand to fit content, but no taller than the screen.
In either case we can't use autosize because the children may be scaled to
parent size, that doesn't work well.
]]
function DialogUtils.adjustSizeForContentAndScreenFit(dialogContentFrame: Frame)
    -- Dialog children are all rows.
    -- Get the max width.
    -- Also sum up all the heights.
    local totalHeight = 0
    local uiListLayout = dialogContentFrame:FindFirstChildOfClass("UIListLayout")
    local verticalPadding = uiListLayout.Padding.Offset

    local children = dialogContentFrame:GetChildren()
    local maxChildWidth = 0
    for _, child in children do
        if child:IsA("GuiObject") then
            Utils.debugPrint("Dialogs", "adjustWidth with child = ", child.Name)
            Utils.debugPrint("Dialogs", "child.AbsoluteSize = ", child.AbsoluteSize)

            maxChildWidth = math.max(maxChildWidth, child.AbsoluteSize.X)
            if totalHeight ~= 0 then
                totalHeight = totalHeight + verticalPadding
            end
            totalHeight = totalHeight + child.AbsoluteSize.Y
            Utils.debugPrint("Dialogs", "adjustWidth maxChildWidth is now = ", maxChildWidth)
            Utils.debugPrint("Dialogs", "adjustWidth totalHeight is now = ", totalHeight)
        end
    end

    -- Just resize to that.
    local finalWidth = maxChildWidth + 2 * GuiConstants.dialogToContentPaddingPx
    local finalHeight = totalHeight + 2 * GuiConstants.dialogToContentPaddingPx
    -- Note: finalHeight might be bigger than original height.  Original height was a
    -- max so we clamp to that.
    finalHeight = math.min(finalHeight, dialogContentFrame.AbsoluteSize.Y)
    local newSize = UDim2.fromOffset(finalWidth, finalHeight)
    Utils.debugPrint("Dialogs", "adjustWidth original size = ", dialogContentFrame.Size, " new size = ", newSize)
    dialogContentFrame.Size = newSize
end

-- Throw up a dialog using the given config.
-- Clicking any button in the config will kill the dialog and hit the associated callback.
function DialogUtils.makeDialogAndReturnId(dialogConfig: DialogConfig): DialogId
    local dialogId = dialogIdGen
    dialogIdGen = dialogIdGen + 1

    -- Get or make the parent we drop the dialog into.
    local dialogBackground = getOrMakeDialogBackground()

    -- Have it show up with a tweening effect.
    tweenInDialogBackground(dialogBackground)

    local dialogFrame = makeDialogFrame(dialogBackground, dialogId)

    -- Put a cancel button in upper right corner.
    -- Note this is not in "dialogContent" to avoid the UIListLayout.
    addCancelButton(dialogFrame, dialogId)

    -- A separate frame for content since the cancel button ignores UIListLayout.
    local dialogContentFrame = makeDialogContentFrame(dialogFrame)

    addTitleAndDescription(dialogContentFrame, dialogConfig)

    -- There should be at least one of dialogButtonConfigs or makeCustomDialogContent
    local hasDialogButtonConfigs = dialogConfig.dialogButtonConfigs and #dialogConfig.dialogButtonConfigs > 0
    local hasMakeCustomDialogContent = dialogConfig.makeCustomDialogContent
    assert(hasDialogButtonConfigs or hasMakeCustomDialogContent, "Should at least one of dialogButtonConfigs or hasMakeCustomDialogContent")

    if hasMakeCustomDialogContent then
        dialogConfig.makeCustomDialogContent(dialogId, dialogContentFrame)
    end

    if hasDialogButtonConfigs then
        applyDialogButtonConfigs(dialogId, dialogContentFrame, dialogConfig.dialogButtonConfigs)
        if not hasMakeCustomDialogContent then
            -- Dialog is currently sized to scale to screen.
            -- We want it to shrink to fit contents if possible.
            DialogUtils.adjustSizeForContentAndScreenFit(dialogContentFrame)
        end
    end

    updateStackAndTweenIn(dialogFrame, dialogId)

    return dialogId
end

function DialogUtils.showConfirmationDialog(title: string, description: string, onConfirm: () -> nil, opt_proceedButtonName: string?, opt_cancelButtonName: string?)
    local dialogButtonConfigs = {} :: {DialogButtonConfig}
    table.insert(dialogButtonConfigs, {
        text = opt_cancelButtonName or "Cancel",
    })
    table.insert(dialogButtonConfigs, {
        text = opt_proceedButtonName or "OK",
        callback = onConfirm,
    })

    local dialogConfig = {
        title = title,
        description = description,
        dialogButtonConfigs = dialogButtonConfigs,
    } :: DialogConfig

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

function DialogUtils.showAckDialog(title: string, description: string)
    local dialogButtonConfigs = {} :: {DialogButtonConfig}
    table.insert(dialogButtonConfigs, {
        text = "OK",
    })

    local dialogConfig = {
        title = title,
        description = description,
        dialogButtonConfigs = dialogButtonConfigs,
    } :: DialogConfig

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

function DialogUtils.getDialogById(dialogId: DialogId): Frame?
    for _, dialogFrameWithId in ipairs(dialogFrameWithIdStack) do
        if dialogFrameWithId.dialogId == dialogId then
            return dialogFrameWithId.frame
        end
    end
    return nil
end

return DialogUtils