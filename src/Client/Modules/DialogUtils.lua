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

export type DialogFrameWithId = {
    frame: Frame,
    dialogId: number,
}

local dialogStack = {} :: {DialogFrameWithId}

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
    local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
    local tweenOut = TweenService:Create(dialogBackground, tweenInfo, {BackgroundTransparency = 1})
    tweenOut.Completed:Connect(function()
        local db = DialogUtils.getDialogBackground()
        if db then
            db.Visible = false
        end
    end)
    tweenOut:Play()
end

function DialogUtils.cleanupDialog(dialogId: number)
    assert(dialogId, "dialogId should be provided")
    -- Already gone, forget it.
    local dialog = DialogUtils.getDialogById(dialogId)
    if not dialog then
        return
    end

    -- Remove from stack.
    dialogStack = Cryo.List.map(dialogStack, function(dfwi: DialogFrameWithId)
        if dfwi.dialogId ~= dialogId then
            return dfwi
        end
        return nil
    end)

    -- Tween it out then destroy it.
    local uiScale = dialog:FindFirstChild("UIScale")
    local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
    local tweenOut = TweenService:Create(uiScale, tweenInfo, {Scale = 0})
    tweenOut.Completed:Connect(function()
        dialog:Destroy()
    end)
    tweenOut:Play()

    -- if stack is now empty, hide the background.
    if #dialogStack == 0 then
        hideDialogBackground()
    else
        -- Top item in the stack is now visible.
        dialogStack[#dialogStack].frame.Visible = true
    end
end

local function addCancelButton(dialog: Frame, dialogId: number)
    assert(dialog, "dialog should be provided")
    assert(dialogId, "dialogId should be provided")

    local cancelButton = Instance.new("ImageButton")
    cancelButton.Parent = dialog
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
    Utils.debugPrint("Dialogs", "getOrMakeDialogBackground 001")
    local dialogBackground = DialogUtils.getDialogBackground()
    if dialogBackground then
        Utils.debugPrint("Dialogs", "getOrMakeDialogBackground 002")
        return dialogBackground
    end

    Utils.debugPrint("Dialogs", "getOrMakeDialogBackground 003")
    local mainScreenGui = GuiUtils.getMainScreenGui()
    -- Dialog background is a button so it soaks up clicks.
    dialogBackground = Instance.new("TextButton")
    dialogBackground.Position = UDim2.fromOffset(0, GuiConstants.robloxTopBarBottomPadding)
    dialogBackground.Size = UDim2.new(1, 0, 1, -GuiConstants.robloxTopBarBottomPadding)
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
Make the dialog itself.  Just the frame.
]]
local function makeDialogFrame(dialogBackground: Frame, dialogId: number): Frame
    assert(dialogBackground, "dialogBackground should be provided")
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(1, -GuiConstants.screenToDialogPadding, 1, -GuiConstants.screenToDialogPadding)
    dialog.Position = UDim2.fromScale(0.5, 0.5)
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)
    dialog.BackgroundColor3 = Color3.new(1, 1, 1)
    dialog.Parent = dialogBackground
    dialog.Name = GuiConstants.dialogName
    dialog.BorderSizePixel = 0
    dialog.ZIndex = GuiConstants.dialogZIndex + dialogId
    GuiUtils.addUIGradient(dialog, GuiConstants.standardMainScreenColorSequence)
    GuiUtils.addCorner(dialog)

    -- Add a ui scale underneath.
    GuiUtils.addUIScale(dialog)

    return dialog
end

--[[
Almost everything in dialog should be laid out top to bottom with a UI List layout.
But there's the red cancel button in upper right corner, not part of layout flow.
So children of main dialog are that button and a content widget, which holds the
meat of the dialog.
This makes the content widget.
]]
local function makeDialogContentFrame(dialog: Frame): ScrollingFrame
    assert(dialog, "dialog should be provided")
    local dialogContentFrame = Instance.new("ScrollingFrame")
    GuiUtils.setScrollingFrameColors(dialogContentFrame)
    dialogContentFrame.Name = GuiConstants.dialogContentFrameName
    dialogContentFrame.Parent = dialog
    dialogContentFrame.Size = UDim2.fromScale(1, 1)
    dialogContentFrame.Position = UDim2.fromScale(0, 0)
    dialogContentFrame.BackgroundTransparency = 1
    dialogContentFrame.BorderSizePixel = 0
    dialogContentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    dialogContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dialogContentFrame.CanvasSize = UDim2.fromScale(0, 0)

    GuiUtils.addUIPadding(dialogContentFrame, {
        PaddingLeft = UDim.new(0, GuiConstants.dialogToContentPadding),
        PaddingRight = UDim.new(0, GuiConstants.dialogToContentPadding),
        PaddingTop = UDim.new(0, GuiConstants.dialogToContentPadding),
        PaddingBottom = UDim.new(0, GuiConstants.dialogToContentPadding),
    })

    GuiUtils.addUIListLayout(dialogContentFrame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, GuiConstants.paddingBetweenRows),
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


