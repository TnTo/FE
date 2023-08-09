import Base.@kwdef
using Random
using Distributions
using Wasabi
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

@enum Transactions begin
    Consumption
    Investment
    Wage
    WageTax
    CapitalTax
    VATax
    InheritanceTax
    Transfer
    Profit
    Interest
    StockAdjustment
end

initial(t::Int) = t == 1
quarterly(t::Int) = t % 4 == 0
post_quarterly(t::Int) = t % 4 == 1
yearly(t::Int) = t % 12 == 0

yearly2monthly(r::Float64) = (1 + r)^(1 / 12) - 1