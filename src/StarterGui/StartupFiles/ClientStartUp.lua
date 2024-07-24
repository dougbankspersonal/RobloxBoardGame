local ClientStartUp = {}

-- Shared
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiMain = require(RobloxBoardGameStarterGui.Modules.GuiMain)
local ClientEventManagement = require(RobloxBoardGameStarterGui.Modules.ClientEventManagement)
local GameUIs = require(RobloxBoardGameStarterGui.Globals.GameUIs)
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)

-- 3d avatar is irrelevant for this game.
local function turnOffPlayerControls()
    local localPlayer = game.Players.LocalPlayer
    assert(localPlayer, "localPlayer not found")
    local controls = require(localPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
    assert(controls, "controls not found")
    controls:Disable()
end

-- Most Roblox experiences are 3d spaces with avatar running around.
-- This is a 2s board game, no avatar, no 3d space.
-- This has some implications for how we configure the game.
local function configureForBoardGames()
    -- Player can't move or jump.
    turnOffPlayerControls()
    -- We don't need/want local chat: people can use voice chat, and the chat widget gets in the way of
    -- the 2d interface.
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    -- We don't want 3d sound.
    local soundService = game:GetService("SoundService")
    soundService.DistanceFactor = 0

end

ClientStartUp.ClientStartUp = function(screenGui: ScreenGui, gameDetailsByGameId: CommonTypes.GameDetailsByGameId, gameUIsByGameId: CommonTypes.GameUIsByGameId)
    -- Sanity checks.
    assert(gameDetailsByGameId ~= nil, "Should have non=nil gameDetailsByGameIds")
    assert(gameUIsByGameId ~= nil, "Should have non=nil gameUIsByGameId")
    -- must be at least one.
    local numGames = Utils.tableSize(gameDetailsByGameId)
    assert(numGames > 0, "Should have at least one game")
    assert(Utils.tablesHaveSameKeys(gameDetailsByGameId, gameUIsByGameId), "tables should have same keys")

    -- Set up globals.
    GameDetails.setAllGameDetails(gameDetailsByGameId)
    GameUIs.setAllGameUIs(gameUIsByGameId)

    screenGui.IgnoreGuiInset = true
    configureForBoardGames()

    GuiUtils.setMainScreenGui(screenGui)
    GuiMain.makeMainFrame(screenGui)

    -- Show a loading screen while we fetch data from backend.
    GuiMain.showLoadingUI()

    -- Do this before we fetch all tables (just so there's no squirreliness where:
    -- a) we ask for all tables
    -- b) server replies
    -- c) server updates tables and broadcasts updates
    -- d) we get the updates
    ClientEventManagement.listenToServerEvents(GuiMain.onTableCreated, GuiMain.onTableDestroyed, GuiMain.onTableUpdated)

    task.spawn(function()
        local tableDescriptionsByTableId = ClientEventManagement.fetchTableDescriptionsByTableIdAsync()
        TableDescriptions.setTableDescriptions(tableDescriptionsByTableId)
        GuiMain.updateUI()
    end)
end

return ClientStartUp