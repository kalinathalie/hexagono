-- Chart selection logic for the song select screen: builds the ordered list of
-- playable charts for the current song, keeps the per-player cursor, handles
-- the input while the song is chosen and sets the current steps. Drawing is
-- done by ChartRow.lua, which listens to the ChartRowChanged message
-- broadcast here with { Charts, Index = { [pn] = n }, Song, Chosen }.

local ChartIndex = { PlayerNumber_P1 = 1, PlayerNumber_P2 = 1 }
local PrevChartIndex = { PlayerNumber_P1 = 1, PlayerNumber_P2 = 1 }
local PlayerCanMove = { PlayerNumber_P1 = true, PlayerNumber_P2 = true }
local ConfirmStart = { PlayerNumber_P1 = false, PlayerNumber_P2 = false }

local ChartArray = nil
local SongIsChosen = false
-- When the song changes inside a level group ("Single 5", "Double 12", ...),
-- preselect the chart of that level instead of keeping the previous index.
local SnapToGroup = false

local LevelGroupTypes = { ["Single"] = "Single", ["Double"] = "Double", ["Half-Double"] = "Halfdouble" }

local function FindGroupLevelChart(Charts, GroupName)
    if not GroupName then return nil end
    local TypeName, Level = string.match(GroupName, "^(.-) (%d+)$")
    if not TypeName or not LevelGroupTypes[TypeName] then return nil end
    Level = tonumber(Level)
    for i, Chart in ipairs(Charts) do
        if ToEnumShortString(ToEnumShortString(Chart:GetStepsType())) == LevelGroupTypes[TypeName]
        and Chart:GetMeter() == Level then
            return i
        end
    end
    return nil
end

local CanWrap = LoadModule("Config.Load.lua")("WrapChartScroll", "Save/OutFoxPrefs.ini")

-- http://lua-users.org/wiki/CopyTable
function ShallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function SortCharts(a, b)
    if a:GetStepsType() == b:GetStepsType() then
        return a:GetMeter() < b:GetMeter()
    else
        return a:GetStepsType() > b:GetStepsType()
    end
end

local function InputHandler(event)
    local pn = event.PlayerNumber
    if not pn then return end

    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

    if SongIsChosen and PlayerCanMove[pn] then
        -- Filter out everything but button presses
        if event.type == "InputEventType_Repeat" or event.type == "InputEventType_Release" then return end

        local button = event.button
        if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
            if ChartIndex[pn] == 1 then
                if CanWrap then
                    ChartIndex[pn] = #ChartArray
                else return end
            else
                ChartIndex[pn] = ChartIndex[pn] - 1
            end
            MESSAGEMAN:Broadcast("UpdateChartDisplay", { Player = pn })
            ConfirmStart[pn] = false

        elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
            if ChartIndex[pn] == #ChartArray then
                if CanWrap then
                    ChartIndex[pn] = 1
                else return end
            else
                ChartIndex[pn] = ChartIndex[pn] + 1
            end
            MESSAGEMAN:Broadcast("UpdateChartDisplay", { Player = pn })
            ConfirmStart[pn] = false

        elseif button == "UpLeft" or button == "UpRight" or button == "Up" then
            MESSAGEMAN:Broadcast("StepsUnchosen", { Player = pn })
            MESSAGEMAN:Broadcast("SongUnchosen")
            ConfirmStart[pn] = false

        elseif button == "Start" or button == "MenuStart" or button == "Center" then
            -- No song start while any command window is open
            if not (PlayerCanMove[PLAYER_1] and PlayerCanMove[PLAYER_2]) then return end
            if ConfirmStart[pn] then
                SongIsChosen = false

                -- Set these or else we crash.
                GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
                GAMESTATE:SetCurrentStyle(GAMESTATE:GetNumSidesJoined() > 1 and "versus" or string.lower(ShortType(GAMESTATE:GetCurrentSteps(pn))))
                SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
            else
                MESSAGEMAN:Broadcast("StepsChosen", { Player = pn })
                ConfirmStart[pn] = true
            end
        end
    end
    return
end

