-- Per-player panel shown while the difficulty is being chosen (Phoenix
-- transition): the selected chart as a big ball with its type and level, the
-- player's best score for it and the grade. Hidden while browsing songs.
local pn = ...
local Side = (pn == PLAYER_2) and 1 or -1
local PanelW, PanelH = 440, 120
local Border = (pn == PLAYER_2) and color("#ff2d9a") or color("#2a6cff")
local ClassicGrades = LoadModule("Config.Load.lua")("ClassicGrades", "Save/OutFoxPrefs.ini")
local ScoringSystem = LoadModule("Config.Load.lua")("ScoringSystem", "Save/OutFoxPrefs.ini") or "Old"
if ScoringSystem ~= "Old" then ClassicGrades = false end

local function BestScore(Song, Steps)
    if not Song or not Steps or not GAMESTATE:IsHumanPlayer(pn) then return nil end
    local Profile = PROFILEMAN:GetProfile(pn)
    if not Profile then return nil end
    local List = Profile:GetHighScoreList(Song, Steps)
    local Scores = List and List:GetHighScores() or {}
    return Scores[1]
end

return Def.ActorFrame {
    InitCommand=function(self)
        self:xy(SCREEN_CENTER_X + Side * 330, SCREEN_BOTTOM + PanelH):visible(GAMESTATE:IsHumanPlayer(pn))
    end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(0.4):y(SCREEN_BOTTOM + PanelH) end,
    SongChosenMessageCommand=function(self)
        self:playcommand("Refresh"):stoptweening():easeoutexpo(0.4):y(SCREEN_BOTTOM - 150)
    end,
    SongUnchosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.4):y(SCREEN_BOTTOM + PanelH) end,
    CurrentChartChangedMessageCommand=function(self, params) if params.Player == pn then self:playcommand("Refresh") end end,
    UpdateChartDisplayMessageCommand=function(self, params) if params.Player == pn then self:playcommand("Refresh") end end,
    PlayerJoinedMessageCommand=function(self) self:visible(GAMESTATE:IsHumanPlayer(pn)) end,

    RefreshCommand=function(self)
        local Song = GAMESTATE:GetCurrentSong()
        local Steps = GAMESTATE:GetCurrentSteps(pn)
        local Level, Type, Score, Grade = self:GetChild("Level"), self:GetChild("Type"), self:GetChild("Score"), self:GetChild("Grade")
        if not Steps then
            Level:settext(""); Type:settext(""); Score:settext("-"); Grade:visible(false)
            return
        end
        local Meter = Steps:GetMeter()
        Level:settext(Meter == 99 and "??" or string.format("%02d", Meter))
        Type:settext(ToUpper(FullModeChartLabel(Steps)))
        -- same colors as the bubbles: plain single red, plain double green, others from the theme
        local Kind = LoadModule("Select.ChartRow.lua").Kind({ Type = ToEnumShortString(ToEnumShortString(Steps:GetStepsType())), Meter = Meter, Description = Steps:GetDescription() })
        local KindColor = { single = color("#ff2d2d"), double = color("#1fbf3a") }
        self:GetChild("Ball"):diffuse(KindColor[Kind] or ChartTypeToColor(Steps))
        local Best = BestScore(Song, Steps)
        if Best and Best:GetScore() > 0 then
            Score:settext(FormatScore(Best:GetScore()))
            local Path = THEME:GetPathG("", "LetterGrades/" .. (ClassicGrades and "" or "New/") .. LoadModule("PIU/Score.Grading.lua")(Best), true)
            if Path and Path ~= "" then Grade:visible(true):Load(Path):zoom(0.45) else Grade:visible(false) end
        else
            Score:settext("-")
            Grade:visible(false)
        end
    end,

    -- Panel body
    Def.Quad { InitCommand=function(self) self:zoomto(PanelW + 4, PanelH + 4):diffuse(Border) end },
    Def.Quad { InitCommand=function(self) self:zoomto(PanelW, PanelH):diffuse(color("#0b1220")):diffusealpha(0.92) end },

    -- Big difficulty ball on the outer side (left for P1, right for P2)
    Def.Sprite {
        Name="Ball",
        Texture=THEME:GetPathG("", "DifficultyDisplay/LargeBall"),
        InitCommand=function(self) self:x(Side * -(PanelW / 2 - 70)):zoom(0.9) end,
    },
    Def.Sprite {
        Texture=THEME:GetPathG("", "DifficultyDisplay/LargeTrim"),
        InitCommand=function(self) self:x(Side * -(PanelW / 2 - 70)):zoom(0.9) end,
    },
    Def.BitmapText {
        Name="Type",
        Font="Montserrat extrabold 20px",
        InitCommand=function(self) self:xy(Side * -(PanelW / 2 - 70), -22):zoom(0.55):maxwidth(100 / 0.55):shadowlength(1) end,
    },
    Def.BitmapText {
        Name="Level",
        Font="Montserrat numbers 40px",
        InitCommand=function(self) self:xy(Side * -(PanelW / 2 - 70), 8):zoom(1.1):shadowlength(2) end,
    },

    -- MY BEST
    Def.BitmapText {
        Font="Montserrat extrabold 20px",
        Text=THEME:GetString("ScreenSelectMusicFull", "MyBest"),
        InitCommand=function(self) self:xy(Side * 50, -40):zoom(0.7):diffuse(color("#ffe15a")):shadowlength(1) end,
    },
    Def.Quad { InitCommand=function(self) self:xy(Side * 50, -12):zoomto(190, 28):diffuse(Color.Black):diffusealpha(0.6) end },
    Def.BitmapText {
        Name="Score",
        Font="Montserrat semibold 20px",
        InitCommand=function(self) self:xy(Side * 50, -12):zoom(0.9):shadowlength(1) end,
    },
    Def.Sprite {
        Name="Grade",
        InitCommand=function(self) self:xy(Side * 50, 30):visible(false) end,
    },
}
