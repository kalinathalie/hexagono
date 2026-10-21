-- The single row of difficulty bubbles at the bottom of the song select screen,
-- with each player's record above/below the bubble. Pure drawing: the chart list
-- and cursors arrive through the ChartRowChanged message from ChartDisplay.lua.
local Row = LoadModule("Select.ChartRow.lua")
local Records = LoadModule("Select.Records.lua")({
    Players = { PLAYER_1, PLAYER_2 },
    GetHighScore = function(pn, song, steps)
        if not GAMESTATE:IsHumanPlayer(pn) or not song or not steps then return nil end
        local Profile = PROFILEMAN:GetProfile(pn)
        if not Profile then return nil end
        local List = Profile:GetHighScoreList(song, steps)
        local Scores = List and List:GetHighScores() or {}
        return Scores[1] and Scores[1]:GetScore() or nil
    end,
})

local Visible = 10
local SlotW = 62
local BallZoom = 0.8          -- DifficultyDisplay/Ball is 64 px logical: ~51 px bubbles
local RecordColor = color("#ffe15a")

-- Phoenix colors: singles red, doubles green; other chart types keep the theme colors
local KindColor = { single = color("#ff2d2d"), double = color("#1fbf3a") }
local function BubbleColor(Chart)
    local Kind = Row.Kind({ Type = ToEnumShortString(ToEnumShortString(Chart:GetStepsType())), Meter = Chart:GetMeter(), Description = Chart:GetDescription() })
    return KindColor[Kind] or ChartTypeToColor(Chart)
end

local t = Def.ActorFrame {
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM + 80) end,
    OnCommand=function(self) self:easeoutexpo(1):y(SCREEN_BOTTOM - 62) end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(1):y(SCREEN_BOTTOM + 80) end,

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
            if Chart then
                Slot:GetChild("Ball"):diffuse(BubbleColor(Chart)):diffusealpha(1)
                Slot:GetChild("Level"):visible(true):settext(Row.MeterText(Chart:GetMeter()))
                Slot:GetChild("RecordP1"):settext(Labels[Item.Index][PLAYER_1] or "")
                Slot:GetChild("RecordP2"):settext(Labels[Item.Index][PLAYER_2] or "")
                Slot:GetChild("CursorP1"):visible(params.Chosen and GAMESTATE:IsHumanPlayer(PLAYER_1) and Index[PLAYER_1] == Item.Index)
                Slot:GetChild("CursorP2"):visible(params.Chosen and GAMESTATE:IsHumanPlayer(PLAYER_2) and Index[PLAYER_2] == Item.Index)
            else
                Slot:GetChild("Ball"):diffuse(color("#2a2f3a")):diffusealpha(1)
                Slot:GetChild("Level"):visible(false)
                Slot:GetChild("RecordP1"):settext("")
                Slot:GetChild("RecordP2"):settext("")
                Slot:GetChild("CursorP1"):visible(false)
                Slot:GetChild("CursorP2"):visible(false)
            end
        end
        self:GetChild("MoreLeft"):visible(Slots.MoreLeft)
        self:GetChild("MoreRight"):visible(Slots.MoreRight)
    end,

    Def.Sprite {
        Name="MoreLeft",
        Texture=THEME:GetPathG("", "DifficultyDisplay/MoreLeft"),
        InitCommand=function(self)
            self:x(-(Visible / 2) * SlotW - 24):zoom(0.35):visible(false)
            :bounce():effectmagnitude(12, 0, 0):effectclock("bgm")
        end
    },
    Def.Sprite {
        Name="MoreRight",
        Texture=THEME:GetPathG("", "DifficultyDisplay/MoreRight"),
        InitCommand=function(self)
            self:x((Visible / 2) * SlotW + 24):zoom(0.35):visible(false)
            :bounce():effectmagnitude(-12, 0, 0):effectclock("bgm")
        end
    },

    -- Footer
    Def.BitmapText {
        Font="Montserrat semibold 20px",
        Text=THEME:GetString("ScreenSelectMusicFull", "ModeLabel"),
        InitCommand=function(self) self:y(52):zoom(0.7):diffuse(color("#dddddd")):diffusealpha(0.9) end,
    },
}

for i = 1, Visible do
    local X = (i - (Visible + 1) / 2) * SlotW
    t[#t+1] = Def.ActorFrame {
        Name="Slot" .. i,
        InitCommand=function(self) self:x(X) end,

        Def.Sprite {
            Name="Ball",
            Texture=THEME:GetPathG("", "DifficultyDisplay/Ball"),
            InitCommand=function(self) self:zoom(BallZoom):diffuse(color("#2a2f3a")) end
        },
        Def.Sprite {
            Name="CursorP1",
            Texture=THEME:GetPathG("", "DifficultyDisplay/Trim"),
            InitCommand=function(self) self:zoom(BallZoom + 0.05):diffuse(Color.White):visible(false) end
        },
        Def.Sprite {
            Name="CursorP2",
            Texture=THEME:GetPathG("", "DifficultyDisplay/Trim"),
            InitCommand=function(self) self:zoom(BallZoom + 0.1):diffuse(color("#46e0ff")):visible(false) end
        },
        Def.BitmapText {
            Name="Level",
            Font="Montserrat numbers 40px",
            InitCommand=function(self) self:zoom(0.6):shadowlength(1):visible(false) end
        },
        Def.BitmapText {
            Name="RecordP1",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(-40):zoom(0.55):diffuse(RecordColor):shadowlength(1):maxwidth(SlotW / 0.55) end
        },
        Def.BitmapText {
            Name="RecordP2",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(40):zoom(0.55):diffuse(RecordColor):shadowlength(1):maxwidth(SlotW / 0.55) end
        },
    }
end

return t
