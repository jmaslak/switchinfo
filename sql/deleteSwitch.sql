--
-- Removes a switch, when given a switch_id
--
-- Also removes all switchport and mac_history records that references the
-- switch
--
-- Returns i_switch_id
--
CREATE OR REPLACE FUNCTION deleteSwitch(
	i_switch_id INT4
) RETURNS INT4 AS $$
DECLARE
	v_retval INT4;
BEGIN
	DELETE FROM mac_history MH
	WHERE	MH.switchport_id IN (
			SELECT	SP.switchport_id
			FROM	switchport SP
			WHERE	SP.switch_id = i_switch_id
		);

	DELETE FROM switchport SP
	WHERE	SP.switch_id = i_switch_id;

	DELETE FROM switch S
	WHERE	S.switch_id = i_switch_id;

	RETURN v_retval;
END;
$$ LANGUAGE plpgsql;
	
