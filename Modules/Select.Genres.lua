-- Select.Genres: songs grouped by their #GENRE, for the genre category of the group
-- select screen. Pure Lua.
--
--   Name(raw) -> genre in upper case without surrounding spaces, nil when empty
--   Group(songs, GetGenre, IsVariant) -> { { Name, Songs }, ... }: the Phoenix channels
--       first (ORIGINAL, K-POP, WORLD MUSIC, J-MUSIC, XROSS), then any other genre A-Z;
--       GetGenre(song) returns the raw genre (Song:GetGenre() in the theme). Songs for
--       which IsVariant(song) is true (Short Cut, Remix, Full Song) are left out: on
--       the arcade those have their own channels.

local Genres = {}

local PHOENIX_ORDER = { "ORIGINAL", "K-POP", "WORLD MUSIC", "J-MUSIC", "XROSS" }

function Genres.Name(Raw)
    local Name = string.upper((tostring(Raw or ""):gsub("^%s+", ""):gsub("%s+$", "")))
    if Name == "" then return nil end
    return Name
end

function Genres.Group(Songs, GetGenre, IsVariant)
    local ByName, Others = {}, {}
    for _, Song in ipairs(Songs) do
        local Name = not (IsVariant and IsVariant(Song)) and Genres.Name(GetGenre(Song))
        if Name then
            if not ByName[Name] then ByName[Name] = {} end
            table.insert(ByName[Name], Song)
        end
    end
    local Out, Known = {}, {}
    for _, Name in ipairs(PHOENIX_ORDER) do
        Known[Name] = true
        if ByName[Name] then Out[#Out + 1] = { Name = Name, Songs = ByName[Name] } end
    end
    for Name in pairs(ByName) do
        if not Known[Name] then Others[#Others + 1] = Name end
    end
    table.sort(Others)
    for _, Name in ipairs(Others) do Out[#Out + 1] = { Name = Name, Songs = ByName[Name] } end
    return Out
end

return Genres
