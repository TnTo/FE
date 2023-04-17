seed = 8686

# Size
NCapitalFirms::Int = 20
NConsumptionFirms::Int = 10
NHouseholds::Int = 100

# To calibrate
e0::Float64 = 0.001
e1::Float64 = 1.0
skill_growth_rate::Float64 = 0.01

# Not to calibrate
LoanDuration::Int = 60
max_initial_skill::Float64 = 10.0
minimum_household_age::Int = 16 * 12
retirement_age::Int = 65 * 12

# Initialization
average_initial_wealth::Float64 = 100