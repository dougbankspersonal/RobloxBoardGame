local ClientStartUp = {}

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiMain = require(RobloxBoardGameClient.Modules.GuiMain)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local GameUIs = require(RobloxBoardGameClient.Globals.GameUIs)
local TableDescriptions = require(RobloxBoardGameClient.Modules.TableDescriptions)

-- Shared
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- 3d avatar is irrelevant for this game.
local function turnOffPlayerControls()
    local localPlayer = game.Players.LocalPlayer
    assert(localPlayer, "localPlayer not found")
    local controls = require(localPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
    assert(controls, "controls not found")
    controls:Disable()
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
    GuiMain.makeMainFrame(screenGui)

    -- Show a loading screen while we fetch data from backend.
    GuiMain.updateUI()

    -- Do this before we fetch all tables (just so there's no squirreliness where:
    -- a) we ask for all tables
    -- b) server replies
    -- c) server updates tables and broadcasts updates
    -- d) we get the updates

    ClientEventManagement.listenToServerEvents(GuiMain.onTableCreated, GuiMain.onTableDestroyed, GuiMain.onTableUpdated)

    -- Fetch table descriptions from server.  Async, takes non-zero time.
    local allTableDescriptions = ClientEventManagement.fetchTableDescriptionsByTableIdAsync()
    TableDescriptions.setTableDescriptions(allTableDescriptions)

    GuiMain.updateUI()
end

return ClientStartUp