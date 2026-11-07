-- Phoenix 2 top HUD of the select and result screens: the menu timer in a green box at
-- the center (the engine timer is placed there by metrics.ini) and each player's card
-- beside it (P1 left, P2 right, mirrored), drawn after the Phoenix 2 card:
--   outer end   black box with a yellow number (Phoenix's rating; here the songs the
--               profile played) over an orb
--   avatar      inside the card's yellow frame
--   title bar   silver bar with the title in bold (here "LEVEL n")
--   name strip  white strip with the name; the lives (6 hearts) toward the timer
-- A side without a player shows the dim card with "PRESS CENTER STEP" (or "INSERT
-- CREDIT" when credits are needed).
-- LoadActor("../SelectHud", { HideEmpty = true }) hides that side's card entirely
-- (the evaluation screen, where nobody can join).
local Opts = (...) or {}
local Art = LoadModule("Select.Art.lua")
local HeartArt = Art("XSanity/SM-HEARTS 2x1")
local OrbArt = Art("Phoenix/blackball")

-- Geometry, in theme pixels measured on the Phoenix 2 video: u is the distance from the
-- timer box edge outward (the timer box spans 47 px each side of the center)
local Edge = 47
local CardU = 450          -- the card's outer end
local TitleU = 324         -- title bar and name area: u 0 .. TitleU
local Top, Bottom = 4, 65  -- the card's yellow frame (the title bar starts at Top too)
local Yellow = color("#e3f31d")
local Hidden = -90         -- y offset while the HUD is off screen

local function ProfileLevel(pn)
    local Profile = PROFILEMAN:GetProfile(pn)
    if not Profile then return 0 end
    local lvl = math.floor(math.sqrt(Profile:GetTotalDancePoints() / 500)) + 1
    if (lvl < 0) or (lvl ~= lvl) then lvl = 0 end
    return lvl
end

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

    local Player = Def.ActorFrame {
        Name="Player",
        -- outer end: the number over the orb
        Def.BitmapText {
            Name="Number", Font="Montserrat semibold 20px",
            -- right-aligned in its strip on both sides, as in Phoenix 2
            InitCommand=function(self) self:xy(Side < 0 and -396 or 443, 12.5):halign(1):zoom(0.55):maxwidth(48 / 0.55):diffuse(color("#ffe24a")) end,
        },
        OrbArt and Def.Sprite { Texture=OrbArt, InitCommand=function(self) self:xy(Side * 419.5, 40):zoomto(40, 40) end }
            or Box(409, 430, 30, 50, color("#8a8f98")),
        -- avatar in the yellow frame (scaletocover also positions the sprite)
        Def.Sprite {
            Texture=LoadModule("Options.GetProfileData.lua")(pn)["Image"],
            InitCommand=function(self)
                local x0, x1 = Side * 326, Side * 390
                self:scaletocover(math.min(x0, x1), 6, math.max(x0, x1), 62)
            end,
        },
        -- title, centered on the silver bar
        Def.BitmapText {
            Name="Title", Font="Montserrat extrabold 20px",
            InitCommand=function(self)
                self:xy(Side * TitleU / 2, 21):zoom(0.8):maxwidth((TitleU - 24) / 0.8)
                    :diffuse(Color.White):shadowlength(2):shadowcolor(color("0,0,0,0.85"))
            end,
        },
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
            P:GetChild("Title"):settext(ToUpper(THEME:GetString("ProfileStats", "Level") .. " " .. ProfileLevel(pn)))
            P:GetChild("Number"):settext(tostring(Profile and Profile:GetNumTotalSongsPlayed() or 0))
            local Left = GAMESTATE:IsEventMode() and 6 or GAMESTATE:GetNumStagesLeft(pn)
            for k = 1, 6 do
                local H = P:GetChild("Heart" .. k)
                if HeartArt then H:setstate(k <= Left and 0 or 1) else H:diffusealpha(k <= Left and 1 or 0.25) end
            end
        end,

        -- The card (shared by both states), as measured on the Phoenix 2 video: the yellow
        -- frame around the avatar and the outer box, the black outer box (a number strip
        -- over the orb's body), the silver title bar (lighter at the top, with a soft
        -- highlight), a yellow-green line under it, the black name area and a yellow-green
        -- line closing it
        Box(TitleU, CardU, Top, Bottom, Yellow, function(self) self:diffusebottomedge(color("#b9e01a")) end),
        Box(393, 446, 6, 59, color("#050608")),
        Box(393, 446, 19, 21, Yellow),
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

return Def.ActorFrame {
    Card(PLAYER_1),
    Card(PLAYER_2),

    -- Green timer box at the center, with the card's yellow-green frame (the timer digits
    -- are drawn above it by the engine: metrics.ini, centered at y 29 like Phoenix 2's)
    Def.ActorFrame {
        InitCommand=function(self) self:xy(SCREEN_CENTER_X, 34 + Hidden) end,
        OnCommand=function(self) self:easeoutexpo(0.5):y(34) end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):y(34 + Hidden) end,
        Def.Quad { InitCommand=function(self) self:zoomto(94, 60):diffuse(color("#d4f01c")):diffusebottomedge(color("#8fd41a")) end },
        Def.Quad { InitCommand=function(self) self:zoomto(88, 54):diffuse(color("#0a2a10")) end },
        Def.Quad { InitCommand=function(self) self:zoomto(84, 50):diffuse(color("#4fe25a")):diffusebottomedge(color("#10902a")) end },
    },
}
