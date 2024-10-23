local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local GamePicker = require(RobloxBoardGameClient.Modules.GamePicker)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local ClientGameInstanceFunctions = require(RobloxBoardGameClient.Globals.ClientGameInstanceFunctions)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)
local GameConfigPicker = require(RobloxBoardGameClient.Modules.GameConfigPicker)

local AnalyticsView = {}

local analyticsConversationIdGen = 0
local latestConversationId = 0

local statusLabelRowName = "StatusLabelRow"

export type progressRecord ={
    totalRecordCount: number,
    analyticsGameRecords: {CommonTypes.AnalyticsGameRecord}
}

local function getDescriptionString(gameId, opt_nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions?): string
    local gameDetails = GameDetails.getGameDetails(gameId)
    local gameName = gameDetails.name
    local text = "Analytics for \"".. gameName .. "\""
    -- Describe the optional configs as well.
    local nonDefaultGameOptions = opt_nonDefaultGameOptions or {}
    local optionsConfigString = GuiUtils.getGameOptionsString(gameId, nonDefaultGameOptions)
    if optionsConfigString then
        optionsConfigString = GuiUtils.italicize(optionsConfigString)
        text = text .. ":" .. optionsConfigString
    end
    return text
end

local function makeCustomDialogContent(dialogId: number, dialogContentFrame: Frame, gameId: CommonTypes.GameId)
    assert(dialogContentFrame, "parent must be provided")
    assert(gameId, "gameId must be provided")
    Utils.debugPrint("Analytics", "makeCustomDialogContent gameId = ", gameId)

    local nonDefaultGameOptions = {} :: CommonTypes.NonDefaultGameOptions

    -- While loading records we show a status label.
    local statusUpdateTextLabel = GuiUtils.addTextLabel(dialogContentFrame, "", {
        Name = GuiConstants.statusUpdateTextLabel,
    })

    local progressRecord = {
        totalRecordCount = 0,
        analyticsGameRecords = {},
    }

    latestConversationId = analyticsConversationIdGen
    analyticsConversationIdGen = analyticsConversationIdGen + 1

    local analyticsRecordCountBindableEvent = ClientEventManagement.getOrMakeBindableEvent(EventUtils.BindableEventNameAnalyticsRecordCount)
    local analyticsHandfulBindableEvent = ClientEventManagement.getOrMakeBindableEvent(EventUtils.BindableEventNameAnalyticsHandful)

    local function updateDescription()
        local dialog = DialogUtils.getDialogById(dialogId)
        assert(dialog, "dialog must exist")
        -- Update the description for the dialog.
        local updatedDescription = getDescriptionString(gameId, nonDefaultGameOptions)

        local descriptionTextLabel = dialog:FindFirstChild(GuiConstants.dialogDescriptionTextLabel, true)
        assert(descriptionTextLabel, "Should have descriptionTextLabel")

        descriptionTextLabel.Text = updatedDescription
    end

    local function promptForGameConfig()
        GameConfigPicker.promptToSelectGameConfig(gameId, nonDefaultGameOptions, function(ndgo: CommonTypes.NonDefaultGameOptions)
            local dialog = DialogUtils.getDialogById(dialogId)
            if not dialog then
                return
            end
            nonDefaultGameOptions = ndgo
            updateDescription()
            -- Re-render.
            local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(gameId)
            clientGameInstanceFunctions.renderAnalyticsRecords(dialogContentFrame, nonDefaultGameOptions, progressRecord.analyticsGameRecords)
        end)
    end

    local function addOptionsConfigButton()
        GuiUtils.addStandardTextButtonInContainer(dialogContentFrame, "Select a different game configuration", promptForGameConfig)
    end

    local function handleNewHandful(gameRecords: {CommonTypes.AnalyticsGameRecord}, isFinal:boolean)
        assert(statusUpdateTextLabel, "statusUpdateTextLabel must exist")
        progressRecord.analyticsGameRecords = Cryo.List.join(progressRecord.analyticsGameRecords, gameRecords)

        if isFinal then
            -- Remove the status label and its parent.
            local dialog = DialogUtils.getDialogById(dialogId)
            assert(dialog, "dialog must exist")
            local statusLabelRow = dialog:FindFirstChild(statusLabelRowName, true)
            statusLabelRow:Destroy()

            -- Maybe add a button to swap game config.
            local gameDetails = GameDetails.getGameDetails(gameId)
            assert(gameDetails, "gameDetails must exist")
            if gameDetails.gameOptions then
                addOptionsConfigButton()
            end

            -- Hand it over to game-specific logic.
            local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(gameId)
            clientGameInstanceFunctions.renderAnalyticsRecords(dialogContentFrame, nonDefaultGameOptions, progressRecord.analyticsGameRecords)
        else
            -- Just update the status message.
            local fetchedRecordCount = #progressRecord.analyticsGameRecords
            local message = "Fetched " .. fetchedRecordCount .. "/" .. progressRecord.totalRecordCount .. " records."
            statusUpdateTextLabel.Text = message
        end
    end

    analyticsHandfulBindableEvent.Event:Connect(function(conversationId: number, gameRecords: {CommonTypes.AnalyticsGameRecord}, isFinal: number)
        -- Ignore things that are not from our conversation.
        if conversationId ~= latestConversationId then
            return
        end
        Utils.debugPrint("Analytics", "analyticsHandfulBindableEvent fired")
        -- Dialog is dead, forget it.
        local dialog = DialogUtils.getDialogById(dialogId)
        if not dialog then
            return
        end

        handleNewHandful(gameRecords, isFinal)
    end)

    analyticsRecordCountBindableEvent.Event:Connect(function(conversationId: number, recordCount: number)
        -- Ignore things that are not from our conversation.
        if conversationId ~= latestConversationId then
            return
        end
        Utils.debugPrint("Analytics", "analyticsRecordCountBindableEvent fired")
        -- Dialog is dead, forget it.
        if not DialogUtils.getDialogById(dialogId) then
            return
        end

        progressRecord.totalRecordCount = recordCount

        -- Update the status label.
        statusUpdateTextLabel.Text = "Feching " .. recordCount .. " records for this game..."
        ClientEventManagement.getAnalyticsRecords(gameId, conversationId)
    end)

    statusUpdateTextLabel.Text = "Fetching record count..."
    Utils.debugPrint("Analytics", "calling ClientEventManagement.getAnalyticsRecordCount")
    ClientEventManagement.getAnalyticsRecordCount(gameId, latestConversationId)
end

local function showAnalyticsForGame(gameId: CommonTypes.GameId)
    local gameDetails = GameDetails.getGameDetails(gameId)
    local gameName = gameDetails.name

    local descriptionString = getDescriptionString(gameId)

    -- We are going to put up a dialog that shows analytics for the game.
    local dialogConfig: DialogUtils.DialogConfig = {
        title = "Analytics for \"".. gameName .. "\"",
        description = descriptionString,
        makeCustomDialogContent = function(dialogId: number, parent: Frame)
            makeCustomDialogContent(dialogId, parent, gameId)
        end
    }

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

local function promptForGameId()
    -- First we have to pick a game.
    GamePicker.promptToSelectGameID("Select a game", "Which game would you like analytics for?", function(gameId)
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