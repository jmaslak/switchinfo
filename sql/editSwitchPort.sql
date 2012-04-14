--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Modifies switchport records.
--
-- Arguments:
--  i_switchport_id - Switchport to modify
--  i_descr         - Description
--  i_uplink        - Uplink (T/F)
--
-- If descr is NULL, existing description is preserved
-- If uplink is NULL, existing uplink value is preserved
--
-- Returns number of rows affected
--
CREATE OR REPLACE FUNCTION editSwitchPort (
	i_switchport_id INT4,
	i_descr VARCHAR(255),
	i_uplink BOOLEAN
) RETURNS INT4 AS $$
DECLARE
	v_retval INT4;
BEGIN
	UPDATE	switchport
	SET	descr = COALESCE(i_descr, descr),
		uplink = COALESCE(i_uplink, uplink)
	WHERE	switchport_id = i_switchport_id;

	GET DIAGNOSTICS v_retval = ROW_COUNT;

	RETURN v_retval;
END;
$$ LANGUAGE plpgsql;
	
