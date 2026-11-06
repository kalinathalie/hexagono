-- Result screen background: theme gradient, dimmed song image (still) and a
-- green neon strip with the song title. Everything shows at once, no tweens.
local R = LoadModule("Eval.Result.lua")

local Song = GAMESTATE:GetCurrentSong()
local Path = Song and Song:GetBackgroundPath()

-- Title strip: the dark band is centered at y 133.5; the neon lines sit at its edges
local STRIP_X = 637.5
local STRIP_W = 975
local STRIP_Y = 133.5
local STRIP_H = 53
local LINE_YS = { 107, 160 }

-- Neon line: wide additive glow under a bright core, both ends fade out
local function NeonLine(Y)
    return Def.ActorFrame {
        Def.Quad {
            InitCommand=function(self)
                self:xy(STRIP_X, Y):zoomto(STRIP_W, 14)
                :diffuse(color("#3cff5c")):diffusealpha(0.35)
                :blend("BlendMode_Add"):fadeleft(0.15):faderight(0.15)
            end
        },
        Def.Quad {
            InitCommand=function(self)
                self:xy(STRIP_X, Y):zoomto(STRIP_W, 3)
                :diffuse(color("#5dff6e")):fadeleft(0.15):faderight(0.15)
            end
        }
    }
end

local Frame = Def.ActorFrame {
    Def.Sprite {
        Texture=THEME:GetPathG("", "Gradient background"),
        InitCommand=function(self)
            self:Center():scaletocover(0, 0, SCREEN_RIGHT, SCREEN_BOTTOM)
        end
    }
}

-- Song image: still and dimmed, only for image files that exist
if R.IsImage(Path) and FILEMAN:DoesFileExist(Path) then
    Frame[#Frame + 1] = Def.Sprite {
        InitCommand=function(self)
            self:Load(Path):scale_or_crop_background():diffuse(color("0.45,0.45,0.45,1"))
        end
    }
end

-- Dark translucent band between the two neon lines
Frame[#Frame + 1] = Def.Quad {
    InitCommand=function(self)
        self:xy(STRIP_X, STRIP_Y):zoomto(STRIP_W, STRIP_H)
        :diffuse(color("#000000")):diffusealpha(0.35)
        :fadeleft(0.15):faderight(0.15)
    end
}

for _, Y in ipairs(LINE_YS) do
    Frame[#Frame + 1] = NeonLine(Y)
end

-- Song title, centered in the strip (no song: no title)
if Song then
    Frame[#Frame + 1] = Def.BitmapText {
        Font="Montserrat semibold 40px",
        Text=PREFSMAN:GetPreference("ShowNativeLanguage") and Song:GetDisplayFullTitle() or Song:GetTranslitFullTitle(),
        InitCommand=function(self)
            self:xy(640, 133):zoom(0.6):maxwidth(900 / 0.6):diffuse(color("#ffffff")):shadowlength(1)
        end
    }
end

return Frame
