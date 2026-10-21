-- The row of difficulty bubbles at the bottom of the song select screen
-- (Phoenix layout, 13 slots). Each bubble shows the level; above it the grade
-- label and the player's record (player 2 below). Pure drawing: the chart list
-- and cursors arrive through the ChartRowChanged message from ChartDisplay.lua.
-- While a song is chosen the row moves up to the wheel's place and grows.
local Row = LoadModule("Select.ChartRow.lua")
local Art = LoadModule("Select.Art.lua")
local Grading = LoadModule("PIU/Score.Grading.lua")

local BallArt = Art("StepList_Ballons 4x4")   -- glossy balls by type, frame 7 = empty
local GradeArt = Art("sl_grade 1x17")         -- small SSS+ .. F labels
local CursorArt = Art("SSM-FULL-CURSOR 2x2")  -- 1P top / 2P bottom half rings

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
local BallZoom = BallArt and 0.42 or 1.05     -- 160 px art frames / 64 px theme ball
local RowY, ChosenY, ChosenZoom = 650, 470, 1.15
local RecordColor = color("#ffe15a")

-- Fallback colors when the XSanity balls are missing
local KindColor = { single = color("#ff2d2d"), double = color("#1fbf3a") }
local function ChartInfo(Chart)
    return { Type = ToEnumShortString(ToEnumShortString(Chart:GetStepsType())), Meter = Chart:GetMeter(), Description = Chart:GetDescription() }
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
                local Info = ChartInfo(Chart)
                if BallArt then Ball:setstate(Row.Style(Info).Ball)
                else Ball:diffuse(KindColor[Row.Kind(Info)] or ChartTypeToColor(Chart)) end
                Slot:GetChild("Level"):visible(true):settext(Row.MeterText(Chart:GetMeter()))
                for _, pn in ipairs({ PLAYER_1, PLAYER_2 }) do
                    local Tag = ToEnumShortString(pn)
                    local Label = Labels[Item.Index][pn] or ""
                    Slot:GetChild("Record" .. Tag):settext(Label)
                    local Grade = Slot:GetChild("Grade" .. Tag)
                    local Frame = nil
                    if Label ~= "" and GradeArt then
                        local Best = BestScore(pn, params.Song, Chart)
                        Frame = Best and Records.GradeFrame(Grading(Best)) or nil
                    end
                    if Frame then Grade:visible(true):setstate(Frame) else Grade:visible(false) end
                    local CursorOn = params.Chosen and GAMESTATE:IsHumanPlayer(pn) and Index[pn] == Item.Index
                    Slot:GetChild("Cursor" .. Tag):visible(CursorOn)
                    -- the 1P/2P label of the cursor sits where the record is: move the record past it
                    Slot:GetChild("Record" .. Tag):y((pn == PLAYER_1 and -1 or 1) * ((CursorOn and CursorArt) and 68 or 47))
                end
            else
                if BallArt then Ball:setstate(Row.EmptyBall) else Ball:diffuse(color("#2a2f3a")) end
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

local function Cursor(Tag, Y, Frame)
    if CursorArt then
        return Def.Sprite {
            Name="Cursor" .. Tag, Texture=CursorArt,
            InitCommand=function(self)
                self:y(Y):animate(false):setstate(Frame):visible(false)
                :diffuseshift():effectcolor1(color("1,1,1,1")):effectcolor2(color("1,1,1,0.55")):effectperiod(0.8)
            end,
        }
    end
    return Def.Sprite {
        Name="Cursor" .. Tag, Texture=THEME:GetPathG("", "DifficultyDisplay/Trim"),
        InitCommand=function(self) self:zoom(1.15):diffuse(Tag == "P1" and Color.White or color("#46e0ff")):visible(false) end,
    }
end

local function Grade(Tag, Y)
    if GradeArt then
        return Def.Sprite {
            Name="Grade" .. Tag, Texture=GradeArt,
            InitCommand=function(self) self:y(Y):animate(false):zoom(0.45):visible(false) end,
        }
    end
    return Def.Actor { Name="Grade" .. Tag }
end

for i = 1, Visible do
    local X = (i - (Visible + 1) / 2) * SlotW
    local BallSprite
    if BallArt then
        BallSprite = Def.Sprite { Name="Ball", Texture=BallArt, InitCommand=function(self) self:zoom(BallZoom):animate(false):setstate(Row.EmptyBall) end }
    else
        BallSprite = Def.Sprite { Name="Ball", Texture=THEME:GetPathG("", "DifficultyDisplay/Ball"), InitCommand=function(self) self:zoom(BallZoom):diffuse(color("#2a2f3a")) end }
    end
    t[#t+1] = Def.ActorFrame {
        Name="Slot" .. i,
        InitCommand=function(self) self:x(X) end,

        BallSprite,
        Def.BitmapText {
            Name="Level",
            Font="Montserrat numbers 40px",
            InitCommand=function(self) self:zoom(0.72):shadowlength(2):visible(false) end
        },
        -- player 1 above the bubble: grade on the rim, record above it
        Grade("P1", -32),
        Def.BitmapText {
            Name="RecordP1",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(-47):zoom(0.52):diffuse(RecordColor):shadowlength(1):maxwidth(SlotW / 0.52) end
        },
        -- player 2 below the bubble
        Grade("P2", 32),
        Def.BitmapText {
            Name="RecordP2",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(47):zoom(0.52):diffuse(RecordColor):shadowlength(1):maxwidth(SlotW / 0.52) end
        },
        Cursor("P1", -30, 1),
        Cursor("P2", 30, 3),
    }
end

return t
