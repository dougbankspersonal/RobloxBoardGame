--[[
UIMode is TableWaitingForPlayers.
Local player belongs to exactly one table (as host or guest) and
that table is in GameTableStates.WaitingForPlayers.
UI Shows:
    * metadata about game, including currently set gameOptions.
    * metadata about host.
    * row of guests who have joined. Host can click to remove.
    * row of outstanding invites.  Host can click to uninvite.
    * (Host only): if game has gameOptions (e.g. optional rules, expanstions) a control to set gameOptions.
    * (Host only): a control to start the game.
    * (Host only): a control to destroy the table.
    * (Guest only): a control to leave the table.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)

local TableWaitingUI = {}

-- Create barebones structure for this UI,
-- Do not bother filling in anything that might change over time: this comes with update.
TableWaitingUI.build = function(screenGui: ScreenGui, currentTableDescription: CommonTypes.TableDescription)
    assert(screenGui, "Should have a screenGui")
    assert(currentTableDescription, "Should have a currentTableDescription")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local isHost = localUserId == currentTableDescription.hostUserId

    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    assert(gameDetails, "Should have a gameDetails")

    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "MainFrame not found")

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = mainFrame

    local row

    -- Game info and host info will not change, might as well fill them in now.
    row  = GuiUtils.addRowWithLabel(mainFrame, "Game")
    row.Name = "Game"
    GuiUtils.addGameWidget(row, currentTableDescription, true)
    -- If there are gameOptions, add a widget to contain that info.
    -- It will be filled in later.
    if gameDetails.configOptions and #gameDetails.configOptions > 0 then
        row = GuiUtils.addRowWithLabel(mainFrame, "Game Options")
        row.Name = "GameOptions"
    end

    row  = GuiUtils.addRowWithLabel(mainFrame, "Host")
    row.Name = "Host"
    GuiUtils.addPlayerWidget(row, currentTableDescription.hostUserId)

    -- Make a row for guests (players who have joined), invites (players invited)
    -- but do not fill in as this info will change: we set this in update function.
    GuiUtils.addRowWithLabel(mainFrame, "Guests")
    GuiUtils.addRowWithLabel(mainFrame, "Invites")

    -- Add row for controls, and add the controls (they may be disabled in update depending
    -- on various factors).
    row = GuiUtils.addRowWithLabel(mainFrame, "Controls")
    if isHost then
        GuiUtils.addButton(row, "Start Game", function()
            ClientEventManagement.startGame()
        end)
        GuiUtils.addButton(row, "Destroy Table", function()
            ClientEventManagement.destroyTable()
        end)
        if currentTableDescription.isPublic then
            GuiUtils.addButton(row, "Invite a Friend", function()
                -- FIXME(dbanks)
                -- This is janky/sub-optimal: it'd be nice to have a dialog to pick
                -- multiple friends at once.
                -- Too lazy/hurried to do that now.
                -- You can add one guy at a time.
                GuiUtils.selectFriend(screenGui, function(friendUserId)
                    if not friendUserId then
                        -- host cancelled.
                        return
                    end
                    ClientEventManagement.invitePlayerToTable(currentTableDescription.tableId, friendUserId)
                end)
            end)
        end
        local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
        if gameDetails.configOptions then
            GuiUtils.addButton(row, "Configure Game", function()
                print("FIXME: configure game")
            end)
        end
    else
        GuiUtils.addButton(row, "Leave Table", function()
            print("FIXME: leave table")
        end)
    end
end

return TableWaitingUI