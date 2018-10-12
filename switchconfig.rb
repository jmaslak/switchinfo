#
# COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
# ALL RIGHTS RESERVED
#

require 'dbi'

# Access switch configuration database
class SwitchConfig

  # Initializer
  # Takes the host, user, password, and database to connect to
  def initialize(dbhost, dbuser, dbpass, dbdatabase)
    # Database configuration hash
    @database = {}
  
    # Database Handle
    @dbh = nil

    @database[:host] = dbhost
    @database[:user] = dbuser
    @database[:password] = dbpass
    @database[:database] = dbdatabase
  end

  # Open database only if needed
  def db_cached_connect
    @dbh or db_connect
  end
   
  # Open the database handle 
  def db_connect
    @dbh and db_close
    puts "DEBUG: Opening DB" if $DEBUG
    @dbh = DBI.connect("dbi:Pg:#{@database[:database]}:#{@database[:host]}",
                      @database[:user],
                      @database[:password])
  end

  # Close the database handle
  def db_close
    @dbh and @dbh.close
    @dbh = nil
  end

  # Add a switch to the database
  def add_switch(hostname, descr, community)
    db_cached_connect

    retvalue = nil

    begin
      modify_switch(nil, hostname, descr, community)
    rescue DBI::ProgrammingError => e
      if e.message[/Key .* already exists/]
        STDERR.puts "This switch (#{hostname}) already exists, not adding."
      else
        raise e
      end
    end

    return retvalue
  end

  # Modify a switch in the database
  # Will also add a switch if switch_id is empty
  #
  # To Add: Provide hostname, descr, and community, but pass nil for switch_id
  #
  # To Modify: Provide switch_id and any element (hostname, descr, community)
  # that you wish to change.  Other elements should be passed as nil
  #
  # If an invalid switch_id is passed, no action will be performed
  #
  # Returns the switch_id of the modified element
  def modify_switch(switch_id, hostname, descr, community)
    db_cached_connect

    retvalue = nil

    sql = 'SELECT addOrUpdateSwitch(?, ?, ?, ?)'
    @dbh.prepare(sql) do |sth|
      sth.execute(switch_id, hostname, descr, community)
      sth.each do |row|
        retvalue = row[0]
        puts "Debug: #{retvalue}" if $DEBUG
      end
    end

    return retvalue
  end

  # Delete a switch
  # 
  # Provide a switch_id
  #
  # Note that this will result in ALL HISTORY FOR THE SWITCH BEING LOST!!!!!
  def delete_switch(switch_id)
    db_cached_connect

    retvalue = nil
    
    sql = 'SELECT deleteSwitch(?)'
    @dbh.prepare(sql) do |sth|
      sth.execute(switch_id)
      sth.each do |row|
        retvalue = row[0]
        puts "Debug: #{retvalue}" if $DEBUG
      end
    end

    return retvalue
  end

  # List switches
  #
  # Arguments:
  #  switch_id: The specific switch_id to list
  #  hostname: A hostname to require for a match
  #  descr: A description to require for a match
  #  community: An SNMP community to require for a match
  #
  # Any argument that is passed in as nil will match all values for that
  # parameter.  Specifically defined values will require the returned records
  # to match exactly.
  #
  # Returns:
  #   Array of hashs
  #     Each array element represents one row (one switch)
  #     Within each array element is a hash with the following keys;
  #       switch_id     -> The switch ID
  #       hostname      -> The host name
  #       descr         -> The switch's description
  #       snmpcommunity -> The SNMP RO community used to connect to the switch
  def list_switches(switch_id=nil, hostname=nil, descr=nil, community=nil)
    db_cached_connect

    retvalue = []

    sql = "SELECT switch_id,
                 hostname,
                 descr,
                 snmpcommunity
           FROM   switch
           WHERE  COALESCE(?, switch_id) = switch_id
             AND  COALESCE(?, hostname) = hostname
             AND  COALESCE(?, descr) = descr
             AND  COALESCE(?, snmpcommunity) = snmpcommunity;"

    @dbh.prepare(sql) do |sth|
      sth.execute(switch_id, hostname, descr, community)
      sth.fetch_hash do |hash|
        retvalue.push(hash)
      end
    end

    return retvalue
  end

  # List switchports
  #
  # Arguments:
  #  switch_id: The specific switch_id to list
  #  name: A portname to require for a match
  #  descr: A description to require for a match
  #  portindex: A port index to require for a match
  #  bridgeport: A bridge port to require for a match
  #  uplink: An uplink to require for a match (use 0 or 1)
  #  active: Only show active ports? (use 0 or 1)
  #
  # Any argument that is passed in as nil will match all values for that
  # parameter.  Specifically defined values will require the returned records
  # to match exactly.
  #
  # Returns:
  #   Array of hashs
  #     Each array element represents one row (one switchport)
  #     Within each array element is a hash with the following keys;
  #       switch_id     -> The switch ID
  #       name          -> The port name
  #       descr         -> The port description
  #       portindex     -> The port index (IF-MIB)
  #       bridgeport    -> The bridge port (BRIDGE-MIB)
  #       uplink        -> Is port an uplink?
  #       active        -> Is port active?
  def list_switchports(switch_id=nil,
                       name=nil,
                       descr=nil,
                       portindex=nil,
                       bridgeport=nil,
                       uplink=nil,
                       active=nil)
    db_cached_connect

    retvalue = []

    sql = "SELECT switch_id,
                  switchport_id,
                  name,
                  descr,
                  portindex,
                  bridgeport,
                  uplink,
                  active
           FROM   switchport
           WHERE  COALESCE(?, switch_id) = switch_id
             AND  COALESCE(?, name) = name
             AND  COALESCE(?, descr) = descr
             AND  COALESCE(?, portindex) = portindex
             AND  COALESCE(?, bridgeport) = bridgeport
             AND  COALESCE(?, uplink) = uplink
             AND  COALESCE(?, active) = active"

    @dbh.prepare(sql) do |sth|
      sth.execute(switch_id, name, descr, portindex, bridgeport, uplink, active)
      sth.fetch_hash do |hash|
        retvalue.push(hash)
      end
    end

    return retvalue
  end

  # Get a list of the active MAC addresses
  #
  # Returns array of strings (MAC)
  def active_macs
    db_cached_connect

    retvalue = []

    sql = "SELECT M.mac
           FROM   mac M,
                  mac_history MH
           WHERE  M.mac_id = MH.mac_id
             AND  NOW() BETWEEN MH.start_dt AND MH.end_dt"

    @dbh.prepare(sql) do |sth|
      sth.execute(switch_id, name, descr, portindex, bridgeport, uplink, active)
      sth.fetch_hash do |hash|
        retvalue.push(hash['mac'])
      end
    end

    return retvalue
  end


  # "Renew" a switchport - adds it if it is new, leaves it alone (in DB) if
  # it is unchanged, or updates it if it is now different from the DB (marks
  # old port as "not active" and creates new records)
  #
  # Arguments:
  #   switch_id  -> Switch's ID
  #   name       -> Switch port's descr (IF-MIB)
  #   portindex  -> Switch port's index (IF-MIB)
  #   bridgeport -> Switch port's bridge port (BRIDGE-MIB)
  #
  # Returns switchport ID if modified
  def renew_switchport(switch_id, name, portindex, bridgeport)
    db_cached_connect

    retvalue = nil

    sql = 'SELECT addOrMoveSwitchport(?, ?, ?, ?)'
    @dbh.prepare(sql) do |sth|
      sth.execute(switch_id, name, portindex, bridgeport)
      sth.each do |row|
        retvalue = row[0]
      end
    end
    
    return retvalue
  end

  # "Renew" a MAC - adds it if it is new, updates last_seen and end_dt's,
  # manages old views of it on other switch ports
  #
  # NOTE! CALL startRun before and endRun after a batch of renew_mac()
  #
  # Arguments:
  #   switch_id  -> Switch's ID
  #   bridgeport -> Switch port's bridge port (BRIDGE-MIB)
  #   mac        -> MAC address
  #
  # Returns 1
  def renew_mac(switch_id, bridgeport, mac)
    retvalue = nil

    sql = 'SELECT addOrMoveMac(?, ?, ?)'
    @dbh.prepare(sql) do |sth|
      sth.execute(switch_id, bridgeport, mac)
      sth.each do |row|
        retvalue = row[0]
      end
    end
    
    return retvalue
  end

  # Initialize data, table values, transaction, etc. for renew_mac()
  #
  # No arguments or return value
  def startRun
    db_cached_connect

    @dbh.do("BEGIN TRANSACTION;")
    @dbh.do("SELECT startRun();")
  end

  # Finalize data, table values, transaction, etc. for renew_mac()
  #
  # No arguments or return value
    def endRun
    db_cached_connect

    @dbh.do("SELECT endRun();")
    @dbh.do("COMMIT TRANSACTION;")
  end

  # Modify a switchport in the database
  #
  # To Modify: Provide switchport_id and any element (descr, uplink)
  # that you wish to change.  Other elements should be passed as nil
  #
  # If an invalid switchport_id is passed, nil will be returned,
  # otherwise true will be returned.
  def modify_switchport(switchport_id, descr, uplink)
    db_cached_connect

    retvalue = nil

    sql = 'SELECT editSwitchPort(?, ?, ?)'
    @dbh.prepare(sql) do |sth|
      sth.execute(switchport_id, descr, uplink)
      sth.each do |row|
        retvalue = row[0]
        puts "Debug: #{retvalue}" if $DEBUG
      end
    end

    return retvalue
  end

  # List macs
  #
  # Filters out "uplink" ports and inactive MACs
  #
  # Arguments:
  #   NONE currently
  #
  # Returns:
  #   Array of hashs
  #     Each array element represents one row (one mac entry)
  #     Within each array element is a hash with the following keys;
  #       switch_descr     -> Nice switch description
  #       switchport_descr -> Nice switch port description
  #       mac              -> MAC address
  #       mac_descr        -> MAC description
  def list_macs
    db_cached_connect

    retvalue = []

    sql = "SELECT  S.descr switch_descr,
                   SP.descr switchport_descr,
                   M.mac mac,
                   M.descr mac_descr
           FROM    mac_history MH,
                   switch S,
                   switchport SP,
                   mac M
           WHERE   MH.mac_id = M.mac_id
             AND   MH.switchport_id = SP.switchport_id
             AND   SP.switch_id = S.switch_id
             AND   NOW() BETWEEN MH.start_dt AND MH.end_dt
             AND   SP.uplink = false
           ORDER BY S.descr, SP.descr, M.mac, M.descr;"

    @dbh.prepare(sql) do |sth|
      sth.execute
      sth.fetch_hash do |hash|
        retvalue.push(hash)
      end
    end

    return retvalue
  end

end
