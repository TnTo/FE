function step(m::Model, t::Int)
    @debug "Step $t"

    update_agents_begin(m, t)



    update_statistics(m, t)
end

function update_statistics(m::Model, t::Int)
    if quarterly(t)
        @debug "Updating Statistics"
        cprice = compute_price(m, t, ConsumptionGoods)
        kprice = compute_price(m, t, CapitalGoods)
        inflation = compute_inflation(m, t, cprice)
        capacity_utilization = compute_capacity_utilization(m, t)
        unemployment_rate = compute_unemployment(m, t)
        gdp = compute_gdp(m, t)
        growth_rate = compute_growth(m, t, gdp)
    else
        res = DBInterface.execute(m.db, "SELECT * FROM Statistics WHERE (t == $(t-1))")
        row = first(res)
        cprice = row.cprice
        kprice = row.kprice
        inflation = row.inflation
        capacity_utilization = row.capacity_utilization
        unemployment_rate = row.unemployment
        gdp = row.gdp
        growth_rate = row.growth_rate
    end
    DBInterface.execute(m.db, "INSERT INTO Statistics(t, inflation, cprice, kprice, capacity_utilization, unemployment, gdp, growth_rate) VALUES ($t, $inflation, $cprice, $kprice, $capacity_utilization, $unemployment_rate, $gpd, $growth_rate)")

end

function compute_price(m::Model, t::Int, class::Stocks)
    res = DBInterface.execute(m.db, "SELECT (SUM(price*quantity)/SUM(quantity)) AS price FROM Transactions WHERE (t <= $t) AND (t > $(t-4)) AND (asset_class == $(Int(class)))")
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

function compute_gdp(m::Model, t::Int)
    res = DBInterface.execute(m.db, "SELECT SUM(price*quantity) AS gdp FROM Transactions WHERE (class == $(Int(Consumption)) OR class == $(Int(Investiment))) AND (t <= $t AND t > $(t-12))")
    return first(res).gdp
end

function compute_growth(m::Model, t::Int, gdp::Float64)
    stmt = SQLite.Stmt(m.db, "SELECT gdp FROM Statistics WHERE (t == ?)")
    if t >= 12
        res = DBInterface.execute(stmt, (t - 12))
    else
        res = DBInterface.execute(stmt, (0))
    end
    gdp0 = first(res).cprice
    return (gdp - gdp0) / gdp0
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
    update_government_begin(m, t)
end

function update_centralbank_begin(m::Model, t::Int)
    res = DBInterface.execute(m.db, "SELECT id FROM Agents WHERE class == $(Int(CentralBank))")
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

function update_government_begin(m::Model, t::Int)

end