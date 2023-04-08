@kwdef mutable struct Loan
    value::Float64
    time_to_expiration::Int = LoanDuration
end

@kwdef mutable struct CapitalGood
    price::Float64
    productivity::Float64
    minimum_skill::Float64
end
