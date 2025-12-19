CREATE TABLE players (
    player_id VARCHAR(100) PRIMARY KEY,   -- puuid
    region VARCHAR(20),
    join_date DATE,  -- first match date
    last_active_date DATE, -- most recent match
    level INT,
    platform VARCHAR(20) DEFAULT 'PC'
);

CREATE TABLE matches (
    match_id VARCHAR(100) PRIMARY KEY,
    match_date DATETIME,
    duration INT,               -- seconds
    game_mode VARCHAR(50),
    map_name VARCHAR(50)
);

CREATE TABLE match_participants (
    match_id VARCHAR(100),
    player_id VARCHAR(100),
    champion VARCHAR(50),
    team INT,
    kills INT,
    deaths INT,
    assists INT,
    win_flag BIT,
    PRIMARY KEY (match_id, player_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

CREATE TABLE events (
    event_id INT IDENTITY(1,1) PRIMARY KEY,
    event_name VARCHAR(50),
    event_timestamp DATETIME,
    player_id VARCHAR(100),
    match_id VARCHAR(100) NULL,
    event_type VARCHAR(50)
);

CREATE TABLE purchases (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    player_id VARCHAR(100),
    item_name VARCHAR(100),
    item_type VARCHAR(50),
    price DECIMAL(10,2),
    purchase_date DATETIME,
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);


ALTER TABLE match_participants
DROP CONSTRAINT PK__match_pa__49326A836E7D8CCF;

ALTER TABLE match_participants
ADD CONSTRAINT PK_match_participants
PRIMARY KEY (match_id, player_id);

