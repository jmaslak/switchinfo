--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Creates new switchport entries if no matching (bridgeport, portindex,
-- and name) exists
--
-- If a bridgeport, portindex both match an existing record, do
-- nothing.
--
-- If bridgeport OR portindex matches, but not both, or if they both
-- match but name does not, mark the records that match either
-- bridgeport or portindex as NOT active and create a new record.
--
-- Parameters:
--   i_switch_id  Switch ID of switch port
--   i_name       Name of switch port (from SNMP)
--   i_portindex  Index of switch port (from SNMP IF-MIB)
--   i_bridgeport Bridge port number (from SNMP BRIDGE-MIB)
--
-- Returns switchport_id
--
CREATE OR REPLACE FUNCTION addOrMoveSwitchPort (
	i_switch_id INT4,
	i_name VARCHAR(255),
	i_portindex INTEGER,
	i_bridgeport INTEGER
) RETURNS INT4 AS $$
DECLARE
	v_retval INT4;
	v_tmp INTEGER;
BEGIN

	--
	-- Check for matching records
	SELECT	switchport_id
	INTO	v_tmp
	FROM	switchport SP
	WHERE	SP.switch_id = i_switch_id
	  AND	SP.active = true
	  AND	(
			SP.portindex = i_portindex
		    OR	( SP.portindex IS NULL AND i_portindex IS NULL )
		)
	  AND	(
			SP.bridgeport = i_bridgeport
		    OR	( SP.bridgeport IS NULL AND i_bridgeport IS NULL )
		)
	  AND	(
			SP.name = i_name
		    OR	( SP.name IS NULL AND i_name IS NULL )
		);

	--
	-- Exit if exact match found
	IF v_tmp > 0 THEN
		RETURN v_tmp;
	END IF;

	--
	-- Depricate old, changed switchport entries
	UPDATE	switchport SP
	   SET	active = false
	WHERE	switch_id = i_switch_id
	  AND	(
			SP.portindex = i_portindex
		    OR	SP.bridgeport = i_bridgeport
		);

	--
	-- Create new switchport entry
	INSERT INTO switchport (
		switch_id,
		descr,
		name,
		portindex,
		bridgeport,
		uplink,
		active
	) VALUES (
		i_switch_id,
		i_name,
		i_name,
		i_portindex,
		i_bridgeport,
		false,
		true
	);

	--
	-- Get currentvalue
	v_retval := CURRVAL('switchport_switchport_id_seq');

	RETURN v_retval;
END;
$$ LANGUAGE plpgsql;

