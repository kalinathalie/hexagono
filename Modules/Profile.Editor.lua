-- Profile.Editor: edit a profile's name and photo with the pad, opened from
-- profile select with a panel code. Pure Lua; the screen applies the actions.
--
--   New(profiles, avatars) -> state
--       profiles = { { Index = local index (0-based), Name, Avatar = path or "" } }
--       avatars  = { { file name, path } }  (Profile.GetAvatarImageArray)
--   Mode: "pick" (which profile) -> "menu" (EDIT NAME / EDIT PHOTO) -> "name" (keyboard) | "photo"
--   Move(state, dir)             lower panels
--   Press(state) -> action|nil   center: { Do = "rename", Index, Name } | { Do = "photo", Index, Path ("" = no photo) }
--   Back(state) -> "close"|nil   red panels: erase / one level back / close from the list
--   Profile(state), PhotoPath(state)

local Keyboard = LoadModule("Profile.Keyboard.lua")
local Slots = LoadModule("Profile.Slots.lua")

local Editor = {}
Editor.MENU = { "name", "photo" }

local function Wrap(i, n) return ((i - 1) % n) + 1 end

function Editor.New(profiles, avatars)
    local Photos = {}
    for _, A in ipairs(avatars or {}) do Photos[#Photos + 1] = { Name = A[1], Path = A[2] } end
    Photos[#Photos + 1] = { Name = "", Path = "" }   -- NO PHOTO
    return { Mode = "pick", Profiles = profiles, Photos = Photos, Pick = 1, Menu = 1, Photo = 1 }
end

function Editor.Profile(E) return E.Profiles[E.Pick] end
function Editor.PhotoPath(E) return E.Photos[E.Photo].Path end

function Editor.Move(E, dir)
    if E.Mode == "pick" then E.Pick = Wrap(E.Pick + dir, #E.Profiles)
    elseif E.Mode == "menu" then E.Menu = Wrap(E.Menu + dir, #Editor.MENU)
    elseif E.Mode == "photo" then E.Photo = Wrap(E.Photo + dir, #E.Photos)
    elseif E.Mode == "name" then Keyboard.Move(E.KB, dir) end
end

function Editor.Press(E)
    E.Msg = nil
    local P = Editor.Profile(E)
    if E.Mode == "pick" then
        E.Mode, E.Menu = "menu", 1
    elseif E.Mode == "menu" then
        if Editor.MENU[E.Menu] == "name" then
            E.Mode, E.KB = "name", Keyboard.New(P.Name)
        else
            E.Mode, E.Photo = "photo", #E.Photos
            for i, Photo in ipairs(E.Photos) do
                if Photo.Path ~= "" and Photo.Path == P.Avatar then E.Photo = i end
            end
        end
    elseif E.Mode == "name" then
        local Result = Keyboard.Press(E.KB)
        if Result == "ok" then
            local Name = Slots.CleanName(E.KB.Name)
            if not Name then E.Msg = "empty" return nil end
            E.Mode = "menu"
            P.Name = Name
            return { Do = "rename", Index = P.Index, Name = Name }
        elseif Result == "empty" or Result == "full" then
            E.Msg = Result
        end
    elseif E.Mode == "photo" then
        local Path = Editor.PhotoPath(E)
        E.Mode = "menu"
        P.Avatar = Path
        return { Do = "photo", Index = P.Index, Path = Path }
    end
    return nil
end

function Editor.Back(E)
    E.Msg = nil
    if E.Mode == "pick" then return "close" end
    if E.Mode == "menu" then E.Mode = "pick" return nil end
    if E.Mode == "photo" then E.Mode = "menu" return nil end
    if E.Mode == "name" then
        if Keyboard.Erase(E.KB) == "cancel" then E.Mode = "menu" end
    end
    return nil
end

return Editor
