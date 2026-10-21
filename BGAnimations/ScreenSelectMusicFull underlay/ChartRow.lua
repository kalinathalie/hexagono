-- The row of difficulty bubbles at the bottom of the song select screen
-- (Phoenix layout, 13 slots). Each bubble shows the level; above it the grade
-- icon and the player's record (player 2 below). Pure drawing: the chart list
-- and cursors arrive through the ChartRowChanged message from ChartDisplay.lua.
-- While a song is chosen the row moves up to the wheel's place and grows.
--
-- Art, in order of preference: the local Phoenix graphics (Graphics/Phoenix),
-- the local XSanity graphics (Graphics/XSanity), then the theme's own ball.
local Row = LoadModule("Select.ChartRow.lua")
local Art = LoadModule("Select.Art.lua")
local Grading = LoadModule("PIU/Score.Grading.lua")

local PX = {
    Balls = Art("Phoenix/fullbar balls 7x1"),     -- red, green, purple, blue, grey, cyan, yellow
    Base = Art("Phoenix/blackball"),               -- dark empty ball under every slot
    Cursor = { P1 = Art("Phoenix/fullbar_PlayerNumber_P1_cursor"), P2 = Art("Phoenix/fullbar_PlayerNumber_P2_cursor") },
}
local PhoenixFrame = { single = 0, double = 1, singlep = 2, doublep = 3, half = 5, coop = 6 }
local XS = {
    Balls = Art("XSanity/StepList_Ballons 4x4"),  -- glossy balls by type, frame 7 = empty
    Grades = Art("XSanity/sl_grade 1x17"),        -- small SSS+ .. F labels
    Cursor = Art("XSanity/SSM-FULL-CURSOR 2x2"),  -- 1P top / 2P bottom half rings
}
local UsePhoenix = PX.Balls and PX.Base

local function BestScore(pn, song, steps)
    if not GAMESTATE:IsHumanPlayer(pn) or not song or not steps then return nil end
    local Profile = PROFILEMAN:GetProfile(pn)
    if not Profile then return nil end
    local List = Profile:GetHighScoreList(song, steps)
    local Scores = List and List:GetHighScores() or {}
    return Scores[1]
end

local Records = LoadModule("Select.Records.lua")({
    Players = { PLAYER_1, PLAYER_2 },
    GetHighScore = function(pn, song, steps)
        local Best = BestScore(pn, song, steps)
        return Best and Best:GetScore() or nil
    end,
})

local Visible = 13
local SlotW = 76
local RowY, ChosenY, ChosenZoom = 650, 470, 1.15
local RecordColor = color("#ffe15a")

-- Fallback colors when no ball art is present
local KindColor = { single = color("#ff2d2d"), double = color("#1fbf3a") }
local function ChartInfo(Chart)
    return { Type = ToEnumShortString(ToEnumShortString(Chart:GetStepsType())), Meter = Chart:GetMeter(), Description = Chart:GetDescription() }
end

-- Grade icon of a record: Phoenix R_/B_ icons, else the XSanity label sheet
local function SetGrade(Sprite, Best)
    if not Best then Sprite:visible(false) return end
    local Grade = Grading(Best)
    local Name = Records.GradeName(Grade)
    local Path = Name and Art("Phoenix/RecordGrades/" .. Name .. " (doubleres)")
    if Path then
        Sprite:visible(true):Load(Path):zoom(0.85)
    elseif XS.Grades and Records.GradeFrame(Grade) then
        Sprite:visible(true):Load(XS.Grades):animate(false):setstate(Records.GradeFrame(Grade)):zoom(0.45)
    else
        Sprite:visible(false)
    end
end

