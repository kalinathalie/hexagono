-- Gameplay.CpuAutoPlay: the operator option "CPU AutoPlay" lets the engine's CPU player
-- play every song by itself, for viewing only (the result screen with real numbers).
-- OutFox's CPU records its judgments, unlike AutoPlay=Autoplay and the PlayerAutoPlay
-- modifier, which hit every note but record nothing. Such plays are never saved.
--
--   Controller(enabled) -> value of the engine's AutoPlay preference
--   SaveScore(enabled, allFailed) -> whether the stage's scores may be saved
return {
    Controller = function(Enabled)
        return Enabled and "PlayerController_Cpu" or "PlayerController_Human"
    end,
    SaveScore = function(Enabled, AllFailed)
        return not Enabled and not AllFailed
    end,
}
