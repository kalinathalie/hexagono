local IsMenuOpen = { PlayerNumber_P1 = false, PlayerNumber_P2 = false}
local CurrentMenu = { PlayerNumber_P1 = nil, PlayerNumber_P2 = nil }
local OptionsListActors = {}
local CurrentClosingPlayer -- Global hack for race condition when exiting with the Select button...
local MenuButtonsOnly = PREFSMAN:GetPreference("OnlyDedicatedMenuButtons")

-- Closing the list with the red (upper) pad panels, XSanity style.
-- The engine swallows every input while the list is open, so the theme never
-- sees the panels directly. What it does see are the engine messages:
--   * Start on a submenu / Exit row: OptionsMenuChanged followed by
--     OptionsListPush / OptionsListPop
--   * upper panels (SwitchMenu, see metrics CodeEnteredNextOpList):
--     OptionsMenuChanged alone
-- A menu change that is not followed by Push/Pop within the same frame is
-- therefore a panel press, and the list is closed. "XSClose" is a stub
-- submenu placed last in SongMenu so the panels also work from the last
-- real submenu (where SwitchMenu +1 would otherwise do nothing).
local JustOpened = { PlayerNumber_P1 = false, PlayerNumber_P2 = false }
local PendingSwitch = { PlayerNumber_P1 = false, PlayerNumber_P2 = false }

-- Same order the LuaNoteSkins row uses for its choices, so the list
-- selection index maps directly onto this table.
local SkinNames = NOTESKIN:GetNoteSkinNames()

local function GetPlayerSkin(pn)
    return GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()
end

local function CloseList(pn)
    local List = OptionsListActors[pn]
    if List and List.Close then
        List:Close()
    else
        SCREENMAN:SystemMessage("OptionsList:Close() indisponivel neste build")
    end
end

local t = Def.ActorFrame {
    Def.Sound {
        File=THEME:GetPathS("", "OpenCommandWindow"),
        OptionsListPlaySoundMessageCommand=function(self, params) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("", "CloseCommandWindow"),
        OptionsListClosedMessageCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("", "MoveCommandWindow"),
        OptionsListRightMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListLeftMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListQuickChangeMessageCommand=function(self) self:queuecommand("Refresh") end,
        RefreshCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("", "StartCommandWindow"),
        -- No idea why we need all of this. OptionsList sucks.
        OptionsListStartMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListResetMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListPopMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListPushMessageCommand=function(self) self:queuecommand("Refresh") end,
        RefreshCommand=function(self) self:play() end
    }
}