local t = Def.ActorFrame {
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM + 80) end,
    OnCommand=function(self) self:easeoutexpo(1):y(RowY) end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(1):y(SCREEN_BOTTOM + 80) end,
    SongChosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.4):y(ChosenY):zoom(ChosenZoom) end,
    SongUnchosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.4):y(RowY):zoom(1) end,

    ChartRowChangedMessageCommand=function(self, params)
        local Charts = params.Charts
        local Index = params.Index
        -- the row scrolls after the enabled player who moved last, so the cursor stays visible
        local Enabled = { [PLAYER_1] = GAMESTATE:IsPlayerEnabled(PLAYER_1), [PLAYER_2] = GAMESTATE:IsPlayerEnabled(PLAYER_2) }
        local MainIndex = Row.MainIndex(Index, Enabled, params.Mover)
        local Slots = Row.Slots(Charts, MainIndex, Visible)
        local Labels = Records.LabelsFor(params.Song, Charts)

        for i = 1, Visible do
            local Slot = self:GetChild("Slot" .. i)
            local Item = Slots.Items[i]
            local Chart = Item.Chart
            local Ball = Slot:GetChild("Ball")
            if Chart then
                local Style = Row.Style(ChartInfo(Chart))
                if UsePhoenix then Ball:visible(true):setstate(PhoenixFrame[Style.Name] or 6)
                elseif XS.Balls then Ball:setstate(Style.Ball)
                else Ball:diffuse(KindColor[Row.Kind(ChartInfo(Chart))] or ChartTypeToColor(Chart)) end
                Slot:GetChild("Level"):visible(true):settext(Row.MeterText(Chart:GetMeter()))
                for _, pn in ipairs({ PLAYER_1, PLAYER_2 }) do
                    local Tag = ToEnumShortString(pn)
                    local Label = Labels[Item.Index][pn] or ""
                    Slot:GetChild("Record" .. Tag):settext(Label)
                    SetGrade(Slot:GetChild("Grade" .. Tag), Label ~= "" and BestScore(pn, params.Song, Chart) or nil)
                    local CursorOn = params.Chosen and GAMESTATE:IsHumanPlayer(pn) and Index[pn] == Item.Index
                    Slot:GetChild("Cursor" .. Tag):visible(CursorOn)
                    -- the cursor's 1P/2P label sits where the record is: move the record past it
                    local HasCursorArt = UsePhoenix and PX.Cursor[Tag] or XS.Cursor
                    Slot:GetChild("Record" .. Tag):y((pn == PLAYER_1 and -1 or 1) * ((CursorOn and HasCursorArt) and 66 or 50))
                end
            else
                if UsePhoenix then Ball:visible(false)
                elseif XS.Balls then Ball:setstate(Row.EmptyBall)
                else Ball:diffuse(color("#2a2f3a")) end
                Slot:GetChild("Level"):visible(false)
                for _, Tag in ipairs({ "P1", "P2" }) do
                    Slot:GetChild("Record" .. Tag):settext("")
                    Slot:GetChild("Grade" .. Tag):visible(false)
                    Slot:GetChild("Cursor" .. Tag):visible(false)
                end
            end
        end
        self:GetChild("MoreLeft"):visible(Slots.MoreLeft)
        self:GetChild("MoreRight"):visible(Slots.MoreRight)
    end,

    Def.Sprite {
        Name="MoreLeft",
        Texture=THEME:GetPathG("", "DifficultyDisplay/MoreLeft"),
        InitCommand=function(self)
            self:x(-(Visible / 2) * SlotW - 26):zoom(0.35):visible(false)
            :bounce():effectmagnitude(12, 0, 0):effectclock("bgm")
        end
    },
    Def.Sprite {
        Name="MoreRight",
        Texture=THEME:GetPathG("", "DifficultyDisplay/MoreRight"),
        InitCommand=function(self)
            self:x((Visible / 2) * SlotW + 26):zoom(0.35):visible(false)
            :bounce():effectmagnitude(-12, 0, 0):effectclock("bgm")
        end
    },
}

local function Cursor(Tag)
    local Pulse = function(self) self:diffuseshift():effectcolor1(color("1,1,1,1")):effectcolor2(color("1,1,1,0.55")):effectperiod(0.8) end
    if UsePhoenix and PX.Cursor[Tag] then
        -- Phoenix ring halves: 1P above, 2P below, both centered on the ball
        return Def.Sprite { Name="Cursor" .. Tag, Texture=PX.Cursor[Tag], InitCommand=function(self) self:zoom(1.35):visible(false) Pulse(self) end }
    elseif XS.Cursor then
        return Def.Sprite {
            Name="Cursor" .. Tag, Texture=XS.Cursor,
            InitCommand=function(self) self:y(Tag == "P1" and -30 or 30):animate(false):setstate(Tag == "P1" and 1 or 3):visible(false) Pulse(self) end,
        }
    end
    return Def.Sprite {
        Name="Cursor" .. Tag, Texture=THEME:GetPathG("", "DifficultyDisplay/Trim"),
        InitCommand=function(self) self:zoom(1.15):diffuse(Tag == "P1" and Color.White or color("#46e0ff")):visible(false) end,
    }
end

local function BallSprites()
    if UsePhoenix then
        return {
            Def.Sprite { Texture=PX.Base, InitCommand=function(self) self:zoom(1.0) end },
            Def.Sprite { Name="Ball", Texture=PX.Balls, InitCommand=function(self) self:zoom(1.17):animate(false):visible(false) end },
        }
    elseif XS.Balls then
        return { Def.Sprite { Name="Ball", Texture=XS.Balls, InitCommand=function(self) self:zoom(0.42):animate(false):setstate(Row.EmptyBall) end } }
    end
    return { Def.Sprite { Name="Ball", Texture=THEME:GetPathG("", "DifficultyDisplay/Ball"), InitCommand=function(self) self:zoom(1.05):diffuse(color("#2a2f3a")) end } }
end

for i = 1, Visible do
    local Slot = Def.ActorFrame {
        Name="Slot" .. i,
        InitCommand=function(self) self:x((i - (Visible + 1) / 2) * SlotW) end,
    }
    for _, Sprite in ipairs(BallSprites()) do Slot[#Slot + 1] = Sprite end
    Slot[#Slot + 1] = Def.BitmapText {
        Name="Level",
        Font="Montserrat numbers 40px",
        InitCommand=function(self) self:zoom(0.72):shadowlength(2):visible(false) end
    }
    -- player 1 above the bubble: grade icon on the rim, record above it; player 2 below
    Slot[#Slot + 1] = Def.Sprite { Name="GradeP1", InitCommand=function(self) self:y(-33):visible(false) end }
    Slot[#Slot + 1] = Def.BitmapText {
        Name="RecordP1",
        Font="Montserrat semibold 20px",
        InitCommand=function(self) self:y(-50):zoom(0.52):diffuse(RecordColor):shadowlength(1):maxwidth(SlotW / 0.52) end
    }
    Slot[#Slot + 1] = Def.Sprite { Name="GradeP2", InitCommand=function(self) self:y(33):visible(false) end }
    Slot[#Slot + 1] = Def.BitmapText {
        Name="RecordP2",
        Font="Montserrat semibold 20px",
        InitCommand=function(self) self:y(50):zoom(0.52):diffuse(RecordColor):shadowlength(1):maxwidth(SlotW / 0.52) end
    }
    Slot[#Slot + 1] = Cursor("P1")
    Slot[#Slot + 1] = Cursor("P2")
    t[#t+1] = Slot
end

return t
