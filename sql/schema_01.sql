--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
-- ALL RIGHTS RESERVED
--

-- 
-- Schema 01
--
-- Create Initial Tables
-- 

BEGIN TRANSACTION;

-- mac_id     => Unique sequence number for a MAC
-- mac        => MAC address, stored in ASCII Hex format 11:22:33:44:55:66
-- descr      => Description of MAC (or just the MAC if no description)
-- first_seen => Date/time of first time MAC is seen
-- last_seen  => Date/time of most recent time MAC is seen
CREATE TABLE mac (
	mac_id		SERIAL		NOT NULL,
	mac		CHAR(17)	NOT NULL,
	descr		VARCHAR(255)	NOT NULL,
	first_seen	TIMESTAMP	NOT NULL,
	last_seen	TIMESTAMP	NOT NULL
);

-- mac_id        => From mac table
-- start_dt      => Start date of this entry (first time corresponding with
--                  this entry that the MAC appeared)
-- end_dt        => Last time the MAC was seen on this port for this entry.
--                  Set to 12/31/9999 for "still on port"
-- switchport_id => From switchport table
CREATE TABLE mac_history (
	mac_id		INT4		NOT NULL,
	start_dt	TIMESTAMP	NOT NULL,
	end_dt		TIMESTAMP	NOT NULL,
	switchport_id	INT4		NOT NULL
);

-- switch_id     => Unique sequence number for a switch
-- hostname      => Hostname and/or IP of switch
-- descr         => Description of switch (same as hostname if no
--                  description)
-- snmpcommunity => SNMP community (RO) of switch
CREATE TABLE switch (
	switch_id	SERIAL		NOT NULL,
	hostname	VARCHAR(255)	NOT NULL,
	descr		VARCHAR(255)	NOT NULL,
	snmpcommunity	VARCHAR(255)	NOT NULL
);

-- switchport_id => Unique sequence number for a switchport
-- switch_id     => From switch table
-- descr         => Description of switchport (same as name if no descr)
-- name          => Name of switchport from SNMP
-- portindex     => IF_MIB index for switchport
-- bridgeport    => BRIDGE_MIB index for switchport
-- uplink        => True if switchport is an uplink (or downlink) to
--                  another switch in the database
CREATE TABLE switchport (
	switchport_id	SERIAL		NOT NULL,
	switch_id	INT4		NOT NULL,
	descr		VARCHAR(255)	NOT NULL,
	name		VARCHAR(255)	NOT NULL,
	portindex	INT4		NULL,
	bridgeport	INT4		NULL,
	uplink		BOOLEAN		NOT NULL
);

ALTER TABLE mac
ADD PRIMARY KEY (mac_id);

ALTER TABLE mac
ADD CONSTRAINT mac_AK1 UNIQUE (mac);

ALTER TABLE mac_history
ADD PRIMARY KEY (mac_id, start_dt);

ALTER TABLE mac_history
ADD CONSTRAINT mac_history_AK1 UNIQUE (mac_id, end_dt);

ALTER TABLE switch
ADD PRIMARY KEY (switch_id);

ALTER TABLE switch
ADD CONSTRAINT switch_AK1 UNIQUE (hostname);

ALTER TABLE switchport
ADD PRIMARY KEY (switchport_id);

ALTER TABLE switchport
ADD CONSTRAINT switchport_fk1 FOREIGN KEY (switch_id)
REFERENCES switch (switch_id);

ALTER TABLE mac_history
ADD CONSTRAINT mac_history_fk1 FOREIGN KEY (mac_id)
REFERENCES mac (mac_id);

ALTER TABLE mac_history
ADD CONSTRAINT mac_history_fk2 FOREIGN KEY (switchport_id)
REFERENCES switchport (switchport_id);

COMMIT;

