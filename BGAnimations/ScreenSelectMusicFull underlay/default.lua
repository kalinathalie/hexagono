setenv("IsBasicMode", false)
-- Song select screen, Phoenix layout (top to bottom): profile bar (overlay),
-- preview strip, title / artist / BPM, jacket wheel, difficulty row with
-- records, mode label. Picking the difficulty adds nothing but the cursor.
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
                self:xy(pn == PLAYER_2 and SCREEN_RIGHT + 72 * 2 or -72 * 2, 170)
                :easeoutexpo(1):x(pn == PLAYER_2 and SCREEN_RIGHT - 72 or 72)
            end,
            OffCommand=function(self)
                self:stoptweening():easeoutexpo(1):x(pn == PLAYER_2 and SCREEN_RIGHT + 72 * 2 or -72 * 2)
            end
        },

        -- Phoenix transition: chosen chart + best score panel while picking the difficulty
        LoadActor("ChosenPanel", pn),

        -- READY tag: appears beside the wheel once the player confirms the difficulty
        Def.ActorFrame {
            InitCommand=function(self)
                self:xy(SCREEN_CENTER_X + (pn == PLAYER_2 and 380 or -380), SCREEN_BOTTOM - 225):diffusealpha(0)
            end,
            OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):diffusealpha(0) end,
            StepsChosenMessageCommand=function(self, params)
                if params.Player == pn then self:stoptweening():easeoutexpo(0.3):diffusealpha(1) end
            end,
            CurrentChartChangedMessageCommand=function(self, params)
                if params.Player == pn then self:stoptweening():easeoutexpo(0.3):diffusealpha(0) end
            end,
            StepsUnchosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.3):diffusealpha(0) end,
            SongUnchosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.3):diffusealpha(0) end,

            Def.Quad {
                InitCommand=function(self)
                    self:zoomto(128, 32):diffuse(Color.White)
                    if pn == PLAYER_2 then
                        self:diffuserightedge(Color.Invisible)
                    else
                        self:diffuseleftedge(Color.Invisible)
                    end
                end
            },
            Def.Sprite {
                Texture=THEME:GetPathG("", "UI/Ready" .. ToEnumShortString(pn)),
                InitCommand=function(self) self:y(1) end
            }
        }
    }
end

return t
