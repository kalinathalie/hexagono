-- Minimal test runner for the pure XSCW modules (Lua 5.1 / LuaJIT).
-- Usage, from the theme root:  luajit tests/xscw/run.lua [file ...]
--   No arguments: runs the default list (missing files are skipped).
--   File arguments: runs only those, in the order given; if one is missing,
--   prints it and exits 1 before running anything.
-- Stubs the only engine helper the modules use (LoadModule) so they load
-- from Modules/ without OutFox.

local Passed, Failed = 0, 0
local Current = ""

function LoadModule(Name)
    return dofile("Modules/" .. Name)
end

function Check(Cond, Msg)
    if Cond then
        Passed = Passed + 1
    else
        Failed = Failed + 1
        print("FAIL [" .. Current .. "] " .. tostring(Msg))
    end
end

function CheckEq(Got, Want, Msg)
    Check(Got == Want, (Msg or "") .. " (got " .. tostring(Got) .. ", want " .. tostring(Want) .. ")")
end

function Test(Name, Fn)
    Current = Name
    local Ok, Err = pcall(Fn)
    if not Ok then
        Failed = Failed + 1
        print("ERROR [" .. Name .. "] " .. tostring(Err))
    end
end

local Files = {
    "tests/xscw/test_state.lua", "tests/xscw/test_categories.lua",
    "tests/xscw/test_records.lua", "tests/xscw/test_chartrow.lua", "tests/xscw/test_wheel.lua", "tests/xscw/test_groups.lua",
    "tests/xscw/test_title.lua", "tests/xscw/test_profiles.lua", "tests/xscw/test_hidden.lua", "tests/xscw/test_startsong.lua", "tests/xscw/test_confirm.lua", "tests/xscw/test_editor.lua",
    "tests/xscw/test_judgeoffset.lua", "tests/xscw/test_receptors.lua", "tests/xscw/test_avatars.lua",
    "tests/xscw/test_eval.lua", "tests/xscw/test_cpuautoplay.lua", "tests/xscw/test_hud.lua",
}
local function Exists(File)
    local Fh = io.open(File, "r")
    if Fh then
        Fh:close()
        return true
    end
    return false
end

local Args = arg or {}
local Run = {}
if #Args > 0 then
    for _, File in ipairs(Args) do
        if not Exists(File) then
            print("missing test file: " .. File)
            os.exit(1)
        end
        Run[#Run + 1] = File
    end
else
    for _, File in ipairs(Files) do
        if Exists(File) then
            Run[#Run + 1] = File
        end
    end
end

for _, File in ipairs(Run) do
    dofile(File)
end

print(string.format("%s: %d passed, %d failed", Failed == 0 and "OK" or "FAILED", Passed, Failed))
os.exit(Failed == 0 and 0 or 1)
