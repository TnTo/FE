CREATE TABLE CapitalFirms (
    t INTEGER NOT NULL,
    id INTEGER NOT NULL REFERENCES Agents (id),
    skill REAL NOT NULL,
    productivity REAL NOT NULL,
    PRIMARY KEY (t, id)
)