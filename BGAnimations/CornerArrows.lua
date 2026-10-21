-- Corner arrows in the Phoenix layout: red BACK arrows at the top corners (they
-- open the group wheel), blue SHIFT arrows at the bottom corners (they move the
-- wheel). With the local Phoenix art (Graphics/Phoenix) the arrows are the
-- animated Phoenix ones with their glow; otherwise the InfiniteWorlds arrows
-- (Graphics/CornerArrows/red.lua and blue.lua) are used. The slide-in runs on
-- the outer frame and the pulse on an inner frame, so a pulse never interrupts
-- the slide.
local Art = LoadModule("Select.Art.lua")
local Phoenix = {
    Up = Art("Phoenix/UpLeft 4x2"), Down = Art("Phoenix/DownLeft 4x2"),
    GlowUp = { Left = Art("Phoenix/left_pink"), Right = Art("Phoenix/right_pink") },
    GlowDown = { Left = Art("Phoenix/left_blue"), Right = Art("Phoenix/right_blue") },
}
local UsePhoenix = Phoenix.Up and Phoenix.Down

-- distance of each arrow's center from the two screen edges: the art touches the corner
local Edge = UsePhoenix and 67 or 44

local function ArrowArt(IsTop, IsRight)
    if UsePhoenix then
        local Glow = (IsTop and Phoenix.GlowUp or Phoenix.GlowDown)[IsRight and "Right" or "Left"]
        return Def.ActorFrame {
            Glow and Def.Sprite { Texture=Glow, InitCommand=function(self) self:y(IsTop and -6 or 6):blend("BlendMode_Add") end } or Def.Actor {},
            Def.Sprite {
                Texture=IsTop and Phoenix.Up or Phoenix.Down,
                InitCommand=function(self) self:zoom(0.67):rotationy(IsRight and 180 or 0) end,
            },
        }
    end
    -- InfiniteWorlds art points down: rotate it toward its own corner
    local Rotation = IsTop and (IsRight and -135 or 135) or (IsRight and -45 or 45)
    return Def.ActorFrame {
        InitCommand=function(self) self:zoom(0.5):rotationz(Rotation) end,
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
