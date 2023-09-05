using DrWatson
@quickactivate "DAS"

using ProgressBars
using Plots
using Statistics

include(srcdir("DAS.jl"))

p = DAS.get_default_parameters()
p.T = 30
m = DAS.create_model(p)
for t = ProgressBar(1:m.p.T)
    DAS.step!(m)
end
DAS.display_matrices(m.states[end], m.states[end-1], m)
plot(
    DAS.map_plot(m, [s -> (s.stats.Y / s.stats.p), s -> DAS.mapsum(h -> h.rc_, values(s.Hs)), s -> (s.B.l_ * (m.p.NFK + m.p.NFC))], ["~rY" "rD" "L"]),
    DAS.map_plot(m, [s -> s.B.rS, s -> s.C.rB, s -> s.stats.ψ, s -> s.stats.u, s -> s.stats.ω], ["rS" "rB" "inf" "cu" "un"]),
    DAS.map_plot(m, [s -> s.stats.p, s -> mean(map(f -> f.μ, values(merge(s.FKs, s.FCs))))], ["p" "mu"]),
    layout=(3, 1)
)