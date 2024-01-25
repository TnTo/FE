using DrWatson
@quickactivate "DAS"

using ProgressBars
using Plots
using Statistics

include(srcdir("DAS.jl"))

p = DAS.Parameters()

m = DAS.create_model(p)
try
    for t = ProgressBar(1:m.p.T)
        println("STEP $(t)")
        DAS.step!(m)
    end
finally
end
DAS.display_matrices(m.states[end], m.states[end-1], m)
