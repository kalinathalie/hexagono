-- Select.GroupCards: what a hexagonal card on the group select screen shows.
-- Pure Lua, no engine calls.
--
-- Category is the sorting category name from Scripts/01 Sorting.lua ("Special",
-- "Group", "Title", "Artist", "Single", "Half-Double", "Double") or nil when the
-- card itself represents a category. SubName is the subgroup name.
--
--   Kind(Category, SubName)  -> "version" | "level" | "letter" | "special" | "category"
--   Title(Category, SubName) -> text drawn on the card ("XX", "S17", "D22", "HD10", "A", "Co-op", "Group")
--   Image(Category, SubName, BannerPath) -> BannerPath for version cards (nil when empty), nil otherwise

local Cards = {}

local LEVEL_PREFIX = { ["Single"] = "S", ["Double"] = "D", ["Half-Double"] = "HD" }

function Cards.Kind(Category, SubName)
    if Category == nil then return "category" end
    if Category == "Group" then return "version" end
    if LEVEL_PREFIX[Category] then return "level" end
    if Category == "Title" or Category == "Artist" then return "letter" end
    return "special"
end

function Cards.Title(Category, SubName)
    local Kind = Cards.Kind(Category, SubName)
    if Kind == "version" then
        -- "14 - XX" -> "XX"; names without the numeric prefix stay as they are
        return (SubName:gsub("^%d+%s*%-%s*", ""))
    elseif Kind == "level" then
        local Meter = SubName:match("(%d+)$")
        if not Meter then return SubName end
        -- 99 is how unrated charts are stored; the bubbles show it as "??"
        return LEVEL_PREFIX[Category] .. (tonumber(Meter) == 99 and "??" or Meter)
    end
    return SubName
end

function Cards.Image(Category, SubName, BannerPath)
    if Cards.Kind(Category, SubName) ~= "version" then return nil end
    if BannerPath == nil or BannerPath == "" then return nil end
    return BannerPath
end

return Cards
