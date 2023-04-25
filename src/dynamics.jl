function step(m::Model, t::Int)
    @debug "Step $t"

    update_db(m, t)

    update_agents_begin(m, t)



    update_statistics(m, t)
end

function update_db(m::Model, t::Int)
    DBInterface.execute(m.db, "INSERT INTO Stocks (t, id, Deposits, Shares, Loans, Bonds, Reserves, CapitalGoods) SELECT $t, id, Deposits, Shares, Loans, Bonds, Reserves, CapitalGoods FROM Stocks WHERE t == $(t-1) AND id IN (SELECT id FROM Agents WHERE death IS NULL)")
end

function update_statistics(m::Model, t::Int)
    if quarterly(t)
        @debug "Updating Statistics"
        cprice = compute_cprice(m, t)
        kprice = compute_kprice(m, t)
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

function compute_cprice(m::Model, t::Int)
    res = fetch_one(m.db, "SELECT (SUM(price*quantity)/SUM(quantity)) AS price FROM Transactions WHERE (t <= $t) AND (t > $(t-4)) AND asset_class == $(Int(ConsumptionGoods)) AND payer IN (SELECT id FROM Agents WHERE class == $(Int(ConsumptionFirm)))")
    return res.price
end

function compute_kprice(m::Model, t::Int)
    res = fetch_one(m.db, "SELECT (SUM(price*quantity)/SUM(quantity)) AS price FROM Transactions WHERE (t <= $t) AND (t > $(t-4)) AND asset_class == $(Int(CapitalGoods)) AND payer IN (SELECT id FROM Agents WHERE class == $(Int(CapitalFirm)))")
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
    res = fetch_one(m.db, "SELECT SUM(price*quantity) AS gdp FROM Transactions WHERE class IN ($(Int(Consumption)), $(Int(Investiment))) AND asset_class == $(Int(Deposits)) AND (t <= $t AND t > $(t-12))")
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
    @debug "Update Agents"
    update_cb_rate(m, t) # B
    update_bank_rates(m, t) # C.0
    arbitrage_lr(m, t) # C.1
    update_government_policy(m, t) # C.2

end

function update_cb_rate(m::Model, t::Int)
    @debug "Update CB"
    id = fetch_one(m.db, "SELECT id FROM Agents WHERE class == $(Int(CentralBank))").id
    if t > 1 & quarterly(t - 1)
        res = fetch_one(m.db, "SELECT inflation, capacity_utilization, unemployment FROM Statistics WHERE t == $(t-1)")
        rate = res.inflation + m.alpha1 * (res.inflation - m.target_inflation) + m.alpha2 * (res.unemployment - m.target_unemployment) - m.alpha3 * (res.capacity_utilization - m.target_capacity_utilization)
    else
        res = fetch_one(m.db, "SELECT rate FROM CentralBanks WHERE t == $(t-1)")
        rate = res.rate
    end
    DBInterface.execute(m.db, "INSERT INTO CentralBanks(t,id,rate) VALUES ($t,$id,$rate)")
end

function update_bank_rates(m::Model, t::Int)
    @debug "Update Bank"
    id = fetch_one(m.db, "SELECT id FROM Agents WHERE class == $(Int(Bank))").id
    res = fetch_one(m.db, "SELECT Loans + Bonds + Reserves - Shares - Deposits AS net_worth, Loans FROM Stocks WHERE id == $id AND t == $(t-1)")
    net_worth = res.net_worth
    loans = res.Loans
    capital_ratio = loans == 0.0 ? 2.0 : (net_worth / loans)
    cb_rate = fetch_one(m.db, "SELECT rate FROM CentralBanks WHERE t == $t").rate # Exploiting uniqueness
    rate = (1 - m.tax_shares) * (cb_rate + m.cr_coefficient * (capital_ratio - m.target_capital_ratio))
    DBInterface.execute(m.db, "INSERT INTO Banks(t,id,rate) VALUES ($t,$id,$rate)")
    if t == 1
        global_loan_limit = (capital_ratio - m.target_capital_ratio) / (m.target_capital_ratio * m.nu1 * m.NFirms)
    else
        global_loan_limit = max(0, loans * (capital_ratio - m.target_capital_ratio) / (m.target_capital_ratio * m.nu1 * m.NFirms))
    end
    res = DBInterface.execute(m.db, "SELECT id FROM Agents WHERE death IS NULL AND class IN ($(Int(CapitalFirm)), $(Int(ConsumptionFirm)))")
    for r in res
        idF = r.id
        resF = fetch_one(m.db, "SELECT Deposits, Loans, CapitalGoods FROM Stocks WHERE id == $idF AND t == $(t-1)")
        loansF = resF.Loans
        capitalF = resF.CapitalGoods
        depositsF = resF.Deposits
        resF = fetch_one(m.db, "SELECT SUM(price) AS profits FROM Transactions WHERE class == $(Int(Profit)) AND t == $(t-1) AND payer == $idF")
        profitsF = resF.profits
        firm_loan_limit = min(global_loan_limit, m.nu0 * capitalF - loansF)
        if t == 1
            rateF = cb_rate + m.nu2 * (m.target_capital_ratio - capital_ratio)
        else
            rateF = cb_rate + m.nu2 * (m.target_capital_ratio - capital_ratio) + m.nu3 * (loansF / (depositsF - loansF + capitalF)) - m.nu4 * (profitsF / loansF)
        end
        DBInterface.execute(m.db, "INSERT INTO Credit (t, bank, firm, rate, loanslimit) VALUES ($t, $id, $idF, $rateF, $firm_loan_limit)")
    end
