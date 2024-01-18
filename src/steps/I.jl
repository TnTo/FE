function stepI!(m::Model)
    s = m.s[m.t]
    s1 = m.s[m.t-1]
    # println("I")
    for h = s.Hs
        if h.employer === nothing
            m = floor(Int, m.p.ϕ * max(s1.Hs[id].m, wH(m, m.t - 1, state1.Hs[id].wF)))
            h.D += m
            s.B.D -= m
            s.B.B += m
            s.G.B -= m
            h.m += m
            s.G.M -= m
        end
    end
    fcs = filter(f -> f.s < f.c, f.FCs)
    for h = shuffle(s.Hs)
        rv = v(s1.Hs[h.id]) / s1.stats.p
        rc_ = ceil(Int, s.G.Ξ * ((1 - m.p.ϵ0) + m.p.ϵ0 * exp(-m.p.ϵ1 * rv)))
        rc = 0
        while rc < rc_ && length(fcs) > 0
            f = rand(fcs)
            if (f.c - f.s) > (rc_ - rc)
                c = (rc_ - rc)
            else
                c = f.c - f.s
                filter!(e -> e == f, fcs)
            end
            rc += c
            state.G.rC += c
            f.s += c
            h.rc += c
            nc = f.pF * c
            s.G.nC += nc
            f.D += nc
            s.B.D -= nc
            s.B.B += nc
            s.G.B -= nc
        end
    end
end