-- Song preview strip at the top of the song select screen (Phoenix layout):
-- the preview video cropped to a wide frame; without a video, the song
-- background (from the image cache), then the banner.
local FrameW, FrameH = 794, 274
local PreviewDelay = THEME:GetMetric("ScreenSelectMusic", "SampleMusicDelay")
local ImagePreviewOnly = LoadModule("Config.Load.lua")("ImagePreviewOnly", "Save/OutFoxPrefs.ini")

local t = Def.ActorFrame {
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, -FrameH) end,
    OnCommand=function(self) self:easeoutexpo(1):y(66 + FrameH / 2) end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(1):y(-FrameH) end,

    -- Dark backing so the frame never shows the background while a video loads
    Def.Quad { InitCommand=function(self) self:zoomto(FrameW, FrameH):diffuse(color("#05070d")) end },

    Def.Sprite {
        Name="Media",
        InitCommand=function(self) self:Load(nil):queuecommand("Refresh") end,
        CurrentSongChangedMessageCommand=function(self) self:Load(nil):queuecommand("Refresh") end,
        RefreshCommand=function(self)
            self:stoptweening():diffusealpha(0):sleep(PreviewDelay)
            local Song = GAMESTATE:GetCurrentSong()
            if not Song then return end
            if Song:GetPreviewVidPath() == nil or ImagePreviewOnly then
                self:queuecommand("LoadBG")
            else
                self:queuecommand("LoadAnimated")
            end
        end,
        LoadBGCommand=function(self)
            local Song = GAMESTATE:GetCurrentSong()
            if not Song then return end
            if Song:HasBackground() then
                self:LoadFromCached("Background", Song:GetBackgroundPath())
            elseif Song:HasBanner() then
                self:LoadFromCached("Banner", Song:GetBannerPath())
            else
                self:Load(nil)
                return
            end
            self:scaletocover(-FrameW / 2, -FrameH / 2, FrameW / 2, FrameH / 2):linear(PreviewDelay):diffusealpha(1)
        end,
        LoadAnimatedCommand=function(self)
            local Song = GAMESTATE:GetCurrentSong()
            local Path = Song and Song:GetPreviewVidPath()
            if Path and Path ~= "" then
                self:Load(Path):scaletocover(-FrameW / 2, -FrameH / 2, FrameW / 2, FrameH / 2)
                :linear(PreviewDelay):diffusealpha(1)
            else
                self:queuecommand("LoadBG")
            end
        end,
    },

    -- Thin frame
    Def.Quad { InitCommand=function(self) self:zoomto(FrameW + 4, 2):y(-FrameH / 2 - 1):diffuse(color("#3a4a6a")) end },
    Def.Quad { InitCommand=function(self) self:zoomto(FrameW + 4, 2):y(FrameH / 2 + 1):diffuse(color("#3a4a6a")) end },
    Def.Quad { InitCommand=function(self) self:zoomto(2, FrameH + 4):x(-FrameW / 2 - 1):diffuse(color("#3a4a6a")) end },
    Def.Quad { InitCommand=function(self) self:zoomto(2, FrameH + 4):x(FrameW / 2 + 1):diffuse(color("#3a4a6a")) end },
}

return t
