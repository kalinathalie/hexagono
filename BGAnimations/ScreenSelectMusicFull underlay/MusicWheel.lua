-- Phoenix-style jacket wheel: 7 visible jackets in a row (plus one hidden slot
-- on each side so every visible item slides), the selected one larger in the
-- center with a position counter. When a song is chosen the wheel slides away
-- (the difficulty row takes its place). Input, busy state and messages are the
-- same as before; images come only from the engine image cache.
local Wheel = LoadModule("Select.Wheel.lua")

local WheelSize = 9            -- 7 visible + 2 off-screen slots
local WheelCenter = 5
local Spacing = 200
local ImageW, ImageH = 180, 101  -- 16:9 jacket/banner area
local BandH = 22                 -- title band at the bottom of the jacket
local WheelY = SCREEN_CENTER_Y + 95

local Songs = {}
local Targets = {}

local ChartPreview = LoadModule("Config.Load.lua")("ChartPreview","Save/OutFoxPrefs.ini")

-- Not load anything if no group sorts are available (catastrophic event or no songs)
if next(GroupsList) == nil then
    AssembleGroupSorting()
    UpdateGroupSorting()

    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible, halting music wheel!")
        return Def.Actor {}
    end
end

LastGroupMainIndex = tonumber(LoadModule("Config.Load.lua")("GroupMainIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
LastGroupSubIndex = tonumber(LoadModule("Config.Load.lua")("GroupSubIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
LastSongIndex = tonumber(LoadModule("Config.Load.lua")("SongIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
--reset LastGroup/Sub/Song if they were deleted since last session to avoid "attempt to index nil" crashes
if GroupsList[LastGroupMainIndex] == nil then
    LastGroupMainIndex = 1
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastGroupMainIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex] == nil then
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastGroupSubIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex].Songs == nil then
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastSongIndex no longer present, reset performed")
end

local SongIndex = LastSongIndex > 0 and LastSongIndex or 1
local GroupMainIndex = LastGroupMainIndex > 0 and LastGroupMainIndex or 1
local GroupSubIndex = LastGroupSubIndex > 0 and LastGroupSubIndex or 1

local IsBusy = false

-- Tracks which players have the options list open, so Back closes the
-- list (handled in the overlay) instead of leaving the screen.
local OptionsOpen = { PlayerNumber_P1 = false, PlayerNumber_P2 = false }

Songs = GroupsList[GroupMainIndex].SubGroups[GroupSubIndex].Songs
if SongIndex > #Songs then SongIndex = 1 end

-- Update Songs item targets
local function UpdateItemTargets(val)
    for i = 1, WheelSize do
        Targets[i] = val + i - WheelCenter
        -- Wrap to fit to Songs list size
        while Targets[i] > #Songs do Targets[i] = Targets[i] - #Songs end
        while Targets[i] < 1 do Targets[i] = Targets[i] + #Songs end
    end
end

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn then return end

    -- Don't want to move when releasing the button
    if event.type == "InputEventType_Release" then return end

    local button = event.GameButton

    -- If an unjoined player attempts to join and has enough credits, join them
    if (button == "Start" or button == "MenuStart" or button == "Center") and
        not GAMESTATE:IsSideJoined(pn) and GAMESTATE:GetCoins() >= GAMESTATE:GetCoinsNeededToJoin() then
        GAMESTATE:JoinPlayer(pn)
        -- The command above does not deduct credits so we'll do it ourselves
        GAMESTATE:InsertCoin(-(GAMESTATE:GetCoinsNeededToJoin()))
        MESSAGEMAN:Broadcast("PlayerJoined", { Player = pn })
    else
        -- To avoid control from a player that has not joined, filter the inputs out
        if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
        if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

        -- This player's command window owns their input while it is open
        if OptionsOpen[pn] then return end

        if not IsBusy then
            if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
                SongIndex = SongIndex - 1
                if SongIndex < 1 then SongIndex = #Songs end

                GAMESTATE:SetCurrentSong(Songs[SongIndex])
                UpdateItemTargets(SongIndex)
                MESSAGEMAN:Broadcast("Scroll", { Direction = -1 })

            elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
                SongIndex = SongIndex + 1
                if SongIndex > #Songs then SongIndex = 1 end

                GAMESTATE:SetCurrentSong(Songs[SongIndex])
                UpdateItemTargets(SongIndex)
                MESSAGEMAN:Broadcast("Scroll", { Direction = 1 })

            elseif button == "Start" or button == "MenuStart" or button == "Center" then
                -- Only the initial press chooses a song. Key repeats of the Center
                -- press that confirmed a group must not choose the first song of
                -- the new group.
                if event.type ~= "InputEventType_FirstPress" then return end

                -- Save this for later
                LastSongIndex = SongIndex
                LoadModule("Config.Save.lua")("SongIndex", LastSongIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")

                MESSAGEMAN:Broadcast("MusicWheelStart")

            elseif button == "Back" then
                if not (OptionsOpen[PLAYER_1] or OptionsOpen[PLAYER_2]) then
                    SCREENMAN:GetTopScreen():Cancel()
                end
            end
        end

        MESSAGEMAN:Broadcast("UpdateMusic")
    end
end

-- Loads the song image into a wheel item through the image cache (never a full PNG decode)
local function UpdateImage(self, Song)
    local Image = self:GetChild("Image")
    local Title = self:GetChild("Title")
    if not Song then
        Image:visible(false); Title:settext("")
        return
    end
    local Kind = Wheel.ImageKind(Song:HasJacket(), Song:HasBanner())
    if Kind == "jacket" then
        Image:visible(true):LoadFromCached("Jacket", Song:GetJacketPath()):scaletoclipped(ImageW, ImageH)
    elseif Kind == "banner" then
        Image:visible(true):LoadFromCached("Banner", Song:GetBannerPath()):scaletoclipped(ImageW, ImageH)
    else
        Image:visible(false)
    end
    Title:settext(Song:GetDisplayMainTitle())
end

local t = Def.ActorFrame {
    InitCommand=function(self)
        self:y(SCREEN_HEIGHT + 160)
        UpdateItemTargets(SongIndex)
    end,

    OnCommand=function(self)
        GAMESTATE:SetCurrentSong(Songs[SongIndex])
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
        self:easeoutexpo(1):y(0)
    end,

    OffCommand=function(self)
        self:stoptweening():easeoutexpo(1):y(SCREEN_HEIGHT + 160)
    end,

    -- Race condition workaround (yuck)
    MusicWheelStartMessageCommand=function(self) self:sleep(0.01):queuecommand("Confirm") end,
    ConfirmCommand=function(self) MESSAGEMAN:Broadcast("SongChosen") end,

    -- Phoenix transition: the wheel slides down out of view while the
    -- difficulty is chosen, and comes back when the song is unchosen
    SongChosenMessageCommand=function(self)
        self:playcommand("Busy"):stoptweening():easeoutexpo(0.4):y(SCREEN_HEIGHT - WheelY + 40):diffusealpha(0)
    end,
    SongUnchosenMessageCommand=function(self)
        self:playcommand("NotBusy"):stoptweening():easeoutexpo(0.4):y(0):diffusealpha(1)
    end,

    OptionsListOpenedMessageCommand=function(self, params) OptionsOpen[params.Player] = true end,
    OptionsListClosedMessageCommand=function(self, params) OptionsOpen[params.Player] = false end,

    OpenGroupWheelMessageCommand=function(self) IsBusy = true end,
    CloseGroupWheelMessageCommand=function(self, params)
        if params.Silent == false then
            -- Grab the new list of songs from the selected group
            Songs = GroupsList[GroupIndex].SubGroups[SubGroupIndex].Songs
            -- Reset back to the first song of the list
            SongIndex = 1
            GAMESTATE:SetCurrentSong(Songs[SongIndex])
        end
        UpdateItemTargets(SongIndex)
        MESSAGEMAN:Broadcast("ForceUpdate")
        self:sleep(0.01):queuecommand("NotBusy")
    end,

    BusyCommand=function(self) IsBusy = true end,
    NotBusyCommand=function(self) IsBusy = false end,

    -- Play song preview (thanks Luizsan)
    Def.Actor {
        CurrentSongChangedMessageCommand=function(self)
            SOUND:StopMusic()
            self:stoptweening():sleep(0.25):queuecommand("PlayMusic")
        end,

        PlayMusicCommand=function(self)
            local Song = GAMESTATE:GetCurrentSong()
            if Song then
                if ChartPreview then
                    local StepList = Song:GetAllSteps()
                    local FirstStep = StepList[1]
                    local Duration = FirstStep:GetChartLength()
                    SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(),
                    (Duration - Song:GetSampleStart()), 0, 1, false, false, false, Song:GetTimingData())
                else
                    SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(),
                    Song:GetSampleLength(), 0, 1, false, false, false, Song:GetTimingData())
                end
            end
        end
    },

    Def.Sound {
        File=THEME:GetPathS("MusicWheel", "change"),
        IsAction=true,
        ScrollMessageCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        MusicWheelStartMessageCommand=function(self) self:play() end
    },

    -- Pointer: a small yellow mark under the centered jacket (above it the title block sits)
    Def.Quad {
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, WheelY + (ImageH * 1.15) / 2 + 52):zoomto(16, 8):diffuse(color("#ffe15a"))
            :bounce():effectmagnitude(0, 3, 0):effectclock("bgm")
        end
    },
}

-- Wheel items. Slot i draws the song at Targets[i]; the slot index is rotated on
-- every scroll, so every item slides to its neighbour position. Only the hidden
-- slots at both ends take new songs, so the visible row never pops.
for i = 1, WheelSize do
    t[#t+1] = Def.ActorFrame{
        OnCommand=function(self)
            UpdateImage(self, Songs[Targets[i]])
            self:playcommand("Scroll", {Direction = 0})
        end,

        ForceUpdateMessageCommand=function(self)
            UpdateImage(self, Songs[Targets[i]])
            self:playcommand("Scroll", {Direction = 0})
        end,

        ScrollMessageCommand=function(self, param)
            self:stoptweening()
            local tween = param and param.Direction and math.abs(param.Direction) > 0
            local Previous = i

            -- Adjust and wrap slot index
            i = i - param.Direction
            while i > WheelSize do i = i - WheelSize end
            while i < 1 do i = i + WheelSize end

            -- The slot that wrapped around (both positions off-screen) and the
            -- hidden end slots take the new song and jump; everything else slides.
            local Wrapped = math.abs(i - Previous) > 1
            if i == 1 or i == WheelSize or Wrapped then
                UpdateImage(self, Songs[Targets[i]])
            elseif tween then
                self:easeoutexpo(0.3)
            end

            local Center = (i == WheelCenter)
            self:xy(SCREEN_CENTER_X + (i - WheelCenter) * Spacing, WheelY)
            :zoom(Center and 1.15 or 1):diffusealpha(Center and 1 or 0.9)
            self:GetChild("Border"):diffuse(Center and color("#3cff5c") or color("#ffffff")):diffusealpha(Center and 1 or 0.5)
            self:GetChild("Counter"):visible(Center)
            if Center then self:GetChild("Counter"):settext(Wheel.Counter(Targets[i], #Songs)) end
        end,

        Def.Quad {
            Name="Border",
            InitCommand=function(self) self:zoomto(ImageW + 6, ImageH + 6):diffuse(Color.White):diffusealpha(0.5) end,
        },
        Def.Quad {
            InitCommand=function(self) self:zoomto(ImageW, ImageH):diffuse(color("#0b1220")) end,
        },
        Def.Sprite {
            Name="Image",
        },
        Def.Quad {
            InitCommand=function(self) self:y(ImageH / 2 - BandH / 2):zoomto(ImageW, BandH):diffuse(Color.Black):diffusealpha(0.7) end,
        },
        Def.BitmapText {
            Name="Title",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(ImageH / 2 - BandH / 2):zoom(0.7):maxwidth((ImageW - 10) / 0.7):shadowlength(1) end,
        },
        Def.BitmapText {
            Name="Counter",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(ImageH / 2 + 22):zoom(0.8):diffuse(color("#ffe15a")):shadowlength(1):visible(false) end,
        },
    }
end

return t
