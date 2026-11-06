-- Eval.Result: logic of the result screen (Phoenix 2 style). Pure Lua, no engine
-- calls: the screen actor reads these values and draws them. Not a factory:
--   local R = LoadModule("Eval.Result.lua")
--
-- Returns:
--   Count(n) -> "026"                       at least three digits; nil -> "000"
--   Kcal(x) -> "042.124"                    %07.3f; nil or negative -> "000.000"
--   ScoreText(n) -> "z958873"               seven digits, leading zeros as "z", last digit kept
--   Thousands(n) -> "986,246"               floor with a comma every three digits
--   Diff(score, previous, broken, persistent) -> text, kind | nil
--   PreviousBest(scores, currentIndex) -> HighScore | nil
--   Counts(get, maxCombo, kcal, pumpTiming) -> { perfect, great, good, bad, miss, maxCombo, kcal }
--       pumpTiming true: the "Pump *" judgment windows (W1..W4 only)
--       pumpTiming false or nil: the normal windows (W1..W5)
--   PlateArt(plate) -> "MARVELOUS GAME" | nil
--   GradeArt(grade) -> "R_SS+" | "B_A" | nil     (Select.Records GradeName)
--   Voice(grade) -> "RANK_SS+_R" | "RANK_A_B" | nil
--   VoicePlayer(scores) -> "PlayerNumber_P1" | "PlayerNumber_P2" | nil
--   IsImage(path) -> boolean
--   CountAt(final, t, start, duration) -> number
--   CanExit(elapsed) -> boolean
--   IsCounting(t) -> boolean                 the table or the score is counting up
--   TIMES, COLORS, ROWS -> timings (seconds), colors (hex), and the 7 table rows

local Records = LoadModule("Select.Records.lua")({ Players = {}, GetHighScore = function() return nil end })

local R = {}

R.TIMES = {
    Fade = 0.2, RowsIn = 0.2, RowStagger = 0.05, CountStart = 1.0, CountTime = 0.8,
    ScoreStart = 2.0, ScoreTime = 0.5, DiffAt = 2.5, GradeAt = 3.0, GradeIn = 0.3,
    PlateAt = 3.3, PlateIn = 0.2, InputFrom = 3.5, ExitFade = 0.3, Tick = 0.08,
}

R.COLORS = {
    first = "#ffd23c", up = "#3cff5c", down = "#ff4a3c", perfect = "#2fd5ff", great = "#8cff3c",
    good = "#ffd23c", bad = "#c040ff", miss = "#ff4a3c", maxCombo = "#ffffff", kcal = "#ffffff",
}

R.ROWS = {
    { key = "perfect", text = "Perfect", art = "_perfect" },
    { key = "great", text = "Great", art = "_great" },
    { key = "good", text = "Good", art = "_good" },
    { key = "bad", text = "Bad", art = "_bad" },
    { key = "miss", text = "Miss", art = "_miss" },
    { key = "maxCombo", text = "MaxCombo", art = "_maxcombo" },
    { key = "kcal", text = "Kcal", art = "_cal" },
}

function R.Count(N)
    return string.format("%03d", math.floor(N or 0))
end

function R.Kcal(X)
    if X == nil or X < 0 then return "000.000" end
    return string.format("%07.3f", X)
end

