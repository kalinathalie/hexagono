-- Per-player panel shown while the difficulty is being chosen (Phoenix
-- transition): the selected chart as a big ball on the inner side (toward the
-- center), and the MY BEST / MACHINE BEST panel with scores and grades.
-- Uses the XSanity art when present; otherwise plain theme graphics.
-- The big ball follows the theme option "Show Big Difficulty Icon".
local pn = ...
local Row = LoadModule("Select.ChartRow.lua")
local Art = LoadModule("Select.Art.lua")
local Grading = LoadModule("PIU/Score.Grading.lua")

local PanelArt = Art("THEME-HIGHSCOREPANEL 1x2")    -- 480x292 frames: P1 layout, P2 layout
local BigArt = Art("StepBall_Body 3x4")             -- big balls with the type printed on them
local BigFrameArt = Art("Difficulty_BigBalls frame")
local ShowBigBall = LoadModule("Config.Load.lua")("ShowBigBall", "Save/OutFoxPrefs.ini") ~= false
local ClassicGrades = LoadModule("Config.Load.lua")("ClassicGrades", "Save/OutFoxPrefs.ini")
if (LoadModule("Config.Load.lua")("ScoringSystem", "Save/OutFoxPrefs.ini") or "Old") ~= "Old" then ClassicGrades = false end

local Side = (pn == PLAYER_2) and 1 or -1
local PanelZoom = 0.6                     -- 480x292 art -> 288x175 on screen
local PanelX = SCREEN_CENTER_X + Side * 330
local PanelY = 618
local BallX = -Side * 186                 -- inner side, overlapping the panel edge
-- Text slots inside the art (frame pixels from its center); P2 art is mirrored
local TextX, GradeX = -Side * 71, Side * 138
local MyY, MachineY, MachineNameY = -49, 48, 92

local function Top(List)
    local Scores = List and List:GetHighScores() or {}
    return Scores[1]
end

local function GradePath(HighScore)
    if not HighScore or HighScore:GetScore() <= 0 then return nil end
    local Path = THEME:GetPathG("", "LetterGrades/" .. (ClassicGrades and "" or "New/") .. Grading(HighScore), true)
    if Path and Path ~= "" then return Path end
    return nil
end

local function SetGrade(Sprite, HighScore)
    local Path = GradePath(HighScore)
    if Path then Sprite:visible(true):Load(Path):zoomto(110, 70) else Sprite:visible(false) end
end

local Panel
if PanelArt then
    Panel = Def.Sprite { Texture=PanelArt, InitCommand=function(self) self:animate(false):setstate(pn == PLAYER_2 and 1 or 0) end }
else
    Panel = Def.ActorFrame {
        Def.Quad { InitCommand=function(self) self:zoomto(484, 296):diffuse(pn == PLAYER_2 and color("#ff2d9a") or color("#2a6cff")) end },
        Def.Quad { InitCommand=function(self) self:zoomto(480, 292):diffuse(color("#0b1220")) end },
        Def.BitmapText { Font="Montserrat extrabold 40px", Text=THEME:GetString("ScreenSelectMusicFull", "MyBest"), InitCommand=function(self) self:xy(TextX, -95):zoom(0.7):diffuse(color("#46e0ff")) end },
        Def.BitmapText { Font="Montserrat extrabold 40px", Text=THEME:GetString("ScreenSelectMusicFull", "MachineBest"), InitCommand=function(self) self:xy(TextX, 5):zoom(0.7):diffuse(color("#ffb347")) end },
    }
end

