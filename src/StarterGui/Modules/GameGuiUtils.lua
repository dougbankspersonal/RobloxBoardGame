--[[
Widgets for games.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)

local GameGuiUtils = {}

-- Standard notion of displaying a game name in text.
-- Start with basic "item text", tweak the size, set the name.
GameGuiUtils.configureGameTextLabel = function(textLabel:TextLabel, gameDetails: CommonTypes.GameDetails)
    assert(textLabel, "Should have textLabel")
    assert(gameDetails, "Should have gameDetails")
    textLabel.Text = gameDetails.name
    textLabel.TextSize = GuiConstants.gameTextLabelFontSize
    textLabel.Size = GuiConstants.gameLabelSize
end

-- Standard notion of displaying a game image in text.
-- Start with basic "item image", tweak the size, set the image.
GameGuiUtils.configureGameImage = function(imageLabel: ImageLabel, gameDetails: CommonTypes.GameDetails): ImageLabel
    assert(imageLabel, "Should have imageLabel")
    assert(gameDetails, "Should have gameDetails")
    imageLabel.Size = UDim2.fromOffset(GuiConstants.gameImageWidth, GuiConstants.gameImageHeight)
    imageLabel.Image = gameDetails.gameImage

    GuiUtils.addCorner(imageLabel)
end

GameGuiUtils.addGameButtonInContainer = function(parent: Instance, gameDetails: CommonTypes.GameDetails, onButtonClicked: () -> nil): (Frame, TextButton)
    local frame, textButton = GuiUtils.addStandardTextButtonInContainer(parent, GuiConstants.gameButtonName, {
        BackgroundTransparency = 1,
        Size = GuiConstants.gameWidgetSize,
    })

    textButton.Activated:Connect(onButtonClicked)

    assert(gameDetails, "Should have gameDetails")
    assert(frame, "Should have frame")

    local imageLabel, textLabel = GuiUtils.addImageOverTextLabel(textButton)

     -- Twiddle the layout.
    local buttonListLayout = textButton:FindFirstChildOfClass("UIListLayout")
    assert(buttonListLayout, "Should have buttonListLayout")
    buttonListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    GameGuiUtils.configureGameTextLabel(textLabel, gameDetails)
    GameGuiUtils.configureGameImage(imageLabel, gameDetails)


    return frame, textButton
end

return GameGuiUtils