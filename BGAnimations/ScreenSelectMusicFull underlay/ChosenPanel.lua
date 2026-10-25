-- Per-player panel shown while the difficulty is being chosen (Phoenix
-- transition): the selected chart as a big ball on the inner side (toward the
-- center) and the MY BEST panel with the score, grade and plate.
-- Art, in order of preference: local Phoenix graphics (MY BEST only, as in
-- Phoenix), local XSanity graphics (MY BEST + MACHINE BEST), plain theme graphics.
-- The big ball follows the theme option "Show Big Difficulty Icon".
local pn = ...
local Row = LoadModule("Select.ChartRow.lua")
local Art = LoadModule("Select.Art.lua")
local Grading = LoadModule("PIU/Score.Grading.lua")
local Records = LoadModule("Select.Records.lua")({ Players = {}, GetHighScore = function() return nil end })

local Tag = ToEnumShortString(pn)
local PX = {
    Panel = Art("Phoenix/my_best_" .. Tag),
    Glow = Art("Phoenix/my_best_glow_" .. Tag),
    Big = Art("Phoenix/Difficulty_BigBalls 4x2"),           -- red, magenta, green, blue, yellow
    Titles = Art("Phoenix/Difficulty_BigBalls_Titles 4x2"), -- SINGLE, S. PERFO., DOUBLE, D. PERFO., CO-OP
    BigGlow = Art("Phoenix/Difficulty_BigBalls glow sidetoside"),
}
local PhoenixBig = { single = 0, singlep = 1, double = 2, doublep = 3, coop = 4 }
local XS = {
    Panel = Art("XSanity/THEME-HIGHSCOREPANEL 1x2"),
    Big = Art("XSanity/StepBall_Body 3x4"),
    BigFrame = Art("XSanity/Difficulty_BigBalls frame"),
}
local UsePhoenixPanel = PX.Panel ~= nil
local UsePhoenixBall = PX.Big ~= nil and PX.Titles ~= nil

local ShowBigBall = LoadModule("Config.Load.lua")("ShowBigBall", "Save/OutFoxPrefs.ini") ~= false
local ClassicGrades = LoadModule("Config.Load.lua")("ClassicGrades", "Save/OutFoxPrefs.ini")
if (LoadModule("Config.Load.lua")("ScoringSystem", "Save/OutFoxPrefs.ini") or "Old") ~= "Old" then ClassicGrades = false end

local Side = (pn == PLAYER_2) and 1 or -1
local PanelY = 610
-- Phoenix print: panel 266 px wide, its inner edge 57 px outside the ball center
local PanelZoom = UsePhoenixPanel and 0.83 or 0.6
local PanelX = SCREEN_CENTER_X + Side * (UsePhoenixPanel and 365 or 330)
local BallX = UsePhoenixPanel and (-Side * 190) or (-Side * 186)   -- relative to the panel

local function Top(List)
    return Records.Best(List and List:GetHighScores())
end

-- HighScore exposes GetTapNoteScore; the plate module expects GetTapNoteScores
local function Plate(HighScore)
    local Adapter = {
        GetTapNoteScores = function(_, Tns) return HighScore:GetTapNoteScore(Tns) end,
        GetGrade = function() return HighScore:GetGrade() end,
    }
    local Ok, Name = pcall(LoadModule("PIU/Score.PlatesEval.lua"), Adapter)
    return Ok and Name or nil
end

local function SetIcon(Sprite, Path, Zoom)
    if Path then Sprite:visible(true):Load(Path):zoom(Zoom) else Sprite:visible(false) end
end

-- theme grade art (fallback layouts)
local function ThemeGradePath(HighScore)
    if not HighScore or HighScore:GetScore() <= 0 then return nil end
    local Path = THEME:GetPathG("", "LetterGrades/" .. (ClassicGrades and "" or "New/") .. Grading(HighScore), true)
    if Path and Path ~= "" then return Path end
    return nil
end

-- Text and icon positions inside the panel art (its own pixels, from its center)
local L = UsePhoenixPanel and {
    Score = { Side * 34, -34 }, Grade = { Side * 85, 19 }, Plate = { -Side * 25, 19 },
} or {
    Score = { -Side * 71, -49 }, Grade = { Side * 138, -72 }, MachineScore = { -Side * 71, 48 },
    MachineName = { -Side * 71, 92 }, MachineGrade = { Side * 138, 49 },
}

local Panel
if UsePhoenixPanel then
    Panel = Def.ActorFrame {
        PX.Glow and Def.Sprite { Texture=PX.Glow, InitCommand=function(self) self:blend("BlendMode_Add"):diffuseshift():effectcolor1(color("1,1,1,0.9")):effectcolor2(color("1,1,1,0.3")):effectperiod(1.6) end } or Def.Actor {},
        Def.Sprite { Texture=PX.Panel },
    }
