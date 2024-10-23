local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Utility for a simple game message log.

ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local TweenService = game:GetService("TweenService")
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)

local MessageLog = {}
MessageLog.__index = MessageLog

export type TextLabelWithCallback = {
    textLabel: TextLabel,
    opt_callback: ()->()?
}

export type MessageLog = {
    -- members
    parent: Frame,
    scrollingFrame: ScrollingFrame,
    messageLayoutOrder: number,
    textLabelsWithCallbacks: {TextLabelWithCallback},
    busyAddingMessage: boolean,

    -- static functions.
    new: (parent: Frame) -> ScrollingFrame,

    -- non static member functions.
    enqueueMessage: (MessageLog, string, ()->()?) -> nil,
    consumeMessageTransparencyQueue: (MessageLog, boolean) -> nil,
}

MessageLog.new = function(parent:Frame): MessageLog
    local self = setmetatable({}, MessageLog)

    self.textLabelsWithCallbacks = {}

    self.parent = parent
    self.scrollingFrame = GuiUtils.addStandardScrollingFrame(parent)
    self.scrollingFrame.Name = "MessageLog"
    self.scrollingFrame.Size = UDim2.new(1, 0, 0, GuiConstants.messageLogHeight)
    self.scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    self.scrollingFrame.ScrollBarThickness = GuiConstants.scrollBarThickness
    self.scrollingFrame.ScrollingEnabled = true
    self.scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.scrollingFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
    self.scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    self.messageLayoutOrder = 1

    -- Adapt scrolling frame with "slide out" effect.
    GuiUtils.addSlideOutEffectToScrollingFrame(self.scrollingFrame, function()
        self:consumeMessageTransparencyQueue()
    end)

    GuiUtils.addUIListLayout(self.scrollingFrame, {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    return self
end

local messageSequenceNumber = 0

function MessageLog:enqueueMessage(message: string, opt_callback: ()->()?)

    Utils.debugPrint("MessageLog", "enqueueMessage: " .. message)
    local layoutOrder = self.messageLayoutOrder
    self.messageLayoutOrder = self.messageLayoutOrder + 1

    -- make but do not add text label.
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Message" .. tostring(messageSequenceNumber)
    messageSequenceNumber = messageSequenceNumber + 1
    textLabel.Size = UDim2.new(1, 0, 0, 20)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.TextTransparency = 1
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.LayoutOrder = layoutOrder
    textLabel.RichText = true

    -- enqueue a struct with this label and callback.
    local textLabelWithCallback = {
        textLabel = textLabel,
        opt_callback = opt_callback,
    }
    table.insert(self.textLabelsWithCallbacks, textLabelWithCallback)

    -- Now parent.
    Utils.debugPrint("MessageLog", "parenting new message: " .. message)

    textLabel.Parent = self.scrollingFrame
end

local function isOnscreen(scrollingFrame: ScrollingFrame, guiObject: GuiObject)
    local guiObjectPosition = guiObject.AbsolutePosition
    local guiObjectSize = guiObject.AbsoluteSize
    local canvasPosition = scrollingFrame.CanvasPosition
    local frameSize = scrollingFrame.AbsoluteSize

    local guiObjectBottom = guiObjectPosition.Y + guiObjectSize.Y
    local canvasTop = canvasPosition.Y

    if guiObjectBottom < canvasTop then
        return false
    end

    local guiObjectTop = guiObjectPosition.Y
    local canvasBottom = canvasPosition.Y + frameSize.Y


    if guiObjectTop > canvasBottom then
        return false
    end

    return true
end

function MessageLog:consumeMessageTransparencyQueue()
    -- There should be something in here.
    assert(self.textLabelsWithCallbacks, "MessageLog:consumeMessageTransparencyQueue: self.textLabelsWithCallbacks is nil")
    assert(#self.textLabelsWithCallbacks > 0, "MessageLog:consumeMessageTransparencyQueue: self.textLabelsWithCallbacks is empty")
    local textLabelWithCallback = table.remove(self.textLabelsWithCallbacks, 1)

    assert(textLabelWithCallback, "MessageLog:consumeMessageTransparencyQueue: textLabelWithCallback is nil")
    local textLabel = textLabelWithCallback.textLabel

    assert(textLabel, "MessageLog:consumeMessageTransparencyQueue: textLabel is nil")
    -- This label is now fully added to the scrolling frame.
    -- If offscreen, just make it visible and punt.
    local _isOnscreen = isOnscreen(self.scrollingFrame, textLabel)
    if not _isOnscreen then
        textLabel.TextTransparency = 0
        if textLabelWithCallback.opt_callback then
            textLabelWithCallback.opt_callback()
        end
        return
    end

    -- Otherwise fade in it.
    local transparencyTweenInfo = TweenInfo.new(GuiConstants.messageQueueTransparencyTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
    local t1 = TweenService:Create(textLabel, transparencyTweenInfo, {TextTransparency = 0})
    t1.Completed:Connect(function()
        -- When the tween is done, hit callback.
        if textLabelWithCallback.opt_callback then
            textLabelWithCallback.opt_callback()
        end
    end)
    t1:Play()
end

function MessageLog:destroy()
    self.scrollingFrame:Destroy()
end

return MessageLog