-- Seven digits; the leading zeros become "z" but the last digit is always kept.
-- More than seven digits: the plain number.
function R.ScoreText(N)
    local Value = math.max(math.floor(N or 0), 0)
    local Digits = string.format("%07.0f", Value)
    if #Digits > 7 then return Digits end
    local Zeros = Digits:match("^0*")
    if #Zeros > 6 then Zeros = Zeros:sub(1, 6) end
    return string.rep("z", #Zeros) .. Digits:sub(#Zeros + 1)
end

function R.Thousands(N)
    local Text = string.format("%.0f", math.floor(N or 0))
    local Out = ""
    while #Text > 3 do
        Out = "," .. Text:sub(-3) .. Out
        Text = Text:sub(1, -4)
    end
    return Text .. Out
end

-- Difference to the previous best. Broken plays and guests without a profile
-- show no difference.
function R.Diff(Score, Previous, Broken, Persistent)
    if Broken or not Persistent then return nil end
    if Previous == nil then return "+" .. R.Thousands(Score), "first" end
    if Score >= Previous then return "+" .. R.Thousands(Score - Previous), "up" end
    return "-" .. R.Thousands(Previous - Score), "down"
end

-- The first high score (the list is sorted best to worst) that is not the play
-- at CurrentIndex (0-based; -1 skips nothing) and is not a broken play.
function R.PreviousBest(Scores, CurrentIndex)
    local Skip = CurrentIndex + 1
    for I, Score in ipairs(Scores or {}) do
        if I ~= Skip and Score:GetGrade() ~= "Grade_Failed" then return Score end
    end
    return nil
end

-- Get(name) returns the judgment count (nil counts as 0). The "Pump *" windows
-- have only W1..W4, so with PumpTiming their names shift down by one.
function R.Counts(Get, MaxCombo, Kcal, PumpTiming)
    local function N(Name) return Get(Name) or 0 end
    local Counts = { maxCombo = MaxCombo, kcal = Kcal }
    if PumpTiming then
        Counts.perfect = N("W1") + N("CheckpointHit")
        Counts.great = N("W2")
        Counts.good = N("W3")
        Counts.bad = N("W4")
    else
        Counts.perfect = N("W1") + N("W2") + N("CheckpointHit")
        Counts.great = N("W3")
        Counts.good = N("W4")
        Counts.bad = N("W5")
    end
    Counts.miss = N("Miss") + N("CheckpointMiss")
    return Counts
end

local PLATE_ART = {
    PerfectGame = "PERFECT GAME", UltimateGame = "ULTIMATE GAME", ExtremeGame = "EXTREME GAME",
    SuperbGame = "SUPERB GAME", MarvelousGame = "MARVELOUS GAME", TalentedGame = "TALENTED GAME",
    FairGame = "FAIR GAME", RoughGame = "ROUGH GAME",
}
function R.PlateArt(Plate)
    return PLATE_ART[Plate]
end

function R.GradeArt(Grade)
    return Records.GradeName(Grade)
end

-- Rank voice: "R_SS+" -> "RANK_SS+_R", "B_A" -> "RANK_A_B"
function R.Voice(Grade)
    local Art = R.GradeArt(Grade)
    if not Art then return nil end
    local Name = Art:match("^R_(.+)$")
    if Name then return "RANK_" .. Name .. "_R" end
    Name = Art:match("^B_(.+)$")
    if Name then return "RANK_" .. Name .. "_B" end
    return nil
end

-- The player with the higher score speaks; a tie goes to P2.
function R.VoicePlayer(Scores)
    Scores = Scores or {}
    local P1, P2 = Scores.PlayerNumber_P1, Scores.PlayerNumber_P2
    if P1 == nil and P2 == nil then return nil end
    if P1 == nil then return "PlayerNumber_P2" end
    if P2 == nil then return "PlayerNumber_P1" end
    if P1 > P2 then return "PlayerNumber_P1" end
    return "PlayerNumber_P2"
end

local IMAGE_EXTENSIONS = { png = true, jpg = true, jpeg = true, bmp = true }
function R.IsImage(Path)
    if type(Path) ~= "string" then return false end
    local Ext = Path:match("%.(%w+)$")
    return Ext ~= nil and IMAGE_EXTENSIONS[Ext:lower()] == true
end

-- Count-up value at time T for a tween that starts at Start and lasts Duration.
-- The 1e-6 absorbs floating point error (1.4 - 1.0 = 0.39999...).
function R.CountAt(Final, T, Start, Duration)
    if T <= Start then return 0 end
    if T >= Start + Duration then return Final end
    return math.floor(Final * (T - Start) / Duration + 1e-6)
end

function R.CanExit(Elapsed)
    return Elapsed >= R.TIMES.InputFrom
end

-- True while the table numbers or the score count up (the counting tick plays then).
function R.IsCounting(T)
    local Ti = R.TIMES
    return (T >= Ti.CountStart and T < Ti.CountStart + Ti.CountTime)
        or (T >= Ti.ScoreStart and T < Ti.ScoreStart + Ti.ScoreTime)
end

return R
