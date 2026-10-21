-- Group select in the Phoenix layout: one row of five hexagonal cards (plus one
-- hidden slot on each side so every visible card slides). The two levels
-- (sorting category -> subgroup) are kept: the green title shows the current
-- category, the cards show its subgroups; the top pad panels move the focus to
-- the categories, which are then shown as cards themselves. Input handling,
-- busy state, saved indexes and messages are unchanged.
local Cards = LoadModule("Select.GroupCards.lua")
local Wheel = LoadModule("Select.Wheel.lua")
local Info = LoadModule("GroupInfo.lua")(function(key) return THEME:GetString("GroupInfo", key) end)

local CardCount = 7           -- 5 visible + 2 off-screen slots
local CardCenter = 4
local CardSpacing = 230
local CardSize = 200          -- hexagon box of a normal card
local CenterZoom = 1.35
local CardY = SCREEN_CENTER_Y + 20

local MenuButtonsOnly = PREFSMAN:GetPreference("OnlyDedicatedMenuButtons")

-- Not load anything if no group sorts are available (catastrophic event or no songs)
if next(GroupsList) == nil then
    AssembleGroupSorting()
    UpdateGroupSorting()

    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible, halting music wheel!")
        return Def.Actor {}
    end
end

-- So that we can grab the Cur screen and use it outside an actor
local ScreenSelectMusic

-- Used for quitting the game
local IsHome = GAMESTATE:GetCoinMode() == "CoinMode_Home"
local IsEvent = GAMESTATE:IsEventMode()
local TickCount = 0 -- Used for InputEventType_Repeat

local IsOptionsList = { PLAYER_1 = false, PLAYER_2 = false }
local IsSelectingGroup = false
local IsBusy = false
local IsFocusedMain = false

