CREATE TABLE Statistics (
    t NOT NULL PRIMARY KEY,
    inflation REAL NOT NULL,
    cprice REAL NOT NULL CHECK (cprice > 0),
    kprice REAL NOT NULL CHECK (kprice > 0),
    capacity_utilization REAL NOT NULL CHECK (1 >= capacity_utilization >= 0),
    unemployment REAL NOT NULL CHECK (1 >= capacity_utilization >= 0)
)