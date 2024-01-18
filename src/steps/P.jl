
function stepP!(m::Model)
    # println("P")
    s = m.s[m.t]
    for h = s.Hs
        i = floor(Int, state.B.rS * h.S)
        t = floor(Int, m.p.τS * i)
        h.D += (i - t)
        s.B.D -= (i - t)
        s.B.B -= t
        s.G.B += t
        h.iS += i
        s.B.iS -= i
        h.t -= t
        state.G.T += t
    end
end
