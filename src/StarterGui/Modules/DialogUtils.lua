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

DialogUtils.getDialogBackground = function(): Frame?
    local containingScrollingFrame = GuiUtils.getContainingScrollingFrame()
    assert(containingScrollingFrame, "ScreenGui not found")
    return containingScrollingFrame:FindFirstChild(GuiConstants.dialogBackgroundName, true)
end

DialogUtils.cleanupDialog = function()
    local dialogBackground = DialogUtils.getDialogBackground()

    assert(dialogBackground, "DialogBackground not found")

    dialogBackground:Destroy()
end

local function addStandardDialogPadding(frame: Frame)
    GuiUtils.addPadding(frame, {
        PaddingTop = UDim.new(0, GuiConstants.dialogOuterPadding),
        PaddingBottom = UDim.new(0, GuiConstants.dialogOuterPadding),
        PaddingLeft = UDim.new(0, GuiConstants.dialogOuterPadding),
        PaddingRight = UDim.new(0, GuiConstants.dialogOuterPadding),
    })
end

-- Throw up a dialog using the given config.
-- Clicking any button in the config will kill the dialog and hit the associated callback.
DialogUtils.makeDialog = function(dialogConfig: CommonTypes.DialogConfig): Frame?
    local containingScrollingFrame = GuiUtils.getContainingScrollingFrame()
    -- Can't have two dialogs up at once.
    local existingDialogBackground = DialogUtils.getDialogBackground()
    if existingDialogBackground then
        Utils.debugPrint("Error: tried to put up a dialog when one is already up")
        return nil
    end

    -- Make it a text button so it soaks up input.
    local dialogBackground = Instance.new("TextButton")
    dialogBackground.Size = UDim2.fromScale(1, 1)
    dialogBackground.BackgroundColor3 = Color3.new(0, 0, 0)
    dialogBackground.BackgroundTransparency = 0.5
    dialogBackground.Parent = containingScrollingFrame
    dialogBackground.Name = GuiConstants.dialogBackgroundName
    dialogBackground.ZIndex = GuiConstants.dialogBackgroundZIndex
    dialogBackground.AutomaticSize = Enum.AutomaticSize.XY
    dialogBackground.Text = ""
    dialogBackground.AutoButtonColor = false

    GuiUtils.addUIListLayout(dialogBackground, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

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

    addStandardDialogPadding(contentFrame)

    GuiUtils.addUIListLayout(contentFrame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, GuiConstants.paddingBetweenRows),
    })

    local titleContent = GuiUtils.addRowAndReturnRowContent(contentFrame, "Row_Title")
    local title = GuiUtils.addTextLabel(titleContent, "<b>" .. dialogConfig.title .. "</b>", {RichText = true})
    title.TextSize = GuiConstants.dialogTitleFontSize

    local descriptionContent = GuiUtils.addRowAndReturnRowContent(contentFrame, "Row_Description")
    GuiUtils.addTextLabel(descriptionContent, GuiUtils.italicize(dialogConfig.description), {
        RichText = true,
        TextWrapped = true,
    })

    -- There should be exactly one of dialogButtonConfigs or makeRowAndAddCustomControls
    local hasDialogButtonConfigs = dialogConfig.dialogButtonConfigs and #dialogConfig.dialogButtonConfigs > 0
    local hasMakeRowAndAddCustomControls = dialogConfig.makeRowAndAddCustomControls
    assert(hasDialogButtonConfigs or hasMakeRowAndAddCustomControls, "Should at least one of dialogButtonConfigs or hasMakeRowAndAddCustomControls")
    assert(not (hasDialogButtonConfigs and hasMakeRowAndAddCustomControls), "Should not have both dialogButtonConfigs hasMakeRowAndAddCustomControls")

    if hasDialogButtonConfigs then
        local rowContent = GuiUtils.addRowAndReturnRowContent(contentFrame, "Row_Controls", nil, {
            horizontalAlignment = Enum.HorizontalAlignment.Center,
            wraps = true,
        })

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
    cancelButton.Size = UDim2.fromOffset(GuiConstants.redXSize, GuiConstants.redXSize)
    cancelButton.Position = UDim2.new(1, -GuiConstants.redXSize - GuiConstants.redXMargin, 0, GuiConstants.redXMargin)
    cancelButton.Image = GuiConstants.redXImage
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