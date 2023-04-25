struct Transaction
    class::Transactions
    payer::Int
    payee::Int
    quantity::Float64
    price::Float64
    asset::Stocks
end

function DoubleTransaction(class:Transaction, payer::Int, payee::Int, quantity::Float64, price::Float64, asset::Stocks, ret_quantity::Float64, ret_price::Float64, ret_asset::Asset)
    return [Transaction(class, payer, payee, quantity, price, asset), Transaction(class, payee, payer, ret_quantity, ret_price, ret_asset)]
end

function execute_transaction(m::Model, t::Int, transaction::Transaction)
    DBInterface.execute("INSERT INTO Transactions(t, class, payer, payee, quantity, price, asset_class) VALUES ($t, $(Int(transaction.class)), transaction.payer, transaction.payee, transaction.quantity, transaction.price, $(Int(transaction.asset)))")
    DBInterface.execute("UPDATE Stocks SET $(transaction.asset) = $(transaction.asset) + $(transaction.quantity * transaction.price) WHERE t == $t AND id == $(transaction.payee)")
    DBInterface.execute("UPDATE Stocks SET $(transaction.asset) = $(transaction.asset) - $(transaction.quantity * transaction.price) WHERE t == $t AND id == $(transaction.payer)")
end

function execute_transactions(m::Model, t::Int, transactions::Vector{Transaction})
    for transaction in transactions
        execute_transaction(m, t, transaction)
    end
end