LastGroupMainIndex = tonumber(LoadModule("Config.Load.lua")("GroupMainIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 0
LastGroupSubIndex = tonumber(LoadModule("Config.Load.lua")("GroupSubIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 0
LastSongIndex = tonumber(LoadModule("Config.Load.lua")("SongIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 0
--reset LastGroup/Sub/Song if they were deleted since last session to avoid "attempt to index nil" crashes
if GroupsList[LastGroupMainIndex] == nil then
    LastGroupMainIndex = 1
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull overlay / GroupSelect.lua: LastGroupMainIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex] == nil then
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull overlay / GroupSelect.lua: LastGroupSubIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex].Songs == nil then
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull overlay / GroupSelect.lua: LastSongIndex no longer, reset performed")
end

-- Create the variables necessary for both wheels
local CurMainIndex = LastGroupMainIndex > 0 and LastGroupMainIndex or 1
local CurSubIndex = LastGroupSubIndex > 0 and LastGroupSubIndex or 1
local MainTargets = {}
local SubTargets = {}

local function BlockScreenInput(State)
    --SCREENMAN:set_input_redirected(PLAYER_1, State)
    --SCREENMAN:set_input_redirected(PLAYER_2, State)
end

-- If no songs don't load anything
if SONGMAN:GetNumSongs() == 0 then
    return Def.Actor {}
else

-- Update Group item targets
local function UpdateMainItemTargets(val)
    for i = 1, CardCount do
        MainTargets[i] = val + i - CardCenter
        -- Wrap to fit to list size
        while MainTargets[i] > #GroupsList do MainTargets[i] = MainTargets[i] - #GroupsList end
        while MainTargets[i] < 1 do MainTargets[i] = MainTargets[i] + #GroupsList end
    end
end

local function UpdateSubItemTargets(val)
    for i = 1, CardCount do
        SubTargets[i] = val + i - CardCenter
        -- Wrap to fit to list size
        while SubTargets[i] > #GroupsList[CurMainIndex].SubGroups do SubTargets[i] = SubTargets[i] - #GroupsList[CurMainIndex].SubGroups end
        while SubTargets[i] < 1 do SubTargets[i] = SubTargets[i] + #GroupsList[CurMainIndex].SubGroups end
    end
end

-- What card slot i shows right now: category or subgroup of the current category
local function CardData(i)
    if IsFocusedMain then
        local Name = GroupsList[MainTargets[i]].Name
        return { Category = nil, Name = Name, Banner = "" }
    end
    local Sub = GroupsList[CurMainIndex].SubGroups[SubTargets[i]]
    return { Category = GroupsList[CurMainIndex].Name, Name = Sub.Name, Banner = Sub.Banner or "" }
end

local function CategoryLabel(Name)
    local s = THEME:GetString("GroupSelect", "Name_" .. Name)
    if s == "" then s = Name end
    return ToUpper(s)
end

local ThemeDir = "/Themes/" .. THEME:GetCurThemeName() .. "/"
local function HasThemeFile(RelPath) return FILEMAN:DoesFileExist(ThemeDir .. RelPath) end

-- XSanity card art (local only, never in the public repo): level and special cards
-- LEVEL_25 is XSanity's "CO-OP PLAY" card
local SpecialArt = { ["All Tunes"] = "ALLTUNES", ["Shortcut"] = "SHORTCUT", ["Remix"] = "REMIX", ["Full Song"] = "FULLSONGS", ["Co-op"] = "LEVEL_25" }
local function CardArt(Data)
    local Kind = Cards.Kind(Data.Category, Data.Name)
    local File
    if Kind == "version" then
        return Cards.Image(Data.Category, Data.Name, Data.Banner), "banner"
    elseif Kind == "level" then
        -- LEVEL_01..LEVEL_24 are level cards; LEVEL_25 is XSanity's co-op card, so 25+ fall back to text
        local Meter = tonumber(Data.Name:match("(%d+)$") or 0)
        if Meter >= 1 and Meter <= 24 then File = string.format("ChanGraph/LEVEL_%02d", Meter) end
    elseif Kind == "special" and SpecialArt[Data.Name] then
        File = "ChanGraph/" .. SpecialArt[Data.Name]
    end
    if File and HasThemeFile("Graphics/XSanity/" .. File .. ".png") then
        return THEME:GetPathG("", "XSanity/" .. File), "card"
    end
    return nil, "text"
end

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn then return end

    -- Don't want to move when releasing the button
    if event.type == "InputEventType_Release" then
        TickCount = 0
        MESSAGEMAN:Broadcast("ExitTickDown")
        return
    end

    local button = event.GameButton

    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

    if IsSelectingGroup then
        if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
            if IsFocusedMain then
                CurMainIndex = CurMainIndex - 1
                if CurMainIndex < 1 then CurMainIndex = #GroupsList end
                UpdateMainItemTargets(CurMainIndex)

                CurSubIndex = 1
                UpdateSubItemTargets(CurSubIndex)

                MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
                MESSAGEMAN:Broadcast("RefreshSub")
            else
                CurSubIndex = CurSubIndex - 1
                if CurSubIndex < 1 then CurSubIndex = #GroupsList[CurMainIndex].SubGroups end

                UpdateSubItemTargets(CurSubIndex)

                MESSAGEMAN:Broadcast("ScrollSub", { Direction = -1 })
            end

        elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
            if IsFocusedMain then
                CurMainIndex = CurMainIndex + 1
                if CurMainIndex > #GroupsList then CurMainIndex = 1 end
                UpdateMainItemTargets(CurMainIndex)

                CurSubIndex = 1
                UpdateSubItemTargets(CurSubIndex)

                MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
                MESSAGEMAN:Broadcast("RefreshSub")
            else
                CurSubIndex = CurSubIndex + 1
                if CurSubIndex > #GroupsList[CurMainIndex].SubGroups then CurSubIndex = 1 end

                UpdateSubItemTargets(CurSubIndex)

                MESSAGEMAN:Broadcast("ScrollSub", { Direction = 1 })
            end
        elseif button == "Start" or button == "MenuStart" or button == "Center" then
            if IsFocusedMain then
                IsFocusedMain = false
                if CurSubIndex > #GroupsList[CurMainIndex].SubGroups then CurSubIndex = 1 end
                UpdateSubItemTargets(CurSubIndex)
                MESSAGEMAN:Broadcast("RefreshHighlight")
            else
                if CurMainIndex == LastGroupMainIndex and CurSubIndex == LastGroupSubIndex then
                    MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = true })
                else
                    GroupIndex = CurMainIndex
                    SubGroupIndex = CurSubIndex

                    -- Save this for later
                    LastGroupMainIndex = CurMainIndex
                    LastGroupSubIndex = CurSubIndex

                    LoadModule("Config.Save.lua")("GroupMainIndex", LastGroupMainIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
                    LoadModule("Config.Save.lua")("GroupSubIndex", LastGroupSubIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")

                    MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = false })
                end
            end

        elseif button == "UpRight" or button == "UpLeft" or button == "Up" or button == "MenuUp" or button == "MenuDown" then
            if not IsFocusedMain then
                IsFocusedMain = true
                MESSAGEMAN:Broadcast("RefreshHighlight")
            elseif IsHome or IsEvent then
                if event.type == "InputEventType_Repeat" then
                    TickCount = TickCount + 1
                    MESSAGEMAN:Broadcast("ExitTickUp")
                    if TickCount == 15 then
                        BlockScreenInput(false)
                        SCREENMAN:GetTopScreen():Cancel()
                    end
                else
                    MESSAGEMAN:Broadcast("ExitPressed")
                end
            end
        end
    end
end

-- Side arrows: XSanity art when present, text otherwise (the art is not in the repo)
local function SideArrow(Dir)
    local X = SCREEN_CENTER_X + Dir * 360
    if HasThemeFile("Graphics/XSanity/SSM-FULLARROWS 2x1.png") then
        return Def.Sprite {
            Texture=THEME:GetPathG("", "XSanity/SSM-FULLARROWS 2x1"),
            InitCommand=function(self)
                self:xy(X, CardY):animate(false):setstate(Dir < 0 and 0 or 1):zoom(1.2):diffuse(color("#3cff5c"))
                :bounce():effectmagnitude(Dir * 8, 0, 0):effectclock("bgm")
            end,
        }
    end
    return Def.BitmapText {
        Font="Montserrat extrabold 40px",
        Text=Dir < 0 and "<" or ">",
        InitCommand=function(self)
            self:xy(X, CardY):zoom(1.4):diffuse(color("#3cff5c")):shadowlength(2)
            :bounce():effectmagnitude(Dir * 8, 0, 0):effectclock("bgm")
        end,
    }
end

local t = Def.ActorFrame {
    InitCommand=function(self)
        self:diffusealpha(0)
        UpdateMainItemTargets(CurMainIndex)
        UpdateSubItemTargets(CurSubIndex)
    end,

    OnCommand=function(self)
        BlockScreenInput(false)
        ScreenSelectMusic = SCREENMAN:GetTopScreen()
        ScreenSelectMusic:AddInputCallback(InputHandler)
    end,

    OffCommand=function(self) BlockScreenInput(false) end,

    SongChosenMessageCommand=function(self) self:queuecommand("Busy") end,
    SongUnchosenMessageCommand=function(self) self:sleep(0.01):queuecommand("NotBusy") end,

    OptionsListOpenedMessageCommand=function(self, params) IsOptionsList[params.Player] = true end,
    OptionsListClosedMessageCommand=function(self, params) IsOptionsList[params.Player] = false end,

    CodeMessageCommand=function(self, params)
        if params.Name == "GroupSelectPad1" or params.Name == "GroupSelectPad2" or
        params.Name == "GroupSelectButton1" or params.Name == "GroupSelectButton2" then
            -- The same panels switch focus once the wheel is open (handled in InputHandler)
            if not IsSelectingGroup and not IsBusy and not IsOptionsList[PLAYER_1] and not IsOptionsList[PLAYER_2] then
                -- Prevent the song list from moving when transitioning
                BlockScreenInput(true)
                MESSAGEMAN:Broadcast("OpenGroupWheel")
                self:stoptweening():sleep(0.01):queuecommand("OpenGroup"):easeoutexpo(1):diffusealpha(1)
            end
        end
    end,

    BusyCommand=function(self) IsBusy = true end,
    NotBusyCommand=function(self) IsBusy = false end,

    OpenGroupCommand=function(self)
        IsSelectingGroup = true
        -- the wheel opens on the subgroups of the current category
        IsFocusedMain = false
        UpdateSubItemTargets(CurSubIndex)
        MESSAGEMAN:Broadcast("RefreshHighlight")
    end,
    CloseGroupCommand=function(self) IsSelectingGroup = false end,

    CloseGroupWheelMessageCommand=function(self, params)
        self:stoptweening():easeoutexpo(0.25):diffusealpha(0)

        BlockScreenInput(false)
        IsSelectingGroup = false

        if params.Silent == false then
            -- The built in wheel needs to be told the group has been changed
            ScreenSelectMusic:PostScreenMessage("SM_SongChanged", 0 )
            MESSAGEMAN:Broadcast("StartSelectingSong")
        end
    end,

    Def.Sound {
        File=THEME:GetPathS("MusicWheel", "change"),
        IsAction=true,
        ScrollMainMessageCommand=function(self) self:play() end,
        ScrollSubMessageCommand=function(self, params) if params.Direction ~= 0 then self:play() end end
    },

    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        CloseGroupWheelMessageCommand=function(self) self:play() end
    },

    -- Green title: the current category, or "CATEGORIES" while choosing one
    Def.BitmapText {
        Name="Title",
        Font="Montserrat extrabold 40px",
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, 118):zoom(1):diffuse(color("#3cff5c")):shadowlength(2):maxwidth(900)
        end,
        OnCommand=function(self) self:playcommand("Refresh") end,
        RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
        ScrollMainMessageCommand=function(self) self:playcommand("Refresh") end,
        RefreshCommand=function(self)
            self:settext(IsFocusedMain and ToUpper(THEME:GetString("GroupSelect", "Categories")) or CategoryLabel(GroupsList[CurMainIndex].Name))
        end,
    },

    -- Description of the centered card
    Def.BitmapText {
        Name="Description",
        Font="Montserrat semibold 20px",
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM - 92):zoom(0.9):shadowlength(1):maxwidth(900 / 0.9)
        end,
        OnCommand=function(self) self:playcommand("Refresh") end,
        RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
        ScrollMainMessageCommand=function(self) self:playcommand("Refresh") end,
        ScrollSubMessageCommand=function(self) self:playcommand("Refresh") end,
        RefreshCommand=function(self)
            local Data = CardData(CardCenter)
            self:settext(Info.Describe(Data.Category, Data.Name))
        end,
    },

    SideArrow(-1),
    SideArrow(1),
}

