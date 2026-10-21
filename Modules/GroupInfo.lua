-- GroupInfo: the one-line description shown under the group cards.
-- Pure Lua; strings come through Text(key) (THEME:GetString("GroupInfo", key)
-- in the theme, which returns "" for a missing key).
--
-- Keys looked up, in order:
--   "Group_<folder>"      version groups ("Group_14 - XX")
--   "Level_<sub>"         level groups   ("Level_Single 17")
--   "Special_<name>"      special groups ("Special_Co-op")
--   "Letter"              title/artist letters
--   "Category_<name>"     category cards ("Category_Double")
-- Fallbacks: "Fallback_Version" with the version name, "Fallback_Level" with the
-- level name in upper case, otherwise the subgroup name itself.

return function(Text)
    local Info = {}

    local function Str(key)
        local s = Text(key)
        if s == nil or s == "" then return nil end
        return s
    end

    function Info.Describe(Category, SubName)
        if Category == nil then
            return Str("Category_" .. SubName) or SubName
        elseif Category == "Group" then
            local Name = (SubName:gsub("^%d+%s*%-%s*", ""))
            return Str("Group_" .. SubName) or string.format(Str("Fallback_Version") or "%s", Name)
        elseif Category == "Single" or Category == "Double" or Category == "Half-Double" then
            return Str("Level_" .. SubName) or string.format(Str("Fallback_Level") or "%s", string.upper(SubName))
        elseif Category == "Title" or Category == "Artist" then
            return Str("Letter") or SubName
        end
        return Str("Special_" .. SubName) or SubName
    end

    return Info
end
