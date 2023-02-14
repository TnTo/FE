# Model
@kwdef mutable struct Model
    # Agents
    CB::CentralBank
    B::Bank
    G::Government
    FK::Vector{CapitalFirm}
    FF::Vector{FundationalFirm}
    FO::Vector{OtherFirm}
    H::Vector{Household}
    #
    last_id::Int = 0
end