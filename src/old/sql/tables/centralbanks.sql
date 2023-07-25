CREATE TABLE CentralBanks (
    t INTEGER NOT NULL,
    id INTEGER NOT NULL REFERENCES Agents (id),
    rate REAL NOT NULL,
    PRIMARY KEY (t, id)
)