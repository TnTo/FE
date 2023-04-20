module FE

import Base.@kwdef
using Random
using Distributions
using SQLite
using DrWatson
using Logging

@enum Agents begin
    Household
    CapitalFirm
    ConsumptionFirm
    Bank
    Government
    CentralBank
end

@enum Stocks begin
    CapitalGoods
    ConsumptionGoods
    Deposits
    Shares
    Bonds
    Reserves
end

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

# SQLite
function execute_file(db::SQLite.DB, file::String)
    @debug "SQLite: executing $file"
    return DBInterface.execute(db, read(file, String))
end

# Create Agents
function skill_from_wealth(wealth::Float64, m::Model)::Float64
    N = m.max_initial_skill
    mean::Float64 = 1 + (N - 1) * (tanh(m.e0 * (wealth)))
    variance::Float64 = (mean / N) * (N - mean + m.e1)
    A::Float64 = (mean * N - mean^2 - variance) / (variance * N - mean * N + mean^2)
    alpha::Float64 = A * mean
    beta::Float64 = A * (N - mean)
    skill = 1 + rand(BetaBinomial(N - 1, alpha, beta))
    return skill
end

function create_agent(m::Model, t::Int, class::Agents, args...)::Int
    DBInterface.execute(m.db, "INSERT INTO Agents(class, birth) VALUES ($(Int(class)),$t)")
    id = SQLite.last_insert_rowid(m.db)

    # match
    class == Household && return create_household(m, t, id, args...)
    class == CapitalFirm && return create_capitalfirm(m, t, id, args...)
    class == ConsumptionFirm && return create_consumptionfirm(m, t, id, args...)
    class == Bank && return create_bank(m, t, id, args...)
    class == Government && return create_government(m, t, id, args...)
    class == CentralBank && return create_centralbank(m, t, id, args...)
    return id
end

function create_household(m::Model, t::Int, id::Int, wealth::Float64)::Int
    @debug "Creating Household $id"
    skill = skill_from_wealth(wealth, m)
    DBInterface.execute(m.db, "INSERT INTO Households(t, id, age, skill) VALUES ($t,$id,$(m.minimum_household_age + floor(12 * skill)),$skill)")
    return id
end

function create_capitalfirm(m::Model, t::Int, id::Int, minimum_skill::Float64, productivity::Float64, capitalgoods::Vector{Int}, inventory::Vector{Int})::Int
    @debug "Creating CapitalFirm $id"
    DBInterface.execute(m.db, "INSERT INTO CapitalFirms(t, id, skill, productivity) VALUES ($t,$id,$minimum_skill,$productivity)")
    stmt = SQLite.Stmt(m.db, "UPDATE CapitalGoodsOwners SET owner = ?, inventory = ? WHERE id = ?")
    for good_id in capitalgoods
        DBInterface.execute(stmt, (id, false, good_id))
    end
    for good_id in inventory
        DBInterface.execute(stmt, (id, true, good_id))
    end
    return id
end

function create_consumptionfirm(m::Model, t::Int, id::Int, capital_goods::Vector{Int})::Int
    @debug "Creating ConsumptionFirm $id"
    DBInterface.execute(m.db, "INSERT INTO ConsumptionFirms(t, id) VALUES ($t,$id)")
    stmt = SQLite.Stmt(m.db, "UPDATE CapitalGoodsOwners SET owner = ?, inventory = false WHERE id = ?")
    for good_id in capital_goods
        DBInterface.execute(stmt, (id, good_id))
    end
    return id
end

function create_bank(m::Model, t::Int, id::Int, rate::Float64)::Int
    @debug "Creating Bank $id"
    DBInterface.execute(m.db, "INSERT INTO Banks(t, id, rate) VALUES ($t,$id,$rate)")
    return id
end

function create_government(m::Model, t::Int, id::Int, expenditure::Float64)::Int
    @debug "Creating Government $id"
    DBInterface.execute(m.db, "INSERT INTO Governments(t, id, expenditure) VALUES ($t,$id,$expenditure)")
    return id
end

function create_centralbank(m::Model, t::Int, id::Int, rate::Float64)::Int
    @debug "Creating CentralBank $id"
    DBInterface.execute(m.db, "INSERT INTO CentralBanks(t, id, rate) VALUES ($t,$id,$rate)")
    return id
end

function create_capitalgood(m::Model, t::Int, skill::Float64, productivity::Float64, price::Float64, owner::Int, inventory::Bool)::Int
    @debug "Creating CapitalGood"
    DBInterface.execute(m.db, "INSERT INTO CapitalGoods(skill, productivity, price) VALUES ($skill,$productivity,$price)")
    id = SQLite.last_insert_rowid(m.db)
    DBInterface.execute(m.db, "INSERT INTO CapitalGoodsOwners(t, id, owner, inventory) VALUES ($t,$id,$owner,$inventory)")
    return id
