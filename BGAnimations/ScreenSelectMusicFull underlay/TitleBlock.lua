-- Song title, artist and BPM on a dark band right under the preview strip
-- (Phoenix layout), so the text never covers the video.
local Art = LoadModule("Select.Art.lua")
local BandArt = Art("XSanity/SM-BACKTITLE")
local BandY = 378

local function BpmText(Song)
    if not Song then return "" end
    local Bpms = Song:GetDisplayBpms()
    if Song:IsDisplayBpmRandom() or not Bpms or (Bpms[2] or 0) <= 0 then return "???" end
    local Low, High = math.ceil(Bpms[1]), math.ceil(Bpms[2])
    if Low == High then return tostring(High) end
    return Low .. "-" .. High
end

local t = Def.ActorFrame {
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, BandY):diffusealpha(0) end,
    OnCommand=function(self) self:easeoutexpo(1):diffusealpha(1) end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):diffusealpha(0) end,
    CurrentSongChangedMessageCommand=function(self) self:playcommand("Refresh") end,
    RefreshCommand=function(self)
        local Song = GAMESTATE:GetCurrentSong()
        local ArtistName = Song and Song:GetDisplayArtist() or ""
        self:GetChild("Title"):settext(Song and Song:GetDisplayFullTitle() or "")
        self:GetChild("Artist"):settext(ArtistName)
        self:GetChild("Slash"):settext(ArtistName ~= "" and " / " or "")
        self:GetChild("Bpm"):settext(Song and ("BPM " .. BpmText(Song)) or "")
        -- center "Artist / BPM n" as one line
        local Artist, Slash, Bpm = self:GetChild("Artist"), self:GetChild("Slash"), self:GetChild("Bpm")
        local AW, SW, BW = Artist:GetZoomedWidth(), Slash:GetZoomedWidth(), Bpm:GetZoomedWidth()
        local Total = AW + SW + BW
        Artist:x(-Total / 2 + AW / 2)
        Slash:x(-Total / 2 + AW + SW / 2)
        Bpm:x(-Total / 2 + AW + SW + BW / 2)
    end,
}

if BandArt then
    t[#t+1] = Def.Sprite { Texture=BandArt, InitCommand=function(self) self:zoomto(SCREEN_WIDTH, 70):diffusealpha(0.9) end }
else
    t[#t+1] = Def.Quad { InitCommand=function(self) self:zoomto(SCREEN_WIDTH, 64):diffuse(Color.Black):diffusealpha(0.65):fadeleft(0.15):faderight(0.15) end }
end

t[#t+1] = Def.BitmapText {
    Name="Title",
    Font="Montserrat semibold 40px",
    InitCommand=function(self) self:y(-14):zoom(0.62):maxwidth(1000 / 0.62):shadowlength(1) end,
}
t[#t+1] = Def.BitmapText {
    Name="Artist",
    Font="Montserrat semibold 20px",
    InitCommand=function(self) self:y(15):zoom(0.8):maxwidth(500 / 0.8):diffuse(color("#ffe15a")):shadowlength(1) end,
}
t[#t+1] = Def.BitmapText {
    Name="Slash",
    Font="Montserrat semibold 20px",
    InitCommand=function(self) self:y(15):zoom(0.8):diffuse(Color.White):shadowlength(1) end,
}
t[#t+1] = Def.BitmapText {
    Name="Bpm",
    Font="Montserrat semibold 20px",
    InitCommand=function(self) self:y(15):zoom(0.8):diffuse(color("#46e0ff")):shadowlength(1) end,
}

return t
