using DrWatson
@quickactivate "DAS"

using ProgressBars
using Plots
using Statistics

include(srcdir("DAS.jl"))

p = DAS.Parameters()

p.T = 100

m = DAS.create_model(p)
#try
for t = ProgressBar(1:m.p.T)
    DAS.step!(m, print=false)
end
#finally
#end
DAS.display_matrices(m, m.t)

DAS.map_plot(m,
    [
        s -> DAS.mapsum(h -> h.rc_, s.Hs),
        s -> DAS.mapsum(h -> h.rc, s.Hs),
        s -> s.G.rC,
        s -> DAS.mapsum(f -> f.c_, s.FCs),
        s -> DAS.mapsum(f -> f.c, s.FCs)
    ],
    ["H rc_" "H rc" "G rc" "F c_" "F c"]
)

DAS.map_plot(m,
    [
        s -> DAS.mapsum(f -> length(f.inv), s.FKs),
        s -> DAS.mapsum(f -> f.Δb_, s.FCs),
        s -> DAS.mapsum(f -> f.Δb, s.FCs),
        s -> DAS.mapsum(f -> f.Δb_, s.FKs),
        s -> DAS.mapsum(f -> f.k_ * f.β * m.p.k, s.FKs),
        s -> DAS.mapsum(f -> f.k * f.β * m.p.k, s.FKs),
        s -> DAS.mapsum(f -> DAS.b(m, f), s.FKs),
        s -> DAS.mapsum(f -> length(f.employees), s.FKs),
        s -> DAS.mapsum(f -> f.s, s.FKs),
    ],
    ["inv" "Δb_ FC" "Δb FC" "Δb_ FK" "k_" "k" "b FK" "empl FK" "s"]
)

DAS.map_plot(m,
    [
        s -> count(h -> h.employer !== nothing, s.Hs),
        s -> count(h -> h.employer === nothing, s.Hs)
    ],
    ["empl" "unempl"]
)

DAS.map_plot(m, [s -> s.B.rS, s -> s.G.rB], ["rS" "rB"])

DAS.map_plot(m,
    [
        s -> DAS.mapsum(f -> length(f.inv), s.FKs),
        s -> DAS.mapsum(f -> length(f.employees), s.FKs),
        s -> DAS.mapsum(f -> f.s, s.FKs),
        s -> DAS.mapsum(f -> f.k, s.FKs),
        s -> DAS.mapsum(f -> DAS.b(m, f), s.FKs),
        s -> DAS.mapsum(f -> length(f.K), s.FKs),
        s -> DAS.mapsum(f -> f.k_, s.FKs),
    ],
    ["inv" "empl FK" "s FK" "k FK" "b FK" "K FK" "k_ FK"]
)

DAS.map_plot(m,
    [
        s -> DAS.mapsum(f -> length(f.Q), s.FKs),
        s -> DAS.mapsum(f -> f.q_, s.FKs),
    ],
    ["Q" "q_"]
)

DAS.map_plot(m,
    [
        s -> DAS.mapmean(f -> f.p, s.FKs),
        s -> DAS.mapmean(f -> f.pF, s.FCs),
        s -> DAS.mapmean(h -> h.wF, filter(h -> h.employer !== nothing, s.Hs)),
        s -> 0,
        s -> s.stats.p,
        s -> DAS.mapmean(h -> h.D, s.Hs)
    ],
    ["pK" "pC" "w" "0" "<p>" "DH"]
)

scatter(map(h -> h.σ, m.s[end].Hs), map(h -> h.wF, m.s[end].Hs))