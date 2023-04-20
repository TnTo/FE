CREATE TABLE CapitalGoodsOwners (
    t INTEGER NOT NULL,
    id INTEGER NOT NULL REFERENCES CapitalGoods(id),
    owner INTEGER NOT NULL REFERENCES Agents(id),
    inventory BOOL NOT NULL,
    user INTEGER REFERENCES Agents(id),
    PRIMARY KEY (t, id)
)