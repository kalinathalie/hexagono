-- Select.GroupFilter: groups hidden by the number of players. Pure Lua.
--
--   ForPlayers(groups, numPlayers) -> groups
--       With two players (versus, one pad each) Double and Half-Double charts are
--       not playable, and co-op charts are for one player: the Double and
--       Half-Double categories and the Special "Co-op" group are removed.
--       Categories left without groups are removed. The list is changed in place.

local Filter = {}

local TWO_PLAYER_HIDDEN = { ["Double"] = true, ["Half-Double"] = true }

function Filter.ForPlayers(groups, numPlayers)
    if numPlayers < 2 then return groups end
    for i = #groups, 1, -1 do
        local Main = groups[i]
        if TWO_PLAYER_HIDDEN[Main.Name] then
            table.remove(groups, i)
        else
            for j = #Main.SubGroups, 1, -1 do
                if Main.SubGroups[j].Name == "Co-op" then table.remove(Main.SubGroups, j) end
            end
            if #Main.SubGroups == 0 then table.remove(groups, i) end
        end
    end
    return groups
end

return Filter
