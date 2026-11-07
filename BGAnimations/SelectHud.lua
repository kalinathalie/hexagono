-- Phoenix 2 top HUD of the select and result screens: the menu timer at the center and
-- each player's card beside it (P1 left, P2 right, mirrored), drawn after Phoenix 2:
--   timer       the theme's own Phoenix-style frame and digits (tools/make_timer.py);
--               the engine timer still counts, hidden (metrics.ini), and its seconds
--               are shown here
--   avatar      inside the card's yellow frame, at the outer end
--   title bar   silver bar with "LEVEL n" in bold, colored by rank (Select.Hud:
--               gray at level 1 up to a rainbow at level 10000)
--   name strip  white strip with the name; the lives (6 hearts) toward the timer
-- A side without a player shows the dim card with "PRESS CENTER STEP" (or "INSERT
-- CREDIT" when credits are needed).
-- LoadActor("../SelectHud", { HideEmpty = true }) hides that side's card entirely
-- (the evaluation screen, where nobody can join).
local Opts = (...) or {}
local Hud = LoadModule("Select.Hud.lua")
local Art = LoadModule("Select.Art.lua")
local HeartArt = Art("XSanity/SM-HEARTS 2x1")

-- Geometry, in theme pixels measured on the Phoenix 2 video: u is the distance from the
-- timer box edge outward (the timer box spans 47 px each side of the center)
local Edge = 47
local CardU = 392          -- the card's outer end, past the avatar's frame
local TitleU = 324         -- title bar and name area: u 0 .. TitleU
local Top, Bottom = 4, 65  -- the card's yellow frame (the title bar starts at Top too)
local Yellow = color("#e3f31d")
local Hidden = -90         -- y offset while the HUD is off screen

-- 1.5 px black outline around the level, so every rank color reads on the silver bar
local Outline = { { -1.5, 0 }, { 1.5, 0 }, { 0, -1.5 }, { 0, 1.5 }, { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }

local function Joined(pn) return GAMESTATE:IsHumanPlayer(pn) end

local function Card(pn)
    local Side = (pn == PLAYER_2) and 1 or -1      -- side of the timer this card sits on
    -- a quad covering u0..u1 and y0..y1 on this side
    local function Box(u0, u1, y0, y1, Color, Init)
        return Def.Quad {
            InitCommand=function(self)
                self:xy(Side * (u0 + u1) / 2, (y0 + y1) / 2):zoomto(u1 - u0, y1 - y0):diffuse(Color)
                if Init then Init(self) end
            end,
        }
    end
    local function Heart(k)
        local X, Y = Side * (18 + (k - 1) * 20), 46.5   -- k = 1 next to the timer
        if HeartArt then
            return Def.Sprite { Name="Heart" .. k, Texture=HeartArt,
                InitCommand=function(self) self:xy(X, Y):animate(false):setstate(0):zoom(0.7) end }
        end
        return Def.Sprite { Name="Heart" .. k, Texture=THEME:GetPathG("", "UI/Heart"),
            InitCommand=function(self) self:xy(X, Y):zoom(0.2) end }
    end

    -- the level on the silver bar: the outline copies, then the colored text
    local Title = Def.ActorFrame {
        Name="Title",
        InitCommand=function(self) self:xy(Side * TitleU / 2, 21) end,
        SetCommand=function(self, params)
            for i = 1, #Outline do self:GetChild("Outline" .. i):settext(params.Text) end
            local Text = self:GetChild("Text")
            Text:settext(params.Text):stopeffect():diffuse(Hud.Color(params.Level))
            if Hud.Rainbow(params.Level) then Text:rainbow():effectperiod(2) end
        end,
    }
    for i, O in ipairs(Outline) do
        Title[#Title + 1] = Def.BitmapText {
            Name="Outline" .. i, Font="Montserrat extrabold 20px",
            InitCommand=function(self) self:xy(O[1], O[2]):zoom(0.8):maxwidth((TitleU - 24) / 0.8):diffuse(color("0,0,0,0.9")) end,
        }
    end
    Title[#Title + 1] = Def.BitmapText {
        Name="Text", Font="Montserrat extrabold 20px",
        InitCommand=function(self) self:zoom(0.8):maxwidth((TitleU - 24) / 0.8) end,
    }

    local Player = Def.ActorFrame {
        Name="Player",
        -- avatar in the yellow frame (scaletocover also positions the sprite)
        Def.Sprite {
            Texture=LoadModule("Options.GetProfileData.lua")(pn)["Image"],
            InitCommand=function(self)
                local x0, x1 = Side * 327, Side * 389
                self:scaletocover(math.min(x0, x1), 7, math.max(x0, x1), 61)
            end,
        },
        Title,
        -- white name strip
        Box(137, 321, 37, 56, color("#f4f6f8")),
        Def.BitmapText {
            Name="Name", Font="Montserrat extrabold 20px",
            InitCommand=function(self) self:xy(Side * 229, 46.5):zoom(0.8):maxwidth(170 / 0.8):diffuse(color("#111318")) end,
        },
    }
    for k = 1, 6 do Player[#Player + 1] = Heart(k) end

    return Def.ActorFrame {
        Name="Card" .. ToEnumShortString(pn),
        InitCommand=function(self) self:xy(SCREEN_CENTER_X + Side * Edge, Hidden):queuecommand("Refresh") end,
        OnCommand=function(self) self:easeoutexpo(0.5):y(0) end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):y(Hidden) end,
        PlayerJoinedMessageCommand=function(self) self:queuecommand("Refresh") end,
        CoinInsertedMessageCommand=function(self) self:queuecommand("Refresh") end,
        CurrentSongChangedMessageCommand=function(self) self:queuecommand("Refresh") end,
        RefreshCommand=function(self)
            local On = Joined(pn)
            if Opts.HideEmpty then self:visible(On) end
            self:GetChild("Player"):visible(On)
            self:GetChild("Empty"):visible(not On)
            if not On then
                local Credit = GAMESTATE:GetCoins() >= GAMESTATE:GetCoinsNeededToJoin()
                self:GetChild("Empty"):GetChild("Text"):settext(THEME:GetString("ScreenSelectMusicFull", Credit and "PressCenterStep" or "InsertCredit"))
                return
            end
            local P = self:GetChild("Player")
            local Profile = PROFILEMAN:GetProfile(pn)
            local Name = Profile and Profile:GetDisplayName() or ""
            if Name == "" then Name = THEME:GetString("ProfileStats", "No Profile") end
            P:GetChild("Name"):settext(Name)
            local Level = Hud.Level(Profile and Profile:GetTotalDancePoints() or 0)
            P:GetChild("Title"):playcommand("Set", {
                Level = Level,
                Text = ToUpper(THEME:GetString("ProfileStats", "Level") .. " " .. Level),
            })
            local Left = GAMESTATE:IsEventMode() and 6 or GAMESTATE:GetNumStagesLeft(pn)
            for k = 1, 6 do
                local H = P:GetChild("Heart" .. k)
                if HeartArt then H:setstate(k <= Left and 0 or 1) else H:diffusealpha(k <= Left and 1 or 0.25) end
            end
        end,

        -- The card (shared by both states), as measured on the Phoenix 2 video: the yellow
        -- frame around the avatar, the silver title bar (lighter at the top, with a soft
        -- highlight), a yellow-green line under it, the black name area and a yellow-green
        -- line closing it
        Box(TitleU, CardU, Top, Bottom, Yellow, function(self) self:diffusebottomedge(color("#b9e01a")) end),
        Box(0, TitleU, Top, 35, color("#c3c8cf"), function(self) self:diffusebottomedge(color("#5d626b")) end),
        Box(0, TitleU, 6, 13, Color.White, function(self) self:diffusealpha(0.35):fadeleft(0.35):faderight(0.35) end),
        Box(0, TitleU, 35, 37, color("#c8f01e")),
        Box(0, TitleU, 37, 56, Color.Black),
        Box(0, TitleU, 56, 60, color("#c8f01e")),

        Player,

        -- Side without a player
        Def.ActorFrame {
            Name="Empty",
            Box(0, CardU, Top, Bottom, Color.Black, function(self) self:diffusealpha(0.55) end),
            Def.BitmapText {
                Name="Text",
                Font="Montserrat extrabold 20px",
                InitCommand=function(self)
                    self:xy(Side * CardU / 2, (Top + Bottom) / 2):zoom(0.85):shadowlength(1)
                        :diffuseshift():effectcolor1(color("#ffffff")):effectcolor2(color("#7a8ba6")):effectperiod(1.6)
                end,
            },
        },
    }
end

-- The timer: the frame and its smoke (a second smoke fading in and out over it), and
-- the engine timer's seconds in the Phoenix-style digits. Sizes from the video: the
-- frame art spans 150 x 91 video pixels from y 2, the digits are 42 px tall at y 42.5.
local Timer = Def.ActorFrame {
    InitCommand=function(self)
        self:xy(SCREEN_CENTER_X, Hidden)
        local Digits, Last
        self:SetUpdateFunction(function(frame)
            Digits = Digits or frame:GetChild("Digits")
            local Screen = SCREENMAN:GetTopScreen()
            local Engine = Screen and Screen:GetChild("Timer")
            local Text = Hud.TimerText(Engine and Engine:GetSeconds() or nil)
            if Text ~= Last then
                Last = Text
                Digits:settext(Text)
            end
        end)
    end,
    OnCommand=function(self) self:easeoutexpo(0.5):y(0) end,
    OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):y(Hidden) end,
    Def.Sprite { Texture=THEME:GetPathG("", "UI/Timer frame"),
        InitCommand=function(self) self:y(47.5 * 2 / 3):zoomto(100, 91 * 2 / 3) end },
    Def.Sprite { Texture=THEME:GetPathG("", "UI/Timer smoke"),
        InitCommand=function(self)
            self:y(47.5 * 2 / 3):zoomto(100, 91 * 2 / 3)
                :diffuseshift():effectcolor1(color("1,1,1,1")):effectcolor2(color("1,1,1,0")):effectperiod(4)
        end },
    Def.BitmapText { Name="Digits", Font="Timer digits", Text="99",
        InitCommand=function(self) self:y(42.5 * 2 / 3):zoom(28 / 86) end },
}

return Def.ActorFrame {
    Card(PLAYER_1),
    Card(PLAYER_2),
    Timer,
}
