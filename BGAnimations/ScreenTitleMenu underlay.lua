-- Title screen, arcade style: the Phoenix title video (when the local art is
-- present, see Scripts/06 PhoenixTitle.lua) or the logo, and a PRESS CENTER
-- STEP prompt per side. The center panel joins a player and a second press
-- starts the game; red left, red right, blue left, blue right, twice, opens
-- the operator options (Modules/Title.Input.lua). The menu buttons of the
-- original theme are gone (ShowScroller=false in metrics.ini).
--
-- The video: intro.mp4 + intro.ogg play once (warning, logos, trailer), then
-- loop.mp4 + loop.ogg repeat forever. The loop movie is loaded at start with
-- decoding paused on its first frame and switched on when the intro ends, so
-- the cut is seamless; the engine repeats a movie by itself. Later visits to
-- the title start directly at the loop.
local Art = LoadModule("Select.Art.lua")
local TitleInput = LoadModule("Title.Input.lua")
local Video = PhoenixTitleVideo and PhoenixTitleVideo() or nil
local PhoenixLogo = Art("Phoenix/Logo/PhoenixLogo")
local K = PhoenixLogo and 1.175 or 1

local State = TitleInput.New()
local Leaving = false
local Swallow = false   -- set by the Pad command: true when the pad press was used here
local function Swallowed() return Swallow end
local IsTitle = false   -- the underlay is shared with ScreenLogo (attract, coin mode): no joining there

local Root   -- the underlay frame, for commands from the input callback

local function Screen() return SCREENMAN:GetTopScreen() end

local function StartLoopAudio()
    SOUND:PlayMusicPart(Video.LoopAudio, 0, Video.LoopAudioLength, 0, 0, true, false, false)
end

