CREATE TABLE ConsumptionFirms (
    t INTEGER NOT NULL,
    id INTEGER NOT NULL REFERENCES Agents (id),
    PRIMARY KEY (t, id)
)