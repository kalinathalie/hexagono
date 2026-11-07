-- Result table (Phoenix 2): 7 judgment rows in the center, with each player's
-- numbers counting from 0 to the final value. Pure drawing; the formatting and
-- the counting math live in Modules/Eval.Result.lua.
local R = LoadModule("Eval.Result.lua")
local Art = LoadModule("Select.Art.lua")

local Green = "#3cff5c"
local RowX, RowY0, RowStep = SCREEN_CENTER_X, 310, 38
local NumberX = { [PLAYER_1] = 407, [PLAYER_2] = 875 }
local NumberZoom = 1.05            -- Montserrat semibold 20px: ~15 px digit height
local BurstTime = 0.15             -- zoomx 0 -> 1
local FlashTime = 0.25

-- Numbers for the human players (loaded once, at creation)
local Pump = (LoadModule("Config.Load.lua")("SmartTimings", "Save/OutFoxPrefs.ini") or ""):find("Pump") ~= nil
local Players = {}
for _, pn in ipairs(GAMESTATE:GetHumanPlayers()) do
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
    if pss and NumberX[pn] then
        Players[#Players + 1] = {
            pn = pn,
            C = R.Counts(function(n) return pss:GetTapNoteScores("TapNoteScore_" .. n) end,
                pss:MaxCombo(), pss:GetCaloriesBurned(), Pump),
        }
    end
end

local Texts = {}   -- { Actor = BitmapText, Key = row key, Final = number (kcal: thousandths), Kcal = kcal }

-- Final text of a number, exactly as the module formats it
local function FinalText(Entry)
    if Entry.Key == "kcal" then return R.Kcal(Entry.Kcal) end
    return R.Count(Entry.Final)
end

local function Finish()
    for _, Entry in ipairs(Texts) do
        Entry.Actor:visible(true):settext(FinalText(Entry))
    end
end

-- Band behind a row. With the scoreboard's labels (pi/assets/lbpiu.py): the green band
-- and the label, as in the game. Else phyrebird's art (band and label in one image).
-- Else the green band and the label as text.
local BandW, BandH = 540, 24         -- 36 px tall at 1080p in the video, a dark gap between rows
local LabelZoom = 0.316           -- the label's 2x art: PERFECT 150 px wide at 1080p, as in the video
local function RowBand(Row)
    local Label = Art("Phoenix/Scoreboard/Labels/" .. Row.art)
    if Label then
        return Def.ActorFrame {
            LoadActor("GreenBand", { Width = BandW, Height = BandH }),
            Def.Sprite { Texture = Label, InitCommand = function(self) self:zoom(LabelZoom) end },
        }
    end
    local Path = Art("Phoenix/Evaluation/" .. Row.art)
    if Path then
        return Def.Sprite { Texture = Path, InitCommand = function(self) self:zoom(0.95) end }
    end
    return Def.ActorFrame {
        LoadActor("GreenBand", { Width = BandW, Height = BandH }),
        Def.BitmapText {
            Font = "Montserrat extrabold 20px",
            Text = THEME:GetString("ResultScreen", Row.text),
            InitCommand = function(self) self:diffuse(color(R.COLORS[Row.key])):shadowlength(1) end,
        },
    }
end

local Children = {}

for i, Row in ipairs(R.ROWS) do
    local Y = RowY0 + RowStep * (i - 1)
    local Delay = R.TIMES.RowsIn + (i - 1) * R.TIMES.RowStagger
    Children[#Children + 1] = Def.ActorFrame {
        InitCommand = function(self) self:xy(RowX, Y):zoomx(0) end,
        OnCommand = function(self) self:zoomx(0):sleep(Delay):decelerate(BurstTime):zoomx(1) end,
        RowBand(Row),
        -- additive flash that fades right after the burst
        Def.Quad {
            InitCommand = function(self)
                self:zoomto(560, BandH):diffuse(color(Green)):diffusealpha(0):blend("BlendMode_Add")
                    :fadeleft(0.3):faderight(0.3)
            end,
            OnCommand = function(self)
                self:diffusealpha(0):sleep(Delay):diffusealpha(0.8):linear(FlashTime):diffusealpha(0)
            end,
        },
    }
end

-- Numbers on top of the rows; hidden until the count starts
for _, P in ipairs(Players) do
    for i, Row in ipairs(R.ROWS) do
        local Final = P.C[Row.key] or 0
        if Row.key == "kcal" then Final = math.floor((P.C.kcal or 0) * 1000 + 0.5) end
        local Entry = { Key = Row.key, Final = Final, Kcal = P.C.kcal }
        Texts[#Texts + 1] = Entry
        Children[#Children + 1] = Def.BitmapText {
            Font = "Montserrat semibold 20px",
            Text = "",
            InitCommand = function(self)
                Entry.Actor = self
                self:xy(NumberX[P.pn], RowY0 + RowStep * (i - 1)):halign(P.pn == PLAYER_1 and 0 or 1)
                    :zoom(NumberZoom):diffuse(color("#ffffff")):visible(false)
            end,
        }
    end
end

local T = 0
local Finished = false   -- a flag instead of SetUpdateFunction(nil), which the binding may refuse

return Def.ActorFrame {
    OnCommand = function(self)
        T = 0
        Finished = false
        local Start, Time = R.TIMES.CountStart, R.TIMES.CountTime
        self:SetUpdateFunction(function(Frame, Dt)
            if Finished then return end
            T = T + (Dt or 1 / 60)   -- the engine passes the frame time; 60 FPS if not
            if T < Start then return end
            if T >= Start + Time then
                Finish()
                Finished = true
                return
            end
            for _, Entry in ipairs(Texts) do
                local Value = R.CountAt(Entry.Final, T, Start, Time)
                local Text
                if Entry.Key == "kcal" then Text = R.Kcal(Value / 1000) else Text = R.Count(Value) end
                Entry.Actor:visible(true):settext(Text)
            end
        end)
    end,
    unpack(Children),
}
