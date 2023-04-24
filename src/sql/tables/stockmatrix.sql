CREATE TABLE Stocks (
    t INTEGER NOT NULL,
    id INTEGER NOT NULL REFERENCES Agents(id),
    Deposits REAL NOT NULL,
    Shares REAL NOT NULL,
    Loans REAL NOT NULL,
    Bonds REAL NOT NULL,
    Reserves REAL NOT NULL,
    CapitalGoods REAL NOT NULL
)