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
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)
local SanityChecks = require(RobloxBoardGameShared.Modules.SanityChecks)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local ClientTableDescriptions = require(RobloxBoardGameClient.Modules.ClientTableDescriptions)
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local ClientGameInstanceFunctions = require(RobloxBoardGameClient.Globals.ClientGameInstanceFunctions)

local metadataLayoutOrder = 0

local addMetadataElement = function(parent: GuiObject, text: string, fontSize: number): TextLabel
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

local fillInMetadata = function(tableMetadataFrame: Frame, tableDescription: CommonTypes.TableDescription)
    metadataLayoutOrder = 0

    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    addMetadataElement(tableMetadataFrame, gameDetails.name, GuiConstants.gamePlayingSidebarH1FontSize)

    addMetadataElement(tableMetadataFrame, "Players", GuiConstants.gamePlayingSidebarH2FontSize)

    local hostName = PlayerUtils.getName(tableDescription.hostUserId)
    local hostString = hostName .. " " .. "(host)"
    hostString = GuiUtils.italicize(hostString)
    addMetadataElement(tableMetadataFrame, hostString, GuiConstants.gamePlayingSidebarNormalFontSize)

    for userId, _ in pairs(tableDescription.memberUserIds) do
        if userId ~= tableDescription.hostUserId then
            local playerName = PlayerUtils.getName(userId)
            addMetadataElement(tableMetadataFrame, GuiUtils.italicize(playerName), GuiConstants.gamePlayingSidebarNormalFontSize)
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
            addMetadataElement(tableMetadataFrame, GuiUtils.italicize(optionValue), GuiConstants.gamePlayingSidebarNormalFontSize)
        end
    end
end

local addSidebar = function(mainFrame: GuiObject, tableDescription: CommonTypes.TableDescription): Frame
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
    local tableMetadataFrame = GuiUtils.addStandardScrollingFrame(sideBarFrame)
    tableMetadataFrame.Name = GuiConstants.gamePlayingTableMetadataName
    tableMetadataFrame.Position = UDim2.new(0, 0, 0, 0)
    tableMetadataFrame.Size = UDim2.new(1, 0, 1, -GuiConstants.gamePlayingSidebarControlsHeight)
    tableMetadataFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    tableMetadataFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tableMetadataFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
    tableMetadataFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
--     GuiUtils.sanitizeScrollingFrame(tableMetadataFrame)
    GuiUtils.addUIGradient(tableMetadataFrame, GuiConstants.scrollBackgroundGradient)
    GuiUtils.addUIPadding(tableMetadataFrame)
    local listLayout = GuiUtils.addUIListLayout(tableMetadataFrame, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    })
    listLayout.Padding = UDim.new(0, 0)

    fillInMetadata(tableMetadataFrame, tableDescription)

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
        GuiUtils.addStandardTextButtonInContainer(controlsFrame, "End Game", function()
            ClientEventManagement.endGame(tableDescription.tableId)
        end)
    else
        -- Guest controls.
        GuiUtils.addStandardTextButtonInContainer(controlsFrame, "Leave Table", function()
            ClientEventManagement.leaveTable(tableDescription.tableId)
        end)
    end

    return sideBarFrame
end

local makeClientGameFrame = function(mainFrame: GuiObject)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = GuiConstants.gamePlayingContentName
    contentFrame.Parent = mainFrame
    contentFrame.Position = UDim2.new(0, GuiConstants.gamePlayingSidebarWidth, 0, 0)
    contentFrame.Size = UDim2.new(1, -GuiConstants.gamePlayingSidebarWidth, 1, 0)
    contentFrame.BackgroundTransparency = 1
    return contentFrame
end

local makeClientGameInstanceAsync = function(tableDescription: CommonTypes.TableDescription, frame: Frame): CommonTypes.ClientGameInstance
    -- Let game build its UI in here.
    local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(tableDescription.gameId)
    assert(clientGameInstanceFunctions, "Should have gameInstanceFunctions")
    assert(clientGameInstanceFunctions.makeClientGameInstanceAsync, "Should have gameInstanceFunctions.makeClientGameInstanceAsync")
    local clientGameInstance = clientGameInstanceFunctions.makeClientGameInstanceAsync(tableDescription, frame)
    SanityChecks.sanityCheckClientGameInstance(clientGameInstance)
    return clientGameInstance
end

-- Create barebones structure for this UI,
-- Do not bother filling in anything that might change over time: this comes with update.
function TablePlayingUI.build(tableId: CommonTypes.TableId)
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

    addSidebar(mainFrame, tableDescription)
    local gameFrame = makeClientGameFrame(mainFrame)
    task.spawn(function()
        local gameInstance = makeClientGameInstanceAsync(tableDescription, gameFrame)
        SanityChecks.sanityCheckClientGameInstance(gameInstance)
    end)
end

function TablePlayingUI.update()
end

return TablePlayingUI