# Agents
abstract type Agent end
abstract type Firm <: Agent end

@kwdef mutable struct Household <: Agent
    const M::Model
    const id::Int
    D::Float64
    BB::MVector{BONDT,Float64} = MVector{BONDT,Float64}(0)
    GF::Float64
    GO::Float64
    w::Float64
end

@kwdef mutable struct FundationalFirm <: Firm
    const M::Model
    const id::Int
    D::Float64
    L::Vector{Loan} = []
    GK::Vector{CapitalGood} = []
    GF::Float64
    W::Vector{Household} = []
end

@kwdef mutable struct OtherFirm <: Firm
    const M::Model
    const id::Int
    D::Float64
    L::Vector{Loan} = []
    GK::Vector{CapitalGood} = []
    GO::Float64
    W::Vector{Household} = []
end

@kwdef mutable struct CapitalFirm <: Firm
    const M::Model
    const id::Int
    D::Float64
    L::Vector{Loan} = []
    GK::Vector{CapitalGood} = []
    W::Vector{Household} = []
end

@kwdef mutable struct Bank <: Agent
    const M::Model
    const id::Int
    R::Float64
    GB::MVector{BONDT,Float64} = MVector{BONDT,Float64}(0)
    i::MVector{BONDT,Float64} = MVector{BONDT,Float64}(0)
end

@kwdef mutable struct Governemnt <: Agent
    const M::Model
    const id::Int
    R::Float64
end

@kwdef mutable struct CentralBank <: Agent
    const M::Model
    const id::Int
    GB::MVector{BONDT,Float64} = MVector{BONDT,Float64}(0)
    i::MVector{BONDT,Float64} = MVector{BONDT,Float64}(0)
    π::Float64 = 0.02
    α::Float64 = 0.5
    β::Float64 = 0
end
