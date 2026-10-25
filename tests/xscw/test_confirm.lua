-- Profile.Confirm: when profile select moves on, and with which profiles.

local Confirm = LoadModule("Profile.Confirm.lua")
local P1, P2 = "PlayerNumber_P1", "PlayerNumber_P2"

Test("Confirm: waits until every joined player is ready", function()
    CheckEq(Confirm.Plan({ [P1] = { Ready = true, Index = 1, ID = "00000000" }, [P2] = { Ready = false, Index = 0 } }), nil, "P2 not ready")
end)

Test("Confirm: a profile and a guest load only the profile (the bug: both became guests)", function()
    local Plan = Confirm.Plan({ [P1] = { Ready = true, Index = 1, ID = "00000000" }, [P2] = { Ready = true, Index = 0 } })
    CheckEq(Plan.AllGuest, false, "not all guests")
    CheckEq(Plan.DefaultIDs[P1], "00000000", "P1 loads K4L1zinha")
    CheckEq(Plan.DefaultIDs[P2], "", "P2 stays a guest")
end)

Test("Confirm: guests only skip profile loading", function()
    local Plan = Confirm.Plan({ [P1] = { Ready = true, Index = 0 } })
    CheckEq(Plan.AllGuest, true, "one guest")
    local Plan2 = Confirm.Plan({ [P1] = { Ready = true, Index = 0 }, [P2] = { Ready = true, Index = 0 } })
    CheckEq(Plan2.AllGuest, true, "two guests")
end)

Test("Confirm: two profiles load both", function()
    local Plan = Confirm.Plan({ [P1] = { Ready = true, Index = 2, ID = "00000001" }, [P2] = { Ready = true, Index = 1, ID = "00000000" } })
    CheckEq(Plan.DefaultIDs[P1], "00000001", "P1"); CheckEq(Plan.DefaultIDs[P2], "00000000", "P2")
end)

Test("Confirm: a profile taken by the other player cannot be picked; guest always can", function()
    CheckEq(Confirm.Allowed(1, 1), false, "same profile")
    CheckEq(Confirm.Allowed(2, 1), true, "another profile")
    CheckEq(Confirm.Allowed(0, 0), true, "both guests")
    CheckEq(Confirm.Allowed(1, nil), true, "nobody else")
end)

Test("Confirm: dropping a player who joined mid-session goes back to a one-player style", function()
    -- joining from song select sets versus, and the engine keeps counting both players
    -- as human under it after one unjoins
    CheckEq(Confirm.StyleAfterDrop("StyleType_TwoPlayersTwoSides"), "single", "versus")
    CheckEq(Confirm.StyleAfterDrop("StyleType_TwoPlayersSharedSides"), "single", "shared sides")
    CheckEq(Confirm.StyleAfterDrop("StyleType_OnePlayerOneSide"), nil, "already one player")
    CheckEq(Confirm.StyleAfterDrop(nil), nil, "no style yet (joined on the title screen)")
end)
