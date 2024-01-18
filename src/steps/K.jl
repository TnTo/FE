function stepK!(m::Model)
    # println("K")
    s = m.s[m.t]
    for f = f.FCs
        filter!(k -> k.age == m.p.NK, f.K)
    end
    for f = f.FKs
        filter!(k -> k.age == m.p.NK, f.K)
        filter!(k -> k.age == m.p.NK, f.inv)
    end
    fcs = filter(f -> f.Δb < f.Δb_, s.FCs)
    fks = filter(f -> length(f.inv) > 0, s.FKs)
    while length(fcs) > 0 && length(fks) > 0
        fc = rand(fcs)
        ffks = filter(fk -> any(map(k -> p(m, k) <= fc.D, fk.inv)), fks) # Feasible ks
        if length(ffks) == 0
            filter!(e -> e != fc, fcs)
            continue
        end
        fk = sort(sample(ffks, min(length(ffks), m.p.χK), replace=false), by=f -> f.β * m.p.k * fc.pF - Ewσ(f.σ, state) - f.p / m.p.NK)[1] # The promised β, σ, p/N are not necessary the ones sold !!!
        let nk_ = min(ceil(Int, fc.Δb_ - fc.Δb), ceil(Int, fc.Δb_ / m.p.χK), length(fk.inv))
            nk = 0
            i = 1
            while nk < nk_ && i <= length(fk.inv)
                if p(m, fk.inv[i]) <= fc.D
                    k = popat!(fk.inv, i)
                    push!(fc.K, k)
                    fc.Δb += k.β * m.p.k
                    fc.i += p(m, k)
                    fk.s += 1
                    fc.D -= k.p
                    fk.D += k.p
                    nk += 1
                else
                    i += 1
                end
            end
        end
        if fc.Δb_ <= fc.Δb
            filter!(e -> e != fc, fcs)
        end
        if length(fk.inv) == 0
            filter!(e -> e != fk, fks)
        end
    end
end