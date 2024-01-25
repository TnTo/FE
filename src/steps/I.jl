function stepI!(m::Model)
    s = m.s[m.t]
    s1 = m.s[m.t-1]
    # println("I")
    for h = s.Hs
        if h.employer === nothing
            M = floor(Int, m.p.ϕ * max(s1.Hs[h.id].m, wH(m, m.t - 1, s1.Hs[h.id].wF)))
            h.D += M
            s.B.D -= M
            s.B.B += M
            s.G.B -= M
            h.m += M
            s.G.M -= M
        end
    end
    fcs = filter(f -> f.s < f.c, s.FCs)
    for h = shuffle(OffsetArrays.no_offset_view(s.Hs))
        rv = v(m, s1.Hs[h.id]) / s1.stats.p
        rc_ = ceil(Int, s.G.Ξ * ((1 - m.p.ϵ0) + m.p.ϵ0 * exp(-m.p.ϵ1 * rv)))
        rc = 0
        while rc < rc_ && length(fcs) > 0
            f = rand(fcs)
            if (f.c - f.s) > (rc_ - rc)
                c = (rc_ - rc)
            else
                c = f.c - f.s
                filter!(e -> e != f, fcs)
            end
            rc += c
            s.G.rC += c
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