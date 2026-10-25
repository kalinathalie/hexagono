-- XSanity-style graphical command window (stage 1: Speed, Auto Velocity,
-- Note Skin, Exit). Opened by the pad code "OpenOpList"; navigated with the
-- pad only: lower panels move, Center enters/applies, upper panels go back
-- or close. Logic lives in Modules/XSCW.State.lua and
-- Modules/XSCW.Categories.lua; this file only draws and routes input.
--
-- It emits the same messages as the engine options list
-- (OptionsListOpened/Closed/Start) with XSWindow = true, so the wheel, the
-- group wheel, the chart list and the mod icons behave as they already do.

local MenuButtonsOnly = PREFSMAN:GetPreference("OnlyDedicatedMenuButtons")
local NewState = LoadModule("XSCW.State.lua")
local BuildCategories = LoadModule("XSCW.Categories.lua")

local function G(File) return THEME:GetPathG("", "XSCommandWindow/" .. File) end
local function Text(Key) return THEME:GetString("XSCommandWindow", Key) end
local function PrefsFile(pn)
    return CheckIfUserOrMachineProfile(string.sub(pn, -1) - 1) .. "/OutFoxPrefs.ini"
end
local function PlayerOpts(pn)
    return GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
end

-- PlayerOptions accessor per mod name used by the categories
local ModMethod = {
    expand = "Expand", randomspeed = "RandomSpeed", boost = "Boost", brake = "Brake",
    hidden = "Hidden", sudden = "Sudden", stealth = "Stealth", dark = "Dark", mini = "Mini",
}

local Deps = {
    GetAV = function(pn)
        return tonumber(LoadModule("Config.Load.lua")("AutoVelocity", PrefsFile(pn)))
    end,
    SetAV = function(pn, n)
        LoadModule("Config.Save.lua")("AutoVelocity", tostring(n), PrefsFile(pn))
        LoadModule("Player.SetSpeed.lua")(pn)
    end,
    GetAVType = function(pn)
        local T = LoadModule("Config.Load.lua")("AutoVelocityType", PrefsFile(pn))
        if T == "Auto" or T == "Constant" then return T end
        return false
    end,
    SetAVType = function(pn, t)
        LoadModule("Config.Save.lua")("AutoVelocityType", tostring(t), PrefsFile(pn))
        LoadModule("Player.SetSpeed.lua")(pn)
    end,
    GetMod = function(pn, name)
        local PO = PlayerOpts(pn)
        local Value = PO[ModMethod[name]](PO)
        return (tonumber(Value) or 0) > 0
    end,
    SetMod = function(pn, name, on)
        local PO = PlayerOpts(pn)
        PO[ModMethod[name]](PO, on and 1 or 0)
    end,
    GetNoteSkin = function(pn) return PlayerOpts(pn):NoteSkin() end,
    SetNoteSkin = function(pn, name) PlayerOpts(pn):NoteSkin(name) end,
    NoteSkinNames = NOTESKIN:GetNoteSkinNames(),
    -- Infinitesimal per-player preferences (screen filter etc.)
    GetPref = function(pn, key) return LoadModule("Config.Load.lua")(key, PrefsFile(pn)) end,
    SetPref = function(pn, key, value) LoadModule("Config.Save.lua")(key, value, PrefsFile(pn)) end,
    -- Timing windows: a machine preference read when gameplay starts
    GetJudge = function() return LoadModule("Config.Load.lua")("SmartTimings", "Save/OutFoxPrefs.ini") end,
    SetJudge = function(name) LoadModule("Config.Save.lua")("SmartTimings", name, "Save/OutFoxPrefs.ini") end,
    Text = Text,
}

local Categories = BuildCategories(Deps)

