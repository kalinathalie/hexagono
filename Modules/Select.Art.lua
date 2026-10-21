-- Select.Art: XSanity graphics the select screens use when they are present in
-- Graphics/XSanity (copied locally from the user's XSanity install; that folder
-- is git-ignored and never published). Callers always keep a fallback.
--
--   Art(Name) -> THEME path of Graphics/XSanity/<Name>.png, or nil when missing
local Dir = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/XSanity/"

return function(Name)
    if FILEMAN:DoesFileExist(Dir .. Name .. ".png") then
        return THEME:GetPathG("", "XSanity/" .. Name)
    end
    return nil
end