end

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
    DBInterface.execute(m.db, "INSERT INTO Statistics(t, inflation, cprice, kprice, capacity_utilization, unemployment) VALUES ($t,$(m.target_inflation),1,1,$(m.target_capacity_utilization),$(m.target_unemployment))")
end

# Model
function create_model(p::Dict{Symbol})

    @debug "Create Model"

    @unpack seed = p
    Random.seed!(seed)
    save_params = @dict seed
    @tagsave(datadir("sims", savename(save_params, "jld2")), tostringdict(p), safe = true)
    path = datadir("db", savename("db", save_params, "db"))
    mkpath(dirname(path))
    DrWatson.recursively_clear_path(path)

    p = dict2ntuple(p)

    m = Model(
        SQLite.DB(path), p.minimum_household_age, p.retirement_age, p.max_initial_skill,
        p.e0, p.e1, p.skill_growth_rate, p.alpha1, p.alpha2, p.alpha3,
        p.target_inflation, p.target_capacity_utilization, p.target_unemployment
    )
    t = 0

    for f in readdir(srcdir("sql"), join=true, sort=false)
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

initial(t::Int) = t == 1
quarterly(t::Int) = t % 4 == 0

function step(m::Model, t::Int)
    @debug "Step $t"
    update_statistics(m, t)
    update_agents_begin(m, t)
end

function update_statistics(m::Model, t::Int)
    if quarterly(t)
        @debug "Updating Statistics"
        cprice = compute_price(m, t, ConsumptionGoods)
        kprice = compute_price(m, t, CapitalGoods)
        inflation = compute_inflation(m, t, cprice)
        capacity_utilization = compute_capacity_utilization(m, t)
        unemployment_rate = compute_unemployment(m, t)
    else
        res = DBInterface.execute(m.db, "SELECT * FROM Statistics WHERE (t == $(t-1))")
        row = first(res)
        cprice = row.cprice
        kprice = row.kprice
        inflation = row.inflation
        capacity_utilization = row.capacity_utilization
        unemployment_rate = row.unemployment
    end
    DBInterface.execute(m.db, "INSERT INTO Statistics(t, inflation,cprice,kprice,capacity_utilization,unemployment) VALUES ($t, $inflation, $cprice, $kprice, $capacity_utilization, $unemployment_rate)")

end

function compute_price(m::Model, t::Int, class::Stocks)
    res = DBInterface.execute(m.db, "SELECT (SUM(price*quantity)/SUM(quantity)) AS price FROM Transactions WHERE (t < $t) AND (t >= $(t-4)) AND (asset_class == $(Int(class)))")
    return first(res).price
end

function compute_inflation(m::Model, t::Int, p1::Float64)::Float64
    stmt = SQLite.Stmt(m.db, "SELECT cprice FROM Statistics WHERE (t == ?)")
    if t >= 12
        res = DBInterface.execute(stmt, (t - 12))
    else
        res = DBInterface.execute(stmt, (0))
    end
    p0 = first(res).cprice
    return (p1 - p0) / p0
end

function compute_capacity_utilization(m::Model, t::Int)::Float64
    res = DBInterface.execute(m.db, "WITH CGTemp(id, user) AS (SELECT id, user FROM CapitalGoodsOwners WHERE (t == $t) AND (NOT inventory)) SELECT (COUNT(UCG.id)/COUNT(GCTemp.id)) AS capacity FROM CGTemp, (SELECT * FROM CGTemp WHERE user IS NOT NULL) as UCG")
    return res.capacity
end

function compute_unemployment(m::Model, t::Int)::Float64
    res = DBInterface.execute(m.db, "WITH UTemp(id, employer) AS (SELECT id, employer FROM Households WHERE (t == $t) AND workforce) SELECT (COUNT(UH.id)/COUNT(UTemp.id)) AS unemployment FROM UTemp, (SELECT * FROM UTemp WHERE employer IS NULL) as UH")
    return res.unemployment
end


function update_agents_begin(m::Model, t::Int)
    update_centralbank_begin(m, t)
end

function update_centralbank_begin(m::Model, t::Int)
    res = DBInterface.execute("SELECT id FROM Agents WHERE class == $(Int(CentralBank))")
    id = first(res).id
    if quarterly(t)
        res = DBInterface.execute(m.db, "SELECT inflation, capacity_utilization, unemployment FROM Statistics WHERE t == $t")
        row = first(res)
        rate = row.inflation + m.alpha1 * (row.inflation - m.target_inflation) + m.alpha2 * (row.unemployment - m.target_unemployment) - m.alpha3 * (row.capacity_utilization - m.target_capacity_utilization)
    else
        res = DBInterface.execute(m.db, "SELECT rate FROM CentralBanks WHERE t == $(t-1)")
        rate = first(res).rate
    end
    DBInterface.execute(m.db, "INSERT INTO CentralBanks(t,id,rate) VALUES ($t,$id,$rate)")
end


end