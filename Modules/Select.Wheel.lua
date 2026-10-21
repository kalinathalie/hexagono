-- Select.Wheel: geometry of the jacket wheel on the song select screen (and of
-- the group cards, which reuse SlotVisible). Pure Lua, no engine calls.
--
--   Position(Offset) -> X, Zoom
--       Offset = slot distance from the selected item; Phoenix spacing: 222 px to
--       the neighbours, then 205 px; the selected item at full size, the rest 80%
--   SlotVisible(Offset, Count) -> bool
--       false for slots that would repeat a song when the list is shorter than the wheel
--   Counter(Index, Total) -> "036/139"
--   ImageKind(HasJacket, HasBanner) -> "jacket" | "banner" | "none"
--   ThumbPath(SongDir, ThemeName) -> "/Themes/<theme>/Thumbs/<pack>/<song>.jpg" | nil
--       sharp 400x300 thumbnail made by tools/make_thumbs.py from the song's background

local Wheel = {}

local NEIGHBOR, STEP, SIDE_ZOOM = 222, 205, 0.8

function Wheel.Position(Offset)
    if Offset == 0 then return 0, 1 end
    local Dist = math.abs(Offset)
    local Sign = Offset < 0 and -1 or 1
    return Sign * (NEIGHBOR + (Dist - 1) * STEP), SIDE_ZOOM
end

-- With N items and wrap-around, offsets -floor((N-1)/2) .. N-1-floor((N-1)/2)
-- show every item exactly once; anything outside repeats an item.
function Wheel.SlotVisible(Offset, Count)
    if Count < 1 then return false end
    local Left = math.floor((Count - 1) / 2)
    local Right = Count - 1 - Left
    return Offset >= -Left and Offset <= Right
end

function Wheel.Counter(Index, Total)
    return string.format("%03d/%03d", Index, Total)
end

function Wheel.ImageKind(HasJacket, HasBanner)
    if HasJacket then return "jacket" end
    if HasBanner then return "banner" end
    return "none"
end

-- "/Songs/<pack>/<song>/" (any top folder) -> "/Themes/<theme>/Thumbs/<pack>/<song>.jpg"
function Wheel.ThumbPath(SongDir, ThemeName)
    if not SongDir or SongDir == "" then return nil end
    local Rest = SongDir:gsub("/+$", ""):gsub("^/?[^/]+", "")
    if Rest == "" then return nil end
    return "/Themes/" .. ThemeName .. "/Thumbs" .. Rest .. ".jpg"
end

return Wheel
