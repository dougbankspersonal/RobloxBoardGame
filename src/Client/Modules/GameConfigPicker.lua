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

local GameConfigPicker = {}

local nonDefaultGameOptions = {} :: CommonTypes.NonDefaultGameOptions

local function fillInBooleanGameOptionSection(parent: Frame, gameOption: CommonTypes.GameOption)
    local currentValue = nonDefaultGameOptions[gameOption.gameOptionId] or false
    local italicizedDescription = GuiUtils.italicize(gameOption.description)
    -- These are side by side left to right in the parent.
    GuiUtils.addUIListLayout(parent, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    -- This is a boolean toggle.
    GuiUtils.addCheckbox(parent, currentValue, function(newValue: boolean)
        if newValue then
            nonDefaultGameOptions[gameOption.gameOptionId] = true
        else
            nonDefaultGameOptions[gameOption.gameOptionId] = nil
        end
    end)
    GuiUtils.addTextLabel(parent, italicizedDescription, {
        RichText = true,
    })
end

local function fillInVariantGameOptionSection(parent: Frame, gameOption: CommonTypes.GameOption)
    local currentValue = nonDefaultGameOptions[gameOption.gameOptionId] or 1
    local optionStrings = {}
    for _, variant in gameOption.opt_variants do
        local optionString = GuiUtils.bold(variant.name) .. ": " .. GuiUtils.italicize(variant.description)
        table.insert(optionStrings, optionString)
    end


    GuiUtils.addRadioButtonFamily(parent, optionStrings, currentValue, function(newValue: number)
        if newValue ~= 1 then -- 1 is the default value.
            nonDefaultGameOptions[gameOption.gameOptionId] = newValue
        else
            nonDefaultGameOptions[gameOption.gameOptionId] = nil
        end
    end)
end

local addGameOptionSection = function(parent: Frame, gameOption: CommonTypes.GameOption)
    if gameOption.opt_variants then
        fillInVariantGameOptionSection(parent, gameOption)
    else
        fillInBooleanGameOptionSection(parent, gameOption)
    end
end

local makeCustomDialogContent = function(dialogContentFrame: Frame, gameDetails: CommonTypes.GameDetails)
    assert(dialogContentFrame, "parent must be provided")
    assert(gameDetails, "gameDetails must be provided")
    local gameOptions = gameDetails.gameOptions
    assert(gameOptions, "gameOptions must be provided")

    local optionNames = {}
    for _, gameOption in gameOptions do
        table.insert(optionNames, gameOption.name)
    end

    local labelsWithRows = GuiUtils.makeRowsWithAlignedLeftLabels(optionNames)
    assert(#labelsWithRows == #gameOptions, "Should have the same number of rows as gameOptions")
    for i = 1, #gameOptions do
        local gameOption = gameOptions[i]
        local row = labelsWithRows[i].row
        addGameOptionSection(row, gameOption)
    end
end

function GameConfigPicker.promptToSelectGameConfig(gameId: CommonTypes.GameDetailsByGameId, opt_nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions?, callback: (CommonTypes.NonDefaultGameOptions))
    assert(gameId, "gameId must be provided")
    local gameDetails = GameDetails.getGameDetails(gameId)
    assert(gameDetails, "gameDetails must be provided")

    local title = string.format("\"%s\" Game Options", gameDetails.name)
    local description = "Adjust the settigns for this game."

    local incomingNonDefaultGameOptions = opt_nonDefaultGameOptions or {}
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
        makeCustomDialogContent = function(_: number, parent: Frame)
            makeCustomDialogContent(parent, gameDetails)
        end,
    }

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

return GameConfigPicker