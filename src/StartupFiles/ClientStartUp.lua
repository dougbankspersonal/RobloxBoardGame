local ClientStartUp = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GuiUtils = require(script.Parent.Parent.Gui.GuiUtils)
local CommonTypes = require(script.Parent.Parent.Types.CommonTypes)
local GameDetails = require(script.Parent.Parent.Globals.GameDetails)


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
    TableSelection = "UIModes",
    TableWaiting = "TableWaiting",
    TablePlaying = "TablePlaying",
}

local currentUIMode: UIMode = UIModes.TableSelection
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

local function addGameButton(row: Frame, gameId: CommonTypes.GameId, gameDetails: CommonTypes.GameDetails, onGameIdSelected: (gameId: CommonTypes.GameId) -> nil)
    local button = Instance.new("TextButton")
    button.Parent = row
    button.Size = UDim2.new(0, 0, 1, 0)
    button.AutomaticSize = Enum.AutomaticSize.XY
    button.Position = UDim2.new(0, 0, 0, 0)
    button.Text = ""
    button.TextSize = 14
    button.LayoutOrder = GuiUtils.getLayoutOrder(row)
    button.MouseButton1Click:Connect(onGameIdSelected)
    button.BorderSizePixel = 3
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.Parent = button
    uiCorner.CornerRadius = UDim.new(0, 4)

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Image = gameDetails.GameImage

    return button

end


local function showSelectGameDialog(onGameIdSelected: (gameId: CommonTypes.GameId) -> nil)
    -- Create a dialog to select the game.
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0.5, 0, 0.5, 0)
    dialog.Position = UDim2.new(0.25, 0, 0.25, 0)
    dialog.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    dialog.Parent = screenGui
    GuiUtils.addLayoutOrderTracking(dialog)

    local row = GuiUtils.addRowWithLabel(dialog, "Select Game")

    local allGameDetails = GameDetails.getAllGameDetails()
    for _, gameDetails in ipairs(allGameDetails) do
        addGameButton(row, gameDetails, onGameIdSelected)
    end
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

local function updateTableRow(tableRow:Instance, tableDescriptions:{CommonTypes.TableDescription})
    local allKids = tableRow:GetChildren()
    local tableButtonContainers = {}
    for _, kid in allKids do
        if kid:IsA("Frame") then
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

    contentFrame = Instance.new("Frame")   
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    contentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    contentFrame.Parent = mainFrame
    contentFrame.Name = "content"
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

local function hasEnoughPlayers() 
    assert(currentTableDescription, "Should have a currentTableDescription")
    local gameDetails = getGameDetails(currentTableDescription.gameId)
    return #currentTableDescription.memberPlayerIds >= gameDetails.minPlayers
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
        elseif roomForMorePlayer() then
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