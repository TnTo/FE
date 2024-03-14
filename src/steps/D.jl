function stepD!(m::Model)
    @debug "D"
    s = m.s[m.t]
    if quarterly(m.t)
        avgT = mean(map(i -> m.s[m.t-i].G.T, 1:4))
        avgM = mean(map(i -> m.s[m.t-i].G.M, 1:4))
        avgrC = mean(map(i -> m.s[m.t-i].G.rC, 1:4))
        avgB = mean(map(i -> m.s[m.t-i].G.B, 1:4))

        EG = (1 + s.stats.ψ + s.stats.g) * avgT + (1 + s.stats.g) * (1 - s.G.rB) * m.p.δ_ * s.stats.Y + s.G.rB * avgB
        if avgrC == 0
            Ξ = m.s[m.t-1].G.Ξ
        else
            Ξ = m.s[m.t-1].G.Ξ * (EG - avgM) / (avgrC * (1 + s.stats.ψ) * s.stats.p)
        end
    else
        Ξ = m.s[m.t-1].G.Ξ
    end
    s.G.Ξ = max(1.0, Ξ)
end