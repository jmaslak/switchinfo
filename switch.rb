#
# COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
# ALL RIGHTS RESERVED
#

require 'snmp'

class InvalidDataException < RuntimeError
end

class Switch

  attr_accessor :name
  attr_accessor :community
  attr_accessor :uplinks
  attr_accessor :descriptions

  def initialize(name, community, uplinks, descriptions)
    @name = name
    @community = community
    @interfaces = {}
    @portindex = {}
    @mactable = {}
    @uplinks = uplinks || []
    @descriptions = descriptions || {}

    updateInterfaces!
    updateBridgePortIndexes!
    updateForwardingTable!
  end

  def getMacs(showUplinks=true)
    if showUplinks
      @mactable.keys
    else
      getMactableEliminateUplinks.keys
    end
  end

  def getMacsWithPorts(showUplinks=true)
    if showUplinks
      table = @mactable
    else
      table = getMactableEliminateUplinks
    end

    table.keys.each do |mac|
      table[mac].map! { |port| getPortNameFromIndex(@portindex[port]) }
    end

    table
  end

  def getPortNameFromIndex(port)
    @descriptions[@interfaces[port]] || @interfaces[port]
  end

  def getPorts(mac, showUplinks=true)
    if @mactable.has_key?(mac)
      getMactableEliminateUplinks[mac]
    else
      []
    end
  end

  def getMactableEliminateUplinks
    filteredHash = {}

    @mactable.each do |key,value|
      ports = value.select do |port|
        ! @uplinks.include?(@interfaces[@portindex[port]])
      end

      if ! ports.empty?
        filteredHash[key] = ports
      end
   end

   filteredHash
  end

  def updateInterfaces!
    # The MIB-II standard interface descriptions, by index
    @interfaces = {}

    ifTable_columns = ['ifIndex', 'ifDescr']
    SNMP::Manager.open(:Host => @name,
                       :Community => @community,
                       :MibModules => ['IF-MIB']) do |manager|

      manager.walk(ifTable_columns) do |row|

        cols = row.map { |item| item.value }

        index = cols[0].to_i
        desc = cols[1]

        @interfaces[index] = desc
      end
    end
  end

  def updateBridgePortIndexes!

    # Of course bridge ports use a different interface scheme, they
    # number the port, which you have to look in a different place
    # to find the index.  And of course not all bridge ports have
    # interfaces, just to make life interesting.  So there may be "missing"
    # entries here.
    @portindex = {}

    ifIndex_columns = ['dot1dBasePort', 'dot1dBasePortIfIndex']
    SNMP::Manager.open(:Host => @name,
                       :Community => @community,
                       :MibModules => ['BRIDGE-MIB']) do |manager|
      manager.walk(ifIndex_columns) do |row|
        cols = row.map { |item| item.value }

        port = cols[0].to_i
        index = cols[1].to_i

        @portindex[port] = index

      end
    end

    if @portindex.empty?
      @interfaces.each_key { |k| @portindex[k] = k }
    end
  end

  def updateForwardingTable!

    @mactable = {}

    fdbTable_columns = [
      'dot1dTpFdbAddress',
      'dot1dTpFdbPort',
      'dot1dTpFdbStatus'
    ]

    SNMP::Manager.open(:Host => @name,
                      :Community => @community,
                      :MibModules => ['BRIDGE-MIB']) do |manager|

      manager.walk(fdbTable_columns) do |row|

        mac = row[0].value
        port = row[1].value.to_i

        mac = mac.unpack('H2H2H2H2H2H2').join(':')

        @mactable[mac] ||= []
        @mactable[mac].push(port)
       
      end
    end
  end
end

