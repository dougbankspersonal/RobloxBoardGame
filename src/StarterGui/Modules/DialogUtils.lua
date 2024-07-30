local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)

local DialogUtils = {}

-- mainFrame being set to Inactive, I'd expect, would mean that elements on the
-- mainFrame no longer highlight on mouseover.  Nope.
-- So when dialog goes up we:
--   * Throw on an invisible button to suck up UI stuff that might otherwise
--     go to mainFrame.
--  * Manually shut down all the stuff in main frame.
local function suppressMainFrameInteractions(dialogBackground: Frame)
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "mainFrame not found")
    assert(dialogBackground, "dialogBackground not found")
    local dialogInputSink = Instance.new("TextButton")
    dialogInputSink.Parent = dialogBackground
    dialogInputSink.BackgroundColor3 = Color3.new(0, 0, 0)
    dialogInputSink.BackgroundTransparency = 1
    dialogInputSink.Position = UDim2.fromScale(0, 0)
    dialogInputSink.Size = UDim2.fromScale(1, 1)
    dialogInputSink.BorderSizePixel = 0
    dialogInputSink.ZIndex = GuiConstants.dialogInputSinkZIndex
    dialogInputSink.Name = "DialogInputSink"
    dialogInputSink.Text = ""

    mainFrame.Active = false
    local descendants = mainFrame:GetDescendants()
    for _, d in descendants do
        if d:IsA("GuiButton") then
            d.Active = false
            d.AutoButtonColor = false
        end
    end
end

local restoreMainFrameInteractions = function()
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")
    mainFrame.Active = true
    local descendants = mainFrame:GetDescendants()
    for _, d in descendants do
        if d:IsA("GuiButton") then
            d.Active = true
            d.AutoButtonColor = true
        end
    end
end

DialogUtils.getDialogBackground = function(): Frame?
    local screenGui = GuiUtils.getMainScreenGui()
    assert(screenGui, "ScreenGui not found")
    return screenGui:FindFirstChild("DialogBackground", true)
end

DialogUtils.cleanupDialog = function()
    local dialogBackground = DialogUtils.getDialogBackground()

    assert(dialogBackground, "DialogBackground not found")

    dialogBackground:Destroy()

    restoreMainFrameInteractions()
end

-- Throw up a dialog using the given config.
-- Clicking any button in the config will kill the dialog and hit the associated callback.
DialogUtils.makeDialog = function(dialogConfig: CommonTypes.DialogConfig): Frame?
    local screenGui = GuiUtils.getMainScreenGui()
    -- Can't have two dialogs up at once.
    local existingDialogBackground = DialogUtils.getDialogBackground()
    if existingDialogBackground then
        Utils.debugPrint("Error: tried to put up a dialog when one is already up")
        return nil
    end

    local dialogBackground = Instance.new("Frame")
    dialogBackground.Size = UDim2.fromScale(1, 1)
    dialogBackground.BackgroundColor3 = Color3.new(0, 0, 0)
    dialogBackground.BackgroundTransparency = 0.5
    dialogBackground.Parent = screenGui
    dialogBackground.Name = "DialogBackground"
    dialogBackground.ZIndex = GuiConstants.dialogBackgroundZIndex

    suppressMainFrameInteractions(dialogBackground)

    -- One way to make this nicer, add some kinda cool tweening effect for dialog
    -- going up/down.
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.fromScale(0.75,0)
    dialog.Position = UDim2.fromScale(0.5, 0.5)
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)
    dialog.AutomaticSize = Enum.AutomaticSize.Y
    dialog.BackgroundColor3 = Color3.new(1, 1, 1)
    dialog.Parent = dialogBackground
    dialog.Name = "Dialog"
    dialog.BorderSizePixel = 0
    dialog.ZIndex = GuiConstants.dialogZIndex
    GuiUtils.addUIGradient(dialog, GuiConstants.whiteToGrayColorSequence)

    GuiUtils.addCorner(dialog)

    -- A separate frame for content since the cancel button ignores UIListLayout.
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Parent = dialog
    contentFrame.Size = UDim2.fromScale(1, 0)
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    contentFrame.Position = UDim2.fromScale(0, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0

    GuiUtils.addPadding(contentFrame)

    GuiUtils.addUIListLayout(contentFrame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    local titleContent = GuiUtils.addRowAndReturnRowContent(contentFrame, "Row_Title")
    local title = GuiUtils.addTextLabel(titleContent, "<b>" .. dialogConfig.title .. "</b>", {RichText = true})
    title.TextSize = GuiConstants.dialogTitleFontSize

    local descriptionContent = GuiUtils.addRowAndReturnRowContent(contentFrame, "Row_Description")
    GuiUtils.addTextLabel(descriptionContent, "<i>" .. dialogConfig.description .. "</i>", {
        RichText = true,
        TextWrapped = true,
    })

    -- There should be exactly one of dialogButtonConfigs or makeRowAndAddCustomControls
    local hasDialogButtonConfigs = dialogConfig.dialogButtonConfigs and #dialogConfig.dialogButtonConfigs > 0
    local hasMakeRowAndAddCustomControls = dialogConfig.makeRowAndAddCustomControls
    assert(hasDialogButtonConfigs or hasMakeRowAndAddCustomControls, "Should at least one of dialogButtonConfigs or hasMakeRowAndAddCustomControls")
    assert(not (hasDialogButtonConfigs and hasMakeRowAndAddCustomControls), "Should not have both dialogButtonConfigs hasMakeRowAndAddCustomControls")

    if hasDialogButtonConfigs then
        local rowContent = GuiUtils.addRowAndReturnRowContent(contentFrame, "Row_Controls")
        for _, dialogButtonConfig in ipairs(dialogConfig.dialogButtonConfigs) do
            GuiUtils.addTextButtonWidgetContainer(rowContent, dialogButtonConfig.text, function()
                -- Destroy the dialog.
                DialogUtils.cleanupDialog()
                -- Hit callback if provided.
                if dialogButtonConfig.callback then
                    dialogButtonConfig.callback()
                end
            end)
        end
    else
        dialogConfig.makeRowAndAddCustomControls(contentFrame)
    end

    -- Put a cancel button in upper right corner.
    -- Note this is not in "dialogContent" to avoid the UIListLayout.
    local cancelButton = Instance.new("ImageButton")
    cancelButton.Parent = dialog
    cancelButton.Size = UDim2.fromOffset(20, 20)
    cancelButton.Position = UDim2.new(1, -25, 0, 5)
    cancelButton.Image = "http://www.roblox.com/asset/?id=171846064"
    cancelButton.BackgroundTransparency = 1
    cancelButton.MouseButton1Click:Connect(function()
        DialogUtils.cleanupDialog()
    end)

    return dialog
end

DialogUtils.showConfirmationDialog = function(title: string, description: string, onConfirm: () -> nil)
    local dialogButtonConfigs = {} :: {CommonTypes.DialogButtonConfig}
    table.insert(dialogButtonConfigs, {
        text = "Cancel",
    })
    table.insert(dialogButtonConfigs, {
        text = "OK",
        callback = onConfirm,
    })

    local dialogConfig = {
        title = title,
        description = description,
        dialogButtonConfigs = dialogButtonConfigs,
    } :: CommonTypes.DialogConfig

    DialogUtils.makeDialog(game.Players.LocalPlayer:WaitForChild("PlayerGui"), dialogConfig)
end

return DialogUtils