CREATE TABLE ConsumptionFirms (
    t INTEGER NOT NULL,
    id INTEGER REFERENCES Agents (id),
    PRIMARY KEY (t, id)
)