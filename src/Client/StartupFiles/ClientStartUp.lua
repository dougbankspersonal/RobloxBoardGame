local ClientStartUp = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local RobloxBoardGameClient = script.Parent.Parent

local GuiMain = require(RobloxBoardGameClient.Gui.GuiMain)
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Global UI elements we care about.
local screenGui: ScreenGui?

-- 3d avatar is irrelevant for this game.
local function turnOffPlayerControls()
    local localPlayer = game.Players.LocalPlayer
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
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

    screenGui.IgnoreGuiInset = true
    turnOffPlayerControls()
    GuiMain.makeMakeFrameAndContentFrame(screenGui)
    GuiMain.updateUI()
    listenToServerEvents()
end

return ClientStartUp