local t = Def.ActorFrame {
    OnCommand=function(self)
        -- Reset machine profile mods
        ResetLuaMods(PLAYER_1)
        ResetLuaMods(PLAYER_2)

        GAMESTATE:UpdateDiscordGameMode(GAMESTATE:GetCurrentGame():GetName())
        GAMESTATE:UpdateDiscordScreenInfo("Title Menu", "", 1)

        IsTitle = Screen():GetName() ~= "ScreenLogo"
        if IsTitle then
            -- fresh game state, nobody joined (the engine's ScreenTitleMenu class did this)
            GAMESTATE:Reset()
            Root = self
            Screen():AddInputCallback(function(event) return Root and Root:GetChild("Input"):playcommand("Pad", event) and Swallowed() end)
        end
        self:playcommand("Refresh")
    end,
    OffCommand=function(self) Leaving = true end,

    -- Pad input (the callback swallows every pad press, so the hidden menu never acts)
    Def.Actor {
        Name="Input",
        PadCommand=function(self, event)
            Swallow = false
            local pn = event.PlayerNumber
            if not pn or Leaving then return end
            -- OutFox: event.button is the pad panel (UpLeft, Center...), event.GameButton the menu button (MenuUp, Start...)
            local Button = event.button or event.GameButton
            if Button == "Back" or event.GameButton == "Back" then return end   -- keyboard Esc stays with the engine
            Swallow = true
            if event.type ~= "InputEventType_FirstPress" then return end
            local Action = TitleInput.Press(State, pn, Button, GetTimeSinceStart())
            if Action == "join" then
                GAMESTATE:JoinPlayer(pn)
                MESSAGEMAN:Broadcast("TitleJoined", { Player = pn })
                Root:playcommand("Refresh")
                if Video then Root:GetChild("Video"):playcommand("SkipIntro") end
            elseif Action == "start" then
                Leaving = true
                MESSAGEMAN:Broadcast("TitleStart")
                GAMESTATE:ApplyGameCommand("applydefaultoptions")
                self:sleep(0.6):queuecommand("GoStart")
            elseif Action == "options" then
                Leaving = true
                MESSAGEMAN:Broadcast("TitleOptions")
                self:sleep(0.3):queuecommand("GoOptions")
            end
        end,
        GoStartCommand=function(self) PhoenixTitleSeen = true SCREENMAN:SetNewScreen(CustomBranch.StartGame()) end,
        GoOptionsCommand=function(self) PhoenixTitleSeen = true SCREENMAN:SetNewScreen("ScreenOptionsService") end,
    },

    Def.Sound { File=THEME:GetPathS("Common", "Start"), IsAction=true, TitleJoinedMessageCommand=function(self) self:play() end, TitleStartMessageCommand=function(self) self:play() end },
    Def.Sound { File=THEME:GetPathS("Common", "value"), IsAction=true, TitleOptionsMessageCommand=function(self) self:play() end },
}

if Video then
    t[#t+1] = Def.ActorFrame {
        Name="Video",
        OnCommand=function(self)
            local Intro, Loop = self:GetChild("Intro"), self:GetChild("Loop")
            if PhoenixTitleSeen then
                self:playcommand("ToLoop")
                StartLoopAudio()
            else
                Intro:visible(true):SetDecodeMovie(true)
                SOUND:PlayMusicPart(Video.IntroAudio, 0, Video.IntroAudioLength, 0, 0, false, false, false)
                self:GetChild("AudioTimer"):sleep(Video.IntroAudioLength):queuecommand("Fire")
                self:GetChild("VideoTimer"):sleep(Video.IntroVideoLength):queuecommand("Fire")
            end
        end,
        -- a player joined during the trailer: go straight to the title loop
        SkipIntroCommand=function(self)
            if PhoenixTitleSeen then return end
            self:GetChild("AudioTimer"):stoptweening()
            self:GetChild("VideoTimer"):stoptweening()
            self:playcommand("ToLoop")
            StartLoopAudio()
        end,
        ToLoopCommand=function(self)
            PhoenixTitleSeen = true
            local Intro, Loop = self:GetChild("Intro"), self:GetChild("Loop")
            Loop:visible(true):SetDecodeMovie(true)
            Intro:visible(false):SetDecodeMovie(false)
            Intro:queuecommand("Unload")
        end,

        Def.Actor { Name="AudioTimer", FireCommand=function(self) StartLoopAudio() end },
        Def.Actor { Name="VideoTimer", FireCommand=function(self) self:GetParent():playcommand("ToLoop") end },

        Def.Sprite {
            Name="Loop", Texture=Video.Loop,
            InitCommand=function(self) self:SetDecodeMovie(false):visible(false):Center():zoomto(SCREEN_WIDTH, SCREEN_HEIGHT) end,
        },
        Def.Sprite {
            Name="Intro",
            InitCommand=function(self)
                if PhoenixTitleSeen then self:visible(false) return end
                self:Load(Video.Intro):SetDecodeMovie(false):visible(false):Center():zoomto(SCREEN_WIDTH, SCREEN_HEIGHT)
            end,
            UnloadCommand=function(self) self:Load(nil) end,
        },
    }
else
    -- No video: the logo (Phoenix 2 when the local art is there, else Infinitesimal)
    t[#t+1] = Def.ActorFrame {
        OnCommand=function(self)
            self:xy(SCREEN_CENTER_X, SCREENMAN:GetTopScreen():GetName() == "ScreenLogo" and SCREEN_CENTER_Y or SCREEN_CENTER_Y - 20)
            :queuecommand("ZoomY")
        end,

        OffCommand=function(self)
            self:stoptweening()
            :easeoutexpo(0.5)
            :zoom(1.5):diffusealpha(0)
        end,

        ZoomYCommand=function(self)
            self:accelerate(3.4288)
            :zoom(0.96)
            :decelerate(3.4288)
            :zoom(1)
            :queuecommand("ZoomY")
        end,

        PhoenixLogo and Def.Sprite {
            Texture=PhoenixLogo,
            InitCommand=function(self) self:zoom(0.8 * K) end
        } or LoadActor(THEME:GetPathG("", "Logo/Parts"))..{
            InitCommand=function(self)
                self:zoom(0.8)
            end
        },

        Def.Sprite {
            Texture=PhoenixLogo or THEME:GetPathG("", "Logo/Logo"),
            OnCommand=function(self)
                if PhoenixLogo then self:blend("BlendMode_Add") end
                self:diffusealpha(0)
                :zoom(0.8 * K)
                :queuecommand("Pulse")
            end,
            PulseCommand=function(self)
                self:sleep(3.4288)
                :diffusealpha(0.5)
                :zoom(0.8 * K)
                :decelerate(1.7144)
                :zoom(1 * K)
                :diffusealpha(0)
                :sleep(1.7144)
                :queuecommand("Pulse")
            end,
        },

        Def.Sprite {
            Texture=PhoenixLogo or THEME:GetPathG("", "Logo/BlurLogo"),
            OnCommand=function(self)
                if PhoenixLogo then self:blend("BlendMode_Add") end
                self:zoom(0.83 * K)
                :diffusealpha(0)
                :queuecommand("Flash")
            end,
            FlashCommand=function(self)
                self:accelerate(3.4288)
                :diffusealpha(PhoenixLogo and 0.35 or 0.8)
                :decelerate(3.4288)
                :diffusealpha(0)
                :queuecommand("Flash")
            end,
            OffCommand=function(self)
                self:stoptweening()
                :diffusealpha(1)
                :easeoutexpo(1)
                :zoom(2):diffusealpha(0)
            end,
        }
    }
end

-- PRESS CENTER STEP per side; once a player joined, the READY stamp over a
-- pulsing center step: one more press starts the game
local function Side(pn)
    local Tag = ToEnumShortString(pn)
    local X = SCREEN_CENTER_X + (pn == PLAYER_1 and -1 or 1) * SCREEN_WIDTH * 0.3
    local ReadyArt = Art("Phoenix/READY_" .. Tag)
    local Frame = Def.ActorFrame {
        Name="Side" .. Tag,
        InitCommand=function(self) self:xy(X, SCREEN_HEIGHT * 0.75):visible(false) end,
        RefreshCommand=function(self)
            local Joined = GAMESTATE:IsSideJoined(pn)
            self:visible(IsTitle)
            self:GetChild("Prompt"):GetChild("Press"):visible(not Joined)
            self:GetChild("Ready"):visible(Joined)
        end,
        TitleJoinedMessageCommand=function(self, params)
            if params.Player == pn then self:stoptweening():zoom(1.2):easeoutexpo(0.3):zoom(1) end
        end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(0.25):zoom(2):diffusealpha(0) end,

        LoadActor(THEME:GetPathG("", "PressCenterStep")) .. { Name="Prompt" },
    }
    if ReadyArt then
        Frame[#Frame + 1] = Def.Sprite { Name="Ready", Texture=ReadyArt, InitCommand=function(self) self:y(-10):zoom(0.7):visible(false) end }
    else
        Frame[#Frame + 1] = Def.BitmapText {
            Name="Ready", Font="Montserrat extrabold 40px", Text="READY",
            InitCommand=function(self) self:y(-10):diffuse(color("#ffe600")):shadowlength(2):visible(false) end,
        }
    end
    return Frame
end

t[#t+1] = Side(PLAYER_1)
t[#t+1] = Side(PLAYER_2)

return t
