local t = Def.ActorFrame {}

-- one hidden note per noteskin, for the noteskin icon; the co-op copies never show there
for _,v in pairs(LoadModule("Gameplay.Coop.lua").Choosable(NOTESKIN:GetNoteSkinNames())) do
    t[#t+1] = NOTESKIN:LoadActorForNoteSkin("UpRight", "Tap Note", v)..{
        Name="NS"..string.lower(v), InitCommand=function(s) s:visible(false) end,
    }
end

return t
