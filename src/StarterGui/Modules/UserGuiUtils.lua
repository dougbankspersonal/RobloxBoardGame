--[[
A collection of utils around creating widgets that represent users:
* users seated at table.
* users invited to table.
* users being offered in somme kind of friend selection widget.
--]]

local UserGuiUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)

-- Utility:
-- We have a row of users under given frame.
-- We have a set of userIds describing the users we want in the row.
-- Compare the widgets in the row to widgets we want to have.
-- Tween in new widgets, tween out old widgets.
-- Futher complications: sometimes the widget is just a static widget, but sometimes it's a button.
-- If it's a button:
--   * Make the widget a button.
--   * Hit the callback when button is clicked
UserGuiUtils.updateUserRowContent = function(rowContent: Frame, justBuilt: boolean, userIds: {CommonTypes.UserId}, isButton: (userId: CommonTypes.UserId) -> boolean,
    buttonCallback: (CommonTypes.UserId) -> nil, renderEmptyList: (Frame) -> nil, cleanupEmptyList: (Frame) -> nil)
    assert(rowContent,  "Should have a rowContent")

    local makeUserWidgetContainer = function(frame: Frame, userId: CommonTypes.UserId): Frame
        local userWidgetContainer
        -- For host, if user is not himself, this widget is a button that lets you kick person out of table.
        if isButton(userId) then
            local config = {
                onClick = buttonCallback,
                useRedX = true,
            }
            userWidgetContainer = GuiUtils.addUserButtonWidgetContainer(frame, userId, config, buttonCallback, true)
        else
            userWidgetContainer = GuiUtils.addUserLabelWidgetContainer(frame, userId)
        end
        return userWidgetContainer
    end

    GuiUtils.updateWidgetContainerChildren(rowContent, userIds, makeUserWidgetContainer, renderEmptyList, cleanupEmptyList, justBuilt)
end

return UserGuiUtils
