-- Profile select. Players join on the title screen, so there is no join prompt
-- here (a center press still joins a player who did not). Each joined player
-- gets a card with Guest, the local profiles and CREATE PROFILE at the end:
-- the lower panels move, the center panel picks. CREATE PROFILE opens a pad
-- keyboard (Modules/Profile.Keyboard.lua); the name goes to one of the hidden
-- reserved profiles (Modules/Profile.Slots.lua), since OutFox's Lua cannot
-- create a profile, only rename and save one.
-- With two players, the red panels drop a player (the center brings them back).
-- Blue left, blue right, three times, opens profile editing (Modules/Profile.Editor.lua):
-- pick a profile, then EDIT NAME (the same keyboard) or EDIT PHOTO (the avatars in
-- /Appearance/Avatars and the Phoenix player icons, or no photo).
local Slots = LoadModule("Profile.Slots.lua")
local Keyboard = LoadModule("Profile.Keyboard.lua")
local Confirm = LoadModule("Profile.Confirm.lua")
local Code = LoadModule("Pad.Code.lua")
local Editor = LoadModule("Profile.Editor.lua")
local Avatars = LoadModule("Profile.GetAvatarImageArray.lua")()
local EditCode = Code.New({ "DownLeft", "DownRight", "DownLeft", "DownRight", "DownLeft", "DownRight" }, 2)
local GenericIcon = THEME:GetPathG("UserProfile", "generic icon")
local ReadyArt = { PlayerNumber_P1 = LoadModule("Select.Art.lua")("Phoenix/READY_P1"), PlayerNumber_P2 = LoadModule("Select.Art.lua")("Phoenix/READY_P2") }

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
local Ready = {}   -- players who confirmed their choice
local Edit = {}    -- profile editor per player (nil when closed)

local function AvatarPath(Path)
    if Path and Path ~= "" and FILEMAN:DoesFileExist(Path) then return Path end
    return nil
end
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
                if AvatarPath(Icon) then self:Load(Icon) end
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
        Def.BitmapText { Name="Title", Font="Montserrat extrabold 40px", Text=S("NewProfile"), InitCommand=function(self) self:y(-78):zoom(0.6):diffuse(color("#46e0ff")):shadowlength(1) end },
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
                -- the center key sits in the highlight box; neighbours shrink so DEL / OK / SPC never touch
                local X = Center and 0 or ((o < 0 and -1 or 1) * (48 + (math.abs(o) - 1) * 33))
                self:xy(X, 50):zoom(Center and 0.62 or 0.4):diffusealpha(Center and 1 or (1 - math.abs(o) * 0.22)):shadowlength(1)
                    :maxwidth((Center and 46 or 28) / (Center and 0.62 or 0.4))
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

