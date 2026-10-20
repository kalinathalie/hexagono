-- XSCW.State: navigation state of the graphical command window, one per player.
-- Pure Lua (no engine calls) so it can be unit tested outside OutFox.
--
-- Categories: list of { Kind = "items" | "noteskin" | "exit",
--                       Items = { ... },            -- items/noteskin only
--                       DefaultItem = function(pn) } -- items/noteskin only
--
-- Levels: "cat" (browsing categories) and "item" (browsing the items of
-- the current category).

local function Wrap(Index, Count)
    if Count <= 0 then return 1 end
    return ((Index - 1) % Count) + 1
end

return function(Categories, pn)
    local S = {
        Categories = Categories,
        Player = pn,
        Open = false,
        Level = "cat",
        Cat = 1,
        Item = 1,
    }

    function S:CurrentCategory()
        return self.Categories[self.Cat]
    end

    function S:CurrentItem()
        local Category = self:CurrentCategory()
        if self.Level ~= "item" or not Category or not Category.Items then return nil end
        return Category.Items[self.Item]
    end

    function S:OpenWindow()
        self.Open = true
        self.Level = "cat"
        self.Item = 1
    end

    function S:CloseWindow()
        self.Open = false
        self.Level = "cat"
        self.Item = 1
    end

    -- dir: -1 or +1. Returns true when something moved.
    function S:Move(dir)
        if self.Level == "cat" then
            self.Cat = Wrap(self.Cat + dir, #self.Categories)
            return true
        end
        local Category = self:CurrentCategory()
        if not Category or not Category.Items or #Category.Items == 0 then return false end
        self.Item = Wrap(self.Item + dir, #Category.Items)
        return true
    end

    -- Returns "close" (exit category), "enter" (went into a category) or
    -- "apply" (the current item should be applied by the caller).
    function S:Enter()
        local Category = self:CurrentCategory()
        if not Category then return "close" end
        if Category.Kind == "exit" then
            self:CloseWindow()
            return "close"
        end
        if self.Level == "cat" then
            self.Level = "item"
            local Default = Category.DefaultItem and Category.DefaultItem(self.Player) or 1
            self.Item = Wrap(Default, #Category.Items)
            return "enter"
        end
        return "apply"
    end

    -- Returns "back" (item level -> category level) or "close".
    function S:Back()
        if self.Level == "item" then
            self.Level = "cat"
            self.Item = 1
            return "back"
        end
        self:CloseWindow()
        return "close"
    end

    return S
end
