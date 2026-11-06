-- Result screen music: Phoenix's RESULT_BGM (a short loop) when the kit downloaded
-- it (pi/assets/phyrebird.py), otherwise the theme's own evaluation loop.
local Bgm = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/Phoenix/Evaluation/RESULT_BGM (loop).wav"
if FILEMAN:DoesFileExist(Bgm) then
    return Bgm
end
return THEME:GetPathS("", "MenuMusic/Evaluation")
