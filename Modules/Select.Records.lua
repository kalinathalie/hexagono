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
--   Best(highScores) -> the first high score that is not a broken play, or nil

return function(Deps)
    local R = {}

    -- a play where the life bar ran out (Grade_Failed) is never a record
    function R.Best(Scores)
        for _, Score in ipairs(Scores or {}) do
            if Score:GetGrade() ~= "Grade_Failed" then return Score end
        end
        return nil
    end

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

    -- Phoenix record icons: R_<grade> (passed) / B_<grade> (failed, "broken"), and the plates
    local GRADE_NAMES = {
        ["3PS"] = "SSS+", ["3S"] = "SSS", ["2PS"] = "SS+", ["2S"] = "SS", ["PS"] = "S+", ["S"] = "S",
        ["3PA"] = "AAA+", ["3A"] = "AAA", ["2PA"] = "AA+", ["2A"] = "AA", ["PA"] = "A+", ["A"] = "A",
        ["B"] = "B", ["C"] = "C", ["D"] = "D", ["F"] = "F",
    }
    function R.GradeName(Grade)
        if type(Grade) ~= "string" then return nil end
        local Failed = Grade:find("^Fail") ~= nil
        local Name = GRADE_NAMES[Grade:gsub("^Pass", ""):gsub("^Fail", "")]
        if not Name then return nil end
        return (Failed and "B_" or "R_") .. Name
    end
    local PLATE_NAMES = {
        PerfectGame = "PG", UltimateGame = "UG", ExtremeGame = "EG", SuperbGame = "SG",
        MarvelousGame = "MG", TalentedGame = "TG", FairGame = "FG", RoughGame = "RG",
    }
    function R.PlateName(Plate) return PLATE_NAMES[Plate] end

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
