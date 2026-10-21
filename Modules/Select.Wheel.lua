-- Select.Wheel: geometry of the 7-item jacket wheel on the song select screen.
-- Pure Lua, no engine calls.
--
--   Layout(Count, Center, Index) -> { [i] = { Offset, X, Zoom, Alpha } }
--       Offset = i - Index (negative = left of the selected item); spacing 150 px;
--       zoom/alpha by distance: 0 -> 1/1, 1 -> 0.75/0.8, 2+ -> 0.6/0.55
--   Counter(Index, Total) -> "036/139"
--   ImageKind(HasJacket, HasBanner) -> "jacket" | "banner" | "none"

local Wheel = {}

local SPACING = 150
local ZOOM = { [0] = 1, [1] = 0.75 }
local ALPHA = { [0] = 1, [1] = 0.8 }

function Wheel.Layout(Count, Center, Index)
    local Items = {}
    for i = 1, Count do
        local Offset = i - Index
        local Dist = math.min(math.abs(Offset), 2)
        Items[i] = {
            Offset = Offset,
            X = Center + Offset * SPACING,
            Zoom = ZOOM[Dist] or 0.6,
            Alpha = ALPHA[Dist] or 0.55,
        }
    end
    return Items
end

function Wheel.Counter(Index, Total)
    return string.format("%03d/%03d", Index, Total)
end

function Wheel.ImageKind(HasJacket, HasBanner)
    if HasJacket then return "jacket" end
    if HasBanner then return "banner" end
    return "none"
end

return Wheel
