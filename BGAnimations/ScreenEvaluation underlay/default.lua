local CenterPressCount = 0
local CenterPress3xEnabled = LoadModule("Config.Load.lua")("EvalCenter3xExit", "Save/OutFoxPrefs.ini")
local BasicMode = getenv("IsBasicMode")

local R = LoadModule("Eval.Result.lua")
local Art = LoadModule("Select.Art.lua")

-- Seconds since the screen appeared; the update function advances it until the
-- count-up is over (R.CanExit)
local Clock = 0
local NextTick = 0
local Tick

local Grades = {}
local Scores = {}

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn then return end

    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

    if event.type == "InputEventType_Repeat" or event.type == "InputEventType_Release" then return end

    local button = event.button
    if button == "Center" then
        -- Ignore the pad (and do not count presses) until the table has finished
        if not R.CanExit(Clock) then return false end
        if CenterPressCount == (CenterPress3xEnabled and 2 or 0) then
            SCREENMAN:set_input_redirected(PLAYER_1, false)
            SCREENMAN:set_input_redirected(PLAYER_2, false)
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        else
            CenterPressCount = CenterPressCount + 1
        end
    elseif button == "Start" then
        if not R.CanExit(Clock) then return false end
        SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
    elseif button == "Back" then
        SCREENMAN:set_input_redirected(PLAYER_1, false)
        SCREENMAN:set_input_redirected(PLAYER_2, false)
        SCREENMAN:GetTopScreen():Cancel()
    end
    return false
end

-- Grade of each player, for the rank voice. Created with the file, never during the animation.
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
    Grades[pn] = LoadModule("PIU/Score.GradingEval.lua")(pss)
    Scores[pn] = pss:GetScore()
end

local Speaker = R.VoicePlayer(Scores)
local Voice = Speaker and R.Voice(Grades[Speaker])
local VoicePath = Voice and ("/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/Phoenix/Evaluation/Rank/" .. Voice .. ".mp3")
-- No voice file: no sound at all (not even the OutFox announcer)
if VoicePath and not FILEMAN:DoesFileExist(VoicePath) then VoicePath = nil end

local Shine = Art("Phoenix/Evaluation/_shine")

local t = Def.ActorFrame {
    OnCommand=function(self)
        Clock = 0
        NextTick = 0
        self:SetUpdateFunction(function(self, dt)
            -- stops advancing once the pad may leave (a flag instead of
            -- SetUpdateFunction(nil), which the binding may refuse)
            if R.CanExit(Clock) then return end
            Clock = Clock + (dt or 1 / 60)
            if Tick and R.IsCounting(Clock) and Clock >= NextTick then
                Tick:play()
                NextTick = Clock + R.TIMES.Tick
            end
        end)
    end,

    -- Since we now use an input handler to exit the screen, play the start sound effect here
    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        OffCommand=function(self) self:play() end
    },

    LoadActor("../SelectHud", { HideEmpty = true }),

    -- Footer, as in Phoenix: FREE PLAY, or the credits in pay mode
    Def.BitmapText {
        Font="Montserrat extrabold 20px",
        InitCommand=function(self) self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM - 12):zoom(0.8):shadowlength(2):queuecommand("Refresh") end,
        CoinInsertedMessageCommand=function(self) self:queuecommand("Refresh") end,
        RefreshCommand=function(self)
            local Free = GAMESTATE:IsEventMode() or GAMESTATE:GetCoinMode() ~= "CoinMode_Pay"
            self:settext(Free and THEME:GetString("ScreenSelectMusicFull", "FreePlay")
                or string.format(THEME:GetString("ScreenSelectMusicFull", "Credits"), GAMESTATE:GetCoins()))
        end,
    },

    LoadActor("ResultTable"),
}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    local X = pn == PLAYER_2 and 1248 or 32

    t[#t+1] = LoadActor("ResultSide", pn)

    -- wrapped, so ModIcons keeps its own InitCommand (it queues the icon refresh)
    t[#t+1] = Def.ActorFrame {
        InitCommand=function(self) self:xy(X, 187):visible(not BasicMode) end,
        OnCommand=function(self) self:diffusealpha(0):linear(0.3):diffusealpha(1) end,
        LoadActor("../ModIcons", pn),
    }

    if Shine then
        t[#t+1] = Def.Sprite {
            Texture=Shine,
            InitCommand=function(self) self:xy(X, 187 + 66):zoomto(90, 190):blend("BlendMode_Add") end,
            OnCommand=function(self) self:diffusealpha(1):linear(0.3):diffusealpha(0) end,
        }
    end
end

-- Count-up tick, played from the update function
t[#t+1] = Def.Sound {
    File=THEME:GetPathS("", "Evaluation tick"),
    InitCommand=function(self) Tick = self end,
}

-- Rank voice, once, when the grade lands
if VoicePath then
    t[#t+1] = Def.Sound {
        File=VoicePath,
        OnCommand=function(self) self:sleep(R.TIMES.GradeAt):queuecommand("Play") end,
        PlayCommand=function(self) self:play() end,
    }
end

t[#t+1] = Def.ActorFrame {
    OnCommand=function(self)
        -- Save profile names as score names
        if PROFILEMAN:IsPersistentProfile(PLAYER_1) then
            GAMESTATE:StoreRankingName(PLAYER_1, PROFILEMAN:GetProfile(PLAYER_1):GetDisplayName())
        end
        -- Yes, having to do this twice sucks
        if PROFILEMAN:IsPersistentProfile(PLAYER_2) then
            GAMESTATE:StoreRankingName(PLAYER_2, PROFILEMAN:GetProfile(PLAYER_2):GetDisplayName())
        end

        -- Used for our custom input
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
        SCREENMAN:set_input_redirected(PLAYER_1, true)
        SCREENMAN:set_input_redirected(PLAYER_2, true)

        -- Discord RPC
        local pn = GAMESTATE:GetMasterPlayerNumber()
        local SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
        local StepOrTrails = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(pn) or GAMESTATE:GetCurrentSteps(pn)
        if GAMESTATE:GetCurrentSong() then
            local title = PREFSMAN:GetPreference("ShowNativeLanguage") and GAMESTATE:GetCurrentSong():GetDisplayMainTitle() or GAMESTATE:GetCurrentSong():GetTranslitFullTitle()
            local details = not GAMESTATE:IsCourseMode() and title .. " - " .. SongOrCourse:GetDisplayArtist() or title
            details = string.len(details) < 128 and details or string.sub(details, 1, 124) .. "..."
            local Difficulty = ToEnumShortString(ToEnumShortString((StepOrTrails:GetStepsType()))) .. " " .. StepOrTrails:GetMeter()
            local Percentage = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):GetPercentDancePoints()
            local states = Difficulty .. " (" .. string.format( "%.2f%%", Percentage*100) .. ")"
            GAMESTATE:UpdateDiscordProfile(GAMESTATE:GetPlayerDisplayName(pn))
            GAMESTATE:UpdateDiscordScreenInfo(details, states, 1)
        end
    end,

    OffCommand=function(self) self:playcommand("EnableInput") end,
    CancelCommand=function(self) self:playcommand("EnableInput") end,

    EnableInputCommand=function(self)
        SCREENMAN:set_input_redirected(PLAYER_1, false)
        SCREENMAN:set_input_redirected(PLAYER_2, false)
    end
}

return t
