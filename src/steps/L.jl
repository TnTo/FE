function stepL!(m::Model)
    @debug "L"
    s = m.s[m.t]
    for f = s.FKs
        Q = count(r -> r.operator !== nothing, f.Q)
        if rand(Bernoulli(1 - exp(-m.p.ζ * Q)))
            Δβ = rand(Beta(1, m.p.b0))
            Δσ = Δβ - m.p.b1 * rand(Beta(1, m.p.b2))
            f.β += Δβ
            f.σ = max(0.0, f.σ + Δσ)
        end
    end
end