-- The cards. Slot i is rotated on every scroll like the old wheels, so the
-- cards slide; only the hidden end slots (and the slot that wrapped around,
-- which is off-screen on both sides) take new content without animating.
for i = 1, CardCount do
    t[#t+1] = Def.ActorFrame{
        OnCommand=function(self)
            self:playcommand("Rebuild")
            self:playcommand("Place", { Direction = 0 })
        end,

        -- Category scrolled (subgroup list changed) or focus switched: new content, no slide
        RefreshSubMessageCommand=function(self) if not IsFocusedMain then self:playcommand("Rebuild") end end,
        RefreshHighlightMessageCommand=function(self)
            self:playcommand("Rebuild")
            self:playcommand("Place", { Direction = 0 })
        end,

        ScrollMainMessageCommand=function(self, params) if IsFocusedMain then self:playcommand("Place", params) end end,
        ScrollSubMessageCommand=function(self, params) if not IsFocusedMain then self:playcommand("Place", params) end end,

        PlaceCommand=function(self, params)
            self:stoptweening()
            local tween = params and params.Direction and math.abs(params.Direction) > 0
            local Previous = i

            -- Adjust and wrap slot index
            i = i - params.Direction
            while i > CardCount do i = i - CardCount end
            while i < 1 do i = i + CardCount end

            local Wrapped = math.abs(i - Previous) > 1
            if i == 1 or i == CardCount or Wrapped then
                self:playcommand("Rebuild")
            elseif tween then
                self:easeoutexpo(0.3)
            end

            -- short lists: hide the slots that would repeat a card
            local Count = IsFocusedMain and #GroupsList or #GroupsList[CurMainIndex].SubGroups
            self:visible(Wheel.SlotVisible(i - CardCenter, Count))

            local Dist = math.abs(i - CardCenter)
            self:xy(SCREEN_CENTER_X + (i - CardCenter) * CardSpacing, CardY)
            :zoom(i == CardCenter and CenterZoom or (Dist == 1 and 1 or 0.8))
            :diffusealpha(i == CardCenter and 1 or (Dist == 1 and 0.85 or 0.45))
            self:GetChild("Ring"):playcommand("Refresh", { Center = i == CardCenter })
        end,

        RebuildCommand=function(self)
            local Data = CardData(i)
            local Kind = Cards.Kind(Data.Category, Data.Name)
            local Path, Source = CardArt(Data)
            local Image, Card, Label, Big = self:GetChild("Image"), self:GetChild("Card"), self:GetChild("Label"), self:GetChild("Big")
            Image:visible(false); Card:visible(false)
            if Path and Source == "banner" then
                -- the 17 version banners are small files: full resolution, cached by the texture manager
                Image:visible(true):Load(Path):scaletocover(-CardSize / 2, -CardSize / 2, CardSize / 2, CardSize / 2)
            elseif Path then
                -- XSanity card art is already hexagon-shaped: fit it whole inside the card
                Card:visible(true):Load(Path):scaletofit(-CardSize / 2, -CardSize / 2, CardSize / 2, CardSize / 2)
            end
            local Title = Cards.Title(Data.Category, Data.Name)
            if Kind == "category" then Title = CategoryLabel(Data.Name) end
            Big:visible(not Path):settext(Title)
            Label:visible(Path ~= nil):settext(Title)
        end,

        -- Hexagon clip for the banner art
        Def.Sprite {
            Texture=THEME:GetPathG("", "Select/hex_mask"),
            InitCommand=function(self) self:zoomto(CardSize, CardSize):MaskSource() end,
        },
        Def.Sprite {
            Texture=THEME:GetPathG("", "Select/hex_mask"),
            InitCommand=function(self) self:zoomto(CardSize, CardSize):diffuse(color("#0b1220")) end,
        },
        Def.Sprite {
            Name="Image",
            InitCommand=function(self) self:MaskDest():ztestmode("ZTestMode_WriteOnFail") end,
        },
        Def.Sprite {
            Name="Card",
        },
        -- Ring: white on normal cards, cycling colors on the centered one
        Def.Sprite {
            Name="Ring",
            Texture=THEME:GetPathG("", "Select/hex_frame"),
            InitCommand=function(self) self:zoomto(CardSize + 12, CardSize + 12) end,
            RefreshCommand=function(self, params)
                if params.Center then
                    self:diffuseshift():effectcolor1(color("#ff2d9a")):effectcolor2(color("#3cff5c")):effectperiod(1.2)
                else
                    self:stopeffect():diffuse(Color.White):diffusealpha(0.7)
                end
            end,
        },
        -- Text inside the hexagon when there is no art (categories, letters, co-op)
        Def.BitmapText {
            Name="Big",
            Font="Montserrat extrabold 40px",
            InitCommand=function(self) self:zoom(0.85):maxwidth((CardSize - 24) / 0.85):wrapwidthpixels((CardSize - 24) / 0.85):vertspacing(-10):shadowlength(2) end,
        },
        -- Label under the card when there is art
        Def.BitmapText {
            Name="Label",
            Font="Montserrat extrabold 40px",
            InitCommand=function(self) self:y(CardSize / 2 + 30):zoom(0.6):maxwidth((CardSpacing + 20) / 0.6):shadowlength(2) end,
        },
    }
