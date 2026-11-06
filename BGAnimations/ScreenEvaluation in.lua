-- Result screen: comes out of black in R.TIMES.Fade (Phoenix 2)
local R = LoadModule("Eval.Result.lua")

return Def.Quad {
    OnCommand=function(self)
        self:FullScreen():diffuse(Color.Black)
        :diffusealpha(1):linear(R.TIMES.Fade):diffusealpha(0)
    end
}
