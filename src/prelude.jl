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
    None
    CapitalGoods
    ConsumptionGoods
    Deposits
    Shares
    Bonds
    Reserves
end

@enum Transactions begin
    Consumption
    Investment
    Wage
    Tax
    Transfer
    Profit
    Interest
end

# SQLite
function execute_file(db::SQLite.DB, file::String)
    @debug "SQLite: executing $file"
    return DBInterface.execute(db, read(file, String))
end

function fetch_one(args...)
    return first(DBInterface.execute(args...))
end

initial(t::Int) = t == 1
quarterly(t::Int) = t % 4 == 0