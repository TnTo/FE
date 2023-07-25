# Initialization
function initialize_households(m::Model, t::Int, NHouseholds::Int, skill_initialization_learning_rate::Float64, average_initialization_wealth::Float64)
    @debug "Initializing Households"
    D = Exponential(average_initialization_wealth)
    for _ in 1:NHouseholds
        create_agent(m, t, Household, rand(D))
    end
    update_stmt = SQLite.Stmt(m.db, "UPDATE Households SET age = ?, skill = ? WHERE id = ?")
    for r in DBInterface.execute(m.db, "SELECT * FROM Households WHERE t == $t")
        _, id, age, skill = r
        new_age = rand(DiscreteUniform(age + 1, m.retirement_age - 1))
        net_skill_gained = rand(Binomial(new_age - age, skill_initialization_learning_rate))
        new_skill = skill * (1 + m.skill_growth_rate)^net_skill_gained
        DBInterface.execute(update_stmt, (new_age, new_skill, id))
    end
end

function initialize_capitalfirms(m::Model, t::Int, NCapitalFirms::Int)
    @debug "Initializing CapitalFirms"
    for _ in 1:NCapitalFirms
        id = create_agent(m, t, CapitalFirm, 1.0, 1.0, Vector{Int}([]), Vector{Int}([]))
        create_capitalgood(m, t, 1.0, 1.0, 1.0, id, false)
    end
end

function initialize_consumptionfirms(m::Model, t::Int, NConsumptionFirms::Int)
    @debug "Initializing ConsumptionFirms"
    for _ in 1:NConsumptionFirms
        id = create_agent(m, t, ConsumptionFirm, Vector{Int}([]))
        create_capitalgood(m, t, 1.0, 1.0, 1.0, id, false)
    end
end

function initialize_statistics(m::Model, t::Int)
    @debug "Initializing Statistics"
    DBInterface.execute(m.db, "INSERT INTO Statistics(t, inflation, cprice, kprice, capacity_utilization, unemployment, gdp, growth_rate) VALUES ($t,$(m.target_inflation),1,1,$(m.target_capacity_utilization),$(m.target_unemployment),1,0)")
end