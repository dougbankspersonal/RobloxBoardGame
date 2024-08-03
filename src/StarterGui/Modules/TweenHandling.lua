-- FIXME(dbanks)
-- On this business of tweensToKill:
-- I have to do this in several places.
-- When we change UI Modes, we destroy the whole construct of GuiObjects under ScreenGui and
-- build something new.
-- I was not sure what happens if the previous UI had tweens that are still running: I don't
-- want those tweens to keep playing, don't want any "tween done" events to fire, etc.
-- So when we completely destroy a UI because of mode change, I want to murder all ongoing tweens.
--
-- Current approach: when you call XXXUI.build, you pass back an array of "cleanup" functions, extra
-- junk to do when that UI is destroyed.
-- For several parties, we use this mechanism:
--   * When tweens are created, add to a local "dead meat tweens" list.
--   * when tweens finish, remove from list.
--   * when XXXUI.build is called, we pass back a function to destroy all tweens in the list.
--
-- So questions:
--   * Is this necessary?  Can we just ignore the tweens and let them play out since they are operating on GuiObjets
--     no longer under a screen gui?
--   * Is there some better way of doing this?  Like parenting the tweens to something, or asking tween service
--     to cancel all currently playing tweens or ???

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Cryo = require(ReplicatedStorage.Cryo)

local TweenHandling = {}

local tweensToKill = {}:: CommonTypes.TweensToKill

-- Murder all outstanding tweens.
TweenHandling.killOutstandingTweens = function()
    local plainTweens = Cryo.Dictionary.values(tweensToKill)
    tweensToKill = {}
    for _, tween in plainTweens do
        tween:Cancel()
        tween:Destroy()
    end
end

-- We have some new tweens to monitor.
-- Make sure when they die they are removed from our global list.
TweenHandling.saveTweens = function(newTweensToKill: CommonTypes.TweensToKill)
    for key, tween in newTweensToKill do
        tween.Completed:Connect(function(_)
            print("Doug:tween completed")
            tweensToKill[key] = nil
        end)
    end

    Cryo.Dictionary.join(tweensToKill, newTweensToKill)
end

return TweenHandling