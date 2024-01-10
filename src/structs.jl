import Base.@kwdef
using OffsetArrays

@kwdef mutable struct Loan
    principal::Int
    r::Float
    age::Int
    NPL::Bool
end

abstract type Position end

@kwdef mutable struct CapitalGood <: Position
    p0::Int
    age::Int
    σ::Float
    β::Float
    operator::Union{Nothing,Int}
end

@kwdef mutable struct Researcher <: Position
    operator::Union{Nothing,Int}
end

abstract type Agent end

abstract type Firm end

@kwdef mutable struct Household <: Agent
    id::Int
    D::Int
    S::Int
    σ::Float
    age::Int
    worker::Bool
    employer::Union{Nothing,Int}
    employer_changed::Bool
    rc_::Int
    wF::Int
    m::Int
    t::Int
    rc::Int
    nc::Int
end

@kwdef mutable struct ConsumptionFirm <: Firm
    id::Int
    D::Int
    L::Vector{Loan}
    K::Vector{CapitalGood}
    c_::Int
    Δb_::Float
    l_::Int
    c::Int
    s::Int
    Δb::Float
    i::Int
    wF::Int
    iL::Int
    μ::Float
    pF::Int
    π::Int
    employees::Vector{Int}
end

@kwdef mutable struct CapitalFirm <: Firm
    id::Int
    D::Int
    L::Vector{Loan}
    K::Vector{CapitalGood}
    inv::Vector{CapitalGood}
    Q::Vector{Researcher}
    k_::Int
    Δb_::Float
    q_::Int
    l_::Int
    k::Int
    s::Int
    y::Int
    wF::Int
    iL::Int
    μ::Float
    p::Int
    π::Int
    σ::Float
    β::Float
    employees::Vector{Int}
end

@kwdef mutable struct Bank <: Agent
    D::Int
    S::Int
    L::Int
    B::Int
    rS::Float
    rL::Float
    l_::Int
    Π::Int
    iL::Int
end

@kwdef mutable struct Goverment <: Agent
    B::Int
    rB::Float
    rBy::Float
    Ξ::Float
    rC::Int
    nC::Int
    M::Int
    T::Int
end

@kwdef struct Stats
    ψ::Float # inflation
    u::Float # capacity utilization
    ω::Float # unemployment
    p::Int # CPI
    g::Float # growth
    Y::Int # GDP
    Ewσ::Vector{Int}
end

mutable struct State
    Hs::Vector{Household}
    FCs::Vector{ConsumptionFirm}
    FKs::Vector{CapitalFirm}
    B::Bank
    G::Goverment
    stats::Stats
end

mutable struct Model
    p::Parameters
    s::OffsetArray{State,1}
    t::Int
end

struct Vacancy
    fid::Int
    g::Position
end