-- Phoenix skin: the phyrebird OptionList art (local Graphics/Phoenix/CommandWindow,
-- never in the public repo). Without it the XSanity panel below is used.
local Art = LoadModule("Select.Art.lua")
-- SPEED, DISPLAY, NOTESKIN, ... AUTO VELOCITY; "labels" is the same sheet redrawn at 4x
-- by tools/make_phoenix_labels.py (the Phoenix one is blurry when enlarged) plus JUDGE TIMING
local HDLabels = Art("Phoenix/CommandWindow/labels 1x10")
local PX = {
    Bg = Art("Phoenix/CommandWindow/bg"),                 -- teal "COMMAND" panel with the inner box
    Titles = HDLabels or Art("Phoenix/CommandWindow/MenuIcons 1x9"),
    Icons = Art("Phoenix/CommandWindow/icons 11x11"),     -- option badges
    Badge = Art("Phoenix/CommandWindow/frame"),           -- empty badge for options without art
    Brackets = Art("Phoenix/CommandWindow/arrows_big"),   -- yellow brackets around the cursor
    Glow = Art("Phoenix/CommandWindow/blue"),             -- cyan light behind the cursor
}
local UsePhoenix = PX.Bg and PX.Titles and PX.Icons and PX.Badge and true or false
-- Without either art set (a fresh clone has neither: both are local only) the
-- graphical window stays off and the pad code opens the engine list instead
local HasXSanityArt = Art("XSCommandWindow/bg/bg_1") ~= nil
if not UsePhoenix and not HasXSanityArt then return Def.ActorFrame {} end

-- Phoenix layout, relative to the window center; the panel art is drawn at PZ
local PZ = 1.15
local PLabelY, PValueY, PBoxY, PDescY = -82, -16, 69, 139
local PSlotX = { [-2] = -128, [-1] = -72, [0] = 0, [1] = 72, [2] = 128 }
local PSlotZoom = { [-2] = 0.55, [-1] = 0.8, [0] = 1.12, [1] = 0.8, [2] = 0.55 }
local PSlotAlpha = { [-2] = 0.3, [-1] = 0.75, [0] = 1, [1] = 0.75, [2] = 0.3 }
local PSlotOrder = { 0, -1, 1, -2, 2 }   -- with few options the cursor's own slot wins
local PTitleFrames = HDLabels and 10 or 9
local PTitleW = 140                      -- category name on top, inside a category
local PCatW, PSideW, PSideX = 136, 64, 119   -- category row in the box: current and neighbors
local PSkinZoom = 0.94                   -- noteskin preview zoom relative to a badge
local PYellow = color("#ffe600")
local PDim = { 0.55, 0.6, 0.75, 0.9 }    -- neighbor names, greyed like on Phoenix

-- A category name: its frame of the label sheet, or text when the sheet has none
local function PLabelSlot(Name, X, Y)
    return Def.ActorFrame {
        Name=Name, InitCommand=function(self) self:xy(X, Y) end,
        Def.Sprite { Name="Art", Texture=PX.Titles, InitCommand=function(self) self:animate(false) end },
        Def.BitmapText { Name="Text", Font="Montserrat extrabold 40px", InitCommand=function(self) self:shadowlength(1):visible(false) end },
    }
end

local function PSetLabel(Slot, Category, Width, Dim)
    local Frame = Category.PhoenixTitle
    local HasArt = Frame ~= nil and Frame < PTitleFrames
    local Sprite, Text = Slot:GetChild("Art"), Slot:GetChild("Text")
    Sprite:visible(HasArt)
    Text:visible(not HasArt)
    if HasArt then
        Sprite:setstate(Frame):zoom(Width / Sprite:GetWidth()):diffuse(Dim and PDim or color("1,1,1,1"))
    else
        Text:settext(string.upper(Category.Label or Category.Name)):zoom(1)
        Text:zoom(math.min(0.75, Width / math.max(1, Text:GetWidth()))):diffuse(Dim and PDim or PYellow)
    end
end