elseif XS.Panel then
    Panel = Def.Sprite { Texture=XS.Panel, InitCommand=function(self) self:animate(false):setstate(pn == PLAYER_2 and 1 or 0) end }
else
    Panel = Def.ActorFrame {
        Def.Quad { InitCommand=function(self) self:zoomto(484, 296):diffuse(pn == PLAYER_2 and color("#ff2d9a") or color("#2a6cff")) end },
        Def.Quad { InitCommand=function(self) self:zoomto(480, 292):diffuse(color("#0b1220")) end },
        Def.BitmapText { Font="Montserrat extrabold 40px", Text=THEME:GetString("ScreenSelectMusicFull", "MyBest"), InitCommand=function(self) self:xy(-Side * 71, -95):zoom(0.7):diffuse(color("#46e0ff")) end },
        Def.BitmapText { Font="Montserrat extrabold 40px", Text=THEME:GetString("ScreenSelectMusicFull", "MachineBest"), InitCommand=function(self) self:xy(-Side * 71, 5):zoom(0.7):diffuse(color("#ffb347")) end },
    }
end

local Box = Def.ActorFrame {
    Name="Box",
    InitCommand=function(self) self:zoom(PanelZoom) end,
    Panel,
    Def.BitmapText { Name="MyScore", Font="Montserrat extrabold 40px",
        InitCommand=function(self) self:xy(L.Score[1], L.Score[2]):zoom(UsePhoenixPanel and 0.55 or 0.75):maxwidth((UsePhoenixPanel and 112 or 260) / (UsePhoenixPanel and 0.55 or 0.75)):shadowlength(2) end },
    Def.Sprite { Name="MyGrade", InitCommand=function(self) self:xy(L.Grade[1], L.Grade[2]):visible(false) end },
    Def.Sprite { Name="MyPlate", InitCommand=function(self) if L.Plate then self:xy(L.Plate[1], L.Plate[2]) end self:visible(false) end },
}
if not UsePhoenixPanel then
    Box[#Box + 1] = Def.BitmapText { Name="MachineScore", Font="Montserrat extrabold 40px", InitCommand=function(self) self:xy(L.MachineScore[1], L.MachineScore[2]):zoom(0.7):maxwidth(260 / 0.7):shadowlength(2) end }
    Box[#Box + 1] = Def.BitmapText { Name="MachineName", Font="Montserrat semibold 40px", InitCommand=function(self) self:xy(L.MachineName[1], L.MachineName[2]):zoom(0.6):maxwidth(260 / 0.6):diffuse(color("#ffd08a")):shadowlength(1) end }
    Box[#Box + 1] = Def.Sprite { Name="MachineGrade", InitCommand=function(self) self:xy(L.MachineGrade[1], L.MachineGrade[2]):visible(false) end }
end

local Ball = Def.ActorFrame {
    Name="Ball",
    InitCommand=function(self) self:x(BallX):visible(ShowBigBall) end,
}
if UsePhoenixBall then
    if PX.BigGlow then Ball[#Ball + 1] = Def.Sprite { Texture=PX.BigGlow, InitCommand=function(self) self:zoom(1.6):blend("BlendMode_Add"):spin():effectmagnitude(0, 0, 40) end } end
    Ball[#Ball + 1] = Def.Sprite { Name="Body", Texture=PX.Big, InitCommand=function(self) self:animate(false):zoom(0.9) end }
    Ball[#Ball + 1] = Def.Sprite { Name="Title", Texture=PX.Titles, InitCommand=function(self) self:animate(false):zoom(0.9) end }
    Ball[#Ball + 1] = Def.BitmapText { Name="Type", Font="Montserrat extrabold 20px", InitCommand=function(self) self:y(-44):zoom(0.7):shadowlength(1):visible(false) end }
elseif XS.Big then
    if XS.BigFrame then Ball[#Ball + 1] = Def.Sprite { Texture=XS.BigFrame, InitCommand=function(self) self:zoom(0.55) end } end
    Ball[#Ball + 1] = Def.Sprite { Name="Body", Texture=XS.Big, InitCommand=function(self) self:animate(false):zoom(0.55) end }
else
    Ball[#Ball + 1] = Def.Sprite { Name="Body", Texture=THEME:GetPathG("", "DifficultyDisplay/LargeBall"), InitCommand=function(self) self:zoom(1.1) end }
    Ball[#Ball + 1] = Def.BitmapText { Name="Type", Font="Montserrat extrabold 20px", InitCommand=function(self) self:y(-36):zoom(0.7):shadowlength(1) end }
end
Ball[#Ball + 1] = Def.BitmapText { Name="Level", Font="Montserrat numbers 40px", InitCommand=function(self) self:y(12):zoom(1.5):shadowlength(3) end }

-- READY stamp over the ball once the player confirms the difficulty (Phoenix ring art when present)
local ReadyArt = Art("Phoenix/READY_" .. Tag)
local Ready = Def.ActorFrame {
    Name="Ready",
    InitCommand=function(self) self:diffusealpha(0) end,
    StepsChosenMessageCommand=function(self, params)
        if params.Player == pn then self:stoptweening():zoom(1.3):easeoutexpo(0.3):zoom(1):diffusealpha(1) end
    end,
    CurrentChartChangedMessageCommand=function(self, params) if params.Player == pn then self:stoptweening():easeoutexpo(0.2):diffusealpha(0) end end,
    StepsUnchosenMessageCommand=function(self, params)
        if not params or not params.Player or params.Player == pn then self:stoptweening():easeoutexpo(0.2):diffusealpha(0) end
    end,
    SongUnchosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.2):diffusealpha(0) end,
}
if ReadyArt then
    Ready[#Ready + 1] = Def.Sprite { Texture=ReadyArt, InitCommand=function(self) self:zoom(0.75) end }
else
    Ready[#Ready + 1] = Def.Quad {
        InitCommand=function(self)
            self:zoomto(128, 32):diffuse(Color.White)
            if pn == PLAYER_2 then self:diffuserightedge(Color.Invisible) else self:diffuseleftedge(Color.Invisible) end
        end
    }
    Ready[#Ready + 1] = Def.Sprite { Texture=THEME:GetPathG("", "UI/Ready" .. Tag), InitCommand=function(self) self:y(1) end }
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
        local B, BallFrame = self:GetChild("Box"), self:GetChild("Ball")
        if not Song or not Steps then
            B:GetChild("MyScore"):settext("-"); B:GetChild("MyGrade"):visible(false); B:GetChild("MyPlate"):visible(false)
            BallFrame:GetChild("Level"):settext("")
            return
        end

        -- big ball
        local Meter = Steps:GetMeter()
        local Style = Row.Style({ Type = ToEnumShortString(ToEnumShortString(Steps:GetStepsType())), Meter = Meter, Description = Steps:GetDescription() })
        BallFrame:GetChild("Level"):settext(Row.MeterText(Meter))
        if UsePhoenixBall then
            local Frame = PhoenixBig[Style.Name]
            -- Phoenix has no half-double ball: the blue ball (as the cyan bubble in the row)
            -- with the name written over it
            BallFrame:GetChild("Body"):setstate(Frame or 3)
            BallFrame:GetChild("Title"):visible(Frame ~= nil):setstate(Frame or 0)
            BallFrame:GetChild("Type"):visible(Frame == nil):settext(ToUpper(FullModeChartLabel(Steps)))
        elseif XS.Big then
            BallFrame:GetChild("Body"):setstate(Style.Big)
        else
            BallFrame:GetChild("Body"):diffuse(ChartTypeToColor(Steps))
            BallFrame:GetChild("Type"):settext(ToUpper(FullModeChartLabel(Steps)))
        end

        -- my record
        local Profile = PROFILEMAN:GetProfile(pn)
        local Mine = Profile and Top(Profile:GetHighScoreList(Song, Steps)) or nil
        local HasMine = Mine and Mine:GetScore() > 0
        B:GetChild("MyScore"):settext(HasMine and FormatScore(Mine:GetScore()) or "-")
        if UsePhoenixPanel then
            local GradeName = HasMine and Records.GradeName(Grading(Mine)) or nil
            SetIcon(B:GetChild("MyGrade"), GradeName and Art("Phoenix/RecordGrades/" .. GradeName .. " (doubleres)"), 1.4)
            local PlateName = HasMine and Records.PlateName(Plate(Mine)) or nil
            SetIcon(B:GetChild("MyPlate"), PlateName and Art("Phoenix/RecordGrades/" .. PlateName .. " (doubleres)"), 1.5)
        else
            local Path = ThemeGradePath(Mine)
            if Path then B:GetChild("MyGrade"):visible(true):Load(Path):zoomto(110, 70) else B:GetChild("MyGrade"):visible(false) end
            local Machine = Top(PROFILEMAN:GetMachineProfile():GetHighScoreList(Song, Steps))
            local HasMachine = Machine and Machine:GetScore() > 0
            B:GetChild("MachineScore"):settext(HasMachine and FormatScore(Machine:GetScore()) or "-")
            B:GetChild("MachineName"):settext(HasMachine and Machine:GetName() or "")
            local MPath = ThemeGradePath(Machine)
            if MPath then B:GetChild("MachineGrade"):visible(true):Load(MPath):zoomto(110, 70) else B:GetChild("MachineGrade"):visible(false) end
        end
    end,

    Box,
    Ball,
    Ready .. { InitCommand=function(self) self:x(BallX):diffusealpha(0) end },
}
