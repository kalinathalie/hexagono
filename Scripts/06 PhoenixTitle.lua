-- Phoenix title video (local art, never in the public repo):
-- Graphics/Phoenix/Title/intro.mp4 + intro.ogg play once (warning, logos,
-- trailer), then loop.mp4 and loop.ogg repeat while waiting for players.
-- info.ini holds the lengths:  IntroVideo=<s>  IntroAudio=<s>  LoopAudio=<s>
--
-- PhoenixTitleVideo() -> { Intro, Loop, IntroAudio, LoopAudio, IntroVideoLength,
--                          IntroAudioLength, LoopAudioLength } or nil
-- PhoenixTitleSeen: true once the trailer has played (later visits start at the loop).

local Cached

function PhoenixTitleVideo()
    if Cached ~= nil then return Cached or nil end
    Cached = false
    local Dir = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/Phoenix/Title/"
    for _, File in ipairs({ "intro.mp4", "loop.mp4", "intro.ogg", "loop.ogg", "info.ini" }) do
        if not FILEMAN:DoesFileExist(Dir .. File) then return nil end
    end
    local Text = lua.ReadFile(Dir .. "info.ini") or ""
    local function Number(Key) return tonumber(Text:match(Key .. "%s*=%s*([%d%.]+)")) end
    local IntroVideo, IntroAudio, LoopAudio = Number("IntroVideo"), Number("IntroAudio"), Number("LoopAudio")
    if not (IntroVideo and IntroAudio and LoopAudio) then return nil end
    Cached = {
        Intro = Dir .. "intro.mp4", Loop = Dir .. "loop.mp4",
        IntroAudio = Dir .. "intro.ogg", LoopAudio = Dir .. "loop.ogg",
        IntroVideoLength = IntroVideo, IntroAudioLength = IntroAudio, LoopAudioLength = LoopAudio,
    }
    return Cached
end

PhoenixTitleSeen = PhoenixTitleSeen or false
