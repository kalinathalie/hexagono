-- Result screen: fades to black in R.TIMES.ExitFade when it is left (Phoenix 2)
local R = LoadModule("Eval.Result.lua")

return Def.Quad {
    StartTransitioningCommand=function(self)
        self:FullScreen():diffuse(Color.Black)
        :diffusealpha(0):linear(R.TIMES.ExitFade):diffusealpha(1)
    end
}
