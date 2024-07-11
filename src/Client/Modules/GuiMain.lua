--[[
    GuiMain.lua
    The top level functions for building user interface.
]]

local GuiMain = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Shared...
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local UIModes = require(RobloxBoardGameShared.Globals.UIModes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Client...
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local GameUIs = require(RobloxBoardGameClient.Globals.GameUIs)
local TableDescriptions = require(RobloxBoardGameClient.Modules.TableDescriptions)

-- Globals
local localPlayerId = Players.LocalPlayer.UserId
assert(localPlayerId, "Should have a localPlayerId")

local mainFrame: Frame?
local screenGui: ScreenGui?

local currentUIMode: CommonTypes.UIMode = UIModes.None
local cleanupFunctionsForCurrentUIMode = {}:: {() -> nil}
local uiModeFromServer: CommonTypes.UIMode = UIModes.Loading

local publicTables: {CommonTypes.TableDescription} = {}
local invitedTables: {CommonTypes.TableDescription} = {}

local currentTableDescription: CommonTypes.TableDescription = nil

--[[
    makeMainFrame
    Creates the main frame for the user interface.
    @param _screenGui: ScreenGui
    @returns: nil
]]
GuiMain.makeMainFrame = function(_screenGui: ScreenGui)
    screenGui = _screenGui
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.458823, 0.509803, 0.733333)
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = 1
    mainFrame.Name = "main"
    mainFrame.BorderSizePixel= 0

    GuiUtils.addLayoutOrderTracking(mainFrame)
end

--[[
    Remove all ui elements from mainFrame.
]]
local cleanupCurrentUI = function()
    -- Cancel anything that needs cancelling.
    for _, cleanupFunction in cleanupFunctionsForCurrentUIMode do
        cleanupFunction()
    end
    cleanupFunctionsForCurrentUIMode = {}

    -- Remove all the ui elements.
    local children = mainFrame:GetChildren()
    for _, child in children do
        child:Destroy()
    end
end

