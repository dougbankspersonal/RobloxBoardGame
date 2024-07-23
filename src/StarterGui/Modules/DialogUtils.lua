local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)

local DialogUtils = {}

-- mainFrame being set to Inactive, I'd expect, would mean that elements on the
-- mainFrame no longer highlight on mouseover.  Nope.
-- So when dialog goes up we:
--   * Throw on an invisible button to suck up UI stuff that might otherwise
--     go to mainFrame.
--  * Manually shut down all the stuff in main frame.
local function suppressMainFrameInteractions(dialogBackground: Frame, mainFrame: Frame)
    local dialogInputSink = Instance.new("TextButton")
    dialogInputSink.Parent = dialogBackground
    dialogInputSink.BackgroundColor3 = Color3.new(0, 0, 0)
    dialogInputSink.BackgroundTransparency = 1
    dialogInputSink.Position = UDim2.new(0, 0, 0, 0)
    dialogInputSink.Size = UDim2.new(1, 0, 1, 0)
    dialogInputSink.BorderSizePixel = 0
    dialogInputSink.ZIndex = GuiUtils.dialogInputSinkZIndex
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

local restoreMainFrameInteractions = function(mainFrame: Frame)
    mainFrame.Active = true
    local descendants = mainFrame:GetDescendants()
    for _, d in descendants do
        if d:IsA("GuiButton") then
            d.Active = true
            d.AutoButtonColor = true
        end
    end
end

local cleanupDialog = function(mainFrame: Frame, dialogBackground: Frame)
    dialogBackground:Destroy()
    restoreMainFrameInteractions(mainFrame)
end

-- Throw up a dialog using the given config.
-- Clicking any button in the config will kill the dialog and hit the associated callback.
DialogUtils.makeDialog = function(screenGui: ScreenGui, dialogConfig: CommonTypes.DialogConfig): Frame?
    -- Can't have two dialogs up at once.
    local existingDialog = screenGui:FindFirstChild("DialogBackground", true)
    if existingDialog then
        print("Doug: tried to put up a dialog when one is already up")
        return nil
    end

    local mainFrame = GuiUtils.getMainFrame(screenGui)
    assert(mainFrame, "MainFrame not found")

    local dialogBackground = Instance.new("Frame")
    dialogBackground.Size = UDim2.new(1, 0, 1, 0)
    dialogBackground.BackgroundColor3 = Color3.new(0, 0, 0)
    dialogBackground.BackgroundTransparency = 0.5
    dialogBackground.Parent = screenGui
    dialogBackground.Name = "DialogBackground"
    dialogBackground.ZIndex = GuiUtils.dialogBackgroundZIndex

    suppressMainFrameInteractions(dialogBackground, mainFrame)

    -- One way to make this nicer, add some kinda cool tweening effect for dialog
    -- going up/down.
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0.5, 0, 0.5, 0)
    dialog.Position = UDim2.new(0.25, 0, 0.25, 0)
    dialog.BackgroundColor3 = Color3.new(1, 1, 1)
    dialog.Parent = dialogBackground
    dialog.Name = "Dialog"
    dialog.BorderSizePixel = 0
    dialog.ZIndex = GuiUtils.dialogZIndex
    GuiUtils.addUIGradient(dialog, GuiUtils.whiteToGrayColorSequence)

    GuiUtils.addCorner(dialog)

    -- A separate frame for content since the cancel button ignores UIListLayout.
    local contentFrame = Instance.new("Frame")
    contentFrame.Parent = dialog
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.Position = UDim2.new(0, 0, 0, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0

    local uiListLayout = GuiUtils.makeUiListLayout(contentFrame)
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local titleContent = GuiUtils.makeRowWithLabelAndReturnRowContent(contentFrame, "Row_Title")
    local title = GuiUtils.makeTextLabel(titleContent, "<b>" .. dialogConfig.title .. "</b>", true)
    title.TextSize = GuiUtils.dialogTitleFontSize

    local descriptionContent = GuiUtils.makeRowWithLabelAndReturnRowContent(contentFrame, "Row_Description")
    GuiUtils.makeTextLabel(descriptionContent, "<i>" .. dialogConfig.description .. "</i>", true)

    local rowContent = GuiUtils.makeRowAndReturnRowContent(contentFrame, "Row_Controls")

    -- There should be exactly one of dialogButtonConfigs or addCustomControls
    local hasDialogButtonConfigs = dialogConfig.dialogButtonConfigs and #dialogConfig.dialogButtonConfigs > 0 and dialogConfig.addCustomControls == nil
    local hasAddCustomControls = dialogConfig.addCustomControls and dialogConfig.dialogButtonConfigs == nil
    assert(hasDialogButtonConfigs or hasAddCustomControls, "Should at least one of dialogButtonConfigs or addCustomControls")
    assert(not (hasDialogButtonConfigs and hasAddCustomControls), "Should not have both dialogButtonConfigs addCustomControls")

    if hasDialogButtonConfigs then
        for _, dialogButtonConfig in ipairs(dialogConfig.dialogButtonConfigs) do
            GuiUtils.makeTextButtonWidgetContainer(rowContent, dialogButtonConfig.text, function()
                -- Destroy the dialog.
                cleanupDialog(mainFrame, dialogBackground)
                -- Hit callback if provided.
                if dialogButtonConfig.callback then
                    dialogButtonConfig.callback()
                end
            end)
        end
    else
        dialogConfig.addCustomControls(rowContent)
    end

    -- Put a cancel button in upper right corner.
    -- Note this is not in "dialogContent" to avoid the UIListLayout.
    local cancelButton = Instance.new("ImageButton")
    cancelButton.Parent = dialog
    cancelButton.Size = UDim2.new(0, 20, 0, 20)
    cancelButton.Position = UDim2.new(1, -25, 0, 5)
    cancelButton.Image = "http://www.roblox.com/asset/?id=171846064"
    cancelButton.BackgroundTransparency = 1
    cancelButton.MouseButton1Click:Connect(function()
        cleanupDialog(mainFrame, dialogBackground)
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