local function applyConfigsWithHeading(dialogId: number, parent: Frame, heading: string, dialogButtonConfigs: {DialogButtonConfig}, isFirst: boolean)
    local rowOptions : GuiUtils.RowOptions = {
        horizontalAlignment = Enum.HorizontalAlignment.Center,
        wraps = true,
        uiListLayoutPadding = UDim.new(0, GuiConstants.buttonsUIListLayoutPadding),
        labelText = if heading == "" then nil else heading,
        useGridLayout = true,
        gridCellSize = UDim2.fromOffset(GuiConstants.dialogButtonWidth, GuiConstants.dialogButtonHeight),
    }

    local controlsContent = GuiUtils.addRowAndReturnRowContent(parent, "Row_DialogControls", rowOptions)
    local gridLayout = controlsContent:FindFirstChildOfClass("UIGridLayout")
    assert(gridLayout, "Should have gridLayout")
    if heading == "" then
        gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    end

    Utils.debugPrint("Layout", "configsForHeading = ", dialogButtonConfigs)
    for _, dialogButtonConfig in ipairs(dialogButtonConfigs) do
        -- Should be properly configured.
        assert(dialogButtonConfig.text, "Should have text")

        local _, button = GuiUtils.addStandardTextButtonInContainer(controlsContent, dialogButtonConfig.text, function()
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
        GuiUtils.addUIPadding(controlsContent, {
            PaddingTop = UDim.new(0, GuiConstants.paddingBetweenRows),
        })
    end
end

local function applyDialogButtonConfigs(dialogId: number, dialogContentFrame: Frame, dialogButtonConfigs: {DialogButtonConfig})
    assert(dialogContentFrame, "dialogContentFrame should be provided")
    assert(dialogButtonConfigs, "dialogButtonConfigs should be provided")

    local configsByHeading = getConfigsByHeading(dialogButtonConfigs)

    local isFirst = true
    for heading, configsForHeading in pairs(configsByHeading) do
        applyConfigsWithHeading(dialogId, dialogContentFrame, heading, configsForHeading, isFirst)
        isFirst = false
    end
end

-- Throw up a dialog using the given config.
-- Clicking any button in the config will kill the dialog and hit the associated callback.
function DialogUtils.makeDialogAndReturnId(dialogConfig: DialogConfig): number
    local dialogId = dialogIdGen
    dialogIdGen = dialogIdGen + 1

    -- Get the parent we drop the dialog into.
    local dialogBackground = getOrMakeDialogBackground()

    -- If background is not currently visible, tween it in.
    if not dialogBackground.Visible then
        -- Tween it in.
        dialogBackground.BackgroundTransparency = 1
        dialogBackground.Visible = true
        local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
        local tweenIn = TweenService:Create(dialogBackground, tweenInfo, {BackgroundTransparency = backgroundTransparencyWhenVisible})
        tweenIn:Play()
    end

    -- Background is now visible.
    dialogBackground.Visible = true

    -- One way to make this nicer, a
    -- FIXME(dbanks)
    -- 1. Add some kinda cool tweening effect for dialog going up/down.
    -- 2. I want the dialog to scale to content, but if it's too big, stop at certain
    --    max and add scroll.  Docs suggest using UISizeConstraint but experience
    --    shows this does not work:
    --    https://devforum.roblox.com/t/automaticsize-doesnt-respect-uisizeconstraint-constraints/1391918/10
    --    So we are going with a fixed size, which will look bad with small content and large screen.
    local dialog = makeDialogFrame(dialogBackground, dialogId)

    -- A separate frame for content since the cancel button ignores UIListLayout.
    local dialogContentFrame = makeDialogContentFrame(dialog)

    local titleContent = GuiUtils.addRowAndReturnRowContent(dialogContentFrame, "Row_Title")

    local title = GuiUtils.addTextLabel(titleContent, GuiUtils.bold(dialogConfig.title), {RichText = true})
    title.TextSize = GuiConstants.dialogTitleFontSize

    local descriptionContent = GuiUtils.addRowAndReturnRowContent(dialogContentFrame, "Row_Description")
    GuiUtils.addTextLabel(descriptionContent, GuiUtils.italicize(dialogConfig.description), {
        RichText = true,
        TextWrapped = true,
        Name = GuiConstants.dialogDescriptionTextLabel,
    })

    -- There should be at least one of dialogButtonConfigs or makeCustomDialogContent
    local hasDialogButtonConfigs = dialogConfig.dialogButtonConfigs and #dialogConfig.dialogButtonConfigs > 0
    local hasMakeCustomDialogContent = dialogConfig.makeCustomDialogContent
    assert(hasDialogButtonConfigs or hasMakeCustomDialogContent, "Should at least one of dialogButtonConfigs or hasMakeCustomDialogContent")

    if hasMakeCustomDialogContent then
        dialogConfig.makeCustomDialogContent(dialogId, dialogContentFrame)
    end

    if hasDialogButtonConfigs then
        applyDialogButtonConfigs(dialogId, dialogContentFrame, dialogConfig.dialogButtonConfigs)
    end

    -- Put a cancel button in upper right corner.
    -- Note this is not in "dialogContent" to avoid the UIListLayout.
    addCancelButton(dialog, dialogId)

    -- Anyone already in the stack is now invisible.
    for _, dialogFrameWithId in ipairs(dialogStack) do
        dialogFrameWithId.frame.Visible = false
    end

    -- Add it to the stack.
    local dialogFrameWithId = {
        frame = dialog,
        dialogId = dialogId,
    } :: DialogFrameWithId
    table.insert(dialogStack, dialogFrameWithId)

    -- Tween it in.
    local uiScale = dialog:FindFirstChild("UIScale")
    uiScale.Scale = 0
    local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
    local tweenIn = TweenService:Create(uiScale, tweenInfo, {Scale = 1})
    tweenIn:Play()

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

function DialogUtils.getDialogById(dialogId: number): Frame?
    for _, dialogFrameWithId in ipairs(dialogStack) do
        if dialogFrameWithId.dialogId == dialogId then
            return dialogFrameWithId.frame
        end
    end
    return nil
end

return DialogUtils