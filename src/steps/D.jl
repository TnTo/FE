function stepD!(m::Model)
    # println("D")
    if quarterly(m.t)
        avgT = mean(map(i -> m.s[m.t-i].G.T, 1:4))
        avgM = mean(map(i -> m.s[m.t-i].G.M, 1:4))
        avgrC = mean(map(i -> m.s[m.t-i].G.rC, 1:4))
        avgB = mean(map(i -> m.s[m.t-i].G.B, 1:4))

        EG = (1 + m.s[m.t].stats.ψ + m.s[m.t].stats.g) * avgT + (1 + m.s[m.t].stats.g) * (1 - m.s[m.t].G.rB) * m.p.δ_ * m.s[m.t].stats.Y + m.s[m.t].G.rB * avgB
        if avgrC == 0
            Ξ = m.s[m.t-1].G.Ξ
        else
            Ξ = m.s[m.t-1].G.Ξ * (EG - avgM) / (avgrC * (1 + m.s[m.t].stats.ψ) * m.s[m.t].stats.p)
        end
    else
        Ξ = m.s[m.t-1].G.Ξ
    end
    state.G.Ξ = max(1.0, Ξ)
end