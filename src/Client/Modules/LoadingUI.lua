--[[
Functions to build the UI we show whilw waiting for initial download of tables from server.
]]

local LoadingUI = {}
local TweenService = game:GetService("TweenService")

--[[
Build ui elements for an inital "loading" screen while we fetch stuff from the server.

Returns a list of any special cleanup functions.
"Special" because we have generic cleanup function that just kills
everything under mainFrame.

In this case, we create a tween, and I'd like to be thoughtful about killing the
tween.
]]
LoadingUI.build = function(screenGui: ScreenGui): {()->nil}
    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "MainFrame not found")

    -- FIXME(dbanks): extremely ugly hackery/placeholder.
    local frame = Instance.new("Frame")
    frame.Name = "LoadingFrame"
    frame.Parent = mainFrame
    frame.Size = UDim2.fromScale(1, 1)
    frame.Position = UDim2.fromOffset(0, 0)
    frame.BackgroundColor3 = Color3.new(1, 0.5, 0.5)

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "LoadingLabel"
    textLabel.Parent = frame
    textLabel.Size = UDim2.fromOffset(200, 200)
    textLabel.Text = "Loading"
    textLabel.BackgroundTransparency = 1
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.Position = UDim2.fromScale(0.5, 0.5)

    -- Make it wiggle so you know things are not stuck.
    local jiggleMagnitude = 5
    textLabel.Rotation = jiggleMagnitude

    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
    local tween = TweenService:Create(textLabel, tweenInfo, {Rotation = -jiggleMagnitude})
    tween:Play()
    -- add a function so that when this UI is killed we kill the tween.
    local stopTween = function()
        tween:Cancel()
    end
    return {stopTween}
end

return LoadingUI
