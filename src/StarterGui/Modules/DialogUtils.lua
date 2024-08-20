local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)

local dialogToMainScreenMargin = 20

local DialogUtils = {}

DialogUtils.getDialogBackground = function(): Frame?
    local mainScreenGui = GuiUtils.getMainScreenGui()
    assert(mainScreenGui, "ScreenGui not found")
    return mainScreenGui:FindFirstChild(GuiConstants.dialogBackgroundName, true)
end

DialogUtils.cleanupDialog = function()
    local dialogBackground = DialogUtils.getDialogBackground()

    assert(dialogBackground, "DialogBackground not found")

    dialogBackground:Destroy()
end

DialogUtils.addPaddingForRowContent = function(rowContent:Frame)
    GuiUtils.addPadding(rowContent, {
        PaddingLeft = UDim.new(0, GuiConstants.dialogToContentPadding),
        PaddingRight = UDim.new(0, GuiConstants.dialogToContentPadding),
        PaddingTop = UDim.new(0, 0),
        PaddingBottom = UDim.new(0, 0),
    })
end

-- Throw up a dialog using the given config.
-- Clicking any button in the config will kill the dialog and hit the associated callback.
DialogUtils.makeDialog = function(dialogConfig: CommonTypes.DialogConfig): Frame?
    local mainScreenGui = GuiUtils.getMainScreenGui()
    local mainSize = mainScreenGui.AbsoluteSize

    -- Can't have two dialogs up at once.
    local existingDialogBackground = DialogUtils.getDialogBackground()
    if existingDialogBackground then
        Utils.debugPrint("Dialogs", "Error: tried to put up a dialog when one is already up")
        return nil
    end

    -- Make it a text button so it soaks up input.
    local dialogBackground = Instance.new("TextButton")
    dialogBackground.Size = UDim2.fromScale(1, 1)
    dialogBackground.BackgroundColor3 = Color3.new(0, 0, 0)
    dialogBackground.BackgroundTransparency = 0.5
    dialogBackground.Parent = mainScreenGui
    dialogBackground.Name = GuiConstants.dialogBackgroundName
    dialogBackground.ZIndex = GuiConstants.dialogBackgroundZIndex
    dialogBackground.AutomaticSize = Enum.AutomaticSize.XY
    dialogBackground.Text = ""
    dialogBackground.AutoButtonColor = false

    -- One way to make this nicer, add some kinda cool tweening effect for dialog
    -- going up/down.
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0.66, 0, 0, 100)
    dialog.Position = UDim2.fromScale(0.5, 0.5)
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)
    dialog.AutomaticSize = Enum.AutomaticSize.XY
    dialog.BackgroundColor3 = Color3.new(1, 1, 1)
    dialog.Parent = dialogBackground
    dialog.Name = GuiConstants.dialogName
    dialog.BorderSizePixel = 0
    dialog.ZIndex = GuiConstants.dialogZIndex
    GuiUtils.addUIGradient(dialog, GuiConstants.whiteToGrayColorSequence)
    GuiUtils.addCorner(dialog)

    -- A separate frame for content since the cancel button ignores UIListLayout.
    local dialogContentFrame = Instance.new("ScrollingFrame")
    dialogContentFrame.Name = GuiConstants.dialogContentFrameName
    dialogContentFrame.Parent = dialog
    dialogContentFrame.Size = UDim2.fromScale(1, 0)
    dialogContentFrame.AutomaticSize = Enum.AutomaticSize.Y
    dialogContentFrame.Position = UDim2.fromScale(0, 0)
    dialogContentFrame.BackgroundTransparency = 1
    dialogContentFrame.BorderSizePixel = 0
    dialogContentFrame.ScrollingDirection = Enum.ScrollingDirection.XY
    dialogContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
    dialogContentFrame.CanvasSize = UDim2.fromScale(0, 0)

    GuiUtils.addPadding(dialogContentFrame, {
        PaddingLeft = UDim.new(0, 0),
        PaddingRight = UDim.new(0, 0),
        PaddingTop = UDim.new(0, GuiConstants.dialogToContentPadding),
        PaddingBottom = UDim.new(0, GuiConstants.dialogToContentPadding),
    })
    GuiUtils.addUIListLayout(dialogContentFrame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, GuiConstants.paddingBetweenRows),
    })

    local titleContent = GuiUtils.addRowAndReturnRowContent(dialogContentFrame, "Row_Title")
    DialogUtils.addPaddingForRowContent(titleContent)

    local title = GuiUtils.addTextLabel(titleContent, "<b>" .. dialogConfig.title .. "</b>", {RichText = true})
    title.TextSize = GuiConstants.dialogTitleFontSize

    local descriptionContent = GuiUtils.addRowAndReturnRowContent(dialogContentFrame, "Row_Description")
    DialogUtils.addPaddingForRowContent(descriptionContent)
    GuiUtils.addTextLabel(descriptionContent, GuiUtils.italicize(dialogConfig.description), {
        RichText = true,
        TextWrapped = true,
    })

    -- There should be at least one of dialogButtonConfigs or makeCustomDialogContent
    local hasDialogButtonConfigs = dialogConfig.dialogButtonConfigs and #dialogConfig.dialogButtonConfigs > 0
    local hasMakeCustomDialogContent = dialogConfig.makeCustomDialogContent
    assert(hasDialogButtonConfigs or hasMakeCustomDialogContent, "Should at least one of dialogButtonConfigs or hasMakeCustomDialogContent")

    if hasMakeCustomDialogContent then
        dialogConfig.makeCustomDialogContent(dialogContentFrame)
    end

    if hasDialogButtonConfigs then
        local controlsContent = GuiUtils.addRowAndReturnRowContent(dialogContentFrame, "Row_Controls", nil, {
            horizontalAlignment = Enum.HorizontalAlignment.Center,
            wraps = true,
        })
        DialogUtils.addPaddingForRowContent(controlsContent)

        Utils.debugPrint("Dialogs", "Doug: dialogConfig.dialogButtonConfigs = ", dialogConfig.dialogButtonConfigs)
        for _, dialogButtonConfig in ipairs(dialogConfig.dialogButtonConfigs) do
            GuiUtils.addTextButtonWidgetContainer(controlsContent, dialogButtonConfig.text, function()
                -- Destroy the dialog.
                DialogUtils.cleanupDialog()
                -- Hit callback if provided.
                if dialogButtonConfig.callback then
                    dialogButtonConfig.callback()
                end
            end)
        end
    end

    -- Put a cancel button in upper right corner.
    -- Note this is not in "dialogContent" to avoid the UIListLayout.
    local cancelButton = Instance.new("ImageButton")
    cancelButton.Parent = dialog
    cancelButton.Size = UDim2.fromOffset(GuiConstants.redXSize, GuiConstants.redXSize)
    cancelButton.Position = UDim2.new(1, -GuiConstants.redXSize - GuiConstants.redXMargin, 0, GuiConstants.redXMargin)
    cancelButton.Image = GuiConstants.redXImage
    cancelButton.BackgroundTransparency = 1
    cancelButton.MouseButton1Click:Connect(function()
        DialogUtils.cleanupDialog()
    end)

    return dialog
end

DialogUtils.showConfirmationDialog = function(title: string, description: string, onConfirm: () -> nil): Frame?
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

    return DialogUtils.makeDialog(dialogConfig)
end

return DialogUtils