CREATE TABLE Governments (
    t INTEGER NOT NULL,
    id INTEGER REFERENCES Agents (id),
    expenditure REAL NOT NULL CHECK (expenditure > 0),
    PRIMARY KEY (t, id)
)