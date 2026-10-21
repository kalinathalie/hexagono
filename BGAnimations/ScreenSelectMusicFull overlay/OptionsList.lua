-- Same rule as CommandWindow.lua: is the graphical command window drawn (local art present)?
local function HasArt(Name) return LoadModule("Select.Art.lua")(Name) ~= nil end
local GraphicalWindow = (HasArt("Phoenix/CommandWindow/bg") and HasArt("Phoenix/CommandWindow/MenuIcons 1x9")
    and HasArt("Phoenix/CommandWindow/icons 11x11") and HasArt("Phoenix/CommandWindow/frame"))
    or HasArt("XSCommandWindow/bg/bg_1")

local IsMenuOpen = { PlayerNumber_P1 = false, PlayerNumber_P2 = false}
local CurrentMenu = { PlayerNumber_P1 = nil, PlayerNumber_P2 = nil }
local OptionsListActors = {}
local CurrentClosingPlayer -- Global hack for race condition when exiting with the Select button...
local MenuButtonsOnly = PREFSMAN:GetPreference("OnlyDedicatedMenuButtons")

-- Red (upper) pad panels inside the command window, XSanity style:
-- go back one menu level, and close when already on the main menu.
-- The engine swallows raw input while the list is open, but it still runs the
-- list's own code set ([OptionsList] CodeNames / CodeXSClosePad*) and sends a
-- "Code" message to the list actor. That message arrives from inside the
-- engine's input handling, so the action is deferred one frame.
-- "XSClose" is a stub submenu (last entry of SongMenu, labelled "Close"):
-- entering it closes the list.
local PendingBack = { PlayerNumber_P1 = false, PlayerNumber_P2 = false }

-- Menu stack mirrored from the engine messages (Opened/MenuChanged/Push/Pop),
-- used to go back one level. This build exposes Open() and Close() to Lua but
-- not Pop(), so "back" is done by closing and reopening the list silently at
-- the parent menu (Push() is used for deeper levels when it exists).
local MenuStack = { PlayerNumber_P1 = {}, PlayerNumber_P2 = {} }
local AwaitingTop = { PlayerNumber_P1 = false, PlayerNumber_P2 = false }
local Reopening = { PlayerNumber_P1 = false, PlayerNumber_P2 = false }

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

-- Back one level, or close when already on the top menu.
local function BackList(pn)
    local List = OptionsListActors[pn]
    if not List then return end

    local Stack = MenuStack[pn] or {}
    if #Stack <= 1 or not List.Close or not List.Open then
        CloseList(pn)
        return
    end

    -- Rebuild the stack without its last entry
    local Target = {}
    for i = 1, #Stack - 1 do Target[i] = Stack[i] end

    Reopening[pn] = true
    List:Close()
    List:Open()
    if List.Push then
        for i = 2, #Target do List:Push(Target[i]) end
    else
        Target = { Target[1] }
    end
    Reopening[pn] = false
    MenuStack[pn] = Target
end

local t = Def.ActorFrame {
    Def.Sound {
        File=THEME:GetPathS("", "OpenCommandWindow"),
        OptionsListPlaySoundMessageCommand=function(self, params) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("", "CloseCommandWindow"),
        OptionsListClosedMessageCommand=function(self, params)
            if params.XSWindow then return end
            if not Reopening[params.Player] then self:play() end
        end
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
            -- Messages from the graphical command window are not ours
            if params.XSWindow then return end
            if params.Player == pn then
                IsMenuOpen[pn] = true
                PendingBack[pn] = false
                AwaitingTop[pn] = true
                MenuStack[pn] = {}
                -- Silent reopen while going back one level: stay in place
                if Reopening[pn] then return end
                self:stoptweening():easeoutexpo(0.5):x(pn == PLAYER_1 and 200 or SCREEN_RIGHT - 200)
            end
        end,

        OptionsListClosedMessageCommand=function(self, params)
            if params.XSWindow then return end
            if params.Player == pn then
                PendingBack[pn] = false
                if Reopening[pn] then return end
                CurrentClosingPlayer = pn
                self:stoptweening():easeoutexpo(0.5):x(pn == PLAYER_1 and -200 or SCREEN_RIGHT + 200)
                self:queuecommand("ClosedMenu")
            end
        end,

        -- Start on a submenu entry / on an Exit row: keep the mirrored stack in sync
        OptionsListPushMessageCommand=function(self, params)
            if params.Player == pn and not Reopening[pn] then
                table.insert(MenuStack[pn], CurrentMenu[pn])
            end
        end,
        OptionsListPopMessageCommand=function(self, params)
            if params.Player == pn and not Reopening[pn] then
                table.remove(MenuStack[pn])
            end
        end,

        ClosedMenuCommand=function(self)
            IsMenuOpen[CurrentClosingPlayer] = false
        end,

        -- Make us able to view what menu we're in later (and also adjust its position)
        OptionsMenuChangedMessageCommand=function(self, params)
            if params.Player == pn then
                OptionsListMenu = params.Menu
                CurrentMenu[pn] = params.Menu
                if AwaitingTop[pn] then
                    MenuStack[pn] = { params.Menu }
                    AwaitingTop[pn] = false
                end

                self:playcommand("Adjust", params)

                -- "Close" stub entered (Start on it): close the whole list next frame
                if params.Menu == "XSClose" then
                    self:GetChild("BackTimer"):stoptweening():sleep(0.01):queuecommand("DoClose")
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

        -- Runs the deferred back/close actions one frame after the engine message
        Def.Actor {
            Name="BackTimer",
            DoBackCommand=function(self)
                if PendingBack[pn] and IsMenuOpen[pn] then
                    PendingBack[pn] = false
                    BackList(pn)
                end
            end,
            DoCloseCommand=function(self)
                if IsMenuOpen[pn] then CloseList(pn) end
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
                if params.PlayerNumber ~= pn then return end

                -- Upper pad panels (codes from the [OptionsList] metrics section):
                -- back one level, or close on the main menu. Deferred one frame.
                if params.Name == "XSClosePad1" or params.Name == "XSClosePad2" then
                    if IsMenuOpen[pn] then
                        PendingBack[pn] = true
                        self:GetParent():GetChild("BackTimer"):stoptweening():sleep(0.01):queuecommand("DoBack")
                    end
                    return
                end

                -- The pad code opens the graphical command window when its art is
                -- present; the engine list stays reachable through the Select button.
                local Code = params.Name == "OpenOpListButton" or (params.Name == "OpenOpList" and not GraphicalWindow)
                if Code and not IsMenuOpen[pn] then
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