--[[
    Host has requested to create a table.
    They must select:
    * Which game to play.
    * Whether the game is public or private.
]]
local function promptForTableConfig(onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
    -- FIXME(dbanks)
    -- Right now there's just one experience using this library (SFBG) and one game in that experience
    -- (Nuts) so I am going to fudge this for now.
    local gameDetailsByGameId = GameDetails.getAllGameDetails()
    assert(gameDetailsByGameId, "Should have gameDetailsByGameId")
    assert(#gameDetailsByGameId == 1, "FIXME(dbanks): current use case I know we only have one game, I am coding accordingly.  Once we have mumtiple games, fix this.")

    local gameId
    for gid, _ in gameDetailsByGameId do
        break
    end
    assert(gameId ~= nil, "Should have a gameId")
    assert(type(gameId) == "number", "gameId should be a number")

    -- Put up a UI to get public or private.
    -- FIXME(dbanks): this is horrible temp hack using an array of buttons to pick from a set of two options.
    -- Implement a proper toggle switch (or radio buttons or whatever)
    local dialogConfig: CommonTypes.DialogConfig = {
        title = "Public or Private?",
        description = "Anyone in experience can join a public game.  Only invited players can join a private game.",
        buttons = {
            {
                text = "Public",
                callback = function()
                    onTableConfigSelected(gameId, true)
                end
            } :: CommonTypes.DialogButtonConfig,
            {
                text = "Private",
                callback = function()
                    onTableConfigSelected(gameId, false)
                end
            } :: CommonTypes.DialogButtonConfig,
        } :: {CommonTypes.DialogConfig},
    }

    GuiUtils.makeDialog(screenGui, dialogConfig)
end

local onCreateTableButtonClicked = function()
    -- user must select a game and whether it is public or invite-only.
    promptForTableConfig(function(gameId, isPublic)
        -- Send all this along to the server.
        ClientEventManagement.createTable(gameId, isPublic)
    end)
end

--[[
    Make a row to contain controls for creating a new table.
]]
local function makeCreateTableRow()
    local makeTableRow = GuiUtils.addRow(mainFrame)
    makeTableRow.Name = "MakeTablesRow"
    GuiUtils.addButton(makeTableRow, "Host a new Table", onCreateTableButtonClicked)
end

--[[
Build ui elements for an inital "loading" screen while we fetch stuff from the server.
]]
local buildLoadingUI = function()
    -- FIXME(dbanks): extremely ugly hackery/placeholder.
    local frame = Instance.new("Frame")
    frame.Name = "LoadingFrame"
    frame.Parent = mainFrame
    frame.Size = UDim2.fromScale(1, 1)
    frame.Position = UDim2.fromOffset(0, 0)
    frame.BackgroundColor3 = Color3.new(1, 0.5, 0.5)

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "LoadingLabel"
    textLabel.Parent = frame
    textLabel.Size = UDim2.fromOffset(200, 200)
    textLabel.Text = "Loading"
    textLabel.BackgroundTransparency = 1
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.Position = UDim2.fromScale(0.5, 0.5)

    -- Make it wiggle so you know things are not stuck.
    local jiggleMagnitude = 5
    textLabel.Rotation = jiggleMagnitude

    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
    local tween = TweenService:Create(textLabel, tweenInfo, {Rotation = -jiggleMagnitude})
    tween:Play()
    -- add a function so that when this UI is killed we kill the tween.
    local stopTween = function()
        tween:Cancel()
    end
    table.insert(cleanupFunctionsForCurrentUIMode, stopTween)

end

--[[
    Build ui elements for the table creation/selection ui.
]]
local buildTableSelectionUI = function()
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = mainFrame

    -- Row to add a new table.
    makeCreateTableRow()

    -- Row to show tables you are invited to.
    local invitedTablesRow = GuiUtils.addRowWithLabel(mainFrame, "Your invitations")
    invitedTablesRow.Name = "InvitedTablesRow"

    -- Row to show public tables.
    local publicTablesRow = GuiUtils.addRowWithLabel(mainFrame, "Public Tables")
    publicTablesRow.Name = "PublicTablesRow"
end

local function hasEnoughPlayers() : boolean
    assert(currentTableDescription, "Should have a currentTableDescription")
    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    return #currentTableDescription.memberPlayerIds >= gameDetails.minPlayers
end

local function roomForMorePlayers() : boolean
    assert(currentTableDescription, "Should have a currentTableDescription")
    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    assert(gameDetails.maxPlayers, "GameDetails should have a maxPlayers")
    assert(gameDetails.maxPlayers > 0, "GameDetails should have non-zero maxPlayers")
    assert(gameDetails.maxPlayers >= #currentTableDescription.memberPlayerIds, "GameDetails.maxPlayers should be >= #currentTableDescription.memberPlayerIds")
    return #currentTableDescription.memberPlayerIds < gameDetails.maxPlayers
end

-- build ui elements for the when players are waiting at a table for game to start.
local buildTableWaitingUI = function()
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = mainFrame

    assert(currentTableDescription, "Should have a currentTableDescription")
    local row

    row  = GuiUtils.addRowWithLabel(mainFrame, "Game")
    row.Name = "Game"
    GuiUtils.addGameWidget(row, currentTableDescription, true)

    row  = GuiUtils.addRowWithLabel(mainFrame, "Host")
    row.Name = "Host"
    GuiUtils.addPlayerWidget(row, currentTableDescription.hostPlayerId)

    row = GuiUtils.addRowWithLabel(mainFrame, "Guests")
    for memberPlayerId, _ in currentTableDescription.memberPlayerIds do
        GuiUtils.addPlayerWidget(row, memberPlayerId)
    end

    row = GuiUtils.addRowWithLabel(mainFrame, "Status")
    if localPlayerId == currentTableDescription.hostPlayerId then
        if not hasEnoughPlayers() then
            GuiUtils.addLabel(row, "Waiting for more minimum number of players to join.")
        elseif roomForMorePlayers() then
            GuiUtils.addLabel(row, "Press start when ready, or wait for more players to join.")
        else
            GuiUtils.addLabel(row, "Press start when ready.")
        end
    else
        GuiUtils.addLabel(row, "Waiting for game to start")
    end

    row = GuiUtils.addRowWithLabel(mainFrame, "Controls")

    if localPlayerId == currentTableDescription.hostPlayerId then
        GuiUtils.addButton(row, "Start Game", function()
            print("FIXME: start game")
        end)
        GuiUtils.addButton(row, "Destroy Table", function()
            print("FIXME: destroy game")
        end)
    else
        GuiUtils.addButton(row, "Leave Table", function()
            print("FIXME: leave table")
        end)
    end
end

local function buildTablePlayingUI(): nil
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a currentTableDescription.gameId")

    local gameUI = GameUIs.getGameUI(currentTableDescription.gameId)
    assert(gameUI, "Should have a gameUI")
    gameUI.buildUI(mainFrame, currentTableDescription)
end

-- Which table buttons have no description?
local function getTableButtonContainersOut(tableButtonContainers, tableDescriptions)
    local tableButtonsContainersOut = {}
    for _, tableButtonContainer in tableButtonContainers do
        local tableId = tableButtonContainer.TableId.Value
        local tableButtonInDescs = false
        for _, tableDescription in tableDescriptions do
            if tableDescription.tableId == tableId then
                tableButtonInDescs = true
                break
            end
        end
        if not tableButtonInDescs then
            table.insert(tableButtonsContainersOut, tableButtonContainer)
        end
    end
    return tableButtonsContainersOut
end

-- Which table descriptions have no buttons?
local function getTableDescriptionsIn(tableButtonContainers, tableDescriptions)
    local tableDescriptionsIn = {}
    for _, tableDescription in tableDescriptions do
        local tableId = tableDescription.tableId
        local tableDescInButtons = false
        for _, tableButtonContainer in tableButtonContainers do
            if tableId == tableButtonContainer.TableId.Value then
                tableDescInButtons = true
                break
            end
        end
        if not tableDescInButtons then
            table.insert(tableDescriptionsIn, tableDescription)
        end
    end
    return tableDescriptionsIn
end

local function makeTableButtonContainer(parent: Instance, tableDescription: CommonTypes.TableDescription): Instance
    local tableButtonContainer = Instance.new("Frame")
    tableButtonContainer.Parent = parent
    tableButtonContainer.Size = UDim2.new(0, 200, 0, 30)
    tableButtonContainer.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
    tableButtonContainer.BorderSizePixel = 0
    tableButtonContainer.Name = "TableButtonContainer"
    tableButtonContainer.TableId = Instance.new("IntValue")
    tableButtonContainer.TableId.Value = tableDescription.tableId

    GuiUtils.makeTableButton(tableButtonContainer, tableDescription, function()
    end)

    return tableButtonContainer
end

local function updateTableRow(tableRow:Instance, tableDescriptions:{CommonTypes.TableDescription})
    local allKids = tableRow:GetChildren()
    local tableButtonContainers = {}
    for _, kid in allKids do
        if kid.Name == "TableButtonContainer" then
            table.insert(tableButtonContainers, kid)
        end
    end

    local tableButtonsContainersOut = getTableButtonContainersOut(tableButtonContainers, tableDescriptions)
    local tableDescriptionsIn = getTableDescriptionsIn(tableButtonContainers, tableDescriptions)

    local tweenInfo = TweenInfo.new(0.5)

    -- Tween out unused buttons.
    for _, tableButtonContainer in tableButtonsContainersOut do
        local uiScale = tableButtonContainer:FindFirstChild("UIScale")
        if not uiScale then
            uiScale = Instance.new("UIScale")
            uiScale.Name = "UIScale"
            uiScale.Parent = tableButtonContainer
            uiScale.Scale = 1
        end
        local tween = TweenService:Create(uiScale, tweenInfo, {Scale = 0})
        tween.Completed:Connect(function(_)
            tableButtonContainer:Destroy()
        end)
        tween:Play()
    end

    -- Tween in new buttons.
    for _, tableDescription in tableDescriptionsIn do
        local tableButtonContainer = makeTableButtonContainer(tableRow, tableDescription)
        local tween = TweenService:Create(tableButtonContainer.UIScale, tweenInfo, {Scale = 1})
        tween:Play()
    end
end

local function updateInvitedTables()
    local invitedTablesRow = mainFrame:FindFirstChild("InvitedTablesRow", true)
    assert(invitedTablesRow, "Should have an invitedTablesRow")
    updateTableRow(invitedTablesRow, invitedTables)
end

local function updatePublicTables()
    local publicTablesRow = mainFrame:FindFirstChild("PublicTablesRow", true)
    assert(publicTablesRow, "Should have an publicTablesRow")
    updateTableRow(publicTablesRow, publicTables)
end

-- update ui elements for the table creation/selection ui.
local updateTableSelectionUI = function()
    updateInvitedTables()
    updatePublicTables()
end

-- update ui elements for the "in a table and waiting for game to start"
-- UI.
local updateTableWaitingUI = function()
    assert(false, "FIXME(dbanks) updateTableWaitingUI")
end

-- update ui elements for the "in a table and game is playing" UI.
local updateTablePlayingUI = function()
    assert(false, "FIXME(dbanks) updateTablePlayingUI")
end

--[[
    When we receieve updates from the server, this function is called.
    Updates UI to reflect current state.
]]
GuiMain.updateUI = function()
    if currentUIMode ~= uiModeFromServer then
        cleanupCurrentUI()
        currentUIMode = uiModeFromServer
        if currentUIMode == UIModes.Loading then
            buildLoadingUI()
        elseif currentUIMode == UIModes.TableSelection then
            buildTableSelectionUI()
        elseif currentUIMode == UIModes.TableWaiting then
            buildTableWaitingUI()
        elseif currentUIMode == UIModes.TablePlaying then
            buildTablePlayingUI()
        end
    end

    if currentUIMode == UIModes.TableSelection then
        updateTableSelectionUI()
    elseif currentUIMode == UIModes.TableWaiting then
        updateTableWaitingUI()
    elseif currentUIMode == UIModes.TablePlaying then
        updateTablePlayingUI()
    end
end

GuiMain.onTableCreated = function(tableDescription: CommonTypes.TableDescription)
    TableDescriptions.addTableDescription(tableDescription)
    GuiMain.updateUI()
end

GuiMain.onTableDestroyed = function(tableId: CommonTypes.TableId)
    TableDescriptions.removeTableDescription(tableId)
end

    onTableUpdated: (tableDescription: CommonTypes.TableDescription) -> nil

return GuiMain