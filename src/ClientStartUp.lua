local ClientStartUp = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rgbConfig
local screenGui

function shutDownAvatar()
    -- Shut down the avatar.
    local ContextActionService = game:GetService("ContextActionService")
    local FREEZE_ACTION = "freezeMovement"

    ContextActionService:BindAction(FREEZE_ACTION,
        function() return Enum.ContextActionResult.Sink end,
        false,
        unpack(Enum.PlayerActions:GetEnumItems()))
end 


local addRow = function(parent, rowIndex)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.Parent = parent
    row.LayoutOrder = rowIndex

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = row
    uiListLayout.FillDirection = Enum.FillDirection.Horizontal
    uiListLayout.Padding = UDim.new(0, 10)

    return uiListLayout, rowIndex + 1
end

local addButton = function(parent, text, onClick)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 0, 0, 50)
    button.AutomaticSize = Enum.AutomaticSize.Y
    button.Text = text
    button.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    button.Parent = parent

    button.Activated:Connect(onClick)

    return button
end

local addLabel = function(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 0, 0, 50)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Text = text
    label.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    label.Parent = parent
    return label
end

function showSelectGameDialog(onGameIdSelected)
    -- Create a dialog to select the game.
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0.5, 0, 0.5, 0)
    dialog.Position = UDim2.new(0.25, 0, 0.25, 0)
    dialog.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    dialog.Parent = screenGui

    local rowIndex = 0
    local row, rowIndex = addRow(dialog, rowIndex)
    local label = addLabel(row, "Select Game")
    label.TextSize = 24

    for gameId, gameDetails in ipairs(rgbConfig.gameDetailsList) do
        local row, rowIndex = addRow(dialog, rowIndex)
        addButton(row, gameDetails.name, function()
            dialog:Destroy()
            onGameIdSelected(gameId)
        end)
    end
end

function getGameId(onGameIdSelected)
    -- If more than one game, ask...
    if #rgbConfig.games > 1 then
        showSelectGameDialog(function(selectedGameId)
            onGameIdSelected(selectedGameId)
        end)
    else
        onGameIdSelected(rgbConfig.games[1].id)
    end
end

function getPublicOrPrivate(onPublicSelected)
    -- Create a dialog to select Public or Private.
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0.5, 0, 0.5, 0)
    dialog.Position = UDim2.new(0.25, 0, 0.25, 0)
    dialog.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    dialog.Parent = screenGui

    local row = addRow(dialog)
    local label = addLabel(row, "Public or Private")
    label.TextSize = 24

    local row = addRow(dialog)
    local button = addButton(row, "Public", function()
        dialog:Destroy()
        onPublicSelected(true)
    end)

    local row = addRow(dialog)
    local button = addButton(row, "Private", function()
        dialog:Destroy()
        onPublicSelected(false)
    end)
end

function createUI()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.Parent = screenGui
    frame.ZIndex = 1

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.Parent = frame

    local rowIndex = 0
    local row, rowIndex = addRow(frame, rowIndex)
    local button = addButton(row, "Create Table", function()
        getGameId(function(gameId) 
            getPublicOrPrivate(function(public)
                -- Send the event to the server.
                local event = ReplicatedStorage.TableEvents.CreateNewGameTable
                event:FireServer(gameId, public)
            end)
        end)
    end)
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

ClientStartUp.StartUp = function(_screenGui, _rgbConfig)
    rgbConfig = _rgbConfig
    screenGui = _screenGui
    shutDownAvatar()
    createUI()
    listenToServerEvents()
end

return ClientStartUp