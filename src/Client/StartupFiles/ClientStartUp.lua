local ClientStartUp = {}

local RobloxBoardGameClient = script.Parent.Parent
local GuiMain = require(RobloxBoardGameClient.Gui.GuiMain)
local GameUIs = require(RobloxBoardGameClient.Globals.GameUIs)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Utils.Utils)

-- 3d avatar is irrelevant for this game.
local function turnOffPlayerControls()
    local localPlayer = game.Players.LocalPlayer
    assert(localPlayer, "localPlayer not found")
    local controls = require(localPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
    assert(controls, "controls not found")
    controls:Disable()
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

ClientStartUp.ClientStartUp = function(screenGui: ScreenGui, gameDetailsByGameId: CommonTypes.GameDetailsByGameId, gameUIsByGameId: CommonTypes.GameUIsByGameId)
    -- must be at least one.
    assert(#gameDetailsByGameId > 0, "Should have at least one game")
    -- Sanity checks.
    assert(gameDetailsByGameId ~= nil, "Should have non=nil gameDetailsByGameIds")
    assert(gameUIsByGameId ~= nil, "Should have non=nil gameUIsByGameId")
    assert(Utils.tablesHaveSameKeys(gameDetailsByGameId, gameUIsByGameId), "tables should have same keys")
    assert(#gameDetailsByGameId > 0, "Should have at least one game")

    GameDetails.setAllGameDetails(gameDetailsByGameId)
    GameUIs.setAllGameUIs(gameUIsByGameId)

    screenGui.IgnoreGuiInset = true
    turnOffPlayerControls()
    GuiMain.makeMakeFrameAndContentFrame(screenGui)
    print("Doug: calling updateUI")
    GuiMain.updateUI()
    listenToServerEvents()
end

return ClientStartUp