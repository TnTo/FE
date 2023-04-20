CREATE TABLE Credit (
    t INTEGER NOT NULL,
    bank INTEGER NOT NULL REFERENCES Agents (id),
    firm INTEGER NOT NULL REFERENCES Agents (id),
    rate REAL NOT NULL,
    loanslimit REAL NOT NULL CHECK (loanslimit >= 0),
    PRIMARY KEY (t, bank, firm)
)