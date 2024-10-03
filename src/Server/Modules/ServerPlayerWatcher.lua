-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameTablesStorage = require(RobloxBoardGameServer.Modules.GameTablesStorage)
local ServerEventManagement = require(RobloxBoardGameServer.Modules.ServerEventManagement)


local ServerPlayerWatcher = {}

function ServerPlayerWatcher.startWatchingPlayers()
    game.Players.PlayerRemoving:Connect(function(player)
        -- This player is leaving the experience.
        -- If he is a host at a table, that table is destroyed.
        local userId = player.UserId

        local gameTable = GameTablesStorage.findTableWithHost(userId)
        if gameTable then
            -- This is the equivalent of the host asking to destroy the table.
            ServerEventManagement.handleDestroyTable(gameTable.tableDescription.tableId)
        end

        player.Chatted:Connect(function(message)
            print(player.Name .. " said: " .. message)
        end)
    end)
end

return ServerPlayerWatcher