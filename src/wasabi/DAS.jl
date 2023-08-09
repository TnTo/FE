module DAS

import Base.@kwdef
using Random
using Distributions
using Wasabi
using SQLite
using DrWatson
using Logging

struct2dict(s) = Dict(fieldnames(typeof(s)) .=> getfield.(Ref(s), fieldnames(typeof(s))))

@enum AgentT begin
    Household
    CapitalFirm
    ConsumptionFirm
    Bank
    Government
    CentralBank
end

@enum StockT begin
    CapitalGoods
    ConsumptionGoods
    Deposits
    Shares
    Bonds
    Reserves
end

@enum TransactionT begin
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

Wasabi.mapping(db::Type{SQLite.DB}, t::Type{T}) where {T<:Enum} = "INTEGER"
Wasabi.to_sql_value(value::T) where {T<:Enum} = Int(value)
Wasabi.from_sql_value(t::Type{T}, value::Any) where {T<:Enum} = T(value)

mutable struct Agent <: Wasabi.Model
    id::Union{Nothing,AutoIncrement}
    type::AgentT
    birth::Int
    death::Int
end

Wasabi.primary_key(m::Type{Agent}) = Wasabi.PrimaryKeyConstraint(Symbol[:id])


struct Parameters
    seed::Int
end

struct Model
    db::SQLite.DB
    p::Parameters
end

function get_path(p::Parameters)
    seed = p.seed
    save_params = @dict seed
    @tagsave(datadir("sims", savename(save_params, "jld2")), tostringdict(struct2dict(p)), safe = true)
    path = datadir("db", savename("db", save_params, "db"))
    mkpath(dirname(path))
    DrWatson.recursively_clear_path(path)
    return path
end

function Model(p::Parameters)
    Random.seed!(p.seed)
    m = Model(Wasabi.connect(SQLiteConnectionConfiguration(get_path(p))), p)
    for table in [Agent]
        Wasabi.create_schema(m.db, table)
    end

    Wasabi.autoincrement_fields(Agent)

    t::Int = 0
    Wasabi.insert!(m.db, Agent(nothing, Household, t, nothing))

    return m
end

end