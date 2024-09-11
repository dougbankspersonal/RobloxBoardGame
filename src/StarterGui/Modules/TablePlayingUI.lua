--[[
UIMode is TablePlaying.
Local player belongs to exactly one table (as host or guest) and
that table is in GameTableStates.Playing.
UI Shows:
    * a frame with data and controls common to all games (name, host, players, controls, etc).
    * an area for game-specific UI.
]]

local TablePlayingUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local ClientTableDescriptions = require(RobloxBoardGameStarterGui.Modules.ClientTableDescriptions)
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)
local GameUIs = require(RobloxBoardGameStarterGui.Globals.GameUIs)
local ClientEventManagement = require(RobloxBoardGameStarterGui.Modules.ClientEventManagement)

local metadataLayoutOrder = 0

local addMetadataElement = function(parent: GuiObject, text: string, fontSize: nubmer): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = "SidebarElement"
    label.Parent = parent
    label.Text = text
    label.TextSize = fontSize
    label.TextWrapped = true
    label.Size = UDim2.new(1, 0, 0, 0)
    label.LayoutOrder = metadataLayoutOrder
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.RichText = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    metadataLayoutOrder = metadataLayoutOrder + 1
    label.BackgroundTransparency = 1

    if fontSize == GuiConstants.gamePlayingSidebarH2FontSize then
        GuiUtils.addUIPadding(label, {
            PaddingBottom = UDim.new(0, 0),
            PaddingTop = UDim.new(0, GuiConstants.gamePlayingSidebarH2Separation),
            PaddingLeft = UDim.new(0, 0),
            PaddingRight = UDim.new(0, 0),
        })
    elseif fontSize == GuiConstants.gamePlayingSidebarH3FontSize then
        GuiUtils.addUIPadding(label, {
            PaddingBottom = UDim.new(0, 0),
            PaddingTop = UDim.new(0, GuiConstants.gamePlayingSidebarH3Separation),
            PaddingLeft = UDim.new(0, 0),
            PaddingRight = UDim.new(0, 0),
        })
    elseif fontSize == GuiConstants.gamePlayingSidebarNormalFontSize then
            GuiUtils.addUIPadding(label, {
            PaddingBottom = UDim.new(0, 0),
            PaddingTop = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, GuiConstants.gamePlayingSidebarMetadataValueIndent),
            PaddingRight = UDim.new(0, 0),
        })
    end

    return label
end

local fillInMetadataAsync = function(tableMetadataFrame: Frame, tableDescription: CommonTypes.TableDescription, gameDetails: CommonTypes.GameDetails)
    metadataLayoutOrder = 0

    addMetadataElement(tableMetadataFrame, gameDetails.name, GuiConstants.gamePlayingSidebarH1FontSize)

    addMetadataElement(tableMetadataFrame, "Players", GuiConstants.gamePlayingSidebarH2FontSize)

    local hostName = PlayerUtils.getNameAsync(tableDescription.hostUserId)
    local hostString = GuiConstants.bulletString .. " " .. hostName .. " " .. GuiUtils.italicize("(host)")
    addMetadataElement(tableMetadataFrame, hostString, GuiConstants.gamePlayingSidebarNormalFontSize)

    for userId, _ in pairs(tableDescription.memberUserIds) do
        if userId ~= tableDescription.hostUserId then
            local playerName = PlayerUtils.getNameAsync(userId)
            addMetadataElement(tableMetadataFrame, GuiConstants.bulletString .. playerName, GuiConstants.gamePlayingSidebarNormalFontSize)
        end
    end

    -- Config options, as applicable.
    if gameDetails.gameOptions and #gameDetails.gameOptions > 0 then
        local nonDefaultGameOptions = tableDescription.opt_nonDefaultGameOptions or {}

        addMetadataElement(tableMetadataFrame, "Options", GuiConstants.gamePlayingSidebarH2FontSize)

        for _, gameOption in gameDetails.gameOptions do
            local optionValue = GuiUtils.getOptionValue(gameOption, nonDefaultGameOptions)
            assert(optionValue, "Should have an optionValue")

            local optionName = gameOption.name
            assert(optionName, "Should have an optionName")

            addMetadataElement(tableMetadataFrame, optionName, GuiConstants.gamePlayingSidebarH3FontSize)
            addMetadataElement(tableMetadataFrame, optionValue, GuiConstants.gamePlayingSidebarNormalFontSize)
        end
    end
end

