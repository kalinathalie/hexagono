-- Static background for every menu screen: dark radial gradient, a faint grid
-- and two slow glow bands. Five small textures, no video, cheap on the Pi GPU.
local t = Def.ActorFrame {}

t[#t+1] = Def.Quad {
    Name="Solid",
    InitCommand=function(self) self:Center():zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(color("#05070d")) end
}

t[#t+1] = Def.Sprite {
    Name="Gradient",
    Texture=THEME:GetPathG("", "Select/gradient_bg"),
    InitCommand=function(self) self:Center():scaletocover(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) end
}

-- Glow bands drifting in opposite directions (a full-screen grid layer was measured
-- at ~0.4 ms per frame on the Pi 5 and dropped)
for i, Band in ipairs({ { Texture = "Background/Squiggles/1 (stretch)", Y = -120, Speed = 0.05 },
                        { Texture = "Background/Squiggles/3 (stretch)", Y = 120, Speed = -0.03 } }) do
    t[#t+1] = Def.Sprite {
        Name="Band" .. i,
        Texture=THEME:GetPathG("", Band.Texture),
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y + Band.Y)
            :zoomto(SCREEN_WIDTH, 200)
            :diffuse(color("#3c8cff")):diffusealpha(0.12)
            :texcoordvelocity(Band.Speed, 0)
        end
    }
end

return t
