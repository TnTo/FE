log = true

params = Dict{Symbol,Any}(
    # Seed
    :seed => 8686,

    # Size
    :NCapitalFirms => 20,
    :NConsumptionFirms => 10,
    :NHouseholds => 100,

    # To calibrate
    :e0 => 0.001,
    :e1 => 1.0,
    :skill_growth_rate => 0.01,

    # Not to calibrate
    :LoanDuration => 60,
    :max_initial_skill => 10.0,
    :minimum_household_age => 16 * 12,
    :retirement_age => 65 * 12,

    # Initialization
    :average_initialization_wealth => 100.0,
    :skill_initialization_learning_rate => 0.50,
    :initial_cb_rate => 0.01,
    :initial_government_expenditure => 1.0
)