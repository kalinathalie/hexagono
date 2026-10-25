--[[
    Stage break: a player fails only after MISSES misses in a row (taps, hold
    checkpoints and let-go holds all count, as the engine's miss combo does).
    The K-Pump life gauge (Gameplay.Life.lua) never fails anyone by itself.
    OutFox reads the FailOnMissCombo metric but does not act on it, so this
    actor does: it sets the player's life to 0, the engine then fails them
    (with FailImmediate, the default), and marks PIUStageBreak[pn] so the gauge
    does not refill it.
]]
local MISSES = 40

PIUStageBreak = PIUStageBreak or {}

return function(pn)
    return Def.Actor {
        InitCommand=function(self) PIUStageBreak[pn] = nil end,   -- new song
        JudgmentMessageCommand=function(self, params)
            if params.Player ~= pn or PIUStageBreak[pn] then return end
            local State = GAMESTATE:GetPlayerState(pn)
            if State:GetPlayerController() == "PlayerController_Autoplay" then return end
            local Stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
            if Stats:GetCurrentMissCombo() < MISSES then return end
            if State:GetPlayerOptions("ModsLevel_Current"):FailSetting() == "FailType_Off" then return end
            PIUStageBreak[pn] = true
            local Player = SCREENMAN:GetTopScreen():GetChild("Player" .. ToEnumShortString(pn))
            if Player then Player:SetLife(0) end
        end,
    }
end
