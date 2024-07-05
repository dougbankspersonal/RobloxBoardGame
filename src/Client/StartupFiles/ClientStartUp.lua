local ClientStartUp = {}

local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local RobloxBoardGameClient = script.Parent.Parent

local GuiUtils = require(RobloxBoardGameClient.Gui.GuiUtils)
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Global UI elements we care about.
local screenGui: ScreenGui?
local mainFrame: Frame?
local contentFrame: Frame?

local localPlayerId: number?

local publicTables: {CommonTypes.TableDescription} = {}
local invitedTables: {CommonTypes.TableDescription} = {}

type UIMode = {
    TableSelection: "TableSelection",
    TableWaiting: "PublicOrPrivate",
    ShowTables: "ShowTables",
}

local UIModes = {    
    None = "None",
    TableSelection = "UIModes",
    TableWaiting = "TableWaiting",
    TablePlaying = "TablePlaying",
}

local currentUIMode: UIMode = UIModes.None
local uiModeFromServer: UIMode = UIModes.TableSelection

local currentTableDescription: CommonTypes.TableDescription = nil

-- 3d avatar is irrelevant for this game.
local function turnOffPlayerControls()
    local localPlayer = game.Players.LocalPlayer
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
end

-- A user has opted to create a new table.
-- If there's more than one game in GameDetails, then user needs to select which game to 
-- play.
-- FIXME(dbanks): for now I know I just have one game: this will never be called.
local function showSelectGameDialog(onGameIdSelected: (gameId: CommonTypes.GameId) -> nil)
    assert(onGameIdSelected, "Should have onGameIdSelected")
    assert(false, "FIXME showSelectGameDialog")
end

local function promptForGameId(onGameIdSelected: (gameId: CommonTypes.GameId) -> nil)
    -- If more than one game, ask...
    local allGameDetails = GameDetails.getAllGameDetails()
    if #allGameDetails.games > 1 then
        showSelectGameDialog(function(selectedGameId: CommonTypes.GameId)
            onGameIdSelected(selectedGameId)
        end)
    else
        onGameIdSelected(allGameDetails[1].gameId)
    end
end

local function getPublicOrPrivate(onPublicSelected)
    -- Create a dialog to select Public or Private.
    local dialogConfig: CommonTypes.DialogConfig = {
        title = "Public or Private?", 
        description = "Anyone in experience can join a public game.  Only invited players can join a private game.", 
        buttons = {
            {
                text = "Public", 
                callback = function() 
                    onPublicSelected(true) 
                end
            } :: CommonTypes.DialogButtonConfig,
            {
                text = "Private", 
                callback = function() 
                    onPublicSelected(false) 
                end
            } :: CommonTypes.DialogButtonConfig,
        } :: {CommonTypes.DialogConfig},
    }

    GuiUtils.makeDialog(screenGui, dialogConfig)
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
    local invitedTablesRow = contentFrame:FindFirstChild("InvitedTablesRow", true)
    assert(invitedTablesRow, "Should have an invitedTablesRow")
    updateTableRow(invitedTablesRow, invitedTables)
end

local function updatePublicTables()
    local publicTablesRow = contentFrame:FindFirstChild("PublicTablesRow", true)
    assert(publicTablesRow, "Should have an publicTablesRow")
    updateTableRow(publicTablesRow, publicTables)
end

local makeMakeFrameAndContentFrame = function(): Instance
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.458823, 0.509803, 0.733333)
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = 1
    mainFrame.Name = "main"
    mainFrame.BorderSizePixel= 0

    contentFrame = Instance.new("Frame")   
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    
    contentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    contentFrame.Parent = mainFrame
    contentFrame.Name = "content"
    contentFrame.BorderSizePixel= 0
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    task.wait()
    contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)

    GuiUtils.addLayoutOrderTracking(contentFrame)
end

local function makeCreateTableRow()
    local makeTableRow = GuiUtils.addRow(contentFrame)
    makeTableRow.Name = "MakeTablesRow"
    GuiUtils.addButton(makeTableRow, "Host a new Table", function()
        promptForGameId(function(gameId) 
            getPublicOrPrivate(function(public)
                -- Send the event to the server.
                local event = ReplicatedStorage.TableEvents.CreateNewGameTable
                event:FireServer(gameId, public)
            end)
        end)
    end)