-- Distinct icon sheets used by the categories (one sprite per sheet per slot)
local Sheets = {}
for _, Category in ipairs(Categories) do
    for _, Item in ipairs(Category.Items or {}) do
        if Item.Sheet and not Sheets[Item.Sheet] then
            Sheets[Item.Sheet] = true
            Sheets[#Sheets + 1] = Item.Sheet
        end
    end
end

-- Layout (relative to the window frame center)
local FrameW, FrameH = 320, 420
local TitleY, ItemsY, ValueY, DescY = -115, 10, 72, 138
local SlotOffsets = { -2, -1, 0, 1, 2 }
local SlotX = { [-2] = -124, [-1] = -74, [0] = 0, [1] = 74, [2] = 124 }
local SlotZoom = { [-2] = 0.28, [-1] = 0.42, [0] = 0.7, [1] = 0.42, [2] = 0.28 }
local SlotAlpha = { [-2] = 0.45, [-1] = 0.8, [0] = 1, [1] = 0.8, [2] = 0.45 }

local States = {}
local CanOpen = { PlayerNumber_P1 = true, PlayerNumber_P2 = true }
local GroupWheelOpen = false
local SongIsChosen = false

local function Wrap(Index, Count)
    if Count <= 0 then return 1 end
    return ((Index - 1) % Count) + 1
end

local function AnyOpen()
    for _, S in pairs(States) do if S.Open then return true end end
    return false
end

-- The engine reports the pad panels either by their pump names or by the
-- menu buttons they map to, depending on the input path; accept both.
local LowerDir = { DownLeft = -1, DownRight = 1, MenuLeft = -1, MenuRight = 1, Left = -1, Right = 1 }
local UpperButtons = { UpLeft = true, UpRight = true, MenuUp = true, MenuDown = true, Up = true, Back = true }
local CenterButtons = { Center = true, Start = true, MenuStart = true }

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn then return end
    local S = States[pn]
    if not S or not S.Open then return end

    local Frame = S.Frame
    local button = event.GameButton
    local menu = event.button
    local Press = event.type == "InputEventType_FirstPress"
    local Repeat = event.type == "InputEventType_Repeat"
    local Dir = LowerDir[button] or LowerDir[menu]

    if Dir and (Press or Repeat) then
        if S:Move(Dir) then
            Frame:playcommand("Moved")
        end
    elseif (CenterButtons[button] or CenterButtons[menu]) and Press then
        local Result = S:Enter()
        if Result == "apply" then
            local Item = S:CurrentItem()
            if Item then
                Item.Apply(pn)
                MESSAGEMAN:Broadcast("OptionsListStart", { Player = pn, XSWindow = true })
                Frame:playcommand("Applied")
            end
        elseif Result == "enter" then
            Frame:playcommand("Moved")
        elseif Result == "close" then
            Frame:playcommand("CloseWindow")
        end
    elseif (UpperButtons[button] or UpperButtons[menu]) and Press then
        if S:Back() == "close" then
            Frame:playcommand("CloseWindow")
        else
            Frame:playcommand("Moved")
        end
    end
    -- Swallow everything from this player while the window is open
    return true
end

local t = Def.ActorFrame {
    OnCommand=function(self)
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
    end,
    OffCommand=function(self)
        for _, S in pairs(States) do S:CloseWindow() end
    end,

    OpenGroupWheelMessageCommand=function(self) GroupWheelOpen = true end,
    CloseGroupWheelMessageCommand=function(self) GroupWheelOpen = false end,
    SongChosenMessageCommand=function(self) SongIsChosen = true end,
    SongUnchosenMessageCommand=function(self) SongIsChosen = false end,

    Def.Sound { File=THEME:GetPathS("", "OpenCommandWindow"), XSCWOpenMessageCommand=function(self) self:play() end },
    Def.Sound { File=THEME:GetPathS("", "CloseCommandWindow"), XSCWCloseMessageCommand=function(self) self:play() end },
    Def.Sound { File=THEME:GetPathS("", "MoveCommandWindow"), XSCWMoveMessageCommand=function(self) self:play() end },
    Def.Sound { File=THEME:GetPathS("", "StartCommandWindow"), XSCWApplyMessageCommand=function(self) self:play() end },
}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    local S = NewState(Categories, pn)
    States[pn] = S

    -- clear of the mod icons at the screen edge (x 4..68)
    local OpenX = pn == PLAYER_1 and 230 or SCREEN_RIGHT - 230
    local ClosedX = pn == PLAYER_1 and -290 or SCREEN_RIGHT + 290

    local Window = Def.ActorFrame {
        InitCommand=function(self)
            S.Frame = self
            self:xy(ClosedX, SCREEN_CENTER_Y):visible(false)
        end,

        -- Open by the pad code, also while choosing the difficulty like Phoenix
        -- (never while the group wheel is open); the chart list ignores the pad
        -- while the window is open (OptionsListOpened)
        CodeMessageCommand=function(self, params)
            if params.PlayerNumber ~= pn then return end
            if params.Name ~= "OpenOpList" or MenuButtonsOnly then return end
            if S.Open or GroupWheelOpen or not CanOpen[pn] then return end
            self:playcommand("OpenWindow")
        end,

        OpenWindowCommand=function(self)
            S:OpenWindow()
            MESSAGEMAN:Broadcast("OptionsListOpened", { Player = pn, XSWindow = true })
            MESSAGEMAN:Broadcast("XSCWOpen")
            self:visible(true):stoptweening():easeoutexpo(0.4):x(OpenX)
            self:playcommand("Redraw")
        end,

        CloseWindowCommand=function(self)
            S:CloseWindow()
            MESSAGEMAN:Broadcast("OptionsListClosed", { Player = pn, XSWindow = true })
            MESSAGEMAN:Broadcast("XSCWClose")
            self:stoptweening():easeoutexpo(0.4):x(ClosedX):queuecommand("Hide")
        end,
        HideCommand=function(self) if not S.Open then self:visible(false) end end,

        MovedCommand=function(self)
            MESSAGEMAN:Broadcast("XSCWMove")
            self:playcommand("Redraw")
        end,
        AppliedCommand=function(self)
            MESSAGEMAN:Broadcast("XSCWApply")
            self:playcommand("Redraw")
        end,

    }

    if not UsePhoenix then
    for _, Part in ipairs({
        -- Frame: the XSanity panel already carries the "COMMAND WINDOW"
        -- header and the BACK/SHIFT corner markers.
        Def.Sprite {
            Texture=G("bg/bg_1.png"),
            InitCommand=function(self) self:zoomto(FrameW, FrameH) end
        },

        -- Category carousel: neighbor names as small text (sprites would overflow the frame)
        Def.BitmapText {
            Name="NeighborL", Font="Montserrat semibold 40px",
            InitCommand=function(self) self:xy(-98, TitleY):zoom(0.3):maxwidth(230):diffusealpha(0.45):shadowlength(1) end
        },
        Def.BitmapText {
            Name="NeighborR", Font="Montserrat semibold 40px",
            InitCommand=function(self) self:xy(98, TitleY):zoom(0.3):maxwidth(230):diffusealpha(0.45):shadowlength(1) end
        },
        Def.Sprite {
            Name="CatArrowL", Texture=G("CW/ARRCW 1x2.png"),
            InitCommand=function(self) self:animate(false):setstate(1):xy(-138, TitleY):zoom(0.38):rotationz(90) end
        },
        Def.Sprite {
            Name="CatArrowR", Texture=G("CW/ARRCW 1x2.png"),
            InitCommand=function(self) self:animate(false):setstate(1):xy(138, TitleY):zoom(0.38):rotationz(-90) end
        },

        -- Cursor behind the current item
        Def.Sprite {
            Name="Cursor", Texture=G("CW/CURCW 1x2.png"),
            InitCommand=function(self) self:animate(false):setstate(0):y(ItemsY):zoomto(118, 70):diffuseshift():effectcolor1(1,1,1,0.85):effectcolor2(1,1,1,0.5) end
        },

        -- Noteskin preview (uses the NS<skin> actors preloaded by the decorations layer)
        Def.ActorFrame {
            Name="SkinPreview",
            InitCommand=function(self) self:y(ItemsY):visible(false) end,
            Def.ActorProxy { Name="Proxy", InitCommand=function(self) self:y(-6):zoom(1.4) end },
            Def.BitmapText {
                Name="Label", Font="Montserrat semibold 40px",
                InitCommand=function(self) self:y(46):zoom(0.4):maxwidth(620):shadowlength(1) end
            },
        },

        -- Current value (Auto Velocity)
        Def.BitmapText {
            Name="Value", Font="Montserrat extrabold 40px",
            InitCommand=function(self) self:y(ValueY):zoom(0.55):shadowlength(1):visible(false) end
        },

        -- Description
        Def.BitmapText {
            Name="Description", Font="Montserrat normal 20px",
            InitCommand=function(self)
                self:y(DescY):zoom(0.6):wrapwidthpixels(430):vertalign(top):shadowlength(1)
            end
        },
    }) do Window[#Window + 1] = Part end

    -- Category titles: one actor per category, only the current one is shown.
    -- Each title is scaled so it never exceeds MaxTitleW inside the frame.
    local MaxTitleW = 200
    local TitleZoom = {}
    for i, Category in ipairs(Categories) do
        if Category.Title then
            Window[#Window + 1] = Def.Sprite {
                Name="Title" .. i, Texture=G(Category.Title .. ".png"),
                InitCommand=function(self) self:y(TitleY):visible(false) end,
                OnCommand=function(self) TitleZoom[i] = math.min(1, MaxTitleW / math.max(1, self:GetWidth())) end
            }
        else
            Window[#Window + 1] = Def.BitmapText {
                Name="Title" .. i, Font="Montserrat extrabold 40px", Text=string.upper(Category.Label or Category.Name),
                InitCommand=function(self)
                    self:y(TitleY):diffuse(0.45, 0.9, 1, 1):strokecolor(0.05, 0.15, 0.3, 1):shadowlength(2):visible(false)
                end,
                OnCommand=function(self) TitleZoom[i] = math.min(0.9, MaxTitleW / math.max(1, self:GetWidth())) end
            }
        end
    end

    -- Item slots: five, each with one sprite per icon sheet plus a generic badge with text
    for _, Off in ipairs(SlotOffsets) do
        local Slot = Def.ActorFrame {
            Name="Slot" .. Off,
            InitCommand=function(self) self:xy(SlotX[Off], ItemsY):zoom(SlotZoom[Off]):diffusealpha(SlotAlpha[Off]):visible(false) end,
            Def.Sprite { Name="Generic", Texture=G("Icons08 1x1.png"), InitCommand=function(self) self:visible(false) end },
            Def.BitmapText {
                Name="GenericLabel", Font="Montserrat extrabold 40px",
                -- badge is 120 px wide: keep the text inside it (maxwidth is pre-zoom)
                InitCommand=function(self) self:zoom(0.5):maxwidth(196):shadowlength(1):visible(false) end
            },
        }
        for _, Sheet in ipairs(Sheets) do
            Slot[#Slot + 1] = Def.Sprite {
                Name=Sheet, Texture=G(Sheet .. ".png"),
                InitCommand=function(self) self:animate(false):visible(false) end
            }
        end
        Window[#Window + 1] = Slot
    end

    -- Redraw everything from the state
    Window.RedrawCommand = function(self)
        local Category = S:CurrentCategory()
        local AtItems = S.Level == "item" and Category.Kind ~= "exit"

        -- Titles: current one in art, neighbors as small text
        for i, _ in ipairs(Categories) do
            local Title = self:GetChild("Title" .. i)
            if i == S.Cat then
                Title:visible(true):zoom((TitleZoom[i] or 1) * (AtItems and 0.75 or 1))
            else
                Title:visible(false)
            end
        end
        local Prev = Categories[Wrap(S.Cat - 1, #Categories)]
        local Next = Categories[Wrap(S.Cat + 1, #Categories)]
        self:GetChild("NeighborL"):visible(not AtItems):settext(string.upper(Prev.Label or Prev.Name))
        self:GetChild("NeighborR"):visible(not AtItems):settext(string.upper(Next.Label or Next.Name))
        self:GetChild("CatArrowL"):visible(not AtItems)
        self:GetChild("CatArrowR"):visible(not AtItems)

        -- Items
        local Items = AtItems and Category.Items or {}
        local Shown = {}
        for _, Off in ipairs(SlotOffsets) do
            local Slot = self:GetChild("Slot" .. Off)
            local Index = Wrap(S.Item + Off, #Items)
            local Item = Items[Index]
            local Visible = Item ~= nil and not Shown[Index] and Category.Kind ~= "noteskin"
            if Visible then Shown[Index] = true end
            Slot:visible(Visible)
            if Visible then
                local Generic = Slot:GetChild("Generic")
                local Label = Slot:GetChild("GenericLabel")
                local Active = Item.IsActive(pn)
                for _, Sheet in ipairs(Sheets) do
                    local Sprite = Slot:GetChild(Sheet)
                    if Item.Sheet == Sheet then
                        -- Badges with a dedicated "off" frame use it; the others are dimmed
                        if Item.InactiveFrame and not Active then
                            Sprite:visible(true):setstate(Item.InactiveFrame):diffuse(1, 1, 1, 1)
                        else
                            Sprite:visible(true):setstate(Item.Frame)
                            Sprite:diffuse(Active and 1 or 0.45, Active and 1 or 0.45, Active and 1 or 0.45, 1)
                        end
                    else
                        Sprite:visible(false)
                    end
                end
                Generic:visible(Item.Sheet == nil)
                Label:visible(Item.Sheet == nil):settext(Item.Label)
                if Item.Sheet == nil then
                    local Active = Item.IsActive(pn)
                    Generic:diffuse(Active and 1 or 0.45, Active and 1 or 0.45, Active and 1 or 0.45, 1)
                end
            end
        end
        self:GetChild("Cursor"):visible(AtItems and Category.Kind ~= "noteskin")

        -- Noteskin preview
        local Preview = self:GetChild("SkinPreview")
        if AtItems and Category.Kind == "noteskin" then
            local Item = S:CurrentItem()
            local Screen = SCREENMAN:GetTopScreen()
            local Target = Item and Screen and Screen:GetChild("NS" .. string.lower(Item.Label))
            local Proxy = Preview:GetChild("Proxy")
            if Target then Proxy:SetTarget(Target) end
            Proxy:visible(Target ~= nil)
            Preview:GetChild("Label"):settext(Item and Item.Label or "")
            Preview:visible(true)
        else
            Preview:visible(false)
        end

        -- Value (Auto Velocity, Judge)
        local Value = self:GetChild("Value")
        if Category.Value then
            Value:visible(true):settext((Category.ValuePrefix or "") .. Category.Value(pn))
        else
            Value:visible(false)
        end

        -- Description
        local Desc = Category.Description or ""
        if AtItems then
            local Item = S:CurrentItem()
            if Item and Item.Description then Desc = Item.Description end
        end
        self:GetChild("Description"):settext(Desc)
    end

    else
        -- ===================== Phoenix skin =====================
        Window[#Window + 1] = Def.Sprite { Texture=PX.Bg, InitCommand=function(self) self:zoom(PZ) end }
        Window[#Window + 1] = PLabelSlot("PxTitle", 0, PLabelY)
        -- while choosing a category the box shows its name between the neighbors' names
        Window[#Window + 1] = Def.ActorFrame {
            Name="PxCats", InitCommand=function(self) self:y(PBoxY) end,
            PLabelSlot("Cat-1", -PSideX, 0), PLabelSlot("Cat0", 0, 0), PLabelSlot("Cat1", PSideX, 0),
        }
        Window[#Window + 1] = Def.BitmapText {
            Name="PxValue", Font="Montserrat extrabold 40px",
            InitCommand=function(self) self:y(PValueY):zoom(0.55):maxwidth(250 / 0.55):diffuse(PYellow):shadowlength(1) end,
        }
        if PX.Glow then
            Window[#Window + 1] = Def.Sprite {
                Name="PxGlow", Texture=PX.Glow,
                InitCommand=function(self) self:y(PBoxY):zoomto(104, 62):blend("BlendMode_Add"):diffusealpha(0.45) end,
            }
        else
            Window[#Window + 1] = Def.Actor { Name="PxGlow" }
        end
        for _, Off in ipairs(SlotOffsets) do
            Window[#Window + 1] = Def.ActorFrame {
                Name="PxSlot" .. Off,
                InitCommand=function(self) self:xy(PSlotX[Off], PBoxY):zoom(PSlotZoom[Off]):visible(false) end,
                Def.Sprite { Name="Icon", Texture=PX.Icons, InitCommand=function(self) self:animate(false) end },
                Def.Sprite { Name="Badge", Texture=PX.Badge, InitCommand=function(self) self:visible(false) end },
                Def.BitmapText {
                    Name="BadgeLabel", Font="Montserrat extrabold 40px",
                    InitCommand=function(self) self:zoom(0.36):maxwidth(54 / 0.36):shadowlength(1):visible(false) end,
                },
                -- active options get a cyan bar under the badge
                Def.Quad { Name="Active", InitCommand=function(self) self:y(29):zoomto(40, 4):diffuse(color("#46e0ff")):visible(false) end },
            }
        end
        if PX.Brackets then
            Window[#Window + 1] = Def.Sprite {
                Name="PxBrackets", Texture=PX.Brackets,
                InitCommand=function(self) self:y(PBoxY):zoom(0.8):pulse():effectmagnitude(1.06, 1, 1):effectperiod(0.8) end,
            }
        else
            Window[#Window + 1] = Def.Actor { Name="PxBrackets" }
        end
        -- Noteskin previews around the cursor, laid out like the badges (they show the
        -- NS<skin> actors preloaded by the decorations layer)
        local Skins = Def.ActorFrame { Name="PxSkin", InitCommand=function(self) self:y(PBoxY):visible(false) end }
        for _, Off in ipairs(SlotOffsets) do
            Skins[#Skins + 1] = Def.ActorProxy {
                Name="Proxy" .. Off,
                InitCommand=function(self) self:x(PSlotX[Off]):zoom(PSlotZoom[Off] * PSkinZoom) end,
            }
        end
        Window[#Window + 1] = Skins
        Window[#Window + 1] = Def.BitmapText {
            Name="PxDesc", Font="Montserrat normal 20px",
            InitCommand=function(self) self:y(PDescY):zoom(0.55):wrapwidthpixels(258 / 0.55):shadowlength(1) end,
        }

        Window.RedrawCommand = function(self)
            local Category = S:CurrentCategory()
            local AtItems = S.Level == "item" and Category.Kind ~= "exit"
            local IsSkin = Category.Kind == "noteskin"

            -- Category name on top inside a category; while choosing one, the box shows
            -- it between the previous and next categories
            local Title = self:GetChild("PxTitle"):visible(AtItems)
            if AtItems then PSetLabel(Title, Category, PTitleW) end
            local Row = self:GetChild("PxCats"):visible(not AtItems)
            if not AtItems then
                for _, Off in ipairs({ -1, 0, 1 }) do
                    PSetLabel(Row:GetChild("Cat" .. Off), S.Categories[Wrap(S.Cat + Off, #S.Categories)],
                        Off == 0 and PCatW or PSideW, Off ~= 0)
                end
            end

            -- Badges: the category's options around the cursor
            local Items = Category.Items or {}
            local Center = AtItems and S.Item or (Category.DefaultItem and Category.DefaultItem(pn) or 1)
            local Shown = {}
            for _, Off in ipairs(PSlotOrder) do
                local Slot = self:GetChild("PxSlot" .. Off)
                local Index = Wrap(Center + Off, #Items)
                local Item = Items[Index]
                local Visible = AtItems and Item ~= nil and not Shown[Index] and not IsSkin
                if Visible then Shown[Index] = true end
                Slot:visible(Visible)
                if Visible then
                    local Active = Item.IsActive(pn)
                    local Shade = Active and 1 or 0.5
                    local Icon, Badge, Label = Slot:GetChild("Icon"), Slot:GetChild("Badge"), Slot:GetChild("BadgeLabel")
                    if Item.PhoenixFrame then
                        Icon:visible(true):setstate(Item.PhoenixFrame):diffuse(Shade, Shade, Shade, 1)
                        Badge:visible(false); Label:visible(false)
                    else
                        Icon:visible(false)
                        Badge:visible(true):diffuse(Shade, Shade, Shade, 1)
                        Label:visible(true):settext(string.upper(Item.Label)):diffuse(Shade, Shade, Shade, 1)
                    end
                    Slot:GetChild("Active"):visible(Active)
                    Slot:diffusealpha(PSlotAlpha[Off])
                end
            end
            -- the brackets frame the badge under the cursor, or the current category's name
            local Brackets = self:GetChild("PxBrackets")
            if AtItems then Brackets:zoom(0.8) else Brackets:zoomx(1.12):zoomy(0.85) end
            self:GetChild("PxGlow"):visible(AtItems)

            -- Noteskin previews (2 on each side of the cursor), value above the box
            local ValueText = nil
            local Preview = self:GetChild("PxSkin")
            Preview:visible(IsSkin and AtItems)
            if IsSkin then
                if AtItems then
                    local Screen = SCREENMAN:GetTopScreen()
                    local ShownSkin = {}
                    for _, Off in ipairs(PSlotOrder) do
                        local Index = Wrap(Center + Off, #Items)
                        local Item = not ShownSkin[Index] and Items[Index]
                        local Target = Item and Screen and Screen:GetChild("NS" .. string.lower(Item.Label))
                        if Item then ShownSkin[Index] = true end
                        local Proxy = Preview:GetChild("Proxy" .. Off)
                        if Target then Proxy:SetTarget(Target) end
                        Proxy:visible(Target ~= nil):diffusealpha(PSlotAlpha[Off])
                    end
                end
                local Item = Items[Center]
                ValueText = Item and string.upper(Item.Label) or ""
            end
            if Category.Value then ValueText = (Category.ValuePrefix or "") .. Category.Value(pn) end
            self:GetChild("PxValue"):visible(ValueText ~= nil):settext(ValueText or "")

            -- Description of the category, or of the option under the cursor
            local Desc = Category.Description or ""
            if AtItems then
                local Item = S:CurrentItem()
                if Item and Item.Description then Desc = Item.Description end
            end
            self:GetChild("PxDesc"):settext(Desc)
        end
    end

    t[#t + 1] = Window
end

return t
