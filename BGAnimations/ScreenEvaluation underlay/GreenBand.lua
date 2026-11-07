-- Phoenix 2 green band of the result screen (the title strip and each table row), the
-- way the LBPIU scoreboard draws it in CSS, with the vertical profile measured on the
-- result video: bright green edges, faint at a third of the height, brighter again
-- toward the bottom; fading out toward both ends (clear at the ends, full at the center).
--   LoadActor("GreenBand", { Width = 540, Height = 24 })   centered on the actor
local Args = ... or {}
local W, H = Args.Width or 540, Args.Height or 24

local Edge = { 64 / 255, 1, 48 / 255 }
local Fill = { 32 / 255, 1, 32 / 255 }
local function C(Rgb, A) return { Rgb[1], Rgb[2], Rgb[3], A } end
local Stops = {
    { At = 0.0, Color = C(Edge, 0.95) },
    { At = 0.15, Color = C(Fill, 0.45) },
    { At = 0.4, Color = C(Fill, 0.25) },
    { At = 0.8, Color = C(Fill, 0.5) },
    { At = 1.0, Color = C(Edge, 0.95) },
}

local Band = Def.ActorFrame {}
for i = 1, #Stops - 1 do
    local Top, Bottom = Stops[i], Stops[i + 1]
    local Y0, Y1 = -H / 2 + H * Top.At, -H / 2 + H * Bottom.At
    Band[#Band + 1] = Def.Quad {
        InitCommand = function(self)
            self:y((Y0 + Y1) / 2):zoomto(W, Y1 - Y0)
                :diffusetopedge(Top.Color):diffusebottomedge(Bottom.Color)
                :fadeleft(0.5):faderight(0.5)
        end,
    }
end
return Band
