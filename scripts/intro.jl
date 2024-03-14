using DrWatson
@quickactivate "DAS"

using ProgressBars
using Plots
using Statistics

include(srcdir("DAS.jl"))

p = DAS.Parameters()

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
        s -> sum(h -> h.rc_, s.Hs),
        s -> sum(h -> h.rc, s.Hs),
        s -> s.G.rC,
        s -> sum(f -> f.c_, s.FCs),
        s -> sum(f -> f.c, s.FCs),
        s -> sum(f -> DAS.b(m, f), s.FCs),
        s -> sum(f -> length(f.employees), s.FCs)
    ],
    ["H rc_" "H rc" "G rc" "F c_" "F c" "F b"]
)

DAS.map_plot(m,
    [
        s -> sum(f -> length(f.inv), s.FKs),
        s -> sum(f -> f.Δb_, s.FCs),
        s -> sum(f -> f.Δb, s.FCs),
        s -> sum(f -> f.Δb_, s.FKs),
        s -> sum(f -> f.k_ * f.β * m.p.k, s.FKs),
        s -> sum(f -> f.k * f.β * m.p.k, s.FKs),
        s -> sum(f -> DAS.b(m, f), s.FKs),
        s -> sum(f -> length(f.employees), s.FKs),
        s -> sum(f -> f.s, s.FKs),
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
        s -> sum(f -> length(f.inv), s.FKs),
        s -> sum(f -> length(f.employees), s.FKs),
        s -> sum(f -> f.s, s.FKs),
        s -> sum(f -> f.k, s.FKs),
        s -> sum(f -> DAS.b(m, f), s.FKs),
        s -> sum(f -> length(f.K), s.FKs),
        s -> sum(f -> f.k_, s.FKs),
    ],
    ["inv" "empl FK" "s FK" "k FK" "b FK" "K FK" "k_ FK"]
)

DAS.map_plot(m,
    [
        s -> sum(f -> length(f.Q), s.FKs),
        s -> sum(f -> f.q_, s.FKs),
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

DAS.map_plot(m,
    [
        s -> DAS.mapmean(f -> f.μ, s.FKs),
        s -> DAS.mapmean(f -> f.μ, s.FCs),
    ],
    ["μK" "μC"]
)

scatter(map(h -> h.σ, m.s[end].Hs), map(h -> h.wF, m.s[end].Hs))