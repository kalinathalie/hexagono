-- A soft glow on the receptor of every panel the player is pressing, whatever
-- the noteskin (some skins have no press animation). It only watches the pad
-- input; the noteskin's own receptors and explosions are left alone.
local pn = ...

local ReceptorColumns = LoadModule("Gameplay.ReceptorColumns.lua")
local ReceptorY = THEME:GetMetric("Player", "ReceptorArrowsYStandard")
local ReceptorYReverse = THEME:GetMetric("Player", "ReceptorArrowsYReverse")

local Style = GAMESTATE:GetCurrentStyle()
local NumColumns = Style:ColumnsPerPlayer()
local IsDouble = Style:GetStyleType() == "StyleType_OnePlayerTwoSides"
local Kind = NumColumns == 6 and "half" or IsDouble and "double" or "single"

-- column for a pad press (in double the engine gives both pads to the player: the
-- controller tells them apart)
local function Column(event)
    return ReceptorColumns.For(event.button, event.controller, event.PlayerNumber, pn, Kind)
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
