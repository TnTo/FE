CREATE TABLE Households (
    t INTEGER NOT NULL,
    id INTEGER REFERENCES Agents (id),
    age INTEGER NOT NULL,
    skill REAL NOT NULL,
    PRIMARY KEY (t, id)
)