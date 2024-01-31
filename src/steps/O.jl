
function stepO!(m::Model)
    # println("O")
    s = m.s[m.t]
    for f = s.FCs
        f.π = floor(Int, m.p.ρΠ * (f.pF * f.s - f.wF))
        if f.π > 0
            f.π = min(f.π, f.D)
            f.D -= f.π
            s.B.D += f.π
            s.B.Π += f.π
        else
            ws = sort(map(id -> state.Hs[id], f.employees), by=h -> h.σ, rev=true)
            while f.π < 0 && length(ws) > 0
                h = popfirst!(ws)
                fire!(h)
                filter!(i -> i != h.id, f.employees)
                f.π += h.wF
            end
            f.π = 0
        end
    end
    for f = s.FKs
        f.π = floor(Int, m.p.ρΠ * (f.p * f.s - f.wF))
        if f.π > 0
            f.π = min(f.π, f.D)
            s.B.D += f.π
            s.B.Π += f.π
        else
            ws = sort(map(id -> s.Hs[id], f.employees), by=h -> h.σ, rev=true)
            while f.π < 0 && length(ws) > 0
                h = popfirst!(ws)
                fire!(h)
                filter!(i -> i != h.id, f.employees)
                f.π += h.wF
            end
            f.π = 0
        end
    end
end
