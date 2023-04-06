abstract type Firm end

@kwdef mutable struct Household
    const id::UInt
    skill::Float16
    age::UInt
    in_job_market::Bool = true
    employer::Union{Firm,Nothing} = nothing
    changed_employer::Bool = false
    nominal_consumption::Float64 = 0
    real_consumption::Float64 = 0
    average_price::Float16 = 1
    wage::Float64 = 0
    monetary_transfert::Float64 = 0
    desired_real_consumption::Float64 = 0
    annual_wage::Float64 = 0
    annual_income_taxes::Float64 = 0
end

newHousehold_skill_variance = (max_initial_skill / e1)^2
function newHousehold(id::Int, wealth::Float64)
    mean = (max_initial_skill) * (tanh(e0 * (wealth + 1)) - 0.001)
    beta::Float64 = (max_initial_skill * (max_initial_skill - mean)^2 - newHousehold_skill_variance * (max_initial_skill - mean)) / (max_initial_skill * (newHousehold_skill_variance + mean - max_initial_skill))
    alpha::Float64 = beta * mean / (max_initial_skill - mean)
    skill = rand(BetaBinomial(max_initial_skill, alpha, beta)) + 1 ####
    age = minimum_household_age + floor(12 * skill)
    return Household(id=id, skill=skill, age=age)
end

function ageHousehold(h::Household)
    delta_age = rand(DiscreteUniform(0, retirement_age - h.age - 1))
    h.age = h.age + delta_age - rand(DiscreteUniform(1, 12))
    net_skill_gained = rand(Binomial(delta_age, 0.50))
    println(h.skill)
    h.skill = h.skill * (1 + skill_growth_rate)^net_skill_gained
    return h
end

@kwdef mutable struct ConsumptionFirm <: Firm
    const id::UInt
    employees::Vector{Household} = []
    sold_goods::Float64 = 0
    average_capital_price_per_unit::Float64 = 0
    wages::Float64 = 0
    average_wage::Float64 = 0
    markup::Float64 = 0.1
    price::Float64 = 1
    desired_capacity_investment::Float64 = 0
    desired_output::Float64 = 0
    profits::Float64 = 0
    selling_inventory::Float64 = 0
    capital_goods::Vector{CapitalGood} = []
    maximum_loans::Float64 = 0
    loan_interest_rate::Float64 = 0
end

@kwdef mutable struct CapitalFirm <: Firm
    const id::UInt
    employees::Vector{Household} = []
    sold_goods::UInt = 0
    number_of_researchers::UInt = 0
    wages::Float64 = 0
    average_wage::Float64 = 0
    average_researcher_wage::Float64 = 0
    markup::Float16 = 0.1
    price::Float16 = 1
    desired_capacity_investment::Float64 = 0
    desired_output::UInt = 0
    profits::Float64 = 0
    selling_inventory::Vector{CapitalGood} = []
    capital_goods::Vector{CapitalGood} = []
    maximum_loans::Float64 = 0
    loan_interest_rate::Float64 = 0
end

@kwdef mutable struct Bank
    const id::UInt
    share_interest_rate::Float16 = 0
end

@kwdef mutable struct Government
    const id::UInt
    public_expenditure_level::Float64 = 1
    public_real_consumption::Float64 = 0
    public_nominal_consumption::Float64 = 0
    taxes::Float64 = 0
end

@kwdef mutable struct CentralBank
    const id::UInt
    bond_interest_rate::Float16 = 0
end