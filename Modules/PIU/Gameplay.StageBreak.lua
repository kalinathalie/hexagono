--[[
    Arcade fail rules, for players whose fail setting is not Off:
    - the life bar emptying does not stop the song but breaks the grade: the
      player runs on FailType_ImmediateContinue, so the engine marks the stage
      failed when the K-Pump gauge (Gameplay.Life.lua) reaches 0 and the score
      screen shows the broken (grey) grade;
    - MISSES misses in a row (taps, hold checkpoints and let-go holds, as the
      engine's miss combo counts them) end the song: the fail type goes back to
      FailType_Immediate and the life is set to 0. PIUStageBreak[pn] marks it,
      so the gauge does not refill it and the score screen is skipped.
    OutFox reads the FailOnMissCombo metric but does not act on it, hence this actor.
]]
local MISSES = 40

PIUStageBreak = PIUStageBreak or {}

local function SetFail(pn, FailType)
    local State = GAMESTATE:GetPlayerState(pn)
    for _, Level in ipairs({ "ModsLevel_Song", "ModsLevel_Current" }) do
        State:GetPlayerOptions(Level):FailSetting(FailType)
    end
end

return function(pn)
    return Def.Actor {
        InitCommand=function(self) PIUStageBreak[pn] = nil end,   -- new song
        OnCommand=function(self)
            local Options = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Current")
            if Options:FailSetting() ~= "FailType_Off" then SetFail(pn, "FailType_ImmediateContinue") end
        end,
        JudgmentMessageCommand=function(self, params)
            if params.Player ~= pn or PIUStageBreak[pn] then return end
            local State = GAMESTATE:GetPlayerState(pn)
            if State:GetPlayerController() == "PlayerController_Autoplay" then return end
            local Stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
            if Stats:GetCurrentMissCombo() < MISSES then return end
            if State:GetPlayerOptions("ModsLevel_Current"):FailSetting() == "FailType_Off" then return end
            PIUStageBreak[pn] = true
            SetFail(pn, "FailType_Immediate")
            local Player = SCREENMAN:GetTopScreen():GetChild("Player" .. ToEnumShortString(pn))
            if Player then Player:SetLife(0) end
        end,
    }
end
