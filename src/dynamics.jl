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
        res = fetch_one(m.db, "SELECT * FROM Statistics WHERE (t == $(t-1))")
        cprice = res.cprice
        kprice = res.kprice
        inflation = res.inflation
        capacity_utilization = res.capacity_utilization
        unemployment_rate = res.unemployment
        gdp = res.gdp
        growth_rate = res.growth_rate
    end
    DBInterface.execute(m.db, "INSERT INTO Statistics(t, inflation, cprice, kprice, capacity_utilization, unemployment, gdp, growth_rate) VALUES ($t, $inflation, $cprice, $kprice, $capacity_utilization, $unemployment_rate, $gdp, $growth_rate)")

end

function compute_price(m::Model, t::Int, class::Stocks)
    res = fetch_one(m.db, "SELECT (SUM(price*quantity)/SUM(quantity)) AS price FROM Transactions WHERE (t <= $t) AND (t > $(t-4)) AND (asset_class == $(Int(class)))")
    return res.price
end

function compute_inflation(m::Model, t::Int, p1::Float64)::Float64
    stmt = SQLite.Stmt(m.db, "SELECT cprice FROM Statistics WHERE (t == ?)")
    if t >= 12
        res = fetch_one(stmt, (t - 12))
    else
        res = fetch_one(stmt, (0))
    end
    p0 = res.cprice
    return (p1 - p0) / p0
end

function compute_gdp(m::Model, t::Int)
    res = fetch_one(m.db, "SELECT SUM(price*quantity) AS gdp FROM Transactions WHERE (class == $(Int(Consumption)) OR class == $(Int(Investiment))) AND (t <= $t AND t > $(t-12))")
    return res.gdp
end

function compute_growth(m::Model, t::Int, gdp::Float64)
    stmt = SQLite.Stmt(m.db, "SELECT gdp FROM Statistics WHERE (t == ?)")
    if t >= 12
        res = fetch_one(stmt, (t - 12))
    else
        res = fetch_one(stmt, (0))
    end
    gdp0 = res.cprice
    return (gdp - gdp0) / gdp0
end

function compute_capacity_utilization(m::Model, t::Int)::Float64
    res = fetch_one(m.db, "WITH CGTemp(id, user) AS (SELECT id, user FROM CapitalGoodsOwners WHERE (t == $t) AND (NOT inventory)) SELECT (COUNT(UCG.id)/COUNT(GCTemp.id)) AS capacity FROM CGTemp, (SELECT * FROM CGTemp WHERE user IS NOT NULL) as UCG")
    return res.capacity
end

function compute_unemployment(m::Model, t::Int)::Float64
    res = fetch_one(m.db, "WITH UTemp(id, employer) AS (SELECT id, employer FROM Households WHERE (t == $t) AND workforce) SELECT (COUNT(UH.id)/COUNT(UTemp.id)) AS unemployment FROM UTemp, (SELECT * FROM UTemp WHERE employer IS NULL) as UH")
    return res.unemployment
end


function update_agents_begin(m::Model, t::Int)
    update_centralbank_begin(m, t)
    update_government_begin(m, t)
end

function update_centralbank_begin(m::Model, t::Int)
    id = fetch_one(m.db, "SELECT id FROM Agents WHERE class == $(Int(CentralBank))").id
    if quarterly(t)
        res = fetchone(m.db, "SELECT inflation, capacity_utilization, unemployment FROM Statistics WHERE t == $t")
        rate = res.inflation + m.alpha1 * (res.inflation - m.target_inflation) + m.alpha2 * (res.unemployment - m.target_unemployment) - m.alpha3 * (res.capacity_utilization - m.target_capacity_utilization)
    else
        res = fetch_one(m.db, "SELECT rate FROM CentralBanks WHERE t == $(t-1)")
        rate = res.rate
    end
    DBInterface.execute(m.db, "INSERT INTO CentralBanks(t,id,rate) VALUES ($t,$id,$rate)")
end

function update_government_begin(m::Model, t::Int)
    id = fetch_one(m.db, "SELECT id FROM Agents WHERE class == $(Int(Government))").id
    expenditure = fetch_one(m.db, "SELECT expenditure FROM Governments WHERE t == $(t-1)").expenditure
    if quarterly(t)
        res = fetch_one(m.db, "SELECT (inflation, cprice, gdp, growth_rate) FROM Statistics WHERE t == $t")
        inflation = res.inflation
        cprice = res.cprice
        gdp = res.gdp
        growth = res.growth_rate

        avg_taxes = fetch_one(m.db, "SELECT AVG(tax) AS tax FROM (SELECT SUM(price) AS tax FROM Transactions WHERE class == $(Int(Tax)) t<$t AND t>=$(t-4) GROUP BY t)").tax
        avg_transfert = fetch_one(m.db, "SELECT AVG(transfert) AS transfert FROM (SELECT SUM(price) AS transfert FROM Transactions WHERE class == $(Int(Transfert)) t<$t AND t>=$(t-4) GROUP BY t)").transfert
        avg_real_consumption = fetch_one(m.db, "SELECT AVG(consumption) AS consumption FROM (SELECT SUM(quantity) AS consumption FROM Transactions WHERE class == $(Int(Consumption)) AND buyer == $id AND t<$t AND t>=$(t-4) GROUP BY t)").consumption

        bank_id = fetch_one("SELECT id FROM Agents WHERE class == $(Int(Bank))")
        avg_bank_bond_ratio = fetch_one("m.db, WITH FilteredStocks AS (SELECT * FROM Stocks WHERE t<$t AND t>=$(t-4)) SELECT AVG(Bank.Bonds/Gvt.Bonds) AS avg FROM ((SELECT t, Bonds FROM FilteredStocks WHERE id == $id) AS Gvt JOIN (SELECT t, Bonds FROM FilteredStocks WHERE id == $bank_id) AS Bank ON Gvt.t == Bank.t) GROUP BY Gvt.t").avg

        bonds = fetch_one(m.db, "SELECT Bonds FROM Stocks WHERE t == $(t-1) AND id == $id").Bonds

        expected_spending = (1 + inflation + growth) * avg_taxes + (1 + growth)(1 - cb_rate * avg_bank_bond_ratio) * m.target_deficit * gdp - cb.rate * bonds
        expenditure = expenditure * (expected_spending - avg_transfert) / ((1 + inflation) * cprice * avg_real_consumption)
    end
    DBInterface.execute(m.db, "INSERT INTO Governments(t,id,expenditure) VALUES ($t,$id,$expenditure)")
end