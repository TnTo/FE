function stepQ!(m::Model)
    @debug "Q"
    s = m.s[m.t]
    i = floor(Int, s.G.rB * s.B.B) # If negative can lead to negative reserves
    s.B.B -= i
    s.G.B += i
end