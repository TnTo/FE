# D
function get_D(a::Union{Household,Firm})::Float64
    return a.D
end

function get_D(b::Bank)::Float64
    return get_D(b.M)
end

function get_D(as::Vector{Agent})::Float64
    return sum(map(a -> get_D(a), as))
end

function get_D(m::Model)::Float64
    return get_D(m.H) + get_D(m.FF) + get_D(m.FO) + get_D(m.FK)
end

# L
function get_L(f::Firm)::Float64
    return sum(map(l -> l.value, f.L))
end

function get_L(b::Bank)::Float64
    return get_L(b.M)
end

function get_L(as::Vector{Agent})
    return sum(map(a -> get_L(a), as))
end

function get_L(m::Model)::Float64
    return get_L(m.FF) + get_L(m.FO) + get_L(m.FK)
end

# BB
function get_BB(h::Household)::Float64
    return sum(h.BB)
end

function get_BB(b::Bank)::Float64
    return get_BB(b.M)
end

function get_BB(as::Vector{Agent})
    return sum(map(a -> get_BB(a), as))
end

function get_BB(m::Model)::Float64
    return get_BB(m.H)
end

# GB
function get_GB(b::Bank)::Float64
    return sum(b.GB)
end

function get_GB(cb::CentralBank)::Float64
    return sum(cb.GB)
end

function get_GB(g::Government)::Float64
    return get_GB(g.M)
end

function get_GB(m::Model)::Float64
    return get_GB(m.B) + get_GB(m.CB)
end

# R
function get_R(b::Bank)::Float64
    return b.R
end

function get_R(g::Government)::Float64
    return g.R
end

function get_R(cb::CentralBank)::Float64
    return get_R(cb.M)
end

function get_R(m::Model)::Float64
    return get_R(m.B) + get_R(m.G)
end

# GK
function get_GK(f::Firm)::Float64
    return sum(map(g -> g.value, f.GK))
end

function get_GK(as::Vector{Agent})
    return sum(map(a -> get_GK(a), as))
end

function get_GK(m::Model)::Float64
    return get_GK(m.FF) + get_GK(m.FO) + get_GK(m.FK)
end

# Matrix
function get_stock_matrix(m::Model)::StaticMatrix{5,7,Float64}
    sm = StaticMatrix{6,7,Float64}(0)
    sm[1, 1] = get_D(m.H)
    sm[1, 2] = get_D(m.FF)
    sm[1, 3] = get_D(m.FO)
    sm[1, 4] = get_D(m.FK)
    sm[1, 5] = -get_D(m.B)
    sm[2, 1] = get_BB(m.H)
    sm[2, 5] = -get_BB(m.B)
    sm[3, 2] = -get_L(m.FF)
    sm[3, 3] = -get_L(m.FO)
    sm[3, 4] = -get_L(m.FK)
    sm[3, 5] = get_L(m.B)
    sm[4, 5] = get_GB(m.B)
    sm[4, 6] = -get_GB(m.G)
    sm[4, 7] = get_GB(m.CB)
    sm[5, 5] = get_R(m.B)
    sm[5, 6] = get_R(m.G)
    sm[5, 7] = -get_R(m.CB)
    sm[6, 2] = get_GK(m.FF)
    sm[6, 3] = get_GK(m.FO)
    sm[6, 4] = get_GK(m.FK)
    return sm
end
