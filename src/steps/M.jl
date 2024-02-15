function stepM!(m::Model)
    # println("M")
    s = m.s[m.t]
    for h = s.Hs
        if h.employer === nothing
            h.σ = max(0, h.σ - m.p.Σ)
        elseif !h.employer_changed
            h.σ = h.σ + m.p.Σ
        end
    end
end