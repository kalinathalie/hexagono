-- One player's side of the result screen (Phoenix 2 style): chart ball, score
-- box with the counting score, difference to the previous best, big grade and
-- plate. Loaded with LoadActor("ResultSide", pn) for present players only.
-- Positions are absolute screen coordinates (1280x720). Missing art falls back
-- to text; nothing here may fail without art, a profile or steps.
local pn = ...
local R = LoadModule("Eval.Result.lua")
local Art = LoadModule("Select.Art.lua")
local Row = LoadModule("Select.ChartRow.lua")
local T = R.TIMES

local X = pn == PLAYER_2 and 1040 or 240
local BallX = pn == PLAYER_2 and 845 or 435
local Prefix = "Phoenix/Evaluation/"

-- stats of the play
local Pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
local Score = Pss:GetScore()
local Grade = LoadModule("PIU/Score.GradingEval.lua")(Pss) or ""
local Broken = Grade:find("^Fail") ~= nil
local Scoring = LoadModule("Config.Load.lua")("ScoringSystem", "Save/OutFoxPrefs.ini") or "Old"
local Plate = nil
if not Broken and Scoring == "New" then Plate = LoadModule("PIU/Score.PlatesEval.lua")(Pss) end

-- difference to the previous best (only with a persistent profile)
local Persistent = PROFILEMAN:IsPersistentProfile(pn)
local Prev = nil
if Persistent then
    local Profile = PROFILEMAN:GetProfile(pn)
    local Song = GAMESTATE:GetCurrentSong()
    local Steps = GAMESTATE:GetCurrentSteps(pn)
    if Profile and Song and Steps then
        local List = Profile:GetHighScoreList(Song, Steps)
        if List then Prev = R.PreviousBest(List:GetHighScores(), Pss:GetPersonalHighScoreIndex()) end
    end
end
local DiffText, DiffKind = R.Diff(Score, Prev and Prev:GetScore(), Broken, Persistent)

-- art (all loaded here, never in the update function)
local ShineArt = Art(Prefix .. "_shine")
local ScoreBox = Art(Prefix .. "_score_bg")
local GradeName = R.GradeArt(Grade)
-- the Phoenix 2 grade cut from the result video (pi/assets/grades.py), else phyrebird's
local GradePath = GradeName and (Art(Prefix .. "Grades/" .. GradeName) or Art(Prefix .. GradeName)) or nil
local PlateName = Plate and R.PlateArt(Plate) or nil
-- the LBPIU scoreboard's art (pi/assets/lbpiu.py) where it matches the game better than
-- phyrebird's: plates, chart balls, score digits and the SCORE label
local Board = "Phoenix/Scoreboard/"
local BoardPlate = PlateName and Art(Board .. "Plates/" .. PlateName) or nil
local PlatePath = BoardPlate or (PlateName and Art(Prefix .. PlateName)) or nil
local PlateZoom = BoardPlate and 1 or 0.53        -- the scoreboard's ULTIMATE GAME is 176 px, as in the video
local ScoreLabel = Art(Board .. "Labels/_score")
local DigitsIni = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/" .. Board .. "Digits/Score digits.ini"
if not FILEMAN:DoesFileExist(DigitsIni) then DigitsIni = nil end

-- chart ball art (same sources and fallbacks as the song select panel)
local PX = {
    Big = Art("Phoenix/Difficulty_BigBalls 4x2"),           -- red, magenta, green, blue, yellow
    Titles = Art("Phoenix/Difficulty_BigBalls_Titles 4x2"), -- SINGLE, S. PERFO., DOUBLE, D. PERFO., CO-OP
}
local PhoenixBig = { single = 0, singlep = 1, double = 2, doublep = 3, coop = 4 }
local XS = {
    Big = Art("XSanity/StepBall_Body 3x4"),
    BigFrame = Art("XSanity/Difficulty_BigBalls frame"),
}
local UsePhoenixBall = PX.Big ~= nil and PX.Titles ~= nil
local BoardBall = nil
do
    local Steps = GAMESTATE:GetCurrentSteps(pn)
    if Steps then
        local Style = Row.Style({ Type = ToEnumShortString(ToEnumShortString(Steps:GetStepsType())), Meter = Steps:GetMeter(), Description = Steps:GetDescription() })
        local Name = R.BallArt(Style.Name, Steps:GetMeter())
        BoardBall = Name and Art(Board .. "Balls/" .. Name) or nil
    end