return Def.ActorFrame {
    InitCommand=function(self)
        self:xy(PanelX, SCREEN_BOTTOM + 200):visible(GAMESTATE:IsHumanPlayer(pn))
    end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(0.4):y(SCREEN_BOTTOM + 200) end,
    SongChosenMessageCommand=function(self)
        self:playcommand("Refresh"):stoptweening():easeoutexpo(0.4):y(PanelY)
    end,
    SongUnchosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.4):y(SCREEN_BOTTOM + 200) end,
    CurrentChartChangedMessageCommand=function(self, params) if params.Player == pn then self:playcommand("Refresh") end end,
    UpdateChartDisplayMessageCommand=function(self, params) if params.Player == pn then self:playcommand("Refresh") end end,
    PlayerJoinedMessageCommand=function(self) self:visible(GAMESTATE:IsHumanPlayer(pn)) end,

    RefreshCommand=function(self)
        local Song = GAMESTATE:GetCurrentSong()
        local Steps = GAMESTATE:GetCurrentSteps(pn)
        local Box = self:GetChild("Box")
        local Ball = self:GetChild("Ball")
        if not Song or not Steps then
            Box:GetChild("MyScore"):settext("-"); Box:GetChild("MachineScore"):settext("-"); Box:GetChild("MachineName"):settext("")
            Box:GetChild("MyGrade"):visible(false); Box:GetChild("MachineGrade"):visible(false)
            Ball:GetChild("Level"):settext("")
            return
        end

        -- big ball
        local Meter = Steps:GetMeter()
        local Info = { Type = ToEnumShortString(ToEnumShortString(Steps:GetStepsType())), Meter = Meter, Description = Steps:GetDescription() }
        Ball:GetChild("Level"):settext(Row.MeterText(Meter))
        if BigArt then
            Ball:GetChild("Body"):setstate(Row.Style(Info).Big)
        else
            Ball:GetChild("Body"):diffuse(ChartTypeToColor(Steps))
            Ball:GetChild("Type"):settext(ToUpper(FullModeChartLabel(Steps)))
        end

        -- records
        local Profile = PROFILEMAN:GetProfile(pn)
        local Mine = Profile and Top(Profile:GetHighScoreList(Song, Steps)) or nil
        local Machine = Top(PROFILEMAN:GetMachineProfile():GetHighScoreList(Song, Steps))
        Box:GetChild("MyScore"):settext((Mine and Mine:GetScore() > 0) and FormatScore(Mine:GetScore()) or "-")
        Box:GetChild("MachineScore"):settext((Machine and Machine:GetScore() > 0) and FormatScore(Machine:GetScore()) or "-")
        Box:GetChild("MachineName"):settext((Machine and Machine:GetScore() > 0) and Machine:GetName() or "")
        SetGrade(Box:GetChild("MyGrade"), Mine)
        SetGrade(Box:GetChild("MachineGrade"), Machine)
    end,

    -- MY BEST / MACHINE BEST panel, drawn in the art's own pixel space
    Def.ActorFrame {
        Name="Box",
        InitCommand=function(self) self:zoom(PanelZoom) end,
        Panel,
        Def.BitmapText { Name="MyScore", Font="Montserrat extrabold 40px", InitCommand=function(self) self:xy(TextX, MyY):zoom(0.75):maxwidth(260 / 0.75):shadowlength(2) end },
        Def.BitmapText { Name="MachineScore", Font="Montserrat extrabold 40px", InitCommand=function(self) self:xy(TextX, MachineY):zoom(0.7):maxwidth(260 / 0.7):shadowlength(2) end },
        Def.BitmapText { Name="MachineName", Font="Montserrat semibold 40px", InitCommand=function(self) self:xy(TextX, MachineNameY):zoom(0.6):maxwidth(260 / 0.6):diffuse(color("#ffd08a")):shadowlength(1) end },
        Def.Sprite { Name="MyGrade", InitCommand=function(self) self:xy(GradeX, -72):visible(false) end },
        Def.Sprite { Name="MachineGrade", InitCommand=function(self) self:xy(GradeX, 49):visible(false) end },
    },

    -- Big ball of the selected chart (inner side)
    Def.ActorFrame {
        Name="Ball",
        InitCommand=function(self) self:x(BallX):visible(ShowBigBall) end,
        BigFrameArt and Def.Sprite { Texture=BigFrameArt, InitCommand=function(self) self:zoom(0.55) end } or Def.Actor {},
        BigArt and Def.Sprite { Name="Body", Texture=BigArt, InitCommand=function(self) self:animate(false):zoom(0.55) end }
            or Def.Sprite { Name="Body", Texture=THEME:GetPathG("", "DifficultyDisplay/LargeBall"), InitCommand=function(self) self:zoom(1.1) end },
        BigArt and Def.Actor { Name="Type" }
            or Def.BitmapText { Name="Type", Font="Montserrat extrabold 20px", InitCommand=function(self) self:y(-36):zoom(0.7):shadowlength(1) end },
        Def.BitmapText { Name="Level", Font="Montserrat numbers 40px", InitCommand=function(self) self:y(10):zoom(1.5):shadowlength(3) end },
    },
}
