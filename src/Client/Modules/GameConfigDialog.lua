--[[
Widget to select game options.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

local Cryo = require(ReplicatedStorage.Cryo)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)

local GameConfigDialog = {}

local nonDefaultGameOptions = {} :: CommonTypes.NonDefaultGameOptions

local _makeCustomDialogContent = function(parent: Frame, gameDetails: CommonTypes.GameDetails)
    assert(parent, "parent must be provided")
    assert(gameDetails, "gameDetails must be provided")
    local gameOptions = gameDetails.gameOptions
    assert(gameOptions, "gameOptions must be provided")

    for _, gameOption in gameOptions do
        local rowOptions = {
            horizontalAlignment = Enum.HorizontalAlignment.Left,
            labelText = gameOption.name,
        } :: GuiUtils.RowOptions

        local rowContent = GuiUtils.addRowAndReturnRowContent(parent, gameOption.gameOptionId, rowOptions)

        GuiUtils.addUIPadding(rowContent.Parent, {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
        })

        if gameOption.opt_variants == nil then
            local currentValue = nonDefaultGameOptions[gameOption.gameOptionId] or false
            -- This is a boolean toggle.
            GuiUtils.addCheckbox(rowContent, currentValue, function(newValue: boolean)
                if newValue then
                    nonDefaultGameOptions[gameOption.gameOptionId] = true
                else
                    nonDefaultGameOptions[gameOption.gameOptionId] = nil
                end
            end)
            local italicizedDescription = GuiUtils.italicize(gameOption.description)
            GuiUtils.addTextLabel(rowContent, italicizedDescription, {
                RichText = true,
            })
        else
            local currentValue = nonDefaultGameOptions[gameOption.gameOptionId] or 1
                local optionStrings = {}
                for _, variant in gameOption.opt_variants do
                    local key = GuiUtils.bold(variant.name)
                    local value = GuiUtils.italicize(variant.description)
                    local optionString = key .. ": " .. value
                    table.insert(optionStrings, optionString)
                end


                GuiUtils.addRadioButtonFamily(rowContent, optionStrings, currentValue, function(newValue: number)
                if newValue ~= 1 then -- 1 is the default value.
                    nonDefaultGameOptions[gameOption.gameOptionId] = newValue
                else
                    nonDefaultGameOptions[gameOption.gameOptionId] = nil
                end
            end)
        end
    end
end

GameConfigDialog.setGameConfig = function(tableDescription: CommonTypes.TableDescription, callback: (CommonTypes.NonDefaultGameOptions))
    assert(tableDescription, "tableDescription must be provided")
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    assert(gameDetails, "gameDetails must be provided")

    local title = string.format("\"%s\" Game Options", gameDetails.name)
    local description = "Adjust the settigns for this game."

    local incomingNonDefaultGameOptions = tableDescription.opt_nonDefaultGameOptions or {}
    nonDefaultGameOptions = Cryo.Dictionary.join(incomingNonDefaultGameOptions, {})

    local dialogConfig: DialogUtils.DialogConfig = {
        title = title,
        description = description,
        dialogButtonConfigs = {
            {
                text = "OK",
                callback = function()
                    callback(nonDefaultGameOptions)
                end
            } :: DialogUtils.DialogButtonConfig,
        } :: {DialogUtils.DialogConfig},
        makeCustomDialogContent = function(parent: Frame)
            _makeCustomDialogContent(parent, gameDetails)
        end,
    }

    return DialogUtils.makeDialog(dialogConfig)
end

return GameConfigDialog