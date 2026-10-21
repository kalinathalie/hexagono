-- Phoenix-style profile bar(s) at the top of the select screens: avatar, level,
-- name, lives and the level number box. One centered bar with one player, two
-- half-width bars side by side with two.
local Green = color("#3cff5c")

local function ProfileLevel(pn)
    local Profile = PROFILEMAN:GetProfile(pn)
    if not Profile then return 0 end
    local lvl = math.floor(math.sqrt(Profile:GetTotalDancePoints() / 500)) + 1
    if (lvl < 0) or (lvl ~= lvl) then lvl = 0 end
    return lvl
end

-- Every joined player gets a bar (a guest shows "No Profile" and level 0), as in Phoenix.
local function HasProfile(pn)
    return GAMESTATE:IsHumanPlayer(pn) and PROFILEMAN:GetProfile(pn) ~= nil
end

local function Bar(pn)
    local W, H = 576, 50
    local t = Def.ActorFrame {
        Name="Bar" .. ToEnumShortString(pn),
        InitCommand=function(self) self:y(-80):queuecommand("Place") end,
        OnCommand=function(self) self:easeoutexpo(0.5):y(34) end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):y(-80) end,
        PlayerJoinedMessageCommand=function(self) self:queuecommand("Place") end,
        PlaceCommand=function(self)
            local Two = HasProfile(PLAYER_1) and HasProfile(PLAYER_2)
            self:visible(HasProfile(pn))
            if Two then
                self:x(SCREEN_CENTER_X + (pn == PLAYER_2 and 300 or -300)):zoomx(560 / W)
            else
                self:x(SCREEN_CENTER_X):zoomx(1)
            end
        end,

        Def.Quad { InitCommand=function(self) self:zoomto(W + 4, H + 4):diffuse(Green) end },
        Def.Quad { InitCommand=function(self) self:zoomto(W, H):diffuse(color("#0b0f1a")) end },

        -- Avatar
        Def.Sprite {
            Texture=LoadModule("Options.GetProfileData.lua")(pn)["Image"],
            -- scaletocover also positions the sprite, so the x offset comes after it
            InitCommand=function(self) self:scaletocover(-22, -22, 22, 22):x(-W / 2 + 28) end,
        },

        -- Level title and name
        Def.BitmapText {
            Font="Montserrat semibold 20px",
            InitCommand=function(self)
                self:xy(-W / 2 + 60, -11):halign(0):zoom(0.7):diffuse(color("#9fb3c8")):maxwidth(280 / 0.7)
                :settext(ToUpper(THEME:GetString("ProfileStats", "Level") .. " " .. ProfileLevel(pn)))
            end,
        },
        Def.BitmapText {
            Font="Montserrat semibold 20px",
            InitCommand=function(self)
                local Name = PROFILEMAN:GetProfile(pn) and PROFILEMAN:GetProfile(pn):GetDisplayName() or ""
                if Name == "" then Name = THEME:GetString("ProfileStats", "No Profile") end
                self:xy(-W / 2 + 60, 10):halign(0):zoom(0.9):maxwidth(280 / 0.9):shadowlength(1):settext(Name)
            end,
        },

        -- Lives (stages left), six hearts
        Def.ActorFrame {
            InitCommand=function(self) self:x(W / 2 - 200):queuecommand("Refresh") end,
            CurrentSongChangedMessageCommand=function(self) self:queuecommand("Refresh") end,
            RefreshCommand=function(self)
                local Left = GAMESTATE:IsEventMode() and 6 or GAMESTATE:GetNumStagesLeft(pn)
                for i = 1, 6 do
                    self:GetChild("Heart" .. i):diffusealpha(i <= Left and 1 or 0.25)
                end
            end,
        },

        -- Green box: background for the engine's menu timer, which metrics.ini places here
        -- ([ScreenSelectMusicFull] TimerOnCommand), as in the Phoenix layout.
        Def.Quad { InitCommand=function(self) self:x(W / 2 - 34):zoomto(54, 40):diffuse(color("#19e04a")) end },
    }
    local Hearts = t[6] -- the lives frame (sixth child above)
    for i = 1, 6 do
        Hearts[#Hearts + 1] = Def.Sprite {
            Name="Heart" .. i,
            Texture=THEME:GetPathG("", "UI/Heart"),
            InitCommand=function(self) self:x((i - 1) * 22):zoom(0.22) end,
        }
    end
    return t
end

local t = Def.ActorFrame {}
t[#t+1] = Bar(PLAYER_1)
t[#t+1] = Bar(PLAYER_2)
return t
