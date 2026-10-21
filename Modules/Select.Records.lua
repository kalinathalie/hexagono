-- Select.Records: the player's record for a chart as the text shown above its
-- difficulty bubble. Pure Lua; engine access goes through Deps so it can be
-- unit tested.
--
-- Deps:
--   Players -> list of player identifiers (e.g. { PLAYER_1, PLAYER_2 })
--   GetHighScore(pn, song, steps) -> number|nil   (nil when no record)
--
-- Returns:
--   Label(pn, song, steps) -> "878123" or "" (no record, zero or not a number)
--   LabelsFor(song, stepsList) -> { [i] = { [pn] = label } } for every player in Deps.Players

return function(Deps)
    local R = {}

    function R.Label(pn, song, steps)
        local Score = Deps.GetHighScore(pn, song, steps)
        if type(Score) ~= "number" or Score <= 0 then return "" end
        return string.format("%d", math.floor(Score))
    end

    -- Theme grade names ("Pass2S", "FailA", from PIU/Score.Grading.lua) to the
    -- frames of the XSanity grade labels (sl_grade 1x17: SSS+ .. F)
    local GRADE_FRAMES = {
        ["3PS"] = 0, ["3S"] = 1, ["2PS"] = 2, ["2S"] = 3, ["PS"] = 4, ["S"] = 5,
        ["3PA"] = 6, ["3A"] = 7, ["2PA"] = 8, ["2A"] = 9, ["PA"] = 10, ["A"] = 11,
        ["B"] = 12, ["C"] = 13, ["D"] = 14, ["F"] = 15,
    }
    function R.GradeFrame(Grade)
        if type(Grade) ~= "string" then return nil end
        return GRADE_FRAMES[Grade:gsub("^Pass", ""):gsub("^Fail", "")]
    end

    function R.LabelsFor(song, stepsList)
        local Out = {}
        for i, Steps in ipairs(stepsList) do
            Out[i] = {}
            for _, pn in ipairs(Deps.Players) do
                Out[i][pn] = R.Label(pn, song, Steps)
            end
        end
        return Out
    end

    return R
end
