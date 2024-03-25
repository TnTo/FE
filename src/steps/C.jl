function stepC!(m::Model)
    @debug "C"
    Γ0 = Γ(m, m.t - 1)
    s = m.s[m.t]
    if m.s[m.t-1].B.L == 0
        if v(m, m.s[m.t-1].B) > 0
            s.B.rS = max(0, s.G.rB + m.p.λ)
            # s.B.l_ = max(0, floor(Int, v(m, m.s[m.t-1].B) / m.p.Γ_ / (m.p.ν1 * (m.p.NFC + m.p.NFK))))
            s.B.rL = max(0, s.G.rB)
        else
            s.B.rS = 0.0
            # s.B.l_ = 0
            s.B.rL = max(0, s.G.rB + m.p.ν2)
        end
    else
        s.B.rS = max(0, s.G.rB + m.p.λ * (Γ0 - m.p.Γ_))
        # s.B.l_ = max(0, floor(Int, m.s[m.t-1].B.L * (Γ0 / m.p.Γ_ - 1) / (m.p.ν1 * (m.p.NFC + m.p.NFK))))
        s.B.rL = max(0, s.G.rB + m.p.ν2 * (m.p.Γ_ - Γ0))
    end
end