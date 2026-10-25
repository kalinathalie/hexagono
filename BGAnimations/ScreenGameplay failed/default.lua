-- Stage break (40 misses in a row): the Phoenix 2 "HEY! WHY DON'T YOU JUST GET UP AND
-- DANCE MAN?" animation when its local video exists (pi/assets/stagebreak.py), else the
-- theme's own animation below. This is a transition loaded with the gameplay screen,
-- and both OnCommand and StartTransitioning also reach it when the song starts: the
-- video, sound and fade begin once, when the stage has really failed.
local Video = PhoenixStageBreakVideo and PhoenixStageBreakVideo()
if Video then
    local Started = false
    return Def.ActorFrame {
        StartTransitioningCommand=function(self)
            if Started or not STATSMAN:GetCurStageStats():AllFailed() then return end
            Started = true
            self:playcommand("Begin")
        end,
        Def.Sprite {
            BeginCommand=function(self)
                self:Load(Video.Video):Center():zoomto(SCREEN_WIDTH, SCREEN_HEIGHT)
                local Tex = self:GetTexture()
                if Tex then Tex:loop(false) Tex:position(0) end
                self:SetDecodeMovie(true)
            end,
        },
        Def.Sound { File=Video.Audio, BeginCommand=function(self) self:play() end },
        -- fades to black over the last 0.3 s, which also sets how long the screen lasts
        Def.Quad {
            InitCommand=function(self) self:FullScreen():diffuse(0, 0, 0, 0) end,
            BeginCommand=function(self) self:sleep(Video.Length - 0.3):linear(0.3):diffusealpha(1) end,
        },
    }
end

local t = Def.ActorFrame{

    Def.Sprite {
        Texture=THEME:GetPathG("", "Gradient background"),
        InitCommand=function(self)
            self:zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):Center()
        end
    },

    Def.Sprite {
        Texture=THEME:GetPathG("", "ParticlesAndEffects/Stars1"),
        InitCommand=function(self)
            self:zoom(0.1)
            :diffusealpha(0)
            :sleep(0.5)
            :Center()
            :diffusealpha(0.5)
            :decelerate(1)
            :zoom(0.4)
            :diffusealpha(0)
        end
    },

    Def.Sprite {
        Texture=THEME:GetPathG("", "ParticlesAndEffects/Stars2"),
        InitCommand=function(self)
            self:zoom(0.1)
            :diffusealpha(0)
            :sleep(0.5)
            :Center()
            :diffusealpha(0.5)
            :decelerate(1)
            :zoom(0.5)
            :diffusealpha(0)
        end
    },

    Def.Sprite {
        Texture=THEME:GetPathG("", "ParticlesAndEffects/Stars3"),
        InitCommand=function(self)
            self:zoom(0.1)
            :diffusealpha(0)
            :sleep(0.5)
            :Center()
            :diffusealpha(0.75)
            :decelerate(1)
            :zoom(0.6)
            :diffusealpha(0)
        end
    },

    Def.Sprite {
        Texture=THEME:GetPathG("", "ParticlesAndEffects/Circle"),
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-100)
            :diffusealpha(0)
            :sleep(0.5)
            :diffusealpha(0.1)
            :sleep(0.25)
            :zoom(0)
            :decelerate(5)
            :diffusealpha(1)
            :zoom(2)
        end
    },
    
    Def.Sprite {
        Texture=THEME:GetPathG("", "ParticlesAndEffects/Circle"),
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y+50)
            :diffusealpha(0)
            :sleep(0.5)
            :diffusealpha(0.1)
            :sleep(0.85)
            :zoom(0)
            :decelerate(5)
            :diffusealpha(1)
            :zoom(2)
        end
    },

    Def.Sprite {
        Texture="Hey",
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-150)
            :diffusealpha(0)
            :shadowlength(3)
            :shadowcolor(0,0,0,0.25)
            :zoom(0.7)
            :sleep(0.5 + 0.25)
            :accelerate(0.25)
            :diffusealpha(1)
            :zoom(0.4)
        end
    },

    Def.Sprite {
        Texture="GetUpAndDanceMan",
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X - 10, SCREEN_CENTER_Y+75)
            :diffusealpha(0)
            :shadowlength(3)
            :shadowcolor(0,0,0,0.25)
            :zoom(2)
            :sleep(0.5 + 0.85)
            :accelerate(0.25)
            :diffusealpha(1)
            :zoom(0.8)
        end
    },

    Def.Sound {
        File=THEME:GetPathS("", "Pewwwww"),
        OnCommand=function(self)
            self:queuecommand("Play")
        end,
        PlayCommand=function(self) self:play() end
    },

    Def.Sound {
        File="Voice",
        OnCommand=function(self)
            self:sleep(0.9)
            :queuecommand("Play")
        end,
        PlayCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("", "Boom"),
        OnCommand=function(self)
            self:sleep(1.8)
            :queuecommand("Play")
        end,
        PlayCommand=function(self) self:play() end
    },
    
    Def.Quad {
        InitCommand=function(self)
            self:zoomto(SCREEN_WIDTH, SCREEN_HEIGHT)
            :Center():diffuse(1,1,1,1)
        end,

        OnCommand=function(self)
            self:accelerate(1)
            :diffusealpha(0)
        end
    },
    
    Def.Quad {
        InitCommand=function(self)
            self:zoomto(SCREEN_WIDTH, SCREEN_HEIGHT)
            :Center():diffuse(0,0,0,0)
        end,

        OnCommand=function(self)
            self:sleep(4)
            :decelerate(1)
            :diffusealpha(1)
        end
    }
}

return t
