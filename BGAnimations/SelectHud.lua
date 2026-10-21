-- Phoenix-style top HUD of the select screens: the menu timer in a green box at
-- the center (the engine timer is placed there by metrics.ini), each player's bar
-- beside it (P1 left, P2 right) with the avatar at the outer end, level and name,
-- and the lives next to the timer. A side without a player shows a dim bar with
-- "PRESS CENTER STEP" (or "INSERT CREDIT" when credits are needed).
local Art = LoadModule("Select.Art.lua")
local HeartArt = Art("SM-HEARTS 2x1")

local BarW, BarH = 440, 50
local Gap = 52              -- half of the timer box plus a margin
local Y = 33
local PlayerColor = { [PLAYER_1] = color("#ff4a3c"), [PLAYER_2] = color("#ffd23c") }

local function ProfileLevel(pn)
    local Profile = PROFILEMAN:GetProfile(pn)
    if not Profile then return 0 end
    local lvl = math.floor(math.sqrt(Profile:GetTotalDancePoints() / 500)) + 1
    if (lvl < 0) or (lvl ~= lvl) then lvl = 0 end
    return lvl
end

local function Joined(pn) return GAMESTATE:IsHumanPlayer(pn) end

local function Heart(Name, X)
    if HeartArt then
        return Def.Sprite {
            Name=Name, Texture=HeartArt,
            InitCommand=function(self) self:x(X):y(11):animate(false):setstate(0):zoom(0.5) end,
        }
    end
    return Def.Sprite {
        Name=Name, Texture=THEME:GetPathG("", "UI/Heart"),
        InitCommand=function(self) self:x(X):y(11):zoom(0.2) end,
    }
end

local function Bar(pn)
    local Side = (pn == PLAYER_2) and 1 or -1          -- side of the timer this bar sits on
    local Outer = Side * BarW / 2                       -- local x of the outer end
    local HAlign = (Side < 0) and 0 or 1                -- text grows away from the outer end
    local TextX = Side * (BarW / 2 - 58)

    local PlayerFrame = Def.ActorFrame {
        Name="Player",
        Def.Quad { InitCommand=function(self) self:x(Side * (BarW / 2 - 26)):zoomto(48, 48):diffuse(PlayerColor[pn]) end },
        Def.Sprite {
            Texture=LoadModule("Options.GetProfileData.lua")(pn)["Image"],
            -- scaletocover also positions the sprite, so the x offset comes after it
            InitCommand=function(self) self:scaletocover(-22, -22, 22, 22):x(Side * (BarW / 2 - 26)) end,
        },
        Def.BitmapText {
            Name="Level",
            Font="Montserrat extrabold 20px",
            InitCommand=function(self) self:xy(TextX, -12):halign(HAlign):zoom(0.7):maxwidth((BarW - 80) / 0.7):shadowlength(1) end,
        },
        -- white name strip, as in Phoenix
        Def.Quad { InitCommand=function(self) self:xy(Side * (BarW / 2 - 58 - 118), 11):zoomto(236, 22):diffuse(color("#e9edf2")) end },
        Def.BitmapText {
            Name="Name",
            Font="Montserrat extrabold 20px",
            InitCommand=function(self) self:xy(TextX - Side * 6, 11):halign(HAlign):zoom(0.75):maxwidth(224 / 0.75):diffuse(color("#10131c")) end,
        },
    }
    for k = 1, 6 do
        -- lives next to the timer
        PlayerFrame[#PlayerFrame + 1] = Heart("Heart" .. k, -Side * (BarW / 2 - 20 - (k - 1) * 20))
    end

    return Def.ActorFrame {
        Name="Bar" .. ToEnumShortString(pn),
        InitCommand=function(self) self:xy(SCREEN_CENTER_X + Side * (Gap + BarW / 2), -80):queuecommand("Refresh") end,
        OnCommand=function(self) self:easeoutexpo(0.5):y(Y) end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):y(-80) end,
        PlayerJoinedMessageCommand=function(self) self:queuecommand("Refresh") end,
        CoinInsertedMessageCommand=function(self) self:queuecommand("Refresh") end,
        CurrentSongChangedMessageCommand=function(self) self:queuecommand("Refresh") end,
        RefreshCommand=function(self)
            local On = Joined(pn)
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
            P:GetChild("Level"):settext(ToUpper(THEME:GetString("ProfileStats", "Level") .. " " .. ProfileLevel(pn)))
            local Left = GAMESTATE:IsEventMode() and 6 or GAMESTATE:GetNumStagesLeft(pn)
            for k = 1, 6 do
                local H = P:GetChild("Heart" .. k)
                if HeartArt then H:setstate(k <= Left and 0 or 1) else H:diffusealpha(k <= Left and 1 or 0.25) end
            end
        end,

        -- Frame (shared by both states)
        Def.Quad { InitCommand=function(self) self:zoomto(BarW + 4, BarH + 4):diffuse(PlayerColor[pn]) end },
        Def.Quad { InitCommand=function(self) self:zoomto(BarW, BarH):diffuse(color("#0b0f1a")) end },

        PlayerFrame,

        -- Side without a player
        Def.ActorFrame {
            Name="Empty",
            Def.Quad { InitCommand=function(self) self:zoomto(BarW, BarH):diffuse(Color.Black):diffusealpha(0.45) end },
            Def.BitmapText {
                Name="Text",
                Font="Montserrat extrabold 20px",
                InitCommand=function(self)
                    self:zoom(0.85):shadowlength(1):diffuseshift():effectcolor1(color("#ffffff")):effectcolor2(color("#7a8ba6")):effectperiod(1.6)
                end,
            },
        },
    }
end

return Def.ActorFrame {
    Bar(PLAYER_1),
    Bar(PLAYER_2),

    -- Green timer box at the center (the timer digits are drawn above it by the engine)
    Def.ActorFrame {
        InitCommand=function(self) self:xy(SCREEN_CENTER_X, -80) end,
        OnCommand=function(self) self:easeoutexpo(0.5):y(Y) end,
        OffCommand=function(self) self:stoptweening():easeoutexpo(0.5):y(-80) end,
        Def.Quad { InitCommand=function(self) self:zoomto(96, 56):diffuse(color("#0d4f1d")) end },
        Def.Quad { InitCommand=function(self) self:zoomto(90, 50):diffuse(color("#5dff6e")):diffusebottomedge(color("#14a83a")) end },
    },
}
