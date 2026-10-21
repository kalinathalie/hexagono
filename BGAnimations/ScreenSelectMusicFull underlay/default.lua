setenv("IsBasicMode", false)
-- Song select screen, Phoenix layout (top to bottom): profile bar (overlay),
-- preview strip, title / artist / BPM, jacket wheel, difficulty row with
-- records, footer. Picking a song slides the wheel away, moves the row up and
-- shows each player's chosen-chart panel.
local t = Def.ActorFrame {
    -- Add timer functionality
    InitCommand=function(self)
        self:sleep(0.5):queuecommand("CheckTimer")
    end,
    CheckTimerCommand=function(self)
        if SCREENMAN:GetTopScreen():GetChild("Timer"):GetSeconds() <= 0 then
            self:queuecommand("TimerExpired")
        else
            self:sleep(0.5):queuecommand("CheckTimer")
        end
    end,
    TimerExpiredCommand=function(self)
        -- Set these or else we crash.
        GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
        GAMESTATE:SetCurrentStyle(GAMESTATE:GetNumSidesJoined() > 1 and "versus" or string.lower(ShortType(GAMESTATE:GetCurrentSteps(GAMESTATE:GetMasterPlayerNumber()))))
        SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
    end
}

t[#t+1] = LoadActor("SongPreview")
t[#t+1] = LoadActor("TitleBlock")
t[#t+1] = LoadActor("MusicWheel") .. { Name="MusicWheel" }
t[#t+1] = LoadActor("ChartDisplay")
t[#t+1] = LoadActor("ChartRow")

-- Footer, as in Phoenix: FREE PLAY, or the credits in pay mode
t[#t+1] = Def.BitmapText {
    Font="Montserrat extrabold 20px",
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM - 12):zoom(0.8):shadowlength(2):queuecommand("Refresh") end,
    CoinInsertedMessageCommand=function(self) self:queuecommand("Refresh") end,
    RefreshCommand=function(self)
        local Free = GAMESTATE:IsEventMode() or GAMESTATE:GetCoinMode() ~= "CoinMode_Pay"
        self:settext(Free and THEME:GetString("ScreenSelectMusicFull", "FreePlay")
            or string.format(THEME:GetString("ScreenSelectMusicFull", "Credits"), GAMESTATE:GetCoins()))
    end,
}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    t[#t+1] = Def.ActorFrame {
        Def.Actor {
            -- If no AV is defined, do it before it causes any issues
            OnCommand=function(self)
                local AV = LoadModule("Config.Load.lua")("AutoVelocity", CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
                if not AV then
                    LoadModule("Config.Save.lua")("AutoVelocity", tostring(200), CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
                end
                LoadModule("Player.SetSpeed.lua")(pn)
            end,

            -- Make sure the speed is set relative to the selected song when going to gameplay
            OffCommand=function(self)
                LoadModule("Player.SetSpeed.lua")(pn)
            end
        },

        LoadActor("../ModIcons", pn) .. {
            InitCommand=function(self)
                -- below the BACK corner arrow, as the AV badge sits in Phoenix
                self:xy(pn == PLAYER_2 and SCREEN_RIGHT + 72 * 2 or -72 * 2, 150)
                :easeoutexpo(1):x(pn == PLAYER_2 and SCREEN_RIGHT - 36 or 36)
            end,
            OffCommand=function(self)
                self:stoptweening():easeoutexpo(1):x(pn == PLAYER_2 and SCREEN_RIGHT + 72 * 2 or -72 * 2)
            end
        },

        -- Phoenix transition: chosen chart + best score panel while picking the difficulty
        LoadActor("ChosenPanel", pn),
        -- the READY stamp lives in ChosenPanel.lua, over the big ball
    }
end

return t
