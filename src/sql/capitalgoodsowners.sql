CREATE TABLE CapitalGoodsOwners (
    t INTEGER NOT NULL,
    id INTEGER REFERENCES CapitalGoods(id),
    owner INTEGER REFERENCES Agents(id),
    inventory BOOL NOT NULL,
    PRIMARY KEY (t, id)
)