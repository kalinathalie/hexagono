-- Chart.HiddenNotes: notes marked hidden in SSC charts written in the StepF2
-- note syntax, e.g. {2|h|0|0} (a hold head with the "h" appearance). On the
-- arcade those notes are invisible but still have to be stepped on; OutFox
-- reads them but draws them. The regions returned here go to
-- NoteField:add_hidden_regions, which hides them and keeps them judged.
-- Pure Lua, no engine calls.
--
--   Find(ssctext, want) -> the #NOTES text of the matching chart, or nil
--       want = { StepsType = "pump-single", Description, Meter, Difficulty = "Edit", ChartName (optional) }
--   Regions(notes) -> { { start_beat, end_beat, column (1-based) }, ... }

local Hidden = {}

local function Trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

function Hidden.Find(text, want)
    if not text then return nil end
    local Fallback = nil
    -- the text between one #NOTEDATA: and the next is one chart
    local Starts, Pos = {}, 1
    while true do
        local a = text:find("#NOTEDATA:", Pos, true)
        if not a then break end
        Starts[#Starts + 1] = a
        Pos = a + 1
    end
    for i, a in ipairs(Starts) do
        local Block = text:sub(a, (Starts[i + 1] or (#text + 1)) - 1)
        local Tags = {}
        for Key, Value in Block:gmatch("#(%u+):([^;]*);") do Tags[Key] = Value end
        if Trim(Tags.STEPSTYPE):lower() == tostring(want.StepsType):lower()
            and Trim(Tags.DESCRIPTION) == Trim(want.Description)
            and tonumber(Tags.METER) == tonumber(want.Meter)
            and Trim(Tags.DIFFICULTY):lower() == tostring(want.Difficulty):lower() then
            if want.ChartName == nil or Trim(Tags.CHARTNAME) == Trim(want.ChartName) then return Tags.NOTES end
            Fallback = Fallback or Tags.NOTES
        end
    end
    return Fallback
end

-- One row of note data -> list of { char, appearance } per column
local function Cells(Row)
    local Out, i = {}, 1
    while i <= #Row do
        local c = Row:sub(i, i)
        if c == "{" then
            local j = Row:find("}", i, true) or #Row
            local Fields = {}
            for f in Row:sub(i + 1, j - 1):gmatch("[^|]+") do Fields[#Fields + 1] = f end
            Out[#Out + 1] = { Fields[1] or "0", Fields[2] or "n" }
            i = j + 1
        elseif c == "[" then
            -- keysound index after a note: not a column
            i = (Row:find("]", i, true) or #Row) + 1
        else
            Out[#Out + 1] = { c, "n" }
            i = i + 1
        end
    end
    return Out
end

local PAD = 0.005

function Hidden.Regions(notes)
    local Regions = {}
    if not notes then return Regions end
    local Clean = notes:gsub("//[^\n]*", "")
    local OpenHolds = {}
    local Measure = 0
    for Text in (Clean .. ","):gmatch("([^,]*),") do
        local Rows = {}
        for Line in Text:gmatch("[^\r\n]+") do
            Line = Trim(Line)
            if Line ~= "" then Rows[#Rows + 1] = Line end
        end
        for r, Row in ipairs(Rows) do
            local Beat = Measure * 4 + (r - 1) * 4 / #Rows
            for Col, Cell in ipairs(Cells(Row)) do
                local Kind, Look = Cell[1], Cell[2]
                if Kind == "2" or Kind == "4" then
                    OpenHolds[Col] = { Beat = Beat, Hidden = Look == "h" }
                elseif Kind == "3" then
                    local Head = OpenHolds[Col]
                    if Head and Head.Hidden then Regions[#Regions + 1] = { Head.Beat - PAD, Beat + PAD, Col } end
                    OpenHolds[Col] = nil
                elseif Look == "h" and Kind ~= "0" then
                    Regions[#Regions + 1] = { Beat - PAD, Beat + PAD, Col }
                end
            end
        end
        if #Rows > 0 then Measure = Measure + 1 end
    end
    return Regions
end

return Hidden
