local MenuButtonsOnly = PREFSMAN:GetPreference("OnlyDedicatedMenuButtons")

local t = Def.ActorFrame {
    OnCommand=function(self)
        local pn = GAMESTATE:GetMasterPlayerNumber()
        GAMESTATE:UpdateDiscordProfile(GAMESTATE:GetPlayerDisplayName(pn))
        if GAMESTATE:IsCourseMode() then
            GAMESTATE:UpdateDiscordScreenInfo("Selecting Course", "", 1)
        else
            local StageIndex = GAMESTATE:GetCurrentStageIndex()
            GAMESTATE:UpdateDiscordScreenInfo("Selecting Song (Stage " .. StageIndex+1 .. ")", "", 1)
        end
    end,
}

-- PRESS CENTER STEP / INSERT CREDIT are shown in the empty side of the top HUD (SelectHud.lua)

t[#t+1] = Def.ActorFrame {
    -- Background for the group select wheel
    Def.Quad {
        InitCommand=function(self)
            self:FullScreen():diffuse(Color.Black):diffusebottomedge(color("#001122")):diffusealpha(0)
        end,
        CloseGroupWheelMessageCommand=function(self) self:stoptweening():easeoutexpo(0.25):diffusealpha(0) end,
        OpenGroupWheelMessageCommand=function(self) self:stoptweening():easeoutexpo(1):diffusealpha(0.96) end,
    },

    LoadActor("GroupSelect"),
    
    LoadActor("../SelectHud"),

    LoadActor("../CornerArrows"),
    
    LoadActor("OptionsList"),

    -- XSanity-style graphical command window (opened by the pad code)
    LoadActor("CommandWindow"),

    Def.Sound {
        File=THEME:GetPathS("Common", "start"),
        IsAction=true,
        PlayerJoinedMessageCommand=function(self)
            self:play()
            SOUND:DimMusic(0, 1)
            SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectProfile")
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        end
    }
}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    t[#t+1] = Def.Quad {
        InitCommand=function(self)
            local side = (pn == PLAYER_1 and SCREEN_LEFT or SCREEN_RIGHT)
            local alignment = (pn == PLAYER_1 and 0 or 1)

            if pn == PLAYER_1 then self:faderight(50) else self:fadeleft(75) end

            self:diffuse(1,1,1,1):halign(alignment):xy(side, SCREEN_CENTER_Y-70):zoomto(0, 360)
        end,
        CodeMessageCommand=function(self, params)
            if ((params.Name == "OpenOpList" and not MenuButtonsOnly) or
                params.Name == "OpenOpListButton") and params.PlayerNumber == pn then
                self:diffusealpha(100):zoomto(0, 360)
                :linear(0.25)
                :diffusealpha(0):zoomto(60, 360)
            end
        end
    }
end

return t
