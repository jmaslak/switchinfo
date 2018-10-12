--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Creates (if NULL passed in as switch_id) or updates (all other values of
-- switch_id) switch records.
--
-- switch_id = Null if new, otherwise set to switch_id to update
--
-- On add, all the following parameters must be provided except for
-- descr, which will be copied from hostname if not provided.
--
-- On update, any parameter that is NULL will keep existing values in-place
--
-- hostname = Switch's network identity
-- descr = Switch's description; If NULL, routine will use hostname
-- snmpcommunity = Switch's SNMP community
--
CREATE OR REPLACE FUNCTION addOrUpdateSwitch(
	i_switch_id INT4,
	i_hostname VARCHAR(255),
	i_descr VARCHAR(255),
	i_snmpcommunity VARCHAR(255)
) RETURNS INT4 AS $$
DECLARE
	v_retval INT4;
BEGIN

	IF i_switch_id IS NULL THEN
		INSERT INTO switch (
			hostname,
			descr,
			snmpcommunity
		) VALUES (
			i_hostname,
			COALESCE(i_descr, i_hostname),
			i_snmpcommunity
		);
		v_retval := CURRVAL('switch_switch_id_seq');
	ELSE
		UPDATE switch
		SET	hostname = COALESCE(i_hostname, hostname),
			descr = COALESCE(i_descr, descr),
			snmpcommunity = COALESCE(i_snmpcommunity, descr)
		WHERE	switch_id = i_switch_id;
		v_retval := i_switch_id;
	END IF;

	RETURN v_retval;
END;
$$ LANGUAGE plpgsql;
	
