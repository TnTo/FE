log = true

params = Dict{Symbol,Any}(
    # Seed
    :seed => 8686,

    # Size
    :NCapitalFirms => 2,
    :NConsumptionFirms => 5,
    :NHouseholds => 10,
    :T => 5,

    # To calibrate
    :e0 => 0.001,
    :e1 => 1.0,
    :skill_growth_rate => 0.01,

    # Not to calibrate
    :LoanDuration => 60,
    :max_initial_skill => 10.0,
    :minimum_household_age => 16 * 12,
    :retirement_age => 65 * 12,
    :target_inflation => 0.02,
    :target_capacity_utilization => 0.8,
    :target_unemployment => 0.05,
    :alpha1 => 0.5,
    :alpha2 => 0.25,
    :alpha3 => 0.25,

    # Initialization
    :average_initialization_wealth => 100.0,
    :skill_initialization_learning_rate => 0.50,
    :initial_cb_rate => 0.01,
    :initial_government_expenditure => 1.0
)