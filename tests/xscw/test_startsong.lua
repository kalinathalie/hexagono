-- Select.StartSong: where song select opens at the start of a new game.

local Start = LoadModule("Select.StartSong.lua")

local function Groups()
    return {
        { Name = "Special", SubGroups = { { Name = "All Tunes", Songs = { 1, 2, 3 } } } },
        { Name = "Group", SubGroups = {
            { Name = "01 - 1ST~3RD", Songs = { "a", "b" } },
            { Name = "16 - PHOENIX", Songs = { "c" } },
            { Name = "17 - PHOENIX 2", Songs = { "d", "e", "f", "g" } },
            { Name = "Zz Custom Pack", Songs = { "h" } },
        } },
    }
end

Test("StartSong: the newest numbered version group, a random song in it", function()
    local M, S, I = Start.Pick(Groups(), function(n) return n end)
    CheckEq(M, 2, "versions category"); CheckEq(S, 3, "17 - PHOENIX 2, not the custom pack after it"); CheckEq(I, 4, "random index from 1..4")
    local _, _, I2 = Start.Pick(Groups(), function(n) return 1 end)
    CheckEq(I2, 1, "random 1")
end)

Test("StartSong: without numbered groups the last version group is used", function()
    local G = Groups(); G[2].SubGroups = { { Name = "Pack A", Songs = { 1 } }, { Name = "Pack B", Songs = { 1, 2 } } }
    local M, S = Start.Pick(G, function(n) return 1 end)
    CheckEq(M, 2, "versions"); CheckEq(S, 2, "last one")
end)

Test("StartSong: nothing to pick without a versions category or songs", function()
    CheckEq(Start.Pick({ { Name = "Special", SubGroups = { { Name = "All Tunes", Songs = { 1 } } } } }, math.random), nil, "no Group category")
    local G = Groups(); G[2].SubGroups[3].Songs = {}
    local M, S = Start.Pick(G, function(n) return 1 end)
    CheckEq(S, 2, "an empty newest group falls back to the next numbered one")
end)
