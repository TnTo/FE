
function stepO!(m::Model)
    @debug "O"
    s = m.s[m.t]
    for f = s.FCs
        Δ = f.pF * f.s - f.wF
        if Δ < 0
            ws = sort(map(id -> s.Hs[id], f.employees), by=h -> h.σ, rev=true)
            while Δ < 0 && length(ws) > 0
                h = popfirst!(ws)
                fire!(h)
                filter!(i -> i != h.id, f.employees)
                Δ += h.wF
            end
        end
        D_ = ceil(Int, m.p.ρF * (f.wF + f.i))
        if D_ < f.D
            f.π = f.D - D_
            f.D -= f.π
            s.B.D += f.π
            s.B.Π += f.π
        else
            f.π = 0
        end
    end
    for f = s.FKs
        Δ = f.p * f.s - f.wF
        if Δ < 0
            ws = sort(map(id -> s.Hs[id], f.employees), by=h -> h.σ, rev=true)
            while Δ < 0 && length(ws) > 0
                h = popfirst!(ws)
                fire!(h)
                filter!(i -> i != h.id, f.employees)
                Δ += h.wF
            end
        end
        D_ = ceil(Int, m.p.ρF * f.wF)
        if D_ < f.D
            f.π = f.D - D_
            f.D -= f.π
            s.B.D += f.π
            s.B.Π += f.π
        else
            f.π = 0
        end
    end
end