function stepJ!(m::Model)
    @debug "J"
    s = m.s[m.t]
    hs = filter(h -> h.rc < h.rc_, s.Hs)
    fcs = filter(f -> f.s < f.c, s.FCs)
    while length(hs) > 0 && length(fcs) > 0
        h = rand(hs)
        ffcs = filter(f -> ceil(Int, f.pF * (1 + m.p.τC)) <= h.D, fcs)
        if length(ffcs) == 0
            filter!(e -> e != h, hs)
            continue
        end
        f = sort(sample(ffcs, min(length(ffcs), m.p.χC), replace=false), by=(f -> f.pF))[1]
        rc = min(h.rc_ - h.rc, ceil(Int, h.rc_ / m.p.χC), floor(Int, h.D / ceil(Int, f.pF * (1 + m.p.τC))), f.c - f.s)
        nc = f.pF * rc
        tax = floor(Int, m.p.τC * nc)
        h.D -= nc
        f.D += nc
        f.s += rc
        h.rc += rc
        h.nc += nc
        h.D -= tax
        s.B.D += tax
        s.B.B -= tax
        s.G.B += tax
        h.t -= tax
        s.G.T += tax
        if h.rc >= h.rc_
            filter!(e -> e != h, hs)
        end
        if f.s >= f.c
            filter!(e -> e != f, fcs)
        end
    end
end