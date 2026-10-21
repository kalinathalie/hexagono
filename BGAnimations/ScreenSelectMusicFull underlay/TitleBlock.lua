-- Song title, artist and BPM under the preview (Phoenix layout).
local function BpmText(Song)
    if not Song then return "" end
    if Song:IsDisplayBpmRandom() then return "???" end
    local Bpms = Song:GetDisplayBpms()
    local Low, High = math.ceil(Bpms[1]), math.ceil(Bpms[2])
    if Low == High then return tostring(High) end
    return Low .. "-" .. High
end

return Def.ActorFrame {
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, 352):diffusealpha(0) end,
    OnCommand=function(self) self:easeoutexpo(1):diffusealpha(1) end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):diffusealpha(0) end,
    CurrentSongChangedMessageCommand=function(self) self:playcommand("Refresh") end,
    RefreshCommand=function(self)
        local Song = GAMESTATE:GetCurrentSong()
        self:GetChild("Title"):settext(Song and Song:GetDisplayFullTitle() or "")
        self:GetChild("Artist"):settext(Song and Song:GetDisplayArtist() or "")
        self:GetChild("Bpm"):settext(Song and ("BPM " .. BpmText(Song)) or "")
        -- center "Artist / BPM n" as one line
        local Artist, Slash, Bpm = self:GetChild("Artist"), self:GetChild("Slash"), self:GetChild("Bpm")
        local AW, SW, BW = Artist:GetZoomedWidth(), Slash:GetZoomedWidth(), Bpm:GetZoomedWidth()
        local Total = AW + SW + BW
        Artist:x(-Total / 2 + AW / 2)
        Slash:x(-Total / 2 + AW + SW / 2)
        Bpm:x(-Total / 2 + AW + SW + BW / 2)
    end,

    Def.BitmapText {
        Name="Title",
        Font="Montserrat semibold 40px",
        InitCommand=function(self) self:zoom(0.7):maxwidth(900 / 0.7):shadowlength(1) end,
    },
    Def.BitmapText {
        Name="Artist",
        Font="Montserrat semibold 20px",
        InitCommand=function(self) self:y(26):zoom(0.8):maxwidth(500 / 0.8):diffuse(color("#3cff5c")):shadowlength(1) end,
    },
    Def.BitmapText {
        Name="Slash",
        Font="Montserrat semibold 20px",
        Text=" / ",
        InitCommand=function(self) self:y(26):zoom(0.8):diffuse(Color.White):shadowlength(1) end,
    },
    Def.BitmapText {
        Name="Bpm",
        Font="Montserrat semibold 20px",
        InitCommand=function(self) self:y(26):zoom(0.8):diffuse(color("#46e0ff")):shadowlength(1) end,
    },
}