end

-- actors the ball fill needs (nil when that branch is not built)
local Ref = {}

local Inner = Def.ActorFrame {
    InitCommand=function(self) self:zoom(0.52) end,
}
if UsePhoenixBall then
    Inner[#Inner + 1] = Def.Sprite { Texture=PX.Big, InitCommand=function(self) Ref.Body = self; self:animate(false):zoom(0.9) end }
    Inner[#Inner + 1] = Def.Sprite { Texture=PX.Titles, InitCommand=function(self) Ref.Title = self; self:animate(false):zoom(0.9) end }
    Inner[#Inner + 1] = Def.BitmapText { Font="Montserrat extrabold 20px", InitCommand=function(self) Ref.Type = self; self:y(-44):zoom(0.7):shadowlength(1):visible(false) end }
elseif XS.Big then
    if XS.BigFrame then Inner[#Inner + 1] = Def.Sprite { Texture=XS.BigFrame, InitCommand=function(self) self:zoom(0.55) end } end
    Inner[#Inner + 1] = Def.Sprite { Texture=XS.Big, InitCommand=function(self) Ref.Body = self; self:animate(false):zoom(0.55) end }
else
    Inner[#Inner + 1] = Def.Sprite { Texture=THEME:GetPathG("", "DifficultyDisplay/LargeBall"), InitCommand=function(self) Ref.Body = self; self:zoom(1.1) end }
    Inner[#Inner + 1] = Def.BitmapText { Font="Montserrat extrabold 20px", InitCommand=function(self) Ref.Type = self; self:y(-36):zoom(0.7):shadowlength(1) end }
end
Inner[#Inner + 1] = Def.BitmapText { Font="Montserrat numbers 40px", InitCommand=function(self) Ref.Level = self; self:y(12):zoom(1.5):shadowlength(3) end }

-- fills the ball from the current steps, once
local function FillBall()
    local Steps = GAMESTATE:GetCurrentSteps(pn)
    if not Steps then
        if Ref.Level then Ref.Level:settext("") end
        return
    end
    local Meter = Steps:GetMeter()
    local Style = Row.Style({ Type = ToEnumShortString(ToEnumShortString(Steps:GetStepsType())), Meter = Meter, Description = Steps:GetDescription() })
    if Ref.Level then Ref.Level:settext(Row.MeterText(Meter)) end
    if UsePhoenixBall then
        local Frame = PhoenixBig[Style.Name]
        -- no half-double ball in Phoenix: the blue ball with the name over it
        if Ref.Body then Ref.Body:setstate(Frame or 3) end
        if Ref.Title then Ref.Title:visible(Frame ~= nil):setstate(Frame or 0) end
        if Ref.Type then Ref.Type:visible(Frame == nil):settext(ToUpper(FullModeChartLabel(Steps))) end
    elseif XS.Big then
        if Ref.Body then Ref.Body:setstate(Style.Big) end
    else
        if Ref.Body then Ref.Body:diffuse(ChartTypeToColor(Steps)) end
        if Ref.Type then Ref.Type:settext(ToUpper(FullModeChartLabel(Steps))) end
    end
end

local Children = {}

-- chart ball: pops in from a bigger size with a white flash
Children[#Children + 1] = Def.ActorFrame {
    InitCommand=function(self) self:xy(BallX, 232) end,
    Def.ActorFrame {
        InitCommand=function(self) self:zoom(1.3):diffusealpha(0) end,
        OnCommand=function(self)
            if not BoardBall then FillBall() end
            self:decelerate(0.3):zoom(1):diffusealpha(1)
        end,
        -- the scoreboard's ball has the type and level drawn in; its ring is 74 px wide, as in the video
        BoardBall and Def.Sprite { Texture=BoardBall, InitCommand=function(self) self:zoom(0.49) end } or Inner,
    },
}
if ShineArt then
    Children[#Children + 1] = Def.Sprite {
        Texture=ShineArt,
        InitCommand=function(self) self:xy(BallX, 232):zoom(0.7):blend("BlendMode_Add") end,
        OnCommand=function(self) self:diffusealpha(1):linear(0.3):diffusealpha(0) end,
    }
end

-- score box, label and counting score appear together
if ScoreBox then
    Children[#Children + 1] = Def.Sprite {
        Texture=ScoreBox,
        InitCommand=function(self) self:xy(X - 7, 297 + 20):zoom(0.55):diffusealpha(0) end,
        OnCommand=function(self) self:sleep(T.ScoreStart):diffusealpha(1) end,
    }
else
    Children[#Children + 1] = Def.Quad {
        InitCommand=function(self) self:xy(X, 297):zoomto(270, 95):diffuse(0, 0, 0, 0) end,
        OnCommand=function(self) self:sleep(T.ScoreStart):diffusealpha(0.5) end,
    }
end
if ScoreLabel then
    -- the game's SCORE is wider than the font: 75 x 13 px at the theme's size
    Children[#Children + 1] = Def.Sprite {
        Texture=ScoreLabel,
        InitCommand=function(self) self:xy(X, 260):zoomx(0.336):zoomy(0.27):diffusealpha(0) end,
        OnCommand=function(self) self:sleep(T.ScoreStart):diffusealpha(1) end,
    }
else
    Children[#Children + 1] = Def.BitmapText {
        Font="Montserrat extrabold 20px",
        Text=THEME:GetString("ResultScreen", "Score"),
        InitCommand=function(self) self:xy(X, 260):diffuse(color("#ffffff")):diffusealpha(0) end,
        OnCommand=function(self) self:sleep(T.ScoreStart):diffusealpha(1) end,
    }
end
local ScoreActor
-- the scoreboard's digits (51 px tall white, shown 33 px tall as in the video), else PumpFox's
local ScoreFont = DigitsIni and { File=DigitsIni, Zoom=0.641 } or { Font="PIUx boost sc num 60px", Zoom=0.78 }
Children[#Children + 1] = Def.BitmapText {
    File=ScoreFont.File,
    Font=ScoreFont.Font,
    Text=R.ScoreText(0),
    InitCommand=function(self) ScoreActor = self; self:xy(X, 297):zoom(ScoreFont.Zoom):diffusealpha(0) end,
    OnCommand=function(self) self:sleep(T.ScoreStart):diffusealpha(1) end,
}

-- difference to the previous best
if DiffText then
    local Hex = R.COLORS[DiffKind] or "#ffffff"
    Children[#Children + 1] = Def.BitmapText {
        Font="Montserrat semibold 20px",
        Text=DiffText,
        InitCommand=function(self) self:xy(X + 132, 330):halign(1):zoom(0.7):diffuse(color(Hex)):diffusealpha(0) end,
        OnCommand=function(self) self:sleep(T.DiffAt):diffusealpha(1) end,
    }
end

-- big grade: blur copies behind, the main one, an additive white flash and the shine
if GradeName then
    local Big, Fin = 2.2, 0.92
    -- the zooms here are for phyrebird's 256 px icon; a grade cut from the video is
    -- 520 px at 1080p scale, so every zoom scales by R.GradeZoom (read from the texture)
    local K = 1
    local function Scale(self) K = R.GradeZoom(self:GetWidth()) / 0.92; return K end
    local InTime = T.GradeIn * 0.5
    local OutTime = T.GradeIn * 0.4
    if GradePath then
        for I = 1, 3 do
            Children[#Children + 1] = Def.Sprite {
                Texture=GradePath,
                InitCommand=function(self) self:xy(X, 428):zoom((Big + 0.15 * I) * Scale(self)):diffusealpha(0) end,
                OnCommand=function(self)
                    self:sleep(T.GradeAt + 0.03 * I):diffusealpha(0.4 - 0.1 * I)
                        :decelerate(InTime):zoom(Fin * K):diffusealpha(0)
                end,
            }
        end
        Children[#Children + 1] = Def.Sprite {
            Texture=GradePath,
            InitCommand=function(self) self:xy(X, 428):zoom(Big * Scale(self)):diffusealpha(0):glow(1, 1, 1, 0) end,
            OnCommand=function(self)
                self:sleep(T.GradeAt):glow(1, 1, 1, 0.9)
                    :decelerate(InTime):zoom(Fin * K):diffusealpha(1)
                    :linear(OutTime):glow(1, 1, 1, 0)
            end,
        }
        Children[#Children + 1] = Def.Sprite {
            Texture=GradePath,
            -- the glow is drawn even at alpha 0, so it starts off and only flashes at GradeAt
            InitCommand=function(self) self:xy(X, 428):zoom(1.25 * Scale(self)):blend("BlendMode_Add"):diffusealpha(0):glow(1, 1, 1, 0) end,
            OnCommand=function(self)
                self:sleep(T.GradeAt):diffusealpha(0.9):glow(1, 1, 1, 1)
                    :decelerate(InTime):zoom(Fin * K)
                    :linear(OutTime):diffusealpha(0):glow(1, 1, 1, 0)
            end,
        }
        if ShineArt then
            Children[#Children + 1] = Def.Sprite {
                Texture=ShineArt,
                InitCommand=function(self) self:xy(X, 428):zoom(1.5):blend("BlendMode_Add"):diffusealpha(0) end,
                OnCommand=function(self) self:sleep(T.GradeAt):diffusealpha(1):linear(T.GradeIn):diffusealpha(0) end,
            }
        end
    else
        -- no art: the grade name without its prefix, silver when broken
        Children[#Children + 1] = Def.BitmapText {
            Font="Montserrat extrabold 40px",
            Text=GradeName:sub(3),
            InitCommand=function(self) self:xy(X, 428):zoom(3):diffuse(color(Broken and "#c0c8d0" or "#ffffff")):diffusealpha(0) end,
            OnCommand=function(self) self:sleep(T.GradeAt):decelerate(InTime):zoom(2.2):diffusealpha(1) end,
        }
    end
end

-- plate
if PlateName then
    if PlatePath then
        Children[#Children + 1] = Def.Sprite {
            Texture=PlatePath,
            InitCommand=function(self) self:xy(X, 560):zoom(PlateZoom * 1.5):diffusealpha(0) end,
            OnCommand=function(self) self:sleep(T.PlateAt):decelerate(T.PlateIn):zoom(PlateZoom):diffusealpha(1) end,
        }
    else
        local TextZoom = 0.8
        Children[#Children + 1] = Def.BitmapText {
            Font="Montserrat extrabold 40px",
            Text=PlateName,
            InitCommand=function(self)
                self:xy(X, 560):zoom(TextZoom * 1.5):maxwidth(240 / TextZoom):shadowlength(2)
                    :diffuse(color("#ff9a2e")):diffusealpha(0)
            end,
            OnCommand=function(self) self:sleep(T.PlateAt):decelerate(T.PlateIn):zoom(TextZoom):diffusealpha(1) end,
        }
    end
end

-- clock: the score counts up, then the update function stops
local Clock = 0
local Last = nil
local Finished = false   -- a flag instead of SetUpdateFunction(nil), which the binding may refuse
Children.OnCommand = function(self)
    Clock = 0
    Finished = false
    self:SetUpdateFunction(function(Frame, Delta)
        if Finished then return end
        Clock = Clock + (Delta or 1 / 60)   -- the engine passes the frame time; 60 FPS if not
        if not ScoreActor then return end
        local Done = Clock >= T.ScoreStart + T.ScoreTime
        local Text = R.ScoreText(Done and Score or R.CountAt(Score, Clock, T.ScoreStart, T.ScoreTime))
        if Text ~= Last then
            Last = Text
            ScoreActor:settext(Text)
        end
        if Done then Finished = true end
    end)
end

return Def.ActorFrame(Children)
