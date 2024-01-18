function stepN!(m::Model)
    # println("N")
    s = m.s[m.t]
    for f = s.FCs
        i = floor(Int, l.r * l.value)
        Δv = ceil(Int, l.value / (m.p.NL - l.age))
        if f.D < (i + Δv)
            l.value += i
            l.age -= 1
            l.NPL = true
            s.B.L += i
        else
            f.D -= (i + Δv)
            s.B.D += (i + Δv)
            f.iL -= i
            s.B.iL += i
            l.value -= Δv
            l.NPL = false
            s.B.L -= Δv
        end
        filter!(l -> l.value > 0, f.L)
    end
    for f = s.FKs
        i = floor(Int, l.r * l.value)
        Δv = ceil(Int, l.value / (m.p.NL - l.age))
        if f.D < (i + Δv)
            l.value += i
            l.age -= 1
            l.NPL = true
            s.B.L += i
        else
            f.D -= (i + Δv)
            s.B.D += (i + Δv)
            f.iL -= i
            s.B.iL += i
            l.value -= Δv
            l.NPL = false
            s.B.L -= Δv
        end
        filter!(l -> l.value > 0, f.L)
    end
end