-- Special thanks to RhythmLunatic/Accelerator and ROAD24
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    -- This will allow us to determine the position of the list
    local OptionsListActor, OptionsListMenu

    t[#t+1] = Def.ActorFrame {
        InitCommand=function(self,params)
            self:xy(pn == PLAYER_1 and -200 or SCREEN_RIGHT + 200, SCREEN_CENTER_Y - 70)
        end,

        OnCommand=function(self)
            OptionsListActor = self:GetChild("OptionsList" .. pname(pn))
            OptionsListActors[pn] = OptionsListActor
        end,

        -- Move the list around when opened/closed
        OptionsListOpenedMessageCommand=function(self, params)
            if params.Player == pn then
                self:stoptweening():easeoutexpo(0.5):x(pn == PLAYER_1 and 200 or SCREEN_RIGHT - 200)
                IsMenuOpen[pn] = true
                JustOpened[pn] = true
                PendingSwitch[pn] = false
            end
        end,

        OptionsListClosedMessageCommand=function(self, params)
            if params.Player == pn then
                CurrentClosingPlayer = pn
                PendingSwitch[pn] = false
                self:stoptweening():easeoutexpo(0.5):x(pn == PLAYER_1 and -200 or SCREEN_RIGHT + 200)
                self:queuecommand("ClosedMenu")
            end
        end,

        ClosedMenuCommand=function(self)
            IsMenuOpen[CurrentClosingPlayer] = false
        end,

        -- Start on a submenu or on an Exit row: a legitimate menu change
        OptionsListPushMessageCommand=function(self, params)
            if params.Player == pn then PendingSwitch[pn] = false end
        end,
        OptionsListPopMessageCommand=function(self, params)
            if params.Player == pn then PendingSwitch[pn] = false end
        end,

        -- Make us able to view what menu we're in later (and also adjust its position)
        OptionsMenuChangedMessageCommand=function(self, params)
            if params.Player == pn then
                OptionsListMenu = params.Menu
                CurrentMenu[pn] = params.Menu

                self:playcommand("Adjust", params)

                if params.Menu == "XSClose" then
                    -- Stub submenu reached (Start on "Close", or panels from the last submenu)
                    PendingSwitch[pn] = true
                    self:GetChild("SwitchTimer"):stoptweening():sleep(0.01):queuecommand("CheckSwitch")
                elseif JustOpened[pn] then
                    -- First menu change comes from Open() itself
                    JustOpened[pn] = false
                else
                    -- If no Push/Pop follows within the frame, this was a panel press
                    PendingSwitch[pn] = true
                    self:GetChild("SwitchTimer"):stoptweening():sleep(0.01):queuecommand("CheckSwitch")
                end
            end
        end,

        OptionsListLeftMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListRightMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListStartMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListQuickChangeMessageCommand=function(self, params) self:playcommand("Adjust", params) end,

        -- To avoid overflowing the list, we will hide the outer parts and
        -- dynamically move the entire list's vertical position relative
        -- to what the player is currently selecting
        AdjustCommand=function(self, params)
            if params.Player == pn then
                -- Edge case since we don't need to scroll in Speed Mods
                if params.Selection + 1 > 5 and OptionsListMenu == "Noteskins" then
                    OptionsListActor:stoptweening():linear(0.1):y(-110 - (26 * (params.Selection - 5)))
                elseif params.Selection + 1 > 9 then
                    OptionsListActor:stoptweening():linear(0.1):y(-110 - (26 * (params.Selection - 9)))
                else
                    OptionsListActor:stoptweening():linear(0.1):y(-110)
                end
            end
        end,

        -- Timer used to decide, one frame later, whether a menu change was a panel press
        Def.Actor {
            Name="SwitchTimer",
            CheckSwitchCommand=function(self)
                if PendingSwitch[pn] and IsMenuOpen[pn] then
                    PendingSwitch[pn] = false
                    CloseList(pn)
                end
            end
        },

        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/Options"),
            InitCommand=function(self) self:zoom(0.7) end
        },

        -- Masks that will hide the off limits portion of the list, shhh
        Def.Quad {
            InitCommand=function(self) self:setsize(206, 170):xy(0, -205):MaskSource() end,
        },

        Def.Quad {
            InitCommand=function(self) self:setsize(206, 268):xy(0, 296):MaskSource() end,
        },

        Def.OptionsList {
            Name="OptionsList" .. pname(pn),
            Player=pn,
            CodeMessageCommand=function(self, params)
                if ((params.Name == "OpenOpList" and not MenuButtonsOnly) or
                    params.Name == "OpenOpListButton") and params.PlayerNumber == pn and not IsMenuOpen[pn] then
                    self:Open()
                    MESSAGEMAN:Broadcast("OptionsListPlaySound")
                end
            end
        },

        -- Live noteskin preview: follows the cursor inside the Noteskins menu,
        -- so skins can be browsed without selecting each one. It reuses the
        -- hidden "NS<skin>" actors preloaded by the decorations layer.
        Def.ActorFrame {
            Name="SkinPreview",
            InitCommand=function(self)
                self:x(pn == PLAYER_1 and 170 or -170):y(-20):visible(false)
            end,

            OptionsMenuChangedMessageCommand=function(self, params)
                if params.Player ~= pn then return end
                if params.Menu == "Noteskins" then
                    self:visible(true):playcommand("ShowSkin", { Name = GetPlayerSkin(pn) })
                else
                    self:visible(false)
                end
            end,

            OptionsListClosedMessageCommand=function(self, params)
                if params.Player == pn then self:visible(false) end
            end,

            OptionsListLeftMessageCommand=function(self, params) self:playcommand("Browse", params) end,
            OptionsListRightMessageCommand=function(self, params) self:playcommand("Browse", params) end,
            OptionsListQuickChangeMessageCommand=function(self, params) self:playcommand("Browse", params) end,
            OptionsListStartMessageCommand=function(self, params) self:playcommand("Browse", params) end,

            BrowseCommand=function(self, params)
                if params.Player ~= pn or CurrentMenu[pn] ~= "Noteskins" then return end
                local Index = params.Selection
                local Name
                if Index ~= nil and Index >= 0 and Index < #SkinNames then
                    Name = SkinNames[Index + 1]
                else
                    -- Cursor is on the Exit row: show what is currently applied
                    Name = GetPlayerSkin(pn)
                end
                self:playcommand("ShowSkin", { Name = Name })
            end,

            ShowSkinCommand=function(self, params)
                local Name = params.Name or "default"
                local Screen = SCREENMAN:GetTopScreen()
                local Target = Screen and Screen:GetChild("NS" .. string.lower(Name))
                local Proxy = self:GetChild("Proxy")
                if Target then
                    Proxy:SetTarget(Target)
                    Proxy:visible(true)
                else
                    Proxy:visible(false)
                end
                self:GetChild("Label"):settext(Name)
            end,

            Def.Quad {
                InitCommand=function(self)
                    self:zoomto(140, 150):diffuse(0, 0, 0, 0.75)
                end
            },

            Def.ActorProxy {
                Name="Proxy",
                InitCommand=function(self) self:y(-12):zoom(1.5) end
            },

            Def.BitmapText {
                Name="Label",
                Font="Montserrat semibold 40px",
                InitCommand=function(self)
                    self:y(55):zoom(0.4):maxwidth(320):shadowlength(1)
                end
            }
        }
    }
end

return t