end

t[#t+1] = Def.ActorFrame {
    Def.BitmapText {
        Font="Montserrat semibold 20px",
        Name="ExitText",
        InitCommand=function(self)
            self:diffusealpha(0)
            :xy(SCREEN_CENTER_X, SCREEN_CENTER_Y - 125)
            :settext(THEME:GetString("GroupSelect", "Exiting"))
        end,
        ExitPressedMessageCommand=function(self)
            self:stoptweening():sleep(0.1)
            :linear(0.25)
            :diffusealpha(1)
        end,
        ExitTickDownMessageCommand=function(self)
            self:stoptweening()
            :easeoutexpo(0.25)
            :diffusealpha(0)
        end
    },

    Def.Quad {
        Name="ExitBar",
        InitCommand=function(self)
            self:zoomto(200,15)
            :cropright(1)
            :xy(SCREEN_CENTER_X, SCREEN_CENTER_Y - 100)
            :diffuse(color("#f7931e")):diffusebottomedge(color("#ed1e79"))
        end,
        ExitTickUpMessageCommand=function(self)
            self:stoptweening()
            :linear(0.2)
            :cropright(1 - (TickCount + 1) / 15)
        end,
        ExitTickDownMessageCommand=function(self)
            self:stoptweening()
            :easeoutexpo(0.25)
            :cropright(1)
        end
    },

    Def.Quad {
        Name="ExitBarEnd",
        InitCommand=function(self)
            self:zoomto(5,15)
            :xy(SCREEN_CENTER_X - 100, SCREEN_CENTER_Y - 100)
            :diffuse(1,1,1,0)
        end,
        ExitPressedMessageCommand=function(self)
            self:sleep(0.2)
            :diffusealpha(1)
            :easeoutquad(0.5)
            :x(SCREEN_CENTER_X + 100)
        end,
        ExitTickDownMessageCommand=function(self)
            self:stoptweening()
            :easeoutquad(0.25)
            :diffusealpha(0)
            :x(SCREEN_CENTER_X - 100)
        end
    }
}

return t

end
