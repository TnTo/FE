CREATE TABLE CapitalFirms (
    t INTEGER NOT NULL,
    id INTEGER REFERENCES Agents (id),
    skill REAL NOT NULL,
    productivity REAL NOT NULL,
    PRIMARY KEY (t, id)
)