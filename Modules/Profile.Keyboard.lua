-- Profile.Keyboard: typing a profile name with the pad. One row of keys that
-- scrolls with the lower panels; the center panel presses the key under the
-- cursor; the upper panels erase (and cancel when the name is empty).
-- Pure Lua, no engine calls.
--
--   New() -> state { Name, Index, Lower }
--   Current(state) -> key under the cursor ("A".."Z" / "a".."z", digits, "-", "_", ".", "SPACE", "Aa", "DEL", "OK")
--   Label(state, key) -> character typed by that key (nil for the special keys)
--   Move(state, dir)  -- dir -1 / +1, wraps around
--   Press(state) -> "typed" | "full" | "case" | "erased" | "cancel" | "ok" | "empty"
--   Erase(state) -> "erased" | "cancel"

local Keyboard = {}

local MAX = 12
local KEYS = {}
for c = string.byte("A"), string.byte("Z") do KEYS[#KEYS + 1] = string.char(c) end
for c = string.byte("0"), string.byte("9") do KEYS[#KEYS + 1] = string.char(c) end
for _, k in ipairs({ "-", "_", ".", "SPACE", "Aa", "DEL", "OK" }) do KEYS[#KEYS + 1] = k end
Keyboard.KEYS = KEYS
Keyboard.MAX = MAX

function Keyboard.New()
    return { Name = "", Index = 1, Lower = false }
end

local function Key(S, i)
    local k = KEYS[i]
    if #k == 1 and k:match("%a") and S.Lower then return k:lower() end
    return k
end

function Keyboard.Current(S) return Key(S, S.Index) end

-- key at an offset from the cursor (for drawing the row)
function Keyboard.At(S, offset)
    local n = #KEYS
    return Key(S, ((S.Index - 1 + offset) % n) + 1)
end

function Keyboard.Label(S, key)
    if key == "SPACE" then return " " end
    if #key == 1 then return key end
    return nil
end

function Keyboard.Move(S, dir)
    local n = #KEYS
    S.Index = ((S.Index - 1 + dir) % n) + 1
end

function Keyboard.Erase(S)
    if S.Name == "" then return "cancel" end
    S.Name = S.Name:sub(1, -2)
    return "erased"
end

function Keyboard.Press(S)
    local k = Keyboard.Current(S)
    if k == "Aa" then S.Lower = not S.Lower return "case" end
    if k == "DEL" then return Keyboard.Erase(S) end
    if k == "OK" then
        if S.Name:gsub("%s", "") == "" then return "empty" end
        return "ok"
    end
    if #S.Name >= MAX then return "full" end
    S.Name = S.Name .. Keyboard.Label(S, k)
    return "typed"
end

return Keyboard