end

-- Remove all ui elements from content.
local cleanupCurrentUI = function()
    local children = contentFrame:GetChildren()
    for _, child in children do
        child:Destroy()
    end 
end 

-- build ui elements for the table creation/selection ui.
local buildTableSelectionUI = function()
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = contentFrame

    -- Row to add a new table.
    makeCreateTableRow()

    -- Row to show tables you are invited to.
    local invitedTablesRow = GuiUtils.addRowWithLabel(contentFrame, "Your invitations")
    invitedTablesRow.Name = "InvitedTablesRow"

    -- Row to show public tables.
    local publicTablesRow = GuiUtils.addRowWithLabel(contentFrame, "Public Tables")
    publicTablesRow.Name = "PublicTablesRow"
end    

-- update ui elements for the table creation/selection ui.
local updateTableSelectionUI = function()
    updateInvitedTables()
    updatePublicTables()
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
    uiListLayout.Parent = contentFrame

    assert(currentTableDescription, "Should have a currentTableDescription")
    local row

    row  = GuiUtils.addRowWithLabel(contentFrame, "Game")
    row.Name = "Game"
    GuiUtils.addGameWidget(row, currentTableDescription, true)

    row  = GuiUtils.addRowWithLabel(contentFrame, "Host")
    row.Name = "Host"
    GuiUtils.addPersonWidget(row, currentTableDescription.hostPlayerId)
    
    row = GuiUtils.addRowWithLabel(contentFrame, "Guests")
    for _, memberPlayerId in currentTableDescription.memberPlayerIds do
        GuiUtils.addPersonWidget(row, memberPlayerId)
    end

    row = GuiUtils.addRowWithLabel(contentFrame, "Status")
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

    row = GuiUtils.addRowWithLabel(contentFrame, "Controls")

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

local function buildTablePlayingUI()
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a currentTableDescription.gameId")

    local gameUI = GameUI.getGameUI(currentTableDescription.gameId)
    assert(gameUI, "Should have a gameUI")
    gameUI.buildUI(contentFrame, currentTableDescription)
end

local function updateUI()
    if currentUIMode ~= uiModeFromServer then
        cleanupCurrentUI()
        currentUIMode = uiModeFromServer
        if currentUIMode == UIModes.TableSelection then
            buildTableSelectionUI()
        elseif currentUIMode == UIModes.TableWaiting then
            buildTableWaitingUI()
        else
            buildTablePlayingUI()
        end
    end

    if currentUIMode == UIModes.TableSelection then
        updateTableSelectionUI()
    elseif currentUIMode == UIModes.TableWaiting then
        updateTableWaitingUI()
    else
        updateTablePlayingUI()
    end
end

local function listenToServerEvents()
    local event
    
    event = ReplicatedStorage.TableEvents:WaitForChild("TableCreated")
    event.OnClientEvent:Connect(function(gameTableSummary)
        -- New Table Was Created.
    end)

    event = ReplicatedStorage.TableEvents:WaitForChild("TableDestroyed")
    event.OnClientEvent:Connect(function(gameTableId)
        -- Table was destroyed
    end)

    event = ReplicatedStorage.TableEvents:WaitForChild("TableUpdated")
    event.OnClientEvent:Connect(function(gameTableSummary)
        -- Table was updated
    end)
end

ClientStartUp.StartUp = function(_screenGui: ScreenGui, _allGameDetails: {CommonTypes.GameDetails})
    -- must be at least one.
    assert(_allGameDetails ~= nil, "Should have non=nil game details")
    assert(#_allGameDetails > 0, "Should have at least one game")
    GameDetails.setAllGameDetails(_allGameDetails)

    screenGui = _screenGui
    localPlayerId = game.Players.LocalPlayer.UserId

    assert(localPlayerId, "Should have a localPlayerId")

    screenGui.IgnoreGuiInset = true
    turnOffPlayerControls()
    makeMakeFrameAndContentFrame()
    updateUI()
    listenToServerEvents()
end

return ClientStartUp