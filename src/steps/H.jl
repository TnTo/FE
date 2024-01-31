function stepH!(m::Model)
    # println("H")
    s = m.s[m.t]

    for f = s.FCs
        f.c = floor(Int, m.p.k * mapsum(k -> k.β, filter(k -> k.operator !== nothing, f.K)))
        f1 = m.s[m.t-1].FCs[f.id]
        if f.c == 0
            f.pF = ceil(Int, f1.pF * (1 + f.μ) / (1 + f1.μ))
        else
            f.pF = ceil(Int, (1 + f.μ) * (-f.wF) / f.c)
        end
    end
    for f = s.FKs
        f.k = floor(Int, mapsum(k -> k.β, filter(k -> k.operator !== nothing, f.K)))
        f1 = m.s[m.t-1].FKs[f.id]
        if f.k == 0
            f.p = ceil(Int, f1.p * (1 + f.μ) / (1 + f1.μ))
        else
            f.p = ceil(Int, (1 + f.μ) * (f.wF) / f.k)
        end
        for _ = 1:f.k
            push!(f.inv, CapitalGood(f.p, 0, f.σ, f.β, nothing))
        end
        Δ = f.Δb_
        while Δ > 0 && length(f.inv) > 0
            k = pop!(f.inv)
            push!(f.K, k)
            Δ -= k.β
        end
    end
end