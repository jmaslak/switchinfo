--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Creates new mac table entry if no MAC entry exists.
-- Updates MAC last_seen times.
-- Updates or creates mac_history entry.
--
-- Parameters:
--   i_switch_id  Switch ID of switch port
--   i_bridgeport Bridge port number (from SNMP BRIDGE-MIB)
--   i_mac        MAC address (AA:AA:AA:AA:AA:AA in String format)
--
-- Returns integer with a value of 1
--
CREATE OR REPLACE FUNCTION addOrMoveMac (
	i_switch_id INT4,
	i_bridgeport INTEGER,
	i_mac CHAR(17)
) RETURNS INT4 AS $$
DECLARE
	v_mac_id INT4;
	v_now TIMESTAMP;
	v_switchport INT4;
	v_tmp INTEGER;
BEGIN

	--
	-- Get current run time
	SELECT	dt
	INTO	v_now
	FROM	current_run;

	--
	-- Check for matching MAC entry
	SELECT	mac_id
	INTO	v_mac_id
	FROM	mac
	WHERE	mac = i_mac;

	--
	-- If exact match NOT found, add the entry.
	-- Otherwise, update the entry.
	IF v_mac_id IS NULL THEN
		INSERT INTO mac (
			mac,
			descr,
			first_seen,
			last_seen
		) VALUES (
			i_mac,
			i_mac,
			v_now,
			v_now
		);
		v_mac_id := CURRVAL('mac_mac_id_seq');
	ELSE
		UPDATE	mac
		   SET	last_seen = v_now
		WHERE	mac_id = v_mac_id;
	END IF;

	--
	-- Get switchport ID
	SELECT	switchport_id
	INTO	v_switchport
	FROM	switchport
	WHERE	bridgeport = i_bridgeport
	  AND	switch_id = i_switch_id
	  AND	active = true;

	--
	-- Check for old history entry to find out if we need to create it
	SELECT	COUNT(*)
	INTO	v_tmp
	FROM	mac_history
	WHERE	mac_id = v_mac_id
	  AND	switchport_id = v_switchport
	  AND	v_now BETWEEN start_dt AND end_dt;

	--
	-- If old history entry exists and has the
	-- same switchport, do nothing!
	-- But if it doesn't, we need to create it.
	IF v_tmp = 0 THEN
		INSERT INTO mac_history (
			mac_id,
			start_dt,
			end_dt,
			switchport_id
		) VALUES (
			v_mac_id,
			v_now,
			date '9999-12-31',
			v_switchport
		);
	END IF;

	--
	-- Insert into active mac table to allow cleanup
	INSERT INTO active_macs (
		mac_id,
		switchport_id
	) VALUES (
		v_mac_id,
		v_switchport
	);

	RETURN 1;
END;
$$ LANGUAGE plpgsql;

