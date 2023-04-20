CREATE TABLE Transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    t INTEGER NOT NULL,
    class INTEGER NOT NULL,
    seller INTEGER NOT NULL REFERENCES Agents(id),
    buyer INTEGER NOT NULL REFERENCES Agents(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price INTEGER NOT NULL CHECK (price >= 0),
    asset_class INTEGER NOT NULL,
    compensation_class INTEGER NOT NULL
)