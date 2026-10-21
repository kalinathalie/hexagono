-- Phoenix-style preview strip across the top of the song select screen: the
-- song's preview video (or its background image) in the middle, with dimmed,
-- mirrored copies on both sides the way Phoenix projects the BGA on its stage.
-- The copies share the middle one's texture and do not decode, so the video is
-- decoded once. The top HUD is drawn over the upper part of the strip.
local StripH = 346
local CenterW = 800
local PreviewDelay = THEME:GetMetric("ScreenSelectMusic", "SampleMusicDelay")
local ImagePreviewOnly = LoadModule("Config.Load.lua")("ImagePreviewOnly", "Save/OutFoxPrefs.ini")
local ChartPreview = LoadModule("Config.Load.lua")("ChartPreview", "Save/OutFoxPrefs.ini")

-- Sprites are not clipped, so "cover" is done by cropping the texture to the
-- target aspect ratio and then sizing the sprite to the target.
local function Cover(self, W, H)
    local Tex = self:GetTexture()
    local tw, th = Tex and Tex:GetSourceWidth() or W, Tex and Tex:GetSourceHeight() or H
    if tw <= 0 or th <= 0 then tw, th = W, H end
    local Want, Have = W / H, tw / th
    if Have < Want then
        local Keep = Have / Want
        self:customtexturerect(0, (1 - Keep) / 2, 1, 1 - (1 - Keep) / 2)
    else
        local Keep = Want / Have
        self:customtexturerect((1 - Keep) / 2, 0, 1 - (1 - Keep) / 2, 1)
    end
    self:zoomto(W, H)
end

-- What to show for the current song: its preview video, else its background, else its banner
local function MediaFor(Song)
    if not Song then return nil end
    local Video = Song:GetPreviewVidPath()
    if Video and Video ~= "" and not ImagePreviewOnly and FILEMAN:DoesFileExist(Video) then return "video", Video end
    if Song:HasBackground() then return "Background", Song:GetBackgroundPath() end
    if Song:HasBanner() then return "Banner", Song:GetBannerPath() end
    return nil
end

local function Copy(Name, X, IsCenter)
    return Def.Sprite {
        Name=Name,
        InitCommand=function(self) self:x(X) end,
        ShowCommand=function(self, params)
            self:stoptweening():diffusealpha(0)
            if not params.Kind then self:Load(nil) return end
            if params.Kind == "video" then
                self:Load(params.Path)
                if not IsCenter then self:SetDecodeMovie(false) end
            else
                self:LoadFromCached(params.Kind, params.Path)
            end
            Cover(self, CenterW, StripH)
            if not IsCenter then self:rotationy(180) end
            self:linear(PreviewDelay):diffusealpha(1)
            if not IsCenter then self:diffuse(color("#4b5568")) end
        end,
    }
end

local t = Def.ActorFrame {
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, StripH / 2):diffusealpha(0) end,
    OnCommand=function(self) self:easeoutexpo(1):diffusealpha(1):queuecommand("Refresh") end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):diffusealpha(0) end,

    CurrentSongChangedMessageCommand=function(self)
        for _, Name in ipairs({ "Center", "Left", "Right" }) do self:GetChild(Name):stoptweening():Load(nil) end
        self:stoptweening():sleep(PreviewDelay):queuecommand("Refresh")
    end,
    RefreshCommand=function(self)
        local Kind, Path = MediaFor(GAMESTATE:GetCurrentSong())
        for _, Name in ipairs({ "Center", "Left", "Right" }) do
            self:GetChild(Name):playcommand("Show", { Kind = Kind, Path = Path })
        end
    end,

    -- Dark stage behind the copies while they load
    Def.Quad { InitCommand=function(self) self:zoomto(SCREEN_WIDTH, StripH):diffuse(color("#05070d")) end },

    Copy("Left", -CenterW, false),
    Copy("Right", CenterW, false),
    Copy("Center", 0, true),

    -- Soft seams between the middle and the side copies
    Def.Quad { InitCommand=function(self) self:x(-CenterW / 2):zoomto(90, StripH):diffuse(Color.Black):diffusealpha(0.7):fadeleft(0.5):faderight(0.5) end },
    Def.Quad { InitCommand=function(self) self:x(CenterW / 2):zoomto(90, StripH):diffuse(Color.Black):diffusealpha(0.7):fadeleft(0.5):faderight(0.5) end },
    -- Fade into the title band at the bottom
    Def.Quad { InitCommand=function(self) self:y(StripH / 2 - 30):zoomto(SCREEN_WIDTH, 60):diffuse(Color.Black):diffusealpha(0.8):fadetop(1) end },
}

-- Chart preview (theme option, WIP in the original theme): notefields over the strip
if ChartPreview then
    t[#t+1] = Def.ActorFrame {
        InitCommand=function(self) self:y(-20):zoom(0.6) end,
        OnCommand=function(self)
            if GAMESTATE:GetCurrentSong() then
                self:AddChildFromPath(THEME:GetPathB("", "NotefieldPreview"))
            end
        end,
    }
end

return t
