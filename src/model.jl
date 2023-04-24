# Model
struct Model
    db::SQLite.DB
    # Households
    minimum_household_age::Int
    retirement_age::Int
    max_initial_skill::Int
    e0::Float64
    e1::Float64
    skill_growth_rate::Float64
    # CentralBank
    alpha1::Float64
    alpha2::Float64
    alpha3::Float64
    # Target
    target_inflation::Float64
    target_capacity_utilization::Float64
    target_unemployment::Float64

end

function create_model(p::Dict{Symbol})

    @debug "Create Model"

    @unpack seed = p
    Random.seed!(seed)
    save_params = @dict seed
    # @tagsave(datadir("sims", savename(save_params, "jld2")), tostringdict(p), safe = true)
    @tagsave(datadir("sims", savename(save_params, "jld2")), tostringdict(p), safe = false)
    path = datadir("db", savename("db", save_params, "db"))
    mkpath(dirname(path))
    # DrWatson.recursively_clear_path(path)

    p = dict2ntuple(p)

    m = Model(
        SQLite.DB(path), p.minimum_household_age, p.retirement_age, p.max_initial_skill,
        p.e0, p.e1, p.skill_growth_rate, p.alpha1, p.alpha2, p.alpha3,
        p.target_inflation, p.target_capacity_utilization, p.target_unemployment
    )
    t = 0

    for f in readdir(srcdir("sql", "tables"), join=true, sort=false)
        execute_file(m.db, f)
    end

    create_agent(m, t, CentralBank, p.initial_cb_rate)
    create_agent(m, t, Government, p.initial_government_expenditure)
    create_agent(m, t, Bank, 0.0)

    initialize_households(m, t, p.NHouseholds, p.skill_initialization_learning_rate, p.average_initialization_wealth)
    initialize_capitalfirms(m, t, p.NCapitalFirms)
    initialize_consumptionfirms(m, t, p.NConsumptionFirms)

    initialize_statistics(m, t)

    @debug "Initialization Complete"

    return m
end


function run_model(m::Model, T::Int)
    for t in 1:T
        step(m, t)
    end
end