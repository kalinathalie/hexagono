-- Profile.GetAvatarImageArray: the photos profile select offers.

local function WithEngine(Listings, Fn)
    local Saved = { FILEMAN = FILEMAN, ActorUtil = ActorUtil, THEME = THEME }
    FILEMAN = { GetDirListing = function(_, Dir) return Listings[Dir] end }
    ActorUtil = { GetFileType = function(Name) return Name:lower():match("%.png$") and "FileType_Bitmap" or "FileType_Unknown" end }
    THEME = { GetCurThemeName = function() return "Infinitesimal" end }
    local Ok, Err = pcall(Fn)
    FILEMAN, ActorUtil, THEME = Saved.FILEMAN, Saved.ActorUtil, Saved.THEME
    if not Ok then error(Err, 0) end
end

local PHOENIX = "/Themes/Infinitesimal/Graphics/Phoenix/Avatars/"

Test("Avatars: OutFox's own, then the Phoenix player icons of the theme", function()
    WithEngine({
        ["/Appearance/Avatars/"] = { "Narumi.png", "Blue Arrow.png" },
        [PHOENIX] = { "PIU 002.png", "PIU 001.png", "notes.txt" },
    }, function()
        local A = LoadModule("Profile.GetAvatarImageArray.lua")()
        CheckEq(#A, 4, "four images")
        CheckEq(A[1][2], "/Appearance/Avatars/Blue Arrow.png", "OutFox's first, by name")
        CheckEq(A[2][1], "Narumi.png", "file name")
        CheckEq(A[3][2], PHOENIX .. "PIU 001.png", "then the theme's, in number order")
        CheckEq(A[4][1], "PIU 002.png", "PIU 002")
    end)
end)

Test("Avatars: a missing folder is skipped", function()
    WithEngine({ ["/Appearance/Avatars/"] = { "foxchan.png" } }, function()
        local A = LoadModule("Profile.GetAvatarImageArray.lua")()
        CheckEq(#A, 1, "only OutFox's")
        CheckEq(A[1][2], "/Appearance/Avatars/foxchan.png", "path")
    end)
end)
