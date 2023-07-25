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

    DBInterface.execute(m.db, "INSERT INTO Stocks(t, id, Deposits, Shares, Loans, Bonds, Reserves, CapitalGoods) VALUES ($t,$id,0,0,0,0,0,0)")

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
    DBInterface.execute(m.db, "INSERT INTO Households(t, id, age, skill, desired_real_consumption) VALUES ($t,$id,$(m.minimum_household_age + floor(12 * skill)),$skill,0)")
    return id
end

function create_capitalfirm(m::Model, t::Int, id::Int, minimum_skill::Float64, productivity::Float64, capitalgoods::Vector{Int}, inventory::Vector{Int})::Int
    @debug "Creating CapitalFirm $id"
    DBInterface.execute(m.db, "INSERT INTO CapitalFirms(t, id, skill, productivity) VALUES ($t,$id,$minimum_skill,$productivity)")
    owner_stmt = SQLite.Stmt(m.db, "UPDATE CapitalGoodsOwners SET owner = ?, inventory = ? WHERE id = ?")
    stock_stmt = SQLite.Stmt(m.db, "UPDATE Stocks SET CapitalGoods = CapitalGoods + ? WHERE id = ? and t = ?")
    price_stmt = SQLite.Stmt(m.db, "SELECT price FROM CapitalGoods WHERE id = ?")
    for good_id in capitalgoods
        DBInterface.execute(owner_stmt, (id, false, good_id))
        value = fetch_one(price_stmt, (good_id,)).price
        DBInterface.execute(stock_stmt, (value, id, t))
    end
    for good_id in inventory
        DBInterface.execute(owner_stmt, (id, true, good_id))
        value = fetch_one(price_stmt, (good_id,)).price
        DBInterface.execute(stock_stmt, (value, id, t))
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
    DBInterface.execute(m.db, "UPDATE Stocks SET CapitalGoods = CapitalGoods + $price WHERE id == $owner AND t == $t")
    return id
end