local addSidebar = function(mainFrame: GuiObject, tableDescription: CommonTypes.TableDescription, gameDetails: CommonTypes.GameDetails): Frame
    local sideBarFrame = Instance.new("Frame")
    sideBarFrame.Name = GuiConstants.gamePlayingSideBarName
    sideBarFrame.BorderSizePixel = 1
    sideBarFrame.BorderColor3 = GuiConstants.gamePlayingSidebarBorderColor
    sideBarFrame.BackgroundColor3 = GuiConstants.gamePlayingSidebarColor
    sideBarFrame.Position = UDim2.fromOffset(0, 0)
    sideBarFrame.Size = UDim2.new(0, GuiConstants.gamePlayingSidebarWidth, 1, 0)
    sideBarFrame.Parent = mainFrame

    GuiUtils.addUIGradient(sideBarFrame, GuiConstants.standardMainScreenColorSequence)
    GuiUtils.addUIPadding(sideBarFrame)

    -- top section with metadata.
    local tableMetadataFrame = Instance.new("ScrollingFrame")
    tableMetadataFrame.Name = GuiConstants.gamePlayingTableMetadataName
    tableMetadataFrame.Parent = sideBarFrame
    tableMetadataFrame.Position = UDim2.new(0, 0, 0, 0)
    tableMetadataFrame.Size = UDim2.new(1, 0, 1, -GuiConstants.gamePlayingSidebarControlsHeight - GuiConstants.standardPadding)
    tableMetadataFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    tableMetadataFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tableMetadataFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
    tableMetadataFrame.BackgroundColor3 = GuiConstants.scrollBackgroundColor
    GuiUtils.addUIGradient(tableMetadataFrame, GuiConstants.scrollBackgroundGradient)
    GuiUtils.addUIPadding(tableMetadataFrame)
    GuiUtils.addUIListLayout(tableMetadataFrame, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    -- Use a task for async name grabbing.
    task.spawn(function()
        fillInMetadataAsync(tableMetadataFrame, tableDescription, gameDetails)
    end)

    -- Bottom section with controls.
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Parent = sideBarFrame
    controlsFrame.Name = GuiConstants.gamePlayingControlsName
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Position = UDim2.fromScale(0, 1)
    controlsFrame.AnchorPoint = Vector2.new(0, 1)
    controlsFrame.Size = UDim2.new(1, 0, 0, GuiConstants.gamePlayingSidebarControlsHeight)

    GuiUtils.addUIListLayout(controlsFrame)

    if tableDescription.hostUserId == game.Players.LocalPlayer.UserId then
        -- Host controls.
        GuiUtils.addTextButtonInContainer(controlsFrame, "End Game", function()
            ClientEventManagement.endGameEarly(tableDescription.tableId)
        end)
    else
        -- Guest controls.
        GuiUtils.addButton(controlsFrame, "Leave Table", function()
            ClientEventManagement.leaveTable(tableDescription.tableId)
        end)
    end

    return sideBarFrame
end

local addGameSpecificContainer = function(mainFrame: GuiObject, tableDescription: CommonTypes.TableDescription, gameDetails: CommonTypes.GameDetails): Frame
    local content = Instance.new("Frame")
    content.Name = GuiConstants.gamePlayingContentName
    content.Parent = mainFrame
    content.Position = UDim2.new(0, GuiConstants.gamePlayingSidebarWidth, 0, 0)
    content.Size = UDim2.new(1, -GuiConstants.gamePlayingSidebarWidth, 1, 0)
    content.BackgroundTransparency = 1

    return content
end

-- Create barebones structure for this UI,
-- Do not bother filling in anything that might change over time: this comes with update.
TablePlayingUI.build = function(tableId: CommonTypes.TableId)
    -- Sanity check arguments, get all the other stuff we need.
    assert(tableId, "Should have a tableId")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local tableDescription = ClientTableDescriptions.getTableDescription(tableId)
    assert(tableDescription, "Should have a tableDescription")

    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    assert(gameDetails, "Should have a gameDetails")

    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    mainFrame.BackgroundColor3 = GuiConstants.gamePlayingBackgroundColor
    GuiUtils.addUIGradient(mainFrame, GuiConstants.standardMainScreenColorSequence)

    addSidebar(mainFrame, tableDescription, gameDetails)
    addGameSpecificContainer(mainFrame, tableDescription, gameDetails)
end

TablePlayingUI.update = function()
    Utils.debugPrint("TablePlaying", "Doug: in TablePlayingUI.update")
end

return TablePlayingUI