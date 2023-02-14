# Assets
abstract type Asset end
abstract type FinancialAsset <: Asset end
abstract type PhysicalAsset <: Asset end

@kwdef mutable struct Loan <: FinancialAsset
    i::Float64
    expiration_t::Int64
    value::Float64
    NPL::Bool = false
end

@kwdef mutable struct CapitalGood <: PhysicalAsset
    ρ::Float64 # productivity
    b::Float64 # probability of breakage
    value::Float64
end