#
# COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
# ALL RIGHTS RESERVED
#

require 'dbi'

# Access switch configuration database
class History

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

  # List MAC History
  #
  # Arguments:
  #  mac: MAC address to list
  #
  # Any argument that is passed in as nil will match all values for that
  # parameter.  Specifically defined values will require the returned records
  # to match exactly.
  #
  # Returns:
  #   Array of hashes
  #     Each array element represents one row (one history entry)
  #     Within each array element is a hash with the following keys:
  #       switch_descr     -> The switch's pretty name
  #       switchport_descr -> The switchport's pretty name
  #       start_dt         -> "First Seen" date
  #       end_dt           -> "Last Seen" date
  #   Array is sorted by start_dt, switch_descr, and switchport_descr
  #
  def mac_history(mac=nil)
    db_cached_connect

    retvalue = []

    sql = "SELECT  S.descr switch_descr,
                   SP.descr switchport_descr,
                   MH.start_dt,
                   MH.end_dt,
                   CASE   WHEN MH.end_dt = '9999-12-31' THEN NOW() - MH.start_dt
                          ELSE MH.end_dt - MH.start_dt
                   END AS duration
           FROM    mac_history MH, 
                   switch S,
                   switchport SP, 
                   mac M
           WHERE   MH.mac_id = M.mac_id
             AND   MH.switchport_id = SP.switchport_id
             AND   SP.switch_id = S.switch_id
             AND   SP.uplink = false
             AND   COALESCE(?, M.mac) = M.mac
           ORDER BY MH.start_dt, S.descr, SP.descr;"

    @dbh.prepare(sql) do |sth|
      sth.execute(mac)
      sth.fetch_hash do |hash|
        retvalue.push(hash)
      end
    end

    return retvalue
  end

end
