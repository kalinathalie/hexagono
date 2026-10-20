-- XSCW.Categories: content and actions of the graphical command window.
-- Pure Lua: every engine/theme access goes through Deps so the module can
-- be unit tested outside OutFox.
--
-- Deps:
--   GetAV(pn) -> number|nil          SetAV(pn, n)
--   GetAVType(pn) -> false|"Auto"|"Constant"   SetAVType(pn, t)
--   GetMod(pn, name) -> bool         SetMod(pn, name, on)
--   GetNoteSkin(pn) -> string        SetNoteSkin(pn, name)
--   NoteSkinNames -> list of strings
--   Text(key) -> string               (strings from [XSCommandWindow])
--
-- Returns a list of categories:
--   { Name, Kind ("items"|"noteskin"|"exit"), Title (png base name or nil),
--     Label, Description, Items = { { Label, Sheet, Frame, Apply(pn),
--     IsActive(pn), Description } }, DefaultItem(pn), Value(pn) (AV only) }

local AV_MIN, AV_MAX, AV_DEFAULT = 100, 999, 200

local function Clamp(n)
    if n < AV_MIN then return AV_MIN end
    if n > AV_MAX then return AV_MAX end
    return n
end

return function(Deps)
    local function CurrentAV(pn)
        return tonumber(Deps.GetAV(pn)) or AV_DEFAULT
    end

    local function ModItem(Label, Frame, Sheet, ModName, DescKey)
        return {
            Label = Label, Sheet = Sheet, Frame = Frame,
            Description = Deps.Text(DescKey),
            Apply = function(pn) Deps.SetMod(pn, ModName, not Deps.GetMod(pn, ModName)) end,
            IsActive = function(pn) return Deps.GetMod(pn, ModName) end,
        }
    end

    -- ===================== SPEED =====================
    local SpeedSheet = "Icons02 13x1"
    local Speed = {
        Name = "Speed", Kind = "items", Title = "01_title",
        Label = Deps.Text("Speed"), Description = Deps.Text("Speed_Desc"),
        Items = {},
    }
    for i = 1, 6 do
        local Target = i * 100
        Speed.Items[#Speed.Items + 1] = {
            Label = i .. "x", Sheet = SpeedSheet, Frame = i - 1,
            Description = Deps.Text("Speed_Fixed"),
            Apply = function(pn) Deps.SetAV(pn, Target); Deps.SetAVType(pn, false) end,
            IsActive = function(pn) return Deps.GetAVType(pn) == false and CurrentAV(pn) == Target end,
        }
    end
    for _, Step in ipairs({ { "+0.25", 25, 6 }, { "+0.5", 50, 7 } }) do
        Speed.Items[#Speed.Items + 1] = {
            Label = Step[1], Sheet = SpeedSheet, Frame = Step[3],
            Description = Deps.Text("Speed_Increment"),
            Apply = function(pn) Deps.SetAV(pn, Clamp(CurrentAV(pn) + Step[2])) end,
            IsActive = function(pn) return false end,
        }
    end
    Speed.Items[#Speed.Items + 1] = ModItem("EW", 8, SpeedSheet, "expand", "Speed_EW")
    Speed.Items[#Speed.Items + 1] = ModItem("RV", 9, SpeedSheet, "randomspeed", "Speed_RV")
    Speed.Items[#Speed.Items + 1] = {
        Label = "AV", Sheet = SpeedSheet, Frame = 10,
        Description = Deps.Text("Speed_AV"),
        Apply = function(pn) Deps.SetAVType(pn, "Constant") end,
        IsActive = function(pn) return Deps.GetAVType(pn) == "Constant" end,
    }
    Speed.Items[#Speed.Items + 1] = ModItem("AC", 11, SpeedSheet, "boost", "Speed_AC")
    Speed.Items[#Speed.Items + 1] = ModItem("DC", 12, SpeedSheet, "brake", "Speed_DC")
    Speed.DefaultItem = function(pn) return 1 end

    -- ================= AUTO VELOCITY =================
    local AVSheet = "Icons11 6x1"
    local AutoVelocity = {
        Name = "AutoVelocity", Kind = "items", Title = "11_title",
        Label = Deps.Text("AutoVelocity"), Description = Deps.Text("AutoVelocity_Desc"),
        Items = {},
        Value = function(pn) return tostring(CurrentAV(pn)) end,
    }
    for i, Step in ipairs({ 100, 10, 1, -1, -10, -100 }) do
        AutoVelocity.Items[#AutoVelocity.Items + 1] = {
            Label = (Step > 0 and "+" or "") .. Step, Sheet = AVSheet, Frame = i - 1,
            Description = Deps.Text("AutoVelocity_Step"),
            Apply = function(pn) Deps.SetAV(pn, Clamp(CurrentAV(pn) + Step)) end,
            IsActive = function(pn) return false end,
        }
    end
    for _, Kind in ipairs({ { "Multiply", false }, { "Auto", "Auto" }, { "Constant", "Constant" } }) do
        AutoVelocity.Items[#AutoVelocity.Items + 1] = {
            Label = Deps.Text(Kind[1]), Sheet = nil, Frame = 0,
            Description = Deps.Text("AutoVelocity_" .. Kind[1]),
            Apply = function(pn) Deps.SetAVType(pn, Kind[2]) end,
            IsActive = function(pn) return Deps.GetAVType(pn) == Kind[2] end,
        }
    end
    AutoVelocity.DefaultItem = function(pn) return 1 end

    -- =================== NOTE SKIN ===================
    local NoteSkin = {
        Name = "NoteSkin", Kind = "noteskin", Title = "03_title",
        Label = Deps.Text("NoteSkin"), Description = Deps.Text("NoteSkin_Desc"),
        Items = {},
    }
    for _, SkinName in ipairs(Deps.NoteSkinNames or {}) do
        NoteSkin.Items[#NoteSkin.Items + 1] = {
            Label = SkinName, Sheet = nil, Frame = 0,
            Description = SkinName,
            Apply = function(pn) Deps.SetNoteSkin(pn, SkinName) end,
            IsActive = function(pn)
                return string.lower(tostring(Deps.GetNoteSkin(pn))) == string.lower(SkinName)
            end,
        }
    end
    NoteSkin.DefaultItem = function(pn)
        local Current = string.lower(tostring(Deps.GetNoteSkin(pn)))
        for i, Item in ipairs(NoteSkin.Items) do
            if string.lower(Item.Label) == Current then return i end
        end
        return 1
    end

    -- ====================== EXIT =====================
    local Exit = {
        Name = "Exit", Kind = "exit", Title = nil,
        Label = Deps.Text("Exit"), Description = Deps.Text("Exit_Desc"),
    }

    return { Speed, AutoVelocity, NoteSkin, Exit }
end
