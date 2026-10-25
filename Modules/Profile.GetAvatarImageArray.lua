-- Function to return all available avatars: OutFox's Appearance/Avatars folder, then the
-- Phoenix player icons in the theme's Graphics/Phoenix/Avatars (local art made by
-- pi/assets/avatars.py; OutFox reads Appearance only from its install folder).
-- Each item is { file name, path }, by name within each folder.
return function()
    local result = {} -- Here will be the end result.
    local dirs = {
        "/Appearance/Avatars/",
        "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/Phoenix/Avatars/",
    }
    for _, dir in ipairs(dirs) do
        local names = {}
        for _, name in ipairs(FILEMAN:GetDirListing(dir, false, false) or {}) do
            -- Only accept images, anything else should be ignored as we're going to load these
            -- directly as a sprite.
            if ActorUtil.GetFileType(name) == "FileType_Bitmap" then names[#names+1] = name end
        end
        table.sort(names, function(a, b) return a:lower() < b:lower() end)
        -- In this case, we will return the absolute path to the image, to make it easier.
        for _, name in ipairs(names) do result[#result+1] = {name, dir..name} end
    end
    -- Now that we've finished gathering all of the images, return the table.
    return result
end
