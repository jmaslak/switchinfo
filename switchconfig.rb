
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

  # CLose the database handle
  def db_close
    @dbh and @dbh.close
    @dbh = nil
  end

  # Add a switch to the 
  def add_switch(hostname, descr, community)
    db_cached_connect

    retvalue = nil

    sql = 'SELECT addOrUpdateSwitch(?, ?, ?, ?)'
    @dbh.prepare(sql) do |sth|
      begin
        sth.execute(nil, hostname, descr, community)
        sth.each do |row|
          retvalue = row[0]
          puts "Debug: #{retvalue}" if $DEBUG
        end
      rescue DBI::ProgrammingError => e
        if e.message[/Key .* already exists/]
          STDERR.puts "This switch (#{hostname}) already exists, not adding."
        else
          raise e
        end
      end
    end

    return retvalue
  end

  # List switches
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

end
