-- Select.StartSong: song select opens on a random song of the newest version
-- at the start of every new game. Pure Lua.
--
--   Pick(groups, random) -> mainIndex, subIndex, songIndex  (or nil)
--       groups = GroupsList; random(n) -> 1..n (math.random)
--       The newest version is the "Group" subgroup with the highest leading
--       number ("17 - PHOENIX 2"); custom packs without a number are skipped,
--       unless no group has one. Empty groups are skipped.

local Start = {}

function Start.Pick(groups, random)
    for Main, Category in ipairs(groups or {}) do
        if Category.Name == "Group" then
            local Best, BestNumber = nil, -1
            for Sub, Group in ipairs(Category.SubGroups) do
                local Number = tonumber(tostring(Group.Name):match("^(%d+)"))
                if Number and #(Group.Songs or {}) > 0 and Number > BestNumber then Best, BestNumber = Sub, Number end
            end
            if not Best then
                for Sub = #Category.SubGroups, 1, -1 do
                    if #(Category.SubGroups[Sub].Songs or {}) > 0 then Best = Sub break end
                end
            end
            if not Best then return nil end
            return Main, Best, random(#Category.SubGroups[Best].Songs)
        end
    end
    return nil
end

return Start