-- The profile editor inside the card: choose a profile, then a menu, then the photo row
local PhotoOffsets = { -2, -1, 0, 1, 2 }
local function EditorFrame()
    local t = Def.ActorFrame {
        Name="Editor",
        InitCommand=function(self) self:visible(false) end,
        Def.BitmapText { Name="Title", Font="Montserrat extrabold 40px", InitCommand=function(self) self:y(-78):zoom(0.6):maxwidth((CardItemW - 20) / 0.6):diffuse(color("#46e0ff")):shadowlength(1) end },
        Def.ActorFrame {
            Name="Pick",
            Def.Sprite { Name="Avatar", Texture=GenericIcon, InitCommand=function(self) self:y(-12) end },
            Def.BitmapText { Name="Name", Font="Montserrat semibold 40px", InitCommand=function(self) self:y(48):zoom(0.75):maxwidth((CardItemW - 60) / 0.75):shadowlength(1) end },
            Def.BitmapText { Name="Count", Font="Montserrat normal 20px", InitCommand=function(self) self:y(74):zoom(0.7):diffusealpha(0.7) end },
            Def.BitmapText { Font="Montserrat extrabold 40px", Text="<", InitCommand=function(self) self:xy(-108, -12):zoom(0.8):diffuse(color("#ffe600")) end },
            Def.BitmapText { Font="Montserrat extrabold 40px", Text=">", InitCommand=function(self) self:xy(108, -12):zoom(0.8):diffuse(color("#ffe600")) end },
        },
        Def.ActorFrame {
            Name="Menu",
            Def.Quad { Name="Cursor", InitCommand=function(self) self:zoomto(CardItemW - 30, 40):diffuse(color("#ffe600")):diffusealpha(0.25) end },
            Def.BitmapText { Name="Option1", Font="Montserrat extrabold 40px", Text=S("EditName"), InitCommand=function(self) self:y(-12):zoom(0.6):shadowlength(1) end },
            Def.BitmapText { Name="Option2", Font="Montserrat extrabold 40px", Text=S("EditPhoto"), InitCommand=function(self) self:y(42):zoom(0.6):shadowlength(1) end },
        },
        Def.ActorFrame {
            Name="Photo",
            Def.Quad { InitCommand=function(self) self:y(-8):zoomto(84, 84):diffuse(color("#ffe600")) end },
            Def.Quad { InitCommand=function(self) self:y(-8):zoomto(78, 78):diffuse(color("#202838")) end },
            Def.BitmapText { Name="Label", Font="Montserrat semibold 20px", InitCommand=function(self) self:y(52):zoom(0.8):maxwidth((CardItemW - 20) / 0.8):shadowlength(1) end },
        },
        Def.BitmapText { Name="Msg", Font="Montserrat semibold 20px", InitCommand=function(self) self:y(90):zoom(0.7):diffuse(color("#ff6a5c")):shadowlength(1) end },
        Def.BitmapText { Font="Montserrat normal 20px", Text=S("EditHint"), InitCommand=function(self) self:y(118):zoom(0.62):wrapwidthpixels((CardItemW - 10) / 0.62):shadowlength(1) end },
    }
    local Photo = t[4]
    for _, o in ipairs(PhotoOffsets) do
        Photo[#Photo + 1] = Def.Sprite { Name="Photo" .. o, Texture=GenericIcon, InitCommand=function(self) self:diffusealpha(o == 0 and 1 or 0.55) end }
    end
    return t
end

local function FitIcon(Sprite, Path, Size, X, Y)
    Sprite:Load(AvatarPath(Path) or GenericIcon)
    Sprite:scaletofit(-Size / 2, -Size / 2, Size / 2, Size / 2):xy(X, Y)
end

local function DrawKeyboard(KBFrame, State, Title, Msg)
    KBFrame:GetChild("Title"):settext(Title)
    KBFrame:GetChild("Name"):settext(State.Name)
    local Width = KBFrame:GetChild("Name"):GetZoomedWidth()
    KBFrame:GetChild("Caret"):x(Width / 2 + 4)
    for _, o in ipairs(KeyOffsets) do KBFrame:GetChild("Key" .. o):settext(KeyText(Keyboard.At(State, o))) end
    KBFrame:GetChild("Msg"):settext(Msg or "")
end

local function MsgText(Msg)
    if Msg == "empty" then return S("NameEmpty") end
    if Msg == "full" then return S("NameFull") end
    return Msg
end

local function DrawEditor(Frame, E)
    local KBFrame, EdFrame = Frame:GetChild("KB"), Frame:GetChild("Editor")
    if E.Mode == "name" then
        EdFrame:visible(false)
        KBFrame:visible(true)
        DrawKeyboard(KBFrame, E.KB, S("EditName"), MsgText(E.Msg))
        return
    end
    KBFrame:visible(false)
    EdFrame:visible(true)
    local P = Editor.Profile(E)
    EdFrame:GetChild("Title"):settext(E.Mode == "pick" and S("EditProfile") or P.Name)
    EdFrame:GetChild("Msg"):settext(MsgText(E.Msg) or "")
    local Pick, Menu, Photo = EdFrame:GetChild("Pick"), EdFrame:GetChild("Menu"), EdFrame:GetChild("Photo")
    Pick:visible(E.Mode == "pick"); Menu:visible(E.Mode == "menu"); Photo:visible(E.Mode == "photo")
    if E.Mode == "pick" then
        FitIcon(Pick:GetChild("Avatar"), P.Avatar, 84, 0, -12)
        Pick:GetChild("Name"):settext(P.Name)
        Pick:GetChild("Count"):settext(E.Pick .. "/" .. #E.Profiles)
    elseif E.Mode == "menu" then
        Menu:GetChild("Cursor"):y(E.Menu == 1 and -12 or 42)
    else
        local n = #E.Photos
        for _, o in ipairs(PhotoOffsets) do
            local Choice = E.Photos[((E.Photo - 1 + o) % n) + 1]
            local Size = o == 0 and 72 or 44
            local X = o == 0 and 0 or ((o < 0 and -1 or 1) * (66 + (math.abs(o) - 1) * 46))
            FitIcon(Photo:GetChild("Photo" .. o), Choice.Path, Size, X, -8)
        end
        local Choice = E.Photos[E.Photo]
        Photo:GetChild("Label"):settext(Choice.Path == "" and S("NoPhoto") or (Choice.Name:gsub("%.%w+$", "")))
    end
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
        EditorFrame(),
        -- READY over the chosen row once the player confirmed (red panels take it back)
        Def.ActorFrame {
            Name="ReadyStamp",
            InitCommand=function(self) self:xy(CardItemW / 2 - 40, 27):visible(false) end,
            ReadyArt[Player] and Def.Sprite { Texture=ReadyArt[Player], InitCommand=function(self) self:zoom(0.45) end }
                or Def.BitmapText { Font="Montserrat extrabold 40px", Text="READY", InitCommand=function(self) self:zoom(0.6):diffuse(color("#ffe600")):shadowlength(2) end },
        },
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
    local E = Edit[Player]
    List:visible(State == nil and E == nil)
    Frame:GetChild("SmallFrame"):visible(State == nil and E == nil)
    KBFrame:visible(State ~= nil)
    Frame:GetChild("Editor"):visible(false)

    if E then
        Frame:GetChild("ReadyStamp"):visible(false)
        DrawEditor(Frame, E)
        return
    end
    if State then
        Frame:GetChild("ReadyStamp"):visible(false)
        DrawKeyboard(KBFrame, State, S("NewProfile"), State.Msg)
        return
    end

    Frame:GetChild("ReadyStamp"):visible(Ready[Player] == true)
    List:diffusealpha(Ready[Player] and 0.6 or 1)

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
local function OtherIndex(pn)
    local Other = pn == PLAYER_1 and PLAYER_2 or PLAYER_1
    if not GAMESTATE:IsHumanPlayer(Other) then return nil end
    return SCREENMAN:GetTopScreen():GetProfileIndex(Other)
end

local function MoveCursor(pn, Dir)
    local Items = Visible()
    local i = Cursor[pn]
    while true do
        i = i + Dir
        local Item = Items[i]
        if not Item then return false end
        if Item.Kind == "create" then Cursor[pn] = i return true end
        -- a profile the other player holds is skipped (guest is always allowed)
        if Confirm.Allowed(Item.Engine, OtherIndex(pn)) and SCREENMAN:GetTopScreen():SetProfileIndex(pn, Item.Engine) then
            Cursor[pn] = i return true
        end
    end
end

-- Everyone confirmed: load the chosen profiles (guests stay without one) and move on
local function Proceed()
    local Screen = SCREENMAN:GetTopScreen()
    local Players = {}
    for _, pn in ipairs(GAMESTATE:GetHumanPlayers()) do
        local Index = Screen:GetProfileIndex(pn)
        Players[pn] = { Ready = Ready[pn] == true, Index = Index, ID = Index > 0 and PROFILEMAN:GetLocalProfileIDFromIndex(Index - 1) or nil }
    end
    local Plan = Confirm.Plan(Players)
    if not Plan then return end
    setenv("IsBasicMode", Plan.AllGuest)
    if not Plan.AllGuest then
        for pn, ID in pairs(Plan.DefaultIDs) do
            PREFSMAN:SetPreference("DefaultLocalProfileID" .. ToEnumShortString(pn), ID)
        end
        GAMESTATE:LoadProfiles(true)
    end
    Screen:StartTransitioningScreen("SM_GoToNextScreen")
end

-- Put the cursor on the profile the engine has for this player
local function SyncCursor(pn)
    local Engine = SCREENMAN:GetTopScreen():GetProfileIndex(pn)
    -- nothing chosen yet, or the profile the other player already starts on: guest
    if Engine < 0 or not Confirm.Allowed(Engine, OtherIndex(pn)) then
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

-- Profile editor: open with the editable profiles, apply its actions
local function OpenEditor(pn)
    local Profiles = {}
    for _, Item in ipairs(Visible()) do
        if Item.Kind == "profile" then
            local ID = PROFILEMAN:GetLocalProfileIDFromIndex(Item.Engine - 1)
            Profiles[#Profiles + 1] = { Index = Item.Engine - 1, Name = Item.Name,
                Avatar = LoadModule("Config.Load.lua")("AvatarImage", "/Save/LocalProfiles/" .. ID .. "/OutFoxPrefs.ini") or "" }
        end
    end
    if #Profiles == 0 then return end
    Edit[pn] = Editor.New(Profiles, Avatars)
    MESSAGEMAN:Broadcast("StartButton")
end

local function ApplyEdit(Action)
    local ID = PROFILEMAN:GetLocalProfileIDFromIndex(Action.Index)
    if Action.Do == "rename" then
        PROFILEMAN:GetLocalProfileFromIndex(Action.Index):SetDisplayName(Action.Name)
        PROFILEMAN:SaveLocalProfile(ID)
    elseif Action.Do == "photo" then
        LoadModule("Config.Save.lua")("AvatarImage", Action.Path, "/Save/LocalProfiles/" .. ID .. "/OutFoxPrefs.ini")
        -- the photo in both players' lists
        for _, Name in ipairs({ "P1Frame", "P2Frame" }) do
            local Card = Root:GetChild(Name):GetChild("List"):GetChild("Profile" .. Action.Index)
            if Card then FitIcon(Card:GetChild("Icon"), Action.Path, 64, -CardItemW / 2 + 32, -3) end
        end
    end
end

local function EditorInput(pn, Button, First)
    local E = Edit[pn]
    if LOWER_LEFT[Button] then Editor.Move(E, -1) MESSAGEMAN:Broadcast("DirectionButton")
    elseif LOWER_RIGHT[Button] then Editor.Move(E, 1) MESSAGEMAN:Broadcast("DirectionButton")
    elseif not First then return
    elseif UPPER[Button] or Button == "Back" then
        if Editor.Back(E) == "close" then Edit[pn] = nil end
        MESSAGEMAN:Broadcast("BackButton")
    elseif CENTER[Button] then
        local Action = Editor.Press(E)
        if Action then
            ApplyEdit(Action)
            MESSAGEMAN:Broadcast("ProfileCreated", { Player = pn })
        else
            MESSAGEMAN:Broadcast(E.Msg and "BackButton" or "StartButton")
        end
    end
end

-- With two players the red panels drop one; the other one moves on if already READY
local function DropPlayer(pn)
    if GAMESTATE:GetNumSidesJoined() < 2 then return end
    Ready[pn], KB[pn], Edit[pn] = nil, nil, nil
    SCREENMAN:GetTopScreen():SetProfileIndex(pn, -2)
    -- joined from song select: back to a one-player style (Profile.Confirm.StyleAfterDrop)
    local Style = GAMESTATE:GetCurrentStyle()
    local OnePlayer = Confirm.StyleAfterDrop(Style and Style:GetStyleType())
    if OnePlayer then GAMESTATE:SetCurrentStyle(OnePlayer) end
    MESSAGEMAN:Broadcast("BackButton")
    Proceed()
end

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn or event.type == "InputEventType_Release" then return end
    -- OutFox: event.button is the pad panel, event.GameButton the menu button
    local Button = event.button or event.GameButton
    local First = event.type == "InputEventType_FirstPress"

    if Edit[pn] then
        EditorInput(pn, Button, First)
        Root:queuecommand("UpdateInternal2")
        return
    end
    if KB[pn] then
        KeyboardInput(pn, Button, First)
        Root:queuecommand("UpdateInternal2")
        return
    end
    if not First then return end
    local CodeDone = GAMESTATE:IsHumanPlayer(pn) and Code.Press(EditCode, pn, Button, GetTimeSinceStart())

    if CENTER[Button] then
        if not GAMESTATE:IsHumanPlayer(pn) then
            SCREENMAN:GetTopScreen():SetProfileIndex(pn, -1)
            return
        end
        if Ready[pn] then return end
        local Item = Visible()[Cursor[pn]]
        MESSAGEMAN:Broadcast("StartButton")
        if Item and Item.Kind == "create" then
            KB[pn] = Keyboard.New()
        else
            Ready[pn] = true
            Proceed()
        end
        Root:queuecommand("UpdateInternal2")
    elseif UPPER[Button] and Ready[pn] then
        Ready[pn] = nil
        MESSAGEMAN:Broadcast("BackButton")
        Root:queuecommand("UpdateInternal2")
    elseif UPPER[Button] and GAMESTATE:IsHumanPlayer(pn) then
        DropPlayer(pn)
        Root:queuecommand("UpdateInternal2")
    elseif Ready[pn] then
        return
    elseif LOWER_LEFT[Button] and GAMESTATE:IsHumanPlayer(pn) then
        if MoveCursor(pn, -1) then MESSAGEMAN:Broadcast("DirectionButton") end
    elseif LOWER_RIGHT[Button] and GAMESTATE:IsHumanPlayer(pn) then
        if MoveCursor(pn, 1) then MESSAGEMAN:Broadcast("DirectionButton") end
    elseif Button == "Back" or event.GameButton == "Back" then
        SCREENMAN:GetTopScreen():Cancel()
    end
    if CodeDone and not Ready[pn] and not KB[pn] then
        OpenEditor(pn)
        Root:queuecommand("UpdateInternal2")
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
