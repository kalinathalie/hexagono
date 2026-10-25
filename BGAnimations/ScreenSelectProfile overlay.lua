-- Profile select. Players join on the title screen, so there is no join prompt
-- here (a center press still joins a player who did not). Each joined player
-- gets a card with Guest, the local profiles and CREATE PROFILE at the end:
-- the lower panels move, the center panel picks. CREATE PROFILE opens a pad
-- keyboard (Modules/Profile.Keyboard.lua); the name goes to one of the hidden
-- reserved profiles (Modules/Profile.Slots.lua), since OutFox's Lua cannot
-- create a profile, only rename and save one.
local Slots = LoadModule("Profile.Slots.lua")
local Keyboard = LoadModule("Profile.Keyboard.lua")

local CardItemW = 268
local CardItemH = 64
local ListY = 30          -- the selected row (under the highlight at y 27)
local RowsShown = 2       -- rows drawn above and below the selected one (clipped by the mask)

local function S(Key) return THEME:GetString("ProfileCreate", Key) end

-- reserved profiles already renamed in this session (the engine list only refreshes at startup)
HexagonoUsedSlots = HexagonoUsedSlots or {}

local function ReadProfiles()
    local t = {}
    for p = 0, PROFILEMAN:GetNumLocalProfiles() - 1 do
        t[#t + 1] = { Index = p, Name = PROFILEMAN:GetLocalProfileFromIndex(p):GetDisplayName() }
    end
    return t
end

-- Writes one more reserved profile folder; the engine sees it at the next start
local function WriteReservedProfile()
    local Ids = {}
    for _, Dir in ipairs(FILEMAN:GetDirListing("/Save/LocalProfiles/", true, false) or {}) do Ids[#Ids + 1] = Dir end
    local Id = Slots.NextId(Ids)
    local Guid = string.format("%08x%08x", math.random(0, 0x7fffffff), math.random(0, 0x7fffffff))
    for Name, Content in pairs(Slots.Files(Guid, 100 + tonumber(Id))) do
        local f = RageFileUtil.CreateRageFile()
        if f:Open("/Save/LocalProfiles/" .. Id .. "/" .. Name, 2) then f:Write(Content) f:Close() end
        f:destroy()
    end
end

-- Renames the first free reserved profile; returns its local index or nil
local function CreateProfile(Name)
    local Clean = Slots.CleanName(Name)
    if not Clean then return nil end
    local Index = Slots.FirstFree(ReadProfiles(), HexagonoUsedSlots)
    if not Index then return nil end
    HexagonoUsedSlots[Index] = true
    PROFILEMAN:GetLocalProfileFromIndex(Index):SetDisplayName(Clean)
    PROFILEMAN:SaveLocalProfile(PROFILEMAN:GetLocalProfileIDFromIndex(Index))
    WriteReservedProfile()
    return Index
end

-- Per player: position in the visible list and the keyboard (nil when closed)
local Cursor = { PlayerNumber_P1 = 1, PlayerNumber_P2 = 1 }
local KB = {}
local function Visible() return Slots.VisibleList(ReadProfiles()) end

local function SongsPlayedString(NumSongs)
    return THEME:GetString("ScreenSelectProfile", NumSongs == 1 and "SingularSongPlayed" or "SeveralSongsPlayed")
end

-- One card per item: Guest, every local profile (reserved ones stay hidden until renamed), Create
local function Card(Name, Icon, Title, Sub)
    return Def.ActorFrame {
        Name=Name,
        Def.Sprite {
            Name="Icon", Texture=THEME:GetPathG("UserProfile", "generic icon"),
            InitCommand=function(self)
                if Icon then self:Load(Icon) end
                self:scaletofit(0, 0, 64, 64):xy(-CardItemW / 2 + 32, -3):ztest(true)
            end
        },
        Def.BitmapText {
            Name="Title", Font="Montserrat semibold 40px", Text=Title,
            InitCommand=function(self) self:shadowlength(1):xy(CardItemW / 2 - 8, Sub and -14 or -3):zoom(0.75):halign(1):maxwidth(250):ztest(true) end,
        },
        Def.BitmapText {
            Name="Sub", Font="Montserrat normal 20px", Text=Sub or "",
            InitCommand=function(self) self:shadowlength(1):xy(CardItemW / 2 - 8, 14):zoom(0.75):halign(1):ztest(true) end,
        },
    }
end

local function ListCards()
    local t = {
        -- mask above and below the visible rows (cards draw with ztest)
        Def.Quad { InitCommand=function(self) self:zoomto(320, 300):y(-129.5 - 150):MaskSource() end },
        Def.Quad { InitCommand=function(self) self:zoomto(320, 300):y(129.5 + 150):MaskSource() end },
        Card("Guest", nil, "Guest"),
    }
    for p = 0, PROFILEMAN:GetNumLocalProfiles() - 1 do
        local Profile = PROFILEMAN:GetLocalProfileFromIndex(p)
        local Avatar = LoadModule("Config.Load.lua")("AvatarImage", "/Save/LocalProfiles/" .. PROFILEMAN:GetLocalProfileIDFromIndex(p) .. "/OutFoxPrefs.ini")
        local Played = Profile:GetNumTotalSongsPlayed()
        t[#t + 1] = Card("Profile" .. p, Avatar, Profile:GetDisplayName(), string.format(SongsPlayedString(Played), Played))
    end
    local Create = Card("Create", nil, S("Create"))
    Create[#Create + 1] = Def.BitmapText {
        Font="Montserrat extrabold 40px", Text="+",
        InitCommand=function(self) self:xy(-CardItemW / 2 + 32, -4):zoom(1.1):diffuse(color("#3cff5c")):ztest(true) end,
    }
    t[#t + 1] = Create
    return t
end

local function LoadCard(cColor)
    return Def.ActorFrame {
        InitCommand=function(self) self:y(15):diffusealpha(0.75) end,
        Def.Sprite { Texture=THEME:GetPathG("", "UI/CardBackground"), InitCommand=function(self) self:y(15):zoom(0.75):diffuse(cColor) end },
        Def.Sprite { Texture=THEME:GetPathG("", "UI/CardFrame"), InitCommand=function(self) self:y(-15):zoom(0.75) end },
    }
end

-- The pad keyboard inside the card: name box, one scrolling row of keys, hint
local KeyOffsets = { -3, -2, -1, 0, 1, 2, 3 }
local function KeyboardFrame()
    local t = Def.ActorFrame {
        Name="KB",
        InitCommand=function(self) self:visible(false) end,
        Def.BitmapText { Font="Montserrat extrabold 40px", Text=S("NewProfile"), InitCommand=function(self) self:y(-78):zoom(0.6):diffuse(color("#46e0ff")):shadowlength(1) end },
        Def.Quad { InitCommand=function(self) self:y(-25):zoomto(CardItemW - 10, 46):diffuse(color("#05070d")):diffusealpha(0.85) end },
        Def.Quad { InitCommand=function(self) self:y(-2):zoomto(CardItemW - 30, 2):diffuse(color("#3cff5c")) end },
        Def.BitmapText { Name="Name", Font="Montserrat semibold 40px", InitCommand=function(self) self:y(-26):zoom(0.8):maxwidth((CardItemW - 20) / 0.8):shadowlength(1) end },
        Def.Quad {
            Name="Caret", InitCommand=function(self) self:y(-26):zoomto(3, 30):diffuse(Color.White):diffuseblink():effectperiod(0.8) end,
        },
        -- highlight behind the key under the cursor
        Def.Quad { InitCommand=function(self) self:y(50):zoomto(58, 54):diffuse(color("#ffe600")) end },
        Def.Quad { InitCommand=function(self) self:y(50):zoomto(52, 48):diffuse(color("#202838")) end },
        Def.BitmapText { Font="Montserrat normal 20px", Text=S("KeyboardHint"), InitCommand=function(self) self:y(118):zoom(0.62):wrapwidthpixels((CardItemW - 10) / 0.62):shadowlength(1) end },
        Def.BitmapText { Name="Msg", Font="Montserrat semibold 20px", InitCommand=function(self) self:y(90):zoom(0.7):diffuse(color("#ff6a5c")):shadowlength(1) end },
    }
    for _, o in ipairs(KeyOffsets) do
        t[#t + 1] = Def.BitmapText {
            Name="Key" .. o, Font="Montserrat extrabold 40px",
            InitCommand=function(self)
                local Center = o == 0
                self:xy(o * 40, 50):zoom(Center and 0.62 or 0.42):diffusealpha(Center and 1 or (1 - math.abs(o) * 0.22)):shadowlength(1)
                    :maxwidth((Center and 48 or 38) / (Center and 0.62 or 0.42))
                if Center then self:diffuse(color("#ffe600")) end
            end,
        }
    end
    return t
end

local function KeyText(Key)
    if Key == "SPACE" then return "SPC" end
    return Key
end

local function LoadPlayerStuff(Player)
    return {
        Def.ActorFrame { Name="BigFrame", LoadCard(Color("Black")) },
        Def.ActorFrame {
            Name="SmallFrame",
            InitCommand=function(self) self:y(27) end,
            Def.Quad { InitCommand=function(self) self:zoomto(CardItemW, CardItemH) end, OnCommand=function(self) self:diffuse(Color("Black")):diffusealpha(0.5) end },
            Def.Quad { InitCommand=function(self) self:zoomto(CardItemW, CardItemH) end, OnCommand=function(self) self:diffuse(Color("Black")):fadeleft(0.25):faderight(0.25):glow(color("1,1,1,0.25")) end },
            Def.Quad { InitCommand=function(self) self:zoomto(CardItemW, CardItemH):y(-40 / 2 + 20) end, OnCommand=function(self) self:diffuse(Color("Black")):fadebottom(1):diffusealpha(0.35) end },
        },
        Def.ActorFrame { Name="List", InitCommand=function(self) self:y(ListY) end, children=ListCards() },
        KeyboardFrame(),
        Def.ActorFrame {
            Name="EffectFrame",
            Def.Quad {
                InitCommand=function(self) self:zoomto(CardItemW, CardItemH):y(27):diffuse(Color("White")):diffusealpha(0) end,
                OffCommand=function(self) self:diffusealpha(1):easeoutexpo(0.5):zoomto(CardItemW * 2, CardItemH * 2):diffusealpha(0) end,
            },
        },
    }
end

-- Draw one player's card from Cursor / KB
local function Update(Root, Player)
    local Frame = Root:GetChild(Player == PLAYER_1 and "P1Frame" or "P2Frame")
    local Joined = GAMESTATE:IsHumanPlayer(Player)
    Frame:visible(Joined)
    if not Joined then return end
    local List, KBFrame = Frame:GetChild("List"), Frame:GetChild("KB")
    local State = KB[Player]
    List:visible(State == nil)
    Frame:GetChild("SmallFrame"):visible(State == nil)
    KBFrame:visible(State ~= nil)

    if State then
        KBFrame:GetChild("Name"):settext(State.Name)
        local Width = KBFrame:GetChild("Name"):GetZoomedWidth()
        KBFrame:GetChild("Caret"):x(Width / 2 + 4)
        for _, o in ipairs(KeyOffsets) do KBFrame:GetChild("Key" .. o):settext(KeyText(Keyboard.At(State, o))) end
        KBFrame:GetChild("Msg"):settext(State.Msg or "")
        return
    end

    -- list: place the visible cards around the cursor, hide reserved profiles
    local Items = Visible()
    Cursor[Player] = math.max(1, math.min(Cursor[Player], #Items))
    List:GetChild("Guest"):visible(false)
    List:GetChild("Create"):visible(false)
    for p = 0, PROFILEMAN:GetNumLocalProfiles() - 1 do List:GetChild("Profile" .. p):visible(false) end
    for i, Item in ipairs(Items) do
        local Name = Item.Kind == "guest" and "Guest" or (Item.Kind == "create" and "Create" or ("Profile" .. (Item.Engine - 1)))
        local Card = List:GetChild(Name)
        local Offset = i - Cursor[Player]
        if Item.Kind == "profile" then Card:GetChild("Title"):settext(Item.Name) end
        Card:visible(math.abs(Offset) <= RowsShown):stoptweening():linear(0.08):y(Offset * CardItemH)
    end
end

-- Move the cursor; profiles taken by the other player are skipped
local function MoveCursor(pn, Dir)
    local Items = Visible()
    local i = Cursor[pn]
    while true do
        i = i + Dir
        local Item = Items[i]
        if not Item then return false end
        if Item.Kind == "create" then Cursor[pn] = i return true end
        if SCREENMAN:GetTopScreen():SetProfileIndex(pn, Item.Engine) then Cursor[pn] = i return true end
    end
end

-- Put the cursor on the profile the engine has for this player
local function SyncCursor(pn)
    local Engine = SCREENMAN:GetTopScreen():GetProfileIndex(pn)
    if Engine < 0 then
        SCREENMAN:GetTopScreen():SetProfileIndex(pn, 0)
        Engine = 0
    end
    for i, Item in ipairs(Visible()) do
        if Item.Engine == Engine then Cursor[pn] = i return end
    end
end

local Root
local LOWER_LEFT = { DownLeft = true, MenuLeft = true, Left = true, Up = true }
local LOWER_RIGHT = { DownRight = true, MenuRight = true, Right = true, Down = true }
local UPPER = { UpLeft = true, UpRight = true, MenuUp = true, MenuDown = true }
local CENTER = { Center = true, Start = true, MenuStart = true }

local function KeyboardInput(pn, Button, First)
    local State = KB[pn]
    State.Msg = nil
    if LOWER_LEFT[Button] then Keyboard.Move(State, -1) MESSAGEMAN:Broadcast("DirectionButton")
    elseif LOWER_RIGHT[Button] then Keyboard.Move(State, 1) MESSAGEMAN:Broadcast("DirectionButton")
    elseif not First then return
    elseif UPPER[Button] or Button == "Back" then
        if Keyboard.Erase(State) == "cancel" or Button == "Back" then KB[pn] = nil end
        MESSAGEMAN:Broadcast("BackButton")
    elseif CENTER[Button] then
        local Result = Keyboard.Press(State)
        if Result == "ok" then
            local Index = CreateProfile(State.Name)
            if Index then
                KB[pn] = nil
                SCREENMAN:GetTopScreen():SetProfileIndex(pn, Index + 1)
                SyncCursor(pn)
                MESSAGEMAN:Broadcast("ProfileCreated", { Player = pn })
            else
                State.Msg = S("NoSlots")
                MESSAGEMAN:Broadcast("BackButton")
            end
        elseif Result == "empty" or Result == "full" then
            State.Msg = S(Result == "empty" and "NameEmpty" or "NameFull")
            MESSAGEMAN:Broadcast("BackButton")
        else
            MESSAGEMAN:Broadcast("StartButton")
        end
    end
end

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn or event.type == "InputEventType_Release" then return end
    -- OutFox: event.button is the pad panel, event.GameButton the menu button
    local Button = event.button or event.GameButton
    local First = event.type == "InputEventType_FirstPress"

    if KB[pn] then
        KeyboardInput(pn, Button, First)
        Root:queuecommand("UpdateInternal2")
        return
    end
    if not First then return end

    if CENTER[Button] then
        if not GAMESTATE:IsHumanPlayer(pn) then
            SCREENMAN:GetTopScreen():SetProfileIndex(pn, -1)
            return
        end
        local Item = Visible()[Cursor[pn]]
        MESSAGEMAN:Broadcast("StartButton")
        if Item and Item.Kind == "create" then
            KB[pn] = Keyboard.New()
            Root:queuecommand("UpdateInternal2")
        elseif SCREENMAN:GetTopScreen():GetProfileIndex(pn) == 0 then
            setenv("IsBasicMode", true)
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        else
            setenv("IsBasicMode", false)
            SCREENMAN:GetTopScreen():Finish()
        end
    elseif LOWER_LEFT[Button] and GAMESTATE:IsHumanPlayer(pn) then
        if MoveCursor(pn, -1) then MESSAGEMAN:Broadcast("DirectionButton") end
    elseif LOWER_RIGHT[Button] and GAMESTATE:IsHumanPlayer(pn) then
        if MoveCursor(pn, 1) then MESSAGEMAN:Broadcast("DirectionButton") end
    elseif Button == "Back" or event.GameButton == "Back" then
        SCREENMAN:GetTopScreen():Cancel()
    end
end

return Def.ActorFrame {
    OnCommand=function(self)
        Root = self
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
        for _, pn in ipairs({ PLAYER_1, PLAYER_2 }) do if GAMESTATE:IsHumanPlayer(pn) then SyncCursor(pn) end end
        self:queuecommand("UpdateInternal2")
    end,
    PlayerJoinedMessageCommand=function(self, params)
        if params and params.Player then SyncCursor(params.Player) end
        self:queuecommand("UpdateInternal2")
    end,
    PlayerUnjoinedMessageCommand=function(self) self:queuecommand("UpdateInternal2") end,
    DirectionButtonMessageCommand=function(self) self:queuecommand("UpdateInternal2") end,
    UpdateInternal2Command=function(self)
        Update(self, PLAYER_1)
        Update(self, PLAYER_2)
    end,

    Def.ActorFrame {
        Name="P1Frame",
        OnCommand=function(self) self:x(SCREEN_CENTER_X - 200):y(SCREEN_CENTER_Y):zoom(0):easeoutexpo(1):zoom(1) end,
        OffCommand=function(self) self:stoptweening():easeinback(0.5):zoom(0) end,
        PlayerJoinedMessageCommand=function(self, params) if params.Player == PLAYER_1 then self:stoptweening():zoom(1.15):easeoutexpo(0.25):zoom(1) end end,
        children=LoadPlayerStuff(PLAYER_1)
    },
    Def.ActorFrame {
        Name="P2Frame",
        OnCommand=function(self) self:x(SCREEN_CENTER_X + 200):y(SCREEN_CENTER_Y):zoom(0):easeoutexpo(1):zoom(1) end,
        OffCommand=function(self) self:stoptweening():easeinback(0.5):zoom(0) end,
        PlayerJoinedMessageCommand=function(self, params) if params.Player == PLAYER_2 then self:stoptweening():zoom(1.15):easeoutexpo(0.25):zoom(1) end end,
        children=LoadPlayerStuff(PLAYER_2)
    },

    Def.Sound { File=THEME:GetPathS("Common", "start"), IsAction=true, StartButtonMessageCommand=function(self) self:play() end, ProfileCreatedMessageCommand=function(self) self:play() end },
    Def.Sound { File=THEME:GetPathS("Common", "cancel"), IsAction=true, BackButtonMessageCommand=function(self) self:play() end },
    Def.Sound { File=THEME:GetPathS("Common", "value"), IsAction=true, DirectionButtonMessageCommand=function(self) self:play() end },
}
