-- The Phoenix title video covers the whole screen: no animated background behind it
if PhoenixTitleVideo and PhoenixTitleVideo() then return Def.ActorFrame {} end
return LoadActor(THEME:GetPathB("", "AnimatedBackground"))
