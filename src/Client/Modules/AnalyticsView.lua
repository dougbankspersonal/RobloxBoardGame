local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local GameSelectionUI = require(RobloxBoardGameClient.Modules.GameSelectionUI)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local ClientGameInstanceFunctions = require(RobloxBoardGameClient.Globals.ClientGameInstanceFunctions)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)

local AnalyticsView = {}

local analyticsConversationIdGen = 0
local latestConversationId = 0
local busy = false

local nonDefaultGameOptions = {} :: CommonTypes.NonDefaultGameOptions

local function updateDescription(gameId: CommonTypes.GameId, dialog: Frame)
    -- Update the description for the dialog.
    local gameDetails = GameDetails.getGameDetails(gameId)
    local gameName = gameDetails.name

    local descriptionTextLabel = dialog:FindFirstChild(GuiConstants.dialogDescriptionTextLabel, true)
    assert(descriptionTextLabel, "Should have descriptionTextLabel")


    local text = "Analytics for \"".. gameName .. "\""

    -- Describe the optional configs as well.
    local optionsConfigString = GuiUtils.getGameOptionsString(gameId, nonDefaultGameOptions)
    if optionsConfigString then
        optionsConfigString = GuiUtils.italicize(optionsConfigString)
        text = text .. ":" .. optionsConfigString
    end

    descriptionTextLabel.Text = text
end

local fetchedRecordCount = 0
local totalRecordCount = 0

local allRecords = {}

local function handleNewHandful(dialog: Frame, conversationId: number, records: {CommonTypes.AnalyticsRecord}, isFinal: boolean)
    -- Dialog is dead, forget it.
    local statusUpdateTextLabel = dialog:FindFirstChild(GuiConstants.statusUpdateTextLabel)
    assert(statusUpdateTextLabel, "statusUpdateTextLabel must exist")

    -- Should match.
    assert(conversationId == latestConversationId, "conversationId mismatch")
    allRecords = Cryo.List.join(allRecords, records)
    if not isFinal then
        -- Just update the status message.
        fetchedRecordCount = #allRecords
        local message = "Fetched " .. fetchedRecordCount .. "/" .. totalRecordCount .. " records."
        statusUpdateTextLabel.Text = message
        return
    end

    -- All done.
    updateDescription(gameId, dialog)

    -- Hand it over to game-specific logic.
    local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(gameId)
    clientGameInstanceFunctions.renderAnalyticsRecords(content, allRecords)

    -- And we're done.
    busy = false
end

local function makeCustomDialogContent(dialogId: number, parent: Frame, gameId: CommonTypes.GameId)
    assert(parent, "parent must be provided")
    assert(gameId, "gameId must be provided")

    local content = GuiUtils.addRowAndReturnRowContent(parent, "Row_Filter")

    -- If we're already busy, ignore this: we don't need to do it twice.
    if busy then
        return
    end

    latestConversationId = analyticsConversationIdGen
    analyticsConversationIdGen = analyticsConversationIdGen + 1

    -- For now, just put in a widget that says we are starting to talk to server.
    local statusUpdateTextLabel = GuiUtils.addTextLabel(content, "Requesting analytics from server...", {
        Name = GuiConstants.statusUpdateTextLabel,
    })

    local analyticsRecordCountBindableEvent = ClientEventManagement.getOrMakeBindableEvent(EventUtils.BindableEventNameAnalyticsRecordCount)
    local analyticsHandfulBindableEvent = ClientEventManagement.getOrMakeBindableEvent(EventUtils.BindableEventNameAnalyticsHandful)

    analyticsHandfulBindableEvent.Event:Connect(function(conversationId: number, records: {CommonTypes.AnalyticsRecord}, isFinal: number)
        -- Dialog is dead, forget it.
        local dialog = DialogUtils.getDialog(dialogId)
        if not dialog then
            return
        end

        handleNewHandful(dialog, conversationId, records, isFinal)

        if isFinal then
            busy = false
        end
    end)

    analyticsRecordCountBindableEvent.Event:Connect(function(conversationId: number, recordCount: number)
        -- Dialog is dead, forget it.
        if not DialogUtils.getDialog(dialogId) then
            return
        end
        totalRecordCount = recordCount
        statusUpdateTextLabel.Text = "Feching " .. recordCount .. " records for this game..."
        ClientEventManagement.getAnalyticsRecords(gameId, conversationId)
    end)

    ClientEventManagement.getAnalyticsRecordCount(gameId, latestConversationId)
end

local function showAnalyticsForGame(gameId: CommonTypes.GameId)
    local gameDetails = GameDetails.getGameDetails(gameId)
    local gameName = gameDetails.name

    -- We are going to put up a dialog that shows analytics for the game.
    local dialogConfig: DialogUtils.DialogConfig = {
        title = "Analytics for \"".. gameName .. "\"",
        description = "Loading data.  Please wait, this may take while.",
        makeCustomDialogContent = function(dialogId: number, parent: Frame)
            makeCustomDialogContent(dialogId, parent, gameId)
        end
    }

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

local function promptForGameId()
    -- First we have to pick a game.
    GameSelectionUI.promptToSelectGameID("Select a game", "Which game would you like analytics for?", function(gameId)
        showAnalyticsForGame(gameId)
    end)
end

function AnalyticsView.addAnalyticsButton(parent: GuiObject, layoutOrder: number)
    GuiUtils.addStandardTextButtonInContainer(parent, "Analytics", promptForGameId, {
        Name = "AnalyticsButton",
    }, {
        LayoutOrder = layoutOrder,
    })
end


return AnalyticsView