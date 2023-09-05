using DrWatson
@quickactivate "DAS"

using ProgressBars

include(srcdir("DAS.jl"))

p = DAS.get_default_parameters()
m = DAS.create_model(p)
for t = ProgressBar(1:m.p.T)
    DAS.step!(m)
end
DAS.display_matrices(m.states[end], m.states[end-1], m)