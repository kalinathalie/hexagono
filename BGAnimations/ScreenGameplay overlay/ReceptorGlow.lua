-- A soft glow on the receptor of every panel the player is pressing, whatever
-- the noteskin (some skins have no press animation). It only watches the pad
-- input; the noteskin's own receptors and explosions are left alone.
local pn = ...

local ColumnsByButton = { DownLeft = 1, UpLeft = 2, Center = 3, UpRight = 4, DownRight = 5 }
local ReceptorY = THEME:GetMetric("Player", "ReceptorArrowsYStandard")
local ReceptorYReverse = THEME:GetMetric("Player", "ReceptorArrowsYReverse")

local Style = GAMESTATE:GetCurrentStyle()
local NumColumns = Style:ColumnsPerPlayer()
local IsDouble = Style:GetStyleType() == "StyleType_OnePlayerTwoSides"
local IsHalf = NumColumns == 6

-- column for a pad press: in double the other pad is columns 6-10; half-double uses
-- the inner 6 panels (UpRight, Center, DownRight of pad 1, then DownLeft, UpLeft, Center of pad 2)
local function Column(event)
    local Index = ColumnsByButton[event.button]
    if not Index then return nil end
    local Pad = event.PlayerNumber
    if IsDouble and not IsHalf then
        return Pad == pn and Index or (Index + 5)
    elseif IsHalf then
        local Own = Pad == pn
        local Map = Own and { [3] = 1, [4] = 2, [5] = 3 } or { [1] = 4, [2] = 5, [3] = 6 }
        return Map[Index]
    end
    if Pad ~= pn then return nil end
    return Index
end

local Frame = Def.ActorFrame {
    OnCommand=function(self)
        local Screen = SCREENMAN:GetTopScreen()
        local Player = Screen:GetChild("Player" .. ToEnumShortString(pn))
        if not Player then return end
        local Options = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Current")
        -- follow the player's position, the notefield zoom (mini) and reverse
        self:SetUpdateFunction(function(f)
            local Field = Player:GetChild("NoteField")
            local Zoom = Player:GetZoom() * (Field and Field:GetZoom() or 1)
            local Reverse = Options:Reverse()
            f:xy(Player:GetX(), Player:GetY() + (ReceptorY + (ReceptorYReverse - ReceptorY) * Reverse) * Zoom):zoom(Zoom)
        end)
        Screen:AddInputCallback(function(event)
            if event.type == "InputEventType_Repeat" then return end
            local c = Column(event)
            if not c then return end
            local Glow = self:GetChild("Glow" .. c)
            if Glow then Glow:playcommand(event.type == "InputEventType_FirstPress" and "Press" or "Lift") end
        end)
    end,
}

for c = 1, NumColumns do
    local Info = Style:GetColumnInfo(pn, c)
    Frame[#Frame + 1] = Def.Sprite {
        Name="Glow" .. c,
        Texture=THEME:GetPathG("", "Gameplay/ReceptorGlow"),
        InitCommand=function(self) self:x(Info.XOffset):zoomto(84, 84):blend("BlendMode_Add"):diffusealpha(0) end,
        PressCommand=function(self) self:stoptweening():diffusealpha(0.7):linear(0.12):diffusealpha(0.42) end,
        LiftCommand=function(self) self:stoptweening():linear(0.12):diffusealpha(0) end,
    }
end

return Frame
