function stepM!(m::Model)
    # println("M")
    s = m.s[m.t]
    for h = s.Hs
        if h.employer === nothing
            h.σ = h.σ / (1 + m.p.Σ)
        elseif !h.employer_changed
            h.σ = h.σ * (1 + m.p.Σ)
        end
    end
end