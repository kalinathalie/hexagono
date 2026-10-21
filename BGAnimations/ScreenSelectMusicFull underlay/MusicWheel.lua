-- Phoenix-style jacket wheel: 7 items in a row, the selected one larger in the
-- center with a position counter. Input, busy state and messages are the same
-- as before; images come only from the engine image cache.
local Wheel = LoadModule("Select.Wheel.lua")

local WheelSize = 7
local WheelCenter = 4
local FrameW, FrameH = 190, 140   -- center item size (tg_wheelitem_music is 328x240)
local ImageW, ImageH = 176, 100   -- image area inside the frame, above the label notch
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

    -- The wheel stays on screen while the difficulty is chosen (Phoenix layout)
    SongChosenMessageCommand=function(self) self:playcommand("Busy") end,
    SongUnchosenMessageCommand=function(self) self:playcommand("NotBusy") end,

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
}

-- Wheel items. Item i draws the song at Targets[i]; the frame index is rotated
-- on every scroll like the previous wheel, so items slide instead of reloading.
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

            local Layout = Wheel.Layout(WheelSize, SCREEN_CENTER_X, WheelCenter)
            local Slot = Layout[i]
            local displace = -param.Direction * 150
            local tween = param and param.Direction and math.abs(param.Direction) > 0

            -- Adjust and wrap actor index
            i = i - param.Direction
            while i > WheelSize do i = i - WheelSize end
            while i < 1 do i = i + WheelSize end

            -- Edge items get the new song and never tween
            if i == 1 or i == WheelSize then
                UpdateImage(self, Songs[Targets[i]])
            elseif tween then
                self:easeoutexpo(0.3)
            end

            local Target = Layout[i]
            self:xy(Target.X, WheelY):zoom(Target.Zoom):diffusealpha(Target.Alpha)
            self:GetChild("Pointer"):visible(i == WheelCenter)
            self:GetChild("Counter"):visible(i == WheelCenter)
            if i == WheelCenter then
                self:GetChild("Counter"):settext(Wheel.Counter(Targets[i], #Songs))
            end
        end,

        Def.Sprite {
            Name="Image",
            InitCommand=function(self) self:y(-12) end,
        },
        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/tg_wheelitem_music"),
            InitCommand=function(self) self:zoomto(FrameW, FrameH) end,
        },
        Def.BitmapText {
            Name="Title",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(FrameH / 2 - 12):zoom(0.75):maxwidth((FrameW - 20) / 0.75):shadowlength(1) end,
        },
        Def.Sprite {
            Name="Pointer",
            Texture=THEME:GetPathG("", "MusicWheel/tg_pointerwheel_music"),
            InitCommand=function(self) self:zoomto(FrameW + 16, FrameH + 16):diffuse(color("#3cff5c")):visible(false) end,
        },
        Def.BitmapText {
            Name="Counter",
            Font="Montserrat semibold 20px",
            InitCommand=function(self) self:y(FrameH / 2 + 20):zoom(0.8):diffuse(color("#ffe15a")):shadowlength(1):visible(false) end,
        },
    }
end

return t
