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
--   PhoenixCard(Category, SubName) -> base name of the Phoenix channel card for that group
--       (Graphics/Phoenix/Channels/<name>.png, copied locally), or nil when Phoenix has none

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

local VERSION_CARDS = {
    ["01 - 1ST~3RD"] = "C_LOGO1", ["02 - S.E.~EXTRA"] = "C_LOGO2", ["03 - REBIRTH~PREX 3"] = "C_LOGO3",
    ["04 - EXCEED~ZERO"] = "C_LOGO4", ["05 - NX~NX2"] = "C_LOGO5", ["06 - NX ABSOLUTE"] = "C_NXA",
    ["07 - PRO~PRO2"] = "C_PRO", ["08 - FIESTA"] = "C_FIESTA", ["09 - FIESTA EX"] = "C_FIESTAEX",
    ["10 - FIESTA 2"] = "C_FIESTA2", ["11 - INFINITY"] = "C_INFINITY", ["12 - PRIME"] = "C_PR",
    ["13 - PRIME 2"] = "C_PR2", ["14 - XX"] = "C_XX", ["15 - MOBILE EDITION"] = "C_ME", ["16 - PHOENIX"] = "C_PHOENIX",
}
local SPECIAL_CARDS = { ["All Tunes"] = "C_ATUNES", ["Full Song"] = "C_FSONG", ["Shortcut"] = "C_SC", ["Remix"] = "C_RMX", ["Co-op"] = "C_COOP" }

-- Category cards and the Double 1-4 / Half-Double level cards are made locally by
-- tools/make_phoenix_cards.py in the style of the Phoenix channel cards
local CATEGORY_CARDS = {
    ["Group"] = "CAT_VERSIONS", ["Single"] = "CAT_SINGLE", ["Double"] = "CAT_DOUBLE", ["Half-Double"] = "CAT_HALFDOUBLE",
    ["Special"] = "CAT_SPECIAL", ["Title"] = "CAT_TITLE", ["Artist"] = "CAT_ARTIST",
}
local LEVEL_CARDS = {   -- prefix, first level with a card, card for that level and over
    ["Single"] = { "C_LV_%02d", 24, "C_LV_24O" },
    ["Double"] = { "C_DLV_%02d", 26, "C_DLV_26O" },
    ["Half-Double"] = { "C_HDLV_%02d", 26, "C_HDLV_26O" },
}

function Cards.PhoenixCard(Category, SubName)
    local Kind = Cards.Kind(Category, SubName)
    if Kind == "category" then return CATEGORY_CARDS[SubName] end
    if Kind == "version" then return VERSION_CARDS[SubName] end
    if Kind == "special" then return SPECIAL_CARDS[SubName] end
    if Kind == "level" then
        local Meter = tonumber(SubName:match("(%d+)$") or "")
        local Spec = LEVEL_CARDS[Category]
        if not Meter or Meter == 99 or Meter < 1 or not Spec then return nil end
        return Meter >= Spec[2] and Spec[3] or string.format(Spec[1], Meter)
    end
    return nil
end

return Cards
