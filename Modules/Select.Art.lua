-- Select.Art: optional art for the select screens, copied locally into the theme
-- and never published (Graphics/Phoenix: Phoenix 2024 graphics; Graphics/XSanity:
-- XSanity graphics; both folders are git-ignored). Callers always keep a fallback.
--
--   Art("Phoenix/fullbar balls 7x1") -> full path of Graphics/Phoenix/fullbar balls 7x1.png,
--   or nil when the file is missing. The full path avoids theme name lookups, where
--   "R_S" would also match "R_SS".
local Dir = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/"

return function(Name)
    local Path = Dir .. Name .. ".png"
    if FILEMAN:DoesFileExist(Path) then return Path end
    return nil
end
