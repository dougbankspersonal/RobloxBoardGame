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
local GuiConstants = require(RobloxBoardGameClient.Modules.GuiConstants)

local MessageLog = {}
MessageLog.__index = MessageLog

export type MessageWithCallback = {
    message: string,
    opt_callback: ()->()?
}

export type MessageLog = {
    -- members
    parent: Frame,
    scrollingFrame: ScrollingFrame,
    messageLayoutOrder: number,
    messageWithCallbackQueue: {MessageWithCallback},
    busyAddingMessage: boolean,

    -- static functions.
    new: (parent: Frame) -> ScrollingFrame,

    -- non static member functions.
    enqueueMessage: (MessageLog, string, ()->()?) -> nil,
    maybeConsumeFromQueue: (MessageLog) -> nil,
    addMessageWidget: (MessageLog, string) -> GuiObject,
}

MessageLog.new = function(parent:Frame): MessageLog
    local self = setmetatable({}, MessageLog)

    self.messageWithCallbackQueue = {}
    self.busyAddingMessage = false

    self.parent = parent
    self.scrollingFrame = Instance.new("ScrollingFrame")
    self.scrollingFrame.Name = "MessageLog"
    self.scrollingFrame.Size = UDim2.new(1, 0, 0, GuiConstants.messageLogHeight)
    self.scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    self.scrollingFrame.BackgroundColor3 = Color3.fromRGB(230, 210, 200)
    self.scrollingFrame.ScrollBarThickness = 8
    self.scrollingFrame.ScrollingEnabled = true
    self.scrollingFrame.Parent = parent
    self.scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.scrollingFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
    self.scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    self.scrollingFrame.ScrollBarImageColor3 = Color3.new(0, 0, 0)
    self.messageLayoutOrder = 1


    self.scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        Utils.debugPrint("MessageLog", "CanvasPosition changed to: ", self.scrollingFrame.CanvasPosition)
        -- Who did this?
        local stackTrace = debug.traceback()
        Utils.debugPrint("MessageLog", "CanvasPosition stackTrace: ", stackTrace)
    end)

    GuiUtils.addUIListLayout(self.scrollingFrame, {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    self.scrollingFrame.ChildAdded:Connect(function(_)
        task.wait() -- delay for one frame to ensure child has been positioned
        -- set the canvasPosition to the bottom of the scrolling frame
        self.scrollingFrame.CanvasPosition = Vector2.new(0, self.scrollingFrame.CanvasSize.Y.Offset - self.scrollingFrame.AbsoluteSize.Y)
    end)

    return self
end

function MessageLog:enqueueMessage(message: string, opt_callback: ()->()?)
    local messageWithCallback = {
        message = message,
        opt_callback = opt_callback,
    }
    table.insert(self.messageWithCallbackQueue, messageWithCallback)
    self:maybeConsumeFromQueue()
end

function MessageLog:addMessageWidget(message:string): GuiObject
    local layoutOrder = self.messageLayoutOrder
    self.messageLayoutOrder = self.messageLayoutOrder + 1

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, 0, 0, 20)
    messageLabel.Position = UDim2.new(0, 0, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextSize = 14
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = self.scrollingFrame
    messageLabel.LayoutOrder = layoutOrder
    messageLabel.RichText = true

    return messageLabel
end

function MessageLog:maybeConsumeFromQueue()
    -- Nothing in queue, done.
    if #self.messageWithCallbackQueue == 0 then
        return
    end

    -- Busy, done.
    if self.busyAddingMessage then
        return
    end

    -- were we at the bottom of the scrolling frame?
    local wasAtBottom = GuiUtils.scrollingFrameIsScrolledToBottom(self.scrollingFrame)

    -- Remove the next message feom queue.
    local messageWithCallback = table.remove(self.messageWithCallbackQueue, 1)
    -- Add the message widget.
    local messageWidget = self:addMessageWidget(messageWithCallback.message)

    -- If the user is scrolled up to some non-bottom location, we're done.
    if not wasAtBottom then
        if messageWithCallback.opt_callback then
            messageWithCallback.opt_callback()
        end
        return
    end

    -- Otherwise, we are now "busy".
    self.busyAddingMessage = true
    messageWidget.TextTransparency = 1

    -- Give everything a second to settle.
    task.spawn(function()
        task.wait()
        -- Do some tweening so message log appearance looks cool.
        local currentCanvasPosition = self.scrollingFrame.CanvasPosition
        local targetCanvasY = GuiUtils.getCanvasPositionYToShowBottomOfVerticalScroll(self.scrollingFrame)
        local targetCanvasPosition = Vector2.new(currentCanvasPosition.X, targetCanvasY)

        Utils.debugPrint("MessageLog", "Doug: currentCanvasPosition: ", currentCanvasPosition)
        Utils.debugPrint("MessageLog", "Doug: targetCanvasPosition: ", targetCanvasPosition)

        local movementTweenInfo = TweenInfo.new(GuiConstants.messageQueueTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)

        local t1 = TweenService:Create(self.scrollingFrame, movementTweenInfo, {CanvasPosition = targetCanvasPosition})
        t1.Completed:Connect(function()
        self.scrollingFrame.CanvasPosition = targetCanvasPosition

            local transparencyTweenInfo = TweenInfo.new(GuiConstants.messageQueueTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
            local t2 = TweenService:Create(messageWidget, transparencyTweenInfo, {TextTransparency = 0})
            t2.Completed:Connect(function()
                self.busyAddingMessage = false
                if messageWithCallback.opt_callback then
                    messageWithCallback.opt_callback()
                end
                self:maybeConsumeFromQueue()
            end)
            t2:Play()
        end)
        t1:Play()
    end)
end

function MessageLog:destroy()
    self.scrollingFrame:Destroy()
end

return MessageLog