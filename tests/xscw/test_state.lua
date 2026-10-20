-- Tests for Modules/XSCW.State.lua (navigation state of the command window)

local NewState = LoadModule("XSCW.State.lua")

local function FakeCategories()
    return {
        { Name = "A", Kind = "items", Items = { "a1", "a2", "a3" }, DefaultItem = function(pn) return 2 end },
        { Name = "B", Kind = "noteskin", Items = { "n1", "n2", "n3", "n4", "n5" }, DefaultItem = function(pn) return 4 end },
        { Name = "Exit", Kind = "exit" },
    }
end

Test("OpenWindow starts at the category level keeping the category", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S.Cat = 2
    S:OpenWindow()
    CheckEq(S.Open, true, "Open")
    CheckEq(S.Level, "cat", "Level")
    CheckEq(S.Cat, 2, "Cat kept")
    CheckEq(S.Item, 1, "Item reset")
end)

Test("Move wraps around at the category level", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    CheckEq(S:Move(1), true, "Move returns true")
    CheckEq(S.Cat, 2, "1 -> 2")
    S.Cat = 1
    S:Move(-1)
    CheckEq(S.Cat, 3, "1 -> 3 (wrap)")
    S:Move(1)
    CheckEq(S.Cat, 1, "3 -> 1 (wrap)")
end)

Test("Enter on an items category goes to the item level at DefaultItem", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    CheckEq(S:Enter(), "enter", "Enter result")
    CheckEq(S.Level, "item", "Level")
    CheckEq(S.Item, 2, "DefaultItem")
end)

Test("Move wraps around at the item level", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    S:Enter()
    S:Move(1)
    CheckEq(S.Item, 3, "2 -> 3")
    S:Move(1)
    CheckEq(S.Item, 1, "3 -> 1 (wrap)")
    S:Move(-1)
    CheckEq(S.Item, 3, "1 -> 3 (wrap)")
end)

Test("Enter at the item level applies and stays", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    S:Enter()
    CheckEq(S:Enter(), "apply", "Enter result")
    CheckEq(S.Level, "item", "Level unchanged")
    CheckEq(S.Item, 2, "Item unchanged")
end)

Test("Back goes up one level, then closes", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    S:Enter()
    CheckEq(S:Back(), "back", "Back from item level")
    CheckEq(S.Level, "cat", "Level")
    CheckEq(S:Back(), "close", "Back from category level")
    CheckEq(S.Open, false, "Closed")
end)

Test("Enter on the exit category closes", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    S.Cat = 3
    CheckEq(S:Enter(), "close", "Enter result")
    CheckEq(S.Open, false, "Closed")
end)

Test("Enter on the noteskin category uses its DefaultItem", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    S.Cat = 2
    CheckEq(S:Enter(), "enter", "Enter result")
    CheckEq(S.Item, 4, "DefaultItem")
end)

Test("CurrentCategory and CurrentItem follow the levels", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    CheckEq(S:CurrentCategory().Name, "A", "category")
    CheckEq(S:CurrentItem(), nil, "no item at category level")
    S:Enter()
    CheckEq(S:CurrentItem(), "a2", "item at item level")
    S:Back()
    S.Cat = 3
    CheckEq(S:CurrentItem(), nil, "no item on exit")
end)

Test("CloseWindow resets to the category level", function()
    local S = NewState(FakeCategories(), "PlayerNumber_P1")
    S:OpenWindow()
    S:Enter()
    S:CloseWindow()
    CheckEq(S.Open, false, "Closed")
    CheckEq(S.Level, "cat", "Level")
end)
