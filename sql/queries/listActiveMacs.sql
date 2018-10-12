--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Lists active MAC addresses, sorted by switch pretty name and
-- then port pretty name.  Filters out uplinks.
--

SELECT	S.descr switch_descr,
	SP.descr switchport_descr,
	M.mac mac,
	M.descr mac_descr
FROM	mac_history MH,
	switch S,
	switchport SP,
	mac M
WHERE	MH.mac_id = M.mac_id
  AND	MH.switchport_id = SP.switchport_id
  AND	SP.switch_id = S.switch_id
  AND	NOW() BETWEEN MH.start_dt AND MH.end_dt
  AND	SP.uplink = false
ORDER BY S.descr, SP.descr, M.mac, M.descr;

