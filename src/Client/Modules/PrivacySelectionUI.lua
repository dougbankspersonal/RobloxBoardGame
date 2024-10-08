--[[
Provide a prompt to select whether game is public or private.
]]

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)

local PrivacySelectionUI = {}

-- Pop up a dialog showing all games, when game is selected hit callback.
function PrivacySelectionUI.promptToSelectPrivacy(title: string, description: string, callback: (boolean))
    -- Put up a UI to get public or private.
    -- FIXME(dbanks): this is horrible temp hack using an array of buttons to pick from a set of two options.
    -- Implement a proper toggle switch (or radio buttons or whatever)
    local dialogConfig: DialogUtils.DialogConfig = {
        title = title,
        description = description,
        dialogButtonConfigs = {
            {
                text = "Public",
                callback = function()
                    callback(true)
                end,
            } :: DialogUtils.DialogButtonConfig,
            {
                text = "Private",
                callback = function()
                    callback(false)
                end,
            } :: DialogUtils.DialogButtonConfig,
        } :: {DialogUtils.DialogConfig},
    }

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

return PrivacySelectionUI