function stepC!(m::Model)
    # println("C")
    Γ0 = Γ(m, -1)
    if m.s[m.t-1].B.L == 0
        if v(m.s[m.t-1].B) > 0
            m.s[m.t].B.rS = m.s[m.t].G.rB + m.p.λ
            m.s[m.t].B.l_ = max(0, floor(Int, v(m.s[m.t-1].B) / m.p.Γ_ / (m.p.ν1 * (m.p.NFC + m.p.NFK))))
            m.s[m.t].B.rL = max(0, state.C.rB)
        else
            m.s[m.t].B.rS = 0.0
            m.s[m.t].B.l_ = 0
            m.s[m.t].B.rL = max(0, state.C.rB + m.p.ν2)
        end
    else
        m.s[m.t].B.rS = m.s[m.t].G.rB + m.p.λ * (Γ0 - m.p.Γ_)
        m.s[m.t].B.l_ = max(0, floor(Int, m.s[m.t-1].B.L * (Γ0 / m.p.Γ_ - 1) / (m.p.ν1 * (m.p.NFC + m.p.NFK))))
        m.s[m.t].B.rL = max(0, state.C.rB + m.p.ν2 * (m.p.Γ_ - Γ0))
    end
end