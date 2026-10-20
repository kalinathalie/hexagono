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

-- PlayerOptions accessor per mod name used by the Speed category
local ModMethod = { expand = "Expand", randomspeed = "RandomSpeed", boost = "Boost", brake = "Brake" }

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
    Text = Text,
}

local Categories = BuildCategories(Deps)

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

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn then return end
    local S = States[pn]
    if not S or not S.Open then return end

    local Frame = S.Frame
    local button = event.GameButton
    local Press = event.type == "InputEventType_FirstPress"
    local Repeat = event.type == "InputEventType_Repeat"

    if (button == "DownLeft" or button == "DownRight") and (Press or Repeat) then
        if S:Move(button == "DownLeft" and -1 or 1) then
            Frame:playcommand("Moved")
        end
    elseif (button == "Center" or button == "Start" or button == "MenuStart") and Press then
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
    elseif (button == "UpLeft" or button == "UpRight" or button == "Back") and Press then
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

    local OpenX = pn == PLAYER_1 and 200 or SCREEN_RIGHT - 200
    local ClosedX = pn == PLAYER_1 and -260 or SCREEN_RIGHT + 260

    local Window = Def.ActorFrame {
        InitCommand=function(self)
            S.Frame = self
            self:xy(ClosedX, SCREEN_CENTER_Y):visible(false)
        end,

        -- Open by the pad code (never while the group wheel is open or a song is chosen)
        CodeMessageCommand=function(self, params)
            if params.PlayerNumber ~= pn then return end
            if params.Name ~= "OpenOpList" or MenuButtonsOnly then return end
            if S.Open or GroupWheelOpen or SongIsChosen or not CanOpen[pn] then return end
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

        -- Frame
        Def.Sprite {
            Texture=G("CW/BACKGROUND02.PNG"),
            InitCommand=function(self) self:zoomto(FrameW, FrameH) end
        },
        Def.BitmapText {
            Font="Montserrat extrabold 40px",
            Text=Text("Header"),
            InitCommand=function(self) self:y(-186):zoom(0.42):shadowlength(1) end
        },
        Def.Sprite { Texture=G("BackIcon.png"), InitCommand=function(self) self:xy(-125, -186):zoom(0.7) end },
        Def.Sprite { Texture=G("BackIcon.png"), InitCommand=function(self) self:xy(125, -186):zoom(0.7):zoomx(-0.7) end },
        Def.Sprite {
            Texture=G("CW/ARRCW 1x2.png"),
            InitCommand=function(self) self:animate(false):setstate(0):xy(-125, 186):zoom(0.6) end
        },
        Def.Sprite {
            Texture=G("CW/ARRCW 1x2.png"),
            InitCommand=function(self) self:animate(false):setstate(0):xy(125, 186):zoom(0.6):zoomx(-0.6) end
        },

        -- Category carousel arrows
        Def.Sprite {
            Name="CatArrowL", Texture=G("CW/ARRCW 1x2.png"),
            InitCommand=function(self) self:animate(false):setstate(1):xy(-148, TitleY):zoom(0.45):rotationz(90) end
        },
        Def.Sprite {
            Name="CatArrowR", Texture=G("CW/ARRCW 1x2.png"),
            InitCommand=function(self) self:animate(false):setstate(1):xy(148, TitleY):zoom(0.45):rotationz(-90) end
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
    }

    -- Category titles: one actor per category, positioned on each redraw
    for i, Category in ipairs(Categories) do
        if Category.Title then
            Window[#Window + 1] = Def.Sprite {
                Name="Title" .. i, Texture=G(Category.Title .. ".png"),
                InitCommand=function(self) self:y(TitleY):visible(false) end
            }
        else
            Window[#Window + 1] = Def.BitmapText {
                Name="Title" .. i, Font="Montserrat extrabold 40px", Text=string.upper(Category.Label or Category.Name),
                InitCommand=function(self) self:y(TitleY):zoom(0.9):shadowlength(1):visible(false) end
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
                InitCommand=function(self) self:zoom(0.7):maxwidth(150):shadowlength(1):visible(false) end
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

        -- Titles
        for i, _ in ipairs(Categories) do
            local Title = self:GetChild("Title" .. i)
            local Off = i - S.Cat
            if Off > #Categories / 2 then Off = Off - #Categories end
            if Off < -#Categories / 2 then Off = Off + #Categories end
            if Off == 0 then
                Title:visible(true):x(0):zoom(AtItems and 0.75 or 1):diffusealpha(1)
            elseif math.abs(Off) == 1 and not AtItems then
                Title:visible(true):x(Off * 105):zoom(0.4):diffusealpha(0.4)
            else
                Title:visible(false)
            end
        end
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
                for _, Sheet in ipairs(Sheets) do
                    local Sprite = Slot:GetChild(Sheet)
                    if Item.Sheet == Sheet then
                        Sprite:visible(true):setstate(Item.Frame)
                        Sprite:diffuse(Item.IsActive(pn) and 1 or 0.45, Item.IsActive(pn) and 1 or 0.45, Item.IsActive(pn) and 1 or 0.45, 1)
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

        -- Value (Auto Velocity)
        local Value = self:GetChild("Value")
        if Category.Value then
            Value:visible(true):settext("AV " .. Category.Value(pn))
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

    t[#t + 1] = Window
end

return t
