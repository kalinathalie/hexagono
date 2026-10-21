-- Corner arrows in the Phoenix layout: red BACK arrows at the top corners (they
-- open the group wheel), blue SHIFT arrows at the bottom corners (they move the
-- wheel). The art is the InfiniteWorlds arrows (Graphics/CornerArrows/red.lua
-- and blue.lua), the same flat chevrons with the BACK/SHIFT label that Phoenix
-- shows. The slide-in runs on the outer frame and the pulse on an inner frame,
-- so a pulse never interrupts the slide.
local Zoom = 0.55
-- Rotated toward its corner, the art reaches 73.5 px (at zoom 1) from its
-- center toward the corner and about 117 px the other way. With the center
-- 44 px from both edges the tip sits about 4 px from the corner, like Phoenix,
-- and the arrow ends near x 109, clear of the player bars that start at x 148.
local Edge = 44

local function ArrowArt(IsTop, IsRight)
    -- InfiniteWorlds art points down: rotate it toward its own corner
    local Rotation = IsTop and (IsRight and -135 or 135) or (IsRight and -45 or 45)
    return Def.ActorFrame {
        InitCommand=function(self) self:zoom(Zoom):rotationz(Rotation) end,
        LoadActor(THEME:GetPathG("", "CornerArrows/" .. (IsTop and "red" or "blue"))),
    }
end

local function Arrow(Name, IsTop, IsRight)
    local X = IsRight and (SCREEN_RIGHT - Edge) or Edge
    local Y = IsTop and Edge or (SCREEN_BOTTOM - Edge)
    local OffX = X + (IsRight and 144 or -144)
    local OffY = Y + (IsTop and -144 or 144)
    return Def.ActorFrame {
        Name=Name,
        InitCommand=function(self) self:xy(OffX, OffY) end,
        OnCommand=function(self) self:easeoutexpo(1):xy(X, Y) end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(1):xy(OffX, OffY) end,

        Def.ActorFrame {
            Name="Pulse",
            PulseCommand=function(self) self:stoptweening():zoom(1.12):linear(0.25):zoom(1) end,
            ArrowArt(IsTop, IsRight),
        },
    }
end

return Def.ActorFrame {
    Arrow("BackLeft", true, false) .. {
        SongUnchosenMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
        OpenGroupWheelMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
    },
    Arrow("BackRight", true, true) .. {
        SongUnchosenMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
        OpenGroupWheelMessageCommand=function(self) self:GetChild("Pulse"):playcommand("Pulse") end,
    },
    Arrow("ShiftLeft", false, false) .. {
        ScrollMessageCommand=function(self, params) if params.Direction == -1 then self:GetChild("Pulse"):playcommand("Pulse") end end,
    },
    Arrow("ShiftRight", false, true) .. {
        ScrollMessageCommand=function(self, params) if params.Direction == 1 then self:GetChild("Pulse"):playcommand("Pulse") end end,
    },
}
