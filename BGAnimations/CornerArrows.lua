-- Corner arrows in the Phoenix layout: red BACK arrows at the top corners (they
-- open the group wheel), blue SHIFT arrows at the bottom corners (they move the
-- wheel). The art comes from InfiniteWorlds (Graphics/CornerArrows/red.lua and
-- blue.lua: masked, continuously animated glow). The arrow art points down, so
-- each corner rotates it toward its own corner. The slide-in runs on the outer
-- frame and the pulse on an inner frame, so a pulse never interrupts the slide.
local function Arrow(Lua, X, Y, Rotation, Name)
    local OffX = X + (X < SCREEN_CENTER_X and -144 or 144)
    local OffY = Y + (Y < SCREEN_CENTER_Y and -144 or 144)
    return Def.ActorFrame {
        Name=Name,
        InitCommand=function(self) self:xy(OffX, OffY) end,
        OnCommand=function(self) self:easeoutexpo(1):xy(X, Y) end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(1):xy(OffX, OffY) end,

        Def.ActorFrame {
            Name="Pulse",
            InitCommand=function(self) self:zoom(0.5):rotationz(Rotation) end,
            PulseCommand=function(self) self:stoptweening():zoom(0.56):linear(0.25):zoom(0.5) end,
            LoadActor(THEME:GetPathG("", "CornerArrows/" .. Lua)),
        },
    }
end

return Def.ActorFrame {
    Arrow("red", 72, 72, 135, "BackLeft") .. {
        SongUnchosenMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
        OpenGroupWheelMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
    },
    Arrow("red", SCREEN_RIGHT - 72, 72, -135, "BackRight") .. {
        SongUnchosenMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
        OpenGroupWheelMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
    },
    Arrow("blue", 72, SCREEN_BOTTOM - 72, 45, "ShiftLeft") .. {
        ScrollMessageCommand=function(self, params) if params.Direction == -1 then self:GetChild("Pulse"):playcommand("Pulse") end end,
    },
    Arrow("blue", SCREEN_RIGHT - 72, SCREEN_BOTTOM - 72, -45, "ShiftRight") .. {
        ScrollMessageCommand=function(self, params) if params.Direction == 1 then self:GetChild("Pulse"):playcommand("Pulse") end end,
    },
}
