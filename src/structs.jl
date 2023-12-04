import Base.@kwdef
using OffsetArrays

@kwdef mutable struct Parameters
    # General
    seed::Int
    T::Int
    NH::Int
    NFC::Int
    NFK::Int
    # Not to calibrate
    σM::Int
    A0::Int
    AM::Int
    α1::Float
    α2::Float
    α3::Float
    ψ_::Float
    u_::Float
    ω_::Float
    Γ_::Float
    Λ_::Float
    δ_::Float
    NK::Int
    NL::Int
    τS::Float
    τC::Float
    τI::Float
    τM::Float
    ϕ::Float
    σ_::Float
    # To calibrate
    e0::Float
    e1::Float
    λ::Float
    ν0::Float
    ν1::Float
    ν2::Float
    ν3::Float
    ν4::Float
    Σ::Float
    ρC::Float
    ρK::Float
    ρF::Float
    ρQ::Float
    ρH::Float
    ρW::Float
    ρΠ::Float
    Θ::Float
    α::Float
    τF::Float
    τT::Float
    χH::Int
    χC::Int
    χK::Int
    ζ::Float
    b0::Float
    b1::Float
    b2::Float
    ϵ0::Float
    ϵ1::Float
    c0::Int
    k::Float
    # Initialization
    v0::Float
    δ0::Float
    p0::Int
    K0::Int
    μ0::Float
end

@kwdef mutable struct Loan
    value::Int
    r::Float
    age::Int
    NPL::Bool
end

@kwdef mutable struct CapitalGood
    p::Int
    age::Int
    σ::Float
    β::Float
    operator::Union{Nothing,Int}
end

@kwdef mutable struct Researcher
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
    w::Int
    z::Int
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
    w::Int
    il::Int
    μ::Float
    p::Int
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
    w::Int
    il::Int
    μ::Float
    p::Int
    π::Int
    σ::Float
    β::Float
    employees::Vector{Int}
end

@kwdef mutable struct Bank <: Agent
    id::Int
    D::Int
    S::Int
    L::Int
    B::Int
    R::Int
    rS::Float
    rL::Float
    l_::Int
    Π::Int
    iL::Int
end

@kwdef mutable struct Goverment <: Agent
    id::Int
    B::Int
    R::Int
    Ξ::Int
    rC::Int
    nC::Int
    M::Int
    T::Int
end

@kwdef mutable struct CentralBank <: Agent
    id::Int
    B::Int
    R::Int
    rB::Float
end

@kwdef struct Stats
    # yearly
    ψ::Float # inflation
    u::Float # capacity utilization
    ω::Float # unemployment
    p::Int # CPI
    g::Float # growth
    Y::Int # GDP
    Ewσ::Vector{Int}
end

mutable struct State
    Hs::Dict{Int,Household}
    FCs::Dict{Int,ConsumptionFirm}
    FKs::Dict{Int,CapitalFirm}
    B::Bank
    G::Goverment
    C::CentralBank
    stats::Stats
end

mutable struct Model
    p::Parameters
    states::OffsetArray{State,1}
    id::Int
    t::Int
end

struct Vacancy
    fid::Int
    g::Union{CapitalGood,Researcher}
end