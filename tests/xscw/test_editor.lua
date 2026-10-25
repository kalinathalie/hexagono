-- Pad.Code (panel codes) and Profile.Editor (edit a profile's name and photo from the pad).

local Code = LoadModule("Pad.Code.lua")
local Editor = LoadModule("Profile.Editor.lua")
local P1, P2 = "PlayerNumber_P1", "PlayerNumber_P2"
local EDIT = { "DownLeft", "DownRight", "DownLeft", "DownRight", "DownLeft", "DownRight" }

Test("Code: the full sequence completes, per player", function()
    local C = Code.New(EDIT, 2)
    local Got
    for i, b in ipairs(EDIT) do
        Got = Code.Press(C, P1, b, i * 0.2)
        if i < #EDIT then CheckEq(Got, false, "step " .. i) end
        Code.Press(C, P2, "UpLeft", i * 0.2 + 0.1)
    end
    CheckEq(Got, true, "done for P1, P2 presses do not interfere")
end)

Test("Code: a wrong panel, a center press or a pause breaks it", function()
    local C = Code.New(EDIT, 2)
    for i = 1, 3 do Code.Press(C, P1, EDIT[i], i * 0.2) end
    Code.Press(C, P1, "UpLeft", 1)
    local Got
    for i = 4, 6 do Got = Code.Press(C, P1, EDIT[i], 1 + i * 0.2) end
    CheckEq(Got, false, "wrong panel restarts")
    local C2 = Code.New(EDIT, 2)
    for i = 1, 5 do Code.Press(C2, P1, EDIT[i], i * 0.2) end
    CheckEq(Code.Press(C2, P1, EDIT[6], 5), false, "pause over 2 s")
    local C3 = Code.New(EDIT, 2)
    for i = 1, 5 do Code.Press(C3, P1, EDIT[i], i * 0.2) end
    Code.Press(C3, P1, "Center", 1.1)
    CheckEq(Code.Press(C3, P1, EDIT[6], 1.2), false, "center in the middle")
end)

local function NewEditor()
    return Editor.New(
        { { Index = 0, Name = "K4L1zinha", Avatar = "/Appearance/Avatars/Narumi2.png" }, { Index = 1, Name = "hexagono", Avatar = "" } },
        { { "Blue Arrow.png", "/Appearance/Avatars/Blue Arrow.png" }, { "Narumi2.png", "/Appearance/Avatars/Narumi2.png" } })
end

Test("Editor: pick a profile, then the menu; red goes back and closes", function()
    local E = NewEditor()
    CheckEq(E.Mode, "pick", "starts on the profile list")
    Editor.Move(E, 1); CheckEq(Editor.Profile(E).Name, "hexagono", "moves")
    Editor.Move(E, 1); CheckEq(Editor.Profile(E).Name, "K4L1zinha", "wraps")
    CheckEq(Editor.Press(E), nil, "no action yet"); CheckEq(E.Mode, "menu", "menu")
    CheckEq(Editor.Back(E), nil, "back to the list"); CheckEq(E.Mode, "pick", "list")
    CheckEq(Editor.Back(E), "close", "red on the list closes the editor")
end)

Test("Editor: edit name starts with the current name and renames on OK", function()
    local E = NewEditor()
    Editor.Press(E)                          -- K4L1zinha -> menu
    CheckEq(Editor.Press(E), nil, "EDIT NAME")
    CheckEq(E.Mode, "name", "keyboard"); CheckEq(E.KB.Name, "K4L1zinha", "prefilled")
    Editor.Back(E); Editor.Back(E)           -- erase two letters
    CheckEq(E.KB.Name, "K4L1zin", "erased")
    local Keyboard = LoadModule("Profile.Keyboard.lua")
    while Keyboard.Current(E.KB) ~= "OK" do Keyboard.Move(E.KB, 1) end
    local A = Editor.Press(E)
    CheckEq(A and A.Do, "rename", "rename action"); CheckEq(A.Index, 0, "profile 0"); CheckEq(A.Name, "K4L1zin", "new name")
    CheckEq(E.Mode, "menu", "back to the menu")
end)

Test("Editor: erasing the whole name and one more red leaves the keyboard without renaming", function()
    local E = NewEditor()
    Editor.Move(E, 1); Editor.Press(E); Editor.Press(E)      -- hexagono, EDIT NAME
    for i = 1, 8 do Editor.Back(E) end
    CheckEq(E.Mode, "name", "still typing with an empty name")
    CheckEq(Editor.Back(E), nil, "one more red"); CheckEq(E.Mode, "menu", "back to the menu")
end)

Test("Editor: edit photo starts on the current photo; NO PHOTO comes after the last photo", function()
    local E = NewEditor()
    Editor.Press(E); Editor.Move(E, 1)        -- menu: EDIT PHOTO
    CheckEq(Editor.Press(E), nil, "open photos")
    CheckEq(E.Mode, "photo", "photo row")
    CheckEq(Editor.PhotoPath(E), "/Appearance/Avatars/Narumi2.png", "cursor on the current photo")
    Editor.Move(E, 1)
    CheckEq(Editor.PhotoPath(E), "", "after the last photo comes NO PHOTO")
    local A = Editor.Press(E)
    CheckEq(A and A.Do, "photo", "photo action"); CheckEq(A.Path, "", "no photo"); CheckEq(A.Index, 0, "profile 0")
    CheckEq(E.Mode, "menu", "back to the menu")
    local E2 = NewEditor(); Editor.Move(E2, 1); Editor.Press(E2); Editor.Move(E2, 1); Editor.Press(E2)
    CheckEq(Editor.PhotoPath(E2), "", "a profile without photo starts on NO PHOTO")
end)