end
   
function arbitrage_lr(m::Model, t::Int)
    @debug "Arbitrage Liquidity Ratio"
    id = fetch_one(m.db, "SELECT id FROM Agents WHERE class == $(Int(Bank))").id
    res = fetch_one(m.db, "SELECT Reserves, Deposits, Bonds FROM Stocks WHERE id == $id AND t == $t")
    reserves = res.Reserves
    deposits = res.Deposits
    bonds = res.Bonds
    cb_id = fetch_one(m.db, "SELECT id FROM Agents WHERE class == $(Int(CentralBank))").id
    cb_bonds = fetch_one(m.db, "SELECT Bonds FROM Stocks WHERE t == $t AND id == $cb_id").Bonds
    if deposits > 0
        delta_reserves = deposits * m.target_liquidity_ratio - reserves
        if delta_reserves > 0
            # increse res -> sell bonds
            value = min(delta_reserves, bonds)
            execute_transactions(m, t, DoubleTransaction(StockAdjustment, id, cb_id, value, 1.0, Bonds, value, 1.0, Reserves))
        else if delta_reserves < 0 
            # decrease res -> buy_bonds
            value = min(-delta_reserves, cb_bonds)
            execute_transactions(m, t, DoubleTransaction(StockAdjustment, id, cb_id, value, 1.0, Reserves, value, 1.0, Bonds))
        end
    end
end
    
function update_government_policy(m::Model, t::Int)
    @debug "Update Government"
    id = fetch_one(m.db, "SELECT id FROM Agents WHERE class == $(Int(Government))").id
    expenditure = fetch_one(m.db, "SELECT expenditure FROM Governments WHERE t == $(t-1)").expenditure
    if t > 1 & quarterly(t - 1)
        res = fetch_one(m.db, "SELECT inflation, cprice, gdp, growth_rate FROM Statistics WHERE t == $t")
        inflation = res.inflation
        cprice = res.cprice
        gdp = res.gdp
        growth = res.growth_rate

        avg_taxes = fetch_one(m.db, "SELECT AVG(tax) AS tax FROM (SELECT SUM(price) AS tax FROM Transactions WHERE class == $(Int(Tax)) AND payee == $id AND t<$t AND t>=$(t-4) GROUP BY t)").tax
        avg_transfert = fetch_one(m.db, "SELECT AVG(transfert) AS transfert FROM (SELECT SUM(price) AS transfert FROM Transactions WHERE class == $(Int(Transfert)) AND asset_class == $(Int(Reserves)) AND t<$t AND t>=$(t-4) GROUP BY t)").transfert
        avg_real_consumption = fetch_one(m.db, "SELECT AVG(consumption) AS consumption FROM (SELECT SUM(quantity) AS consumption FROM Transactions WHERE class == $(Int(Consumption)) AND payee == $id AND asset_class == $(Int(ConsumptionGoods)) AND t<$t AND t>=$(t-4) GROUP BY t)").consumption

        bank_id = fetch_one("SELECT id FROM Agents WHERE class == $(Int(Bank))")
        avg_bank_bond_ratio = fetch_one("m.db, WITH FilteredStocks AS (SELECT * FROM Stocks WHERE t<$t AND t>=$(t-4)) SELECT AVG(Bank.Bonds/Gvt.Bonds) AS avg FROM ((SELECT t, Bonds FROM FilteredStocks WHERE id == $id) AS Gvt JOIN (SELECT t, Bonds FROM FilteredStocks WHERE id == $bank_id) AS Bank ON Gvt.t == Bank.t) GROUP BY Gvt.t").avg

        bonds = fetch_one(m.db, "SELECT Bonds FROM Stocks WHERE t == $(t-1) AND id == $id").Bonds

        expected_spending = (1 + inflation + growth) * avg_taxes + (1 + growth)(1 - cb_rate * avg_bank_bond_ratio) * m.target_deficit * gdp - cb.rate * bonds
        expenditure = expenditure * (expected_spending - avg_transfert) / ((1 + inflation) * cprice * avg_real_consumption)
    end
    DBInterface.execute(m.db, "INSERT INTO Governments(t,id,expenditure) VALUES ($t,$id,$expenditure)")
end