local t = Def.ActorFrame {
    OnCommand=function(self)
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
        self:playcommand("Refresh")
    end,

    -- Prevent the chart list from moving when transitioning
    OffCommand=function(self)
        SongIsChosen = false
    end,

    -- This is done to workaround the loss of input when doing the command window pad code
    CodeMessageCommand=function(self, params)
        if params.Name == "OpenOpList" then
            local pn = params.PlayerNumber

            if SongIsChosen and PlayerCanMove[pn] then
                if ChartIndex[pn] == #ChartArray then
                    if CanWrap then
                        ChartIndex[pn] = 1
                    else return end
                else
                    ChartIndex[pn] = ChartIndex[pn] + 1
                end
                MESSAGEMAN:Broadcast("UpdateChartDisplay", { Player = pn })
            end
        end
    end,

    -- Update chart list
    UpdateChartDisplayMessageCommand=function(self) self:playcommand("Refresh") end,
    CurrentSongChangedMessageCommand=function(self) SnapToGroup = true self:playcommand("Refresh") end,
    -- Group changed without the song changing (same first song): snap as well
    ForceUpdateMessageCommand=function(self) SnapToGroup = true self:playcommand("Refresh") end,

    -- These are to control the visibility of the chart highlight.
    SongChosenMessageCommand=function(self) SongIsChosen = true self:playcommand("Refresh") end,
    SongUnchosenMessageCommand=function(self) SongIsChosen = false self:playcommand("Refresh") end,

    OptionsListOpenedMessageCommand=function(self, params) PlayerCanMove[params.Player] = false end,
    OptionsListClosedMessageCommand=function(self, params) PlayerCanMove[params.Player] = true end,

    RefreshCommand=function(self)
        ChartArray = nil
        local CurrentSong = GAMESTATE:GetCurrentSong()
        if CurrentSong then
            ChartArray = SongUtil.GetPlayableSteps(CurrentSong)

            -- Filter out unwanted charts recursively
            local CurGroupName = GroupsList[LastGroupMainIndex] ~= nil and
            GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex].Name or ""

            local ShowFilters = {"ShowUCSCharts", "ShowQuestCharts", "ShowHiddenCharts" }
            local ChartFilters = {"UCS", "QUEST", "HIDDEN" }
            local PrevChartArray

            for i = 1, 3 do
                if LoadModule("Config.Load.lua")(ShowFilters[i], "Save/OutFoxPrefs.ini") == false then
                    -- Only make a copy of the array if an attempt at removal will happen
                    PrevChartArray = ShallowCopy(ChartArray)

                    for j = #ChartArray, 1, -1 do
                        if string.find(ToUpper(ChartArray[j]:GetDescription()), ChartFilters[i]) then
                            table.remove(ChartArray, j)
                        end
                    end

                    if #ChartArray == 0 then ChartArray = ShallowCopy(PrevChartArray) end
                end
            end

            -- Normal chart checks
            for i = #ChartArray, 1, -1 do
                -- Couple and Routine crashes the game :(
                if string.find(ToUpper(ChartArray[i]:GetStepsType()), "ROUTINE") or
                    string.find(ToUpper(ChartArray[i]:GetStepsType()), "COUPLE") then
                    table.remove(ChartArray, i)
                end

                -- Co-op group should only display co-op charts
                if CurGroupName ~= nil and CurGroupName == "Co-op" then
                    if ChartArray[i]:GetStepsType() == 'StepsType_Pump_Double' and
                    (string.find(ToUpper(ChartArray[i]:GetDescription()), "DP") or
                    string.find(ToUpper(ChartArray[i]:GetDescription()), "COOP")) and
                    ChartArray[i]:GetMeter() == 99 then else
                        table.remove(ChartArray, i)
                    end
                end
            end

            -- If no charts are left, load all of them again in an attempt to avoid other crashes
            if #ChartArray == 0 then ChartArray = SongUtil.GetPlayableSteps(CurrentSong) end
            table.sort(ChartArray, SortCharts)

            -- Level groups: land on the chart of the group's level
            if SnapToGroup then
                local LevelIndex = FindGroupLevelChart(ChartArray, CurGroupName)
                if LevelIndex then
                    ChartIndex[PLAYER_1] = LevelIndex
                    ChartIndex[PLAYER_2] = LevelIndex
                end
            end
        end
        SnapToGroup = false

        if ChartArray then
            -- Correct player chart indexes to ensure they're not off limits
            if ChartIndex[PLAYER_1] < 1 then ChartIndex[PLAYER_1] = 1
            elseif ChartIndex[PLAYER_1] > #ChartArray then ChartIndex[PLAYER_1] = #ChartArray end

            if ChartIndex[PLAYER_2] < 1 then ChartIndex[PLAYER_2] = 1
            elseif ChartIndex[PLAYER_2] > #ChartArray then ChartIndex[PLAYER_2] = #ChartArray end

            -- Set the selected charts and broadcast a new message to avoid possible
            -- race conditions trying to obtain the currently selected chart.
            if GAMESTATE:IsPlayerEnabled(PLAYER_1) then
                GAMESTATE:SetCurrentSteps(PLAYER_1, ChartArray[ChartIndex[PLAYER_1]])
                if ChartIndex[PLAYER_1] ~= PrevChartIndex[PLAYER_1] then
                MESSAGEMAN:Broadcast("CurrentChartChanged", { Player = PLAYER_1 }) end
            end
            if GAMESTATE:IsPlayerEnabled(PLAYER_2) then
                GAMESTATE:SetCurrentSteps(PLAYER_2, ChartArray[ChartIndex[PLAYER_2]])
                if ChartIndex[PLAYER_2] ~= PrevChartIndex[PLAYER_2] then
                MESSAGEMAN:Broadcast("CurrentChartChanged", { Player = PLAYER_2 }) end
            end

            -- After we use the previous chart index, we update it in advance for the next refresh
            PrevChartIndex[PLAYER_1] = ChartIndex[PLAYER_1]
            PrevChartIndex[PLAYER_2] = ChartIndex[PLAYER_2]
        end

        MESSAGEMAN:Broadcast("ChartRowChanged", {
            Charts = ChartArray or {},
            Index = { [PLAYER_1] = ChartIndex[PLAYER_1], [PLAYER_2] = ChartIndex[PLAYER_2] },
            Song = CurrentSong,
            Chosen = SongIsChosen,
        })
    end,

    Def.Sound {
        File=THEME:GetPathS("Common", "value"),
        IsAction=true,
        UpdateChartDisplayMessageCommand=function(self) self:play() end
    },
    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        StepsChosenMessageCommand=function(self) self:play() end
    }
}

return t
