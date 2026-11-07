-- Result screen background: theme gradient, dimmed song image (still) and a
-- green band with the song title. Everything shows at once, no tweens.
local R = LoadModule("Eval.Result.lua")

local Song = GAMESTATE:GetCurrentSong()
local Path = Song and Song:GetBackgroundPath()

-- Title strip: the green band of the result video (ScreenEvaluation underlay/GreenBand),
-- between y 105 and 161, fading toward both ends
local STRIP_X = 637.5
local STRIP_W = 975
local STRIP_Y = 133
local STRIP_H = 56

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

Frame[#Frame + 1] = Def.ActorFrame {
    InitCommand=function(self) self:xy(STRIP_X, STRIP_Y) end,
    LoadActor("ScreenEvaluation underlay/GreenBand", { Width = STRIP_W, Height = STRIP_H }),
}

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
