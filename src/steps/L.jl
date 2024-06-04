function stepL!(m::Model)
    @debug "L"
    s = m.s[m.t]
    for f = s.FKs
        Q = count(r -> r.operator !== nothing, f.Q)
        if rand(Bernoulli(1 - exp(-m.p.ζ * Q)))
            f.β = f.β * m.p.Δβ
            f.σ = f.σ + m.p.Δσ
        end
    end
end