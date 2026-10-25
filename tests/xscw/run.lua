-- Minimal test runner for the pure XSCW modules (Lua 5.1 / LuaJIT).
-- Usage, from the theme root:  luajit tests/xscw/run.lua
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
    "tests/xscw/test_title.lua", "tests/xscw/test_profiles.lua",
}
for _, File in ipairs(Files) do
    local Fh = io.open(File, "r")
    if Fh then
        Fh:close()
        dofile(File)
    end
end

print(string.format("%s: %d passed, %d failed", Failed == 0 and "OK" or "FAILED", Passed, Failed))
os.exit(Failed == 0 and 0 or 1)
