local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local UIModes = require(RobloxBoardGameShared.Globals.UIModes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local StateDigest = require(RobloxBoardGameClient.Modules.StateDigest)

local Mocks = {}

local CrossTableHeading = "Cross-Table"
local WaitingAtTableHeading = "Waiting At Table"

local summonMocksDialog = function(): Frame?
    local dialogButtonConfigs = {
        {
            text = "3rd Party Public, unjoined",
            heading = CrossTableHeading,
            callback = function()
                ClientEventManagement.createMockTable(true, false)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "3rd Party Private, unjoined",
            heading = CrossTableHeading,
            callback = function()
                ClientEventManagement.createMockTable(false, false)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "3rd Party Public, joined",
            heading = CrossTableHeading,
            callback = function()
                ClientEventManagement.createMockTable(true, true)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "3rd Party Private, joined",
            heading = CrossTableHeading,
            callback = function()
                ClientEventManagement.createMockTable(false, true)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "Mine, Public",
            heading = CrossTableHeading,
            callback = function()
                ClientEventManagement.createMockTable(true, true, true)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "Mine, Private",
            heading = CrossTableHeading,
            callback = function()
                ClientEventManagement.createMockTable(false, true, true)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "Destroy Mocks",
            heading = CrossTableHeading,
            callback = function()
                ClientEventManagement.destroyAllMockTables(false)
            end,
        } :: DialogUtils.DialogButtonConfig,
    } :: {DialogUtils.DialogButtonConfig}

    -- Mocks for waiting at a table.
    local currentUIMode = StateDigest.getCurrentUIMode()
    if currentUIMode == UIModes.TableWaitingForPlayers then
        local currentTableDescription = StateDigest.getCurrentTableDescription()
        assert(currentTableDescription, "Should have a current table description")

        local tableId = currentTableDescription.tableId
        assert(tableId, "Should have a tableId")

        if currentTableDescription.isPublic then
            table.insert(dialogButtonConfigs, {
                text = "Add Member",
                heading = WaitingAtTableHeading,
                callback = function()
                    ClientEventManagement.addMockMember(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
        else
            table.insert(dialogButtonConfigs, {
                text = "Add Invite",
                heading = WaitingAtTableHeading,
                callback = function()
                    ClientEventManagement.addMockInvite(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
            table.insert(dialogButtonConfigs, {
                text = "Accept Random Invite",
                heading = WaitingAtTableHeading,
                callback = function()
                    ClientEventManagement.mockInviteAcceptance(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
        end

        table.insert(dialogButtonConfigs, {
            text = "Non-Host Player Quits",
            heading = WaitingAtTableHeading,
            callback = function()
                Utils.debugPrint("Mocks", "firing mockNonHostMemberLeaves event")
                ClientEventManagement.mockNonHostMemberLeaves(tableId)
            end,
        } :: DialogUtils.DialogButtonConfig)

        table.insert(dialogButtonConfigs, {
            text = "Host Destroys Table",
            heading = WaitingAtTableHeading,
            callback = function()
                Utils.debugPrint("Mocks", "firing mockHostDestroysTable event")
                ClientEventManagement.mockHostDestroysTable(tableId)
            end,
        } :: DialogUtils.DialogButtonConfig)

        local localUserId = Players.LocalPlayer.UserId
        if currentTableDescription.hostUserId ~= localUserId then
            table.insert(dialogButtonConfigs, {
                text = "Mock Host Starts Game",
                heading = WaitingAtTableHeading,
                callback = function()
                    ClientEventManagement.mockStartGame(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
        end
    end

    local dialogConfig: DialogUtils.DialogConfig = {
        title = "Mocks",
        description = "Various debug options",
        dialogButtonConfigs = dialogButtonConfigs,
    }
    return DialogUtils.makeDialog(dialogConfig)
end


Mocks.addMocksButton = function(screenGui: ScreenGui)
    -- Throw on a button with a very high z index to summon mocks.
    if RunService:IsStudio() then
        -- I may be running a test with multiple clients.  I only want Mocks for the client that's the real
        -- me.
        if Players.LocalPlayer.UserId == Utils.StudioUserId then
            GuiUtils.addStandardTextButtonInContainer(screenGui, "Mocks", summonMocksDialog, {
                Name = "MocksButton",
            }, {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -10, 1, -10),
                ZIndex = 1000,
            })
        end
    end
end

return Mocks