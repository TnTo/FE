module FE

import Base.@kwdef
using Random
using StaticArrays
using Distributions

include("parameters.jl")
include("stocks.jl")
include("agents.jl")

Random.seed!(seed)

# Model
@kwdef mutable struct Model
    # Agents
    CentralBank::CentralBank
    Bank::Bank
    Government::Government
    CapitalFirms::MVector{NCapitalFirms,CapitalFirm}
    ConsumptionFirms::MVector{NConsumptionFirms,ConsumptionFirm}
    Households::MVector{NHouseholds,Household}

    # Stocks
    Deposits::MVector{NHouseholds + NCapitalFirms + NConsumptionFirms,Float64} = @MVector zeros(NHouseholds + NCapitalFirms + NConsumptionFirms)
    Shares::MVector{NHouseholds,Float64} = @MVector zeros(NHouseholds)
    Loans::MVector{NCapitalFirms + NConsumptionFirms,Vector{Loan}} = MVector{NCapitalFirms + NConsumptionFirms,Vector{Loan}}([Loan[] for _ in 1:NCapitalFirms+NConsumptionFirms])
    Bonds::MVector{2,Float64} = @MVector zeros(2)
    Reserves::MVector{2,Float64} = @MVector zeros(2)
    #
    last_id::Int = 0
end

function create_model()
    centralbank = CentralBank(id=0)
    bank = Bank(id=1)
    government = Government(id=2)
    last_id = 2
    capitalfirms = [CapitalFirm(id=i + last_id, capital_goods=[CapitalGood(1, 1, 1)]) for i in 1:NCapitalFirms]
    last_id += NCapitalFirms
    consumptiofirms = [ConsumptionFirm(id=i + last_id) for i in 1:NConsumptionFirms]
    last_id += NConsumptionFirms
    households = map(ageHousehold, [newHousehold(i + last_id, rand(Exponential(average_initial_wealth))) for i in 1:NHouseholds])
    last_id += NHouseholds
    return Model(CentralBank=centralbank, Bank=bank, Government=government, CapitalFirms=capitalfirms, ConsumptionFirms=consumptiofirms, Households=households, last_id=last_id)
end

end