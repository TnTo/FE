CREATE TABLE Households (
    t INTEGER NOT NULL,
    id INTEGER NOT NULL REFERENCES Agents (id),
    age INTEGER NOT NULL,
    skill REAL NOT NULL,
    employer INTEGER REFERENCES Agents (id) DEFAULT NULL,
    workforce BOOL DEFAULT TRUE,
    desired_real_consumption REAL NOT NULL,
    PRIMARY KEY (t, id)
)