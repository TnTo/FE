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
    minimum_household_age::Int
    retirement_age::Int
    max_initial_skill::Int
    e0::Float64
    e1::Float64
    skill_growth_rate::Float64
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
    stmt_register_agent = SQLite.Stmt(m.db, "INSERT INTO Agents(class, birth) VALUES (?,?)")
    DBInterface.execute(stmt_register_agent, (Int(class), t))
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
    stmt_add_household = SQLite.Stmt(m.db, "INSERT INTO Households(t, id, age, skill) VALUES (?,?,?,?)")
    skill = skill_from_wealth(wealth, m)
    DBInterface.execute(stmt_add_household, (t, id, m.minimum_household_age + floor(12 * skill), skill))
    return id
end

function create_capitalfirm(m::Model, t::Int, id::Int, minimum_skill::Float64, productivity::Float64, capitalgoods::Vector{Int}, inventory::Vector{Int})::Int
    @debug "Creating CapitalFirm $id"
    stmt_add_capitalfirm = SQLite.Stmt(m.db, "INSERT INTO CapitalFirms(t, id, skill, productivity) VALUES (?,?,?,?)")
    DBInterface.execute(stmt_add_capitalfirm, (t, id, minimum_skill, productivity))
    stmt_assign_capitalgoods = SQLite.Stmt(m.db, "UPDATE CapitalGoodsOwners SET owner = ?, inventory = ? WHERE id = ?")
    for good_id in capitalgoods
        DBInterface.execute(stmt_assign_capitalgoods, (id, false, good_id))
    end
    for good_id in inventory
        DBInterface.execute(stmt_assign_capitalgoods, (id, true, good_id))
    end
    return id
end

function create_consumptionfirm(m::Model, t::Int, id::Int, capital_goods::Vector{Int})::Int
    @debug "Creating ConsumptionFirm $id"
    stmt_add_consumptionfirm = SQLite.Stmt(m.db, "INSERT INTO ConsumptionFirms(t, id) VALUES (?,?)")
    DBInterface.execute(stmt_add_consumptionfirm, (t, id))
    stmt_assign_capital_goods = SQLite.Stmt(m.db, "UPDATE CapitalGoodsOwners SET owner = ?, inventory = false WHERE id = ?")
    for good_id in capital_goods
        DBInterface.execute(stmt_assign_capital_goods, (id, good_id))
    end
    return id
end

function create_bank(m::Model, t::Int, id::Int, rate::Float64)::Int
    @debug "Creating Bank $id"
    stmt_add_bank = SQLite.Stmt(m.db, "INSERT INTO Banks(t, id, rate) VALUES (?,?,?)")
    DBInterface.execute(stmt_add_bank, (t, id, rate))
    return id
end

function create_government(m::Model, t::Int, id::Int, expenditure::Float64)::Int
    @debug "Creating Government $id"
    stmt_add_government = SQLite.Stmt(m.db, "INSERT INTO Governments(t, id, expenditure) VALUES (?,?,?)")
    DBInterface.execute(stmt_add_government, (t, id, expenditure))
    return id
end

function create_centralbank(m::Model, t::Int, id::Int, rate::Float64)::Int
    @debug "Creating CentralBank $id"
    stmt_add_centralbank = SQLite.Stmt(m.db, "INSERT INTO CentralBanks(t, id, rate) VALUES (?,?,?)")
    DBInterface.execute(stmt_add_centralbank, (t, id, rate))
    return id
end

function create_capitalgood(m::Model, t::Int, skill::Float64, productivity::Float64, price::Float64, owner::Int, inventory::Bool)::Int
    @debug "Creating CapitalGood"
    stmt_create_capitalgood = SQLite.Stmt(m.db, "INSERT INTO CapitalGoods(skill, productivity, price) VALUES (?,?,?)")
    DBInterface.execute(stmt_create_capitalgood, (skill, productivity, price))
    id = SQLite.last_insert_rowid(m.db)
    stmt_set_capitalgoodowner = SQLite.Stmt(m.db, "INSERT INTO CapitalGoodsOwners(t, id, owner, inventory) VALUES (?,?,?,?)")
    DBInterface.execute(stmt_set_capitalgoodowner, (t, id, owner, inventory))
    return id
end

# Initialization
function initialize_households(m::Model, t::Int, NHouseholds::Int, skill_initialization_learning_rate::Float64, average_initialization_wealth::Float64)
    @debug "Initializing Households"
    D = Exponential(average_initialization_wealth)
    for _ in 1:NHouseholds
        create_agent(m, t, Household, rand(D))
    end
    stmt_update_household = SQLite.Stmt(m.db, "UPDATE Households SET age = ?, skill = ? WHERE id = ?")
    for r in DBInterface.execute(m.db, "SELECT * FROM Households WHERE t == 0")
        _, id, age, skill = r
        new_age = rand(DiscreteUniform(age + 1, m.retirement_age - 1))
        net_skill_gained = rand(Binomial(new_age - age, skill_initialization_learning_rate))
        new_skill = skill * (1 + m.skill_growth_rate)^net_skill_gained
        DBInterface.execute(stmt_update_household, (new_age, new_skill, id))
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

# Model
function create_model(p::Dict{Symbol})

    @unpack seed = p
    Random.seed!(seed)
    save_params = @dict seed
    @tagsave(datadir("sims", savename(save_params, "jld2")), tostringdict(p), safe = true)
    path = datadir("db", savename("db", save_params, "db"))
    mkpath(dirname(path))
    DrWatson.recursively_clear_path(path)

    p = dict2ntuple(p)

    m = Model(SQLite.DB(path), p.minimum_household_age, p.retirement_age, p.max_initial_skill, p.e0, p.e1, p.skill_growth_rate)
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

    return m
end



end