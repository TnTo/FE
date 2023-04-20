CREATE TABLE Governments (
    t INTEGER NOT NULL,
    id INTEGER NOT NULL REFERENCES Agents (id),
    expenditure REAL NOT NULL CHECK (expenditure > 0),
    PRIMARY KEY (t, id)
)