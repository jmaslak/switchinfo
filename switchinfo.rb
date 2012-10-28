#!/usr/bin/ruby -w
#
# COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
# ALL RIGHTS RESERVED
#

require 'optparse'

require 'history.rb'
require 'switch.rb'
require 'switchconfig.rb'


def parse_opts!

  @options = {}

  if ARGV.size > 0
    @options[:action] = ARGV.shift

    parse_global_opts!

    case @options[:action]
    when 'help', '--help', '-h', '-?', '/?'
      usage!
    when 'add_switch'
      parse_opts_add_switch!
    when 'modify_switch'
      parse_opts_modify_switch!
    when 'delete_switch'
      parse_opts_delete_switch!
    when 'list_switches'
      parse_opts_list_switches!
    when 'list_macs'
      parse_opts_list_macs!
    when 'list_switchports'
      parse_opts_list_switchports!
    when 'modify_switchport'
      parse_opts_modify_switchport!
    when 'mac_history'
      parse_opts_mac_history!
    when 'scan'
      parse_opts_scan!
    else
      usage!("Unknown action: #{@options[:action]}")
    end

  else
    usage!("Must supply an action")
  end
end

def parse_global_opts!

  options = ARGV.map {|v| v}

  while options.size > 0
    opt = options.shift

    case opt
    when '--terse'
      @options[:format] = :terse
      ARGV.delete(opt)
    when '--long'
      @options[:format] = :long
      ARGV.delete(opt)
    end

    left = opt[/^[^=]*=?/]
    right = opt[/=(.*)$/, 1]

    case left
    when '--dbhost='
      @options[:dbhost] = right
      ARGV.delete(opt)
    when '--dbuser='
      @options[:dbuser] = right
      ARGV.delete(opt)
    when '--dbpass='
      @options[:dbpass] = right
      ARGV.delete(opt)
    when '--database='
      @options[:dbdatabase] = right
      ARGV.delete(opt)
    end
  end

  @options[:dbhost] ||= 'localhost'
  @options[:dbuser] ||= 'switch'
  @options[:dbpass] ||= 'switch'
  @options[:dbdatabase] ||= 'switch'
  @options[:format] ||= :default
end

def parse_opts_add_switch!
  optparse = OptionParser.new do |opts|

    opts.on('-n', '--hostname HOSTNAME', 'Hostname of the switch') do |hostname|
      @options[:hostname] = hostname
    end

    opts.on('-d', '--descr DESCRIPTION', 'Description of switch') do |descr|
      @options[:descr] = descr
    end

    opts.on('-c', '--community COMMUNITY', 'SNMP community to use for switch') do |community|
      @options[:community] = community
    end

  end
  
  optparse.parse!

  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
  
  if !@options[:hostname]
    usage!("Must supply a hostname (--hostname=...)")
  end

  if !@options[:community]
    usage!("Must supply an SNMP community (--community=...)")
  end

  @options[:descr] ||= @options[:hostname]
end

def parse_opts_modify_switch!
  optparse = OptionParser.new do |opts|

    opts.on('-h', '--hostname HOSTNAME', 'Hostname of the switch') do |hostname|
      @options[:hostname] = hostname
    end

    opts.on('-d', '--descr DESCRIPTION', 'Description of switch') do |descr|
      @options[:descr] = descr
    end

    opts.on('-c', '--community COMMUNITY', 'SNMP community to use for switch') do |community|
      @options[:community] = community
    end

    opts.on('-s', '--switch-id SWITCH-ID', 'Switch ID to modify') do |switch_id|
      @options[:switch_id] = switch_id
    end
  end
  
  optparse.parse!

  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
  
  if !@options[:switch_id]
    usage!("Must supply switch-id (--switch-id=...)")
  end
end

def parse_opts_delete_switch!
  optparse = OptionParser.new do |opts|
    opts.on('-s', '--switch-id SWITCH-ID', 'Switch ID to delete') do |switch_id|
      @options[:switch_id] = switch_id
    end
  end
  
  optparse.parse!

  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
  
  if !@options[:switch_id]
    usage!("Must supply switch-id (--switch-id=...)")
  end
end

def parse_opts_list_switches!
  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
end

def parse_opts_list_macs!
  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
end

def parse_opts_list_switchports!
  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
end

def parse_opts_modify_switchport!
  optparse = OptionParser.new do |opts|

    opts.on('-s', '--switchport-id ID', 'Switchport ID from list_switchports') do |hostname|
      @options[:switchport_id] = hostname
    end

    opts.on('-d', '--descr DESCRIPTION', 'Friendly description of switchport') do |descr|
      @options[:descr] = descr
    end

    opts.on('-u', '--uplink', 'Set as uplink') do |community|
      if @options.has_key?(:uplink)
        usage!("Cannot modify the uplink characteristic twice!")
      end
      @options[:uplink] = 1
    end

    opts.on('-n', '--not-uplink', 'Set as NOT an uplink') do |community|
      if @options.has_key?(:uplink)
        usage!("Cannot modify the uplink characteristic twice!")
      end
      @options[:uplink] = 0
    end
  end
  
  optparse.parse!

  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
  
  if !@options[:switchport_id]
    usage!("Must supply switchport-id (--switchport-id=...)")
  end

  if ! @options.has_key?(:uplink)
    @options[:uplink] = nil
  end

  if ! @options.has_key?(:descr)
    @options[:descr] = nil
  end
end

def parse_opts_mac_history!
  optparse = OptionParser.new do |opts|

    opts.on('-m', '--mac-address MAC', 'address to lookup') do |mac|
      @options[:mac] = mac
    end
  end

  optparse.parse!

  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end

  if ! @options.has_key?(:mac)
    usage!("Must supply MAC address (--mac-address=...)")
  end

  if ! valid_mac?(@options[:mac])
    usage!("MAC must be specified in format 01:23:45:67:89:ab")
  end
  
end

def parse_opts_scan!
  if ARGV.size > 0
    usage!("Unknown arguments: #{ARGV.join(', ')}")
  end
end


def usage!(text=nil)
  if text
    STDERR.puts text
    STDERR.puts ""
  end

  STDERR.puts "#{$0} [-a|--action] ACTION [options]"
  STDERR.puts ""
  STDERR.puts "Actions:"
  STDERR.puts "  add_switch: Add a new switch to the configuration.  Requires the"
  STDERR.puts "              following options:"
  STDERR.puts "    [-n|--hostname HOSTNAME] (REQUIRED) Hostname to use for switch"
  STDERR.puts "    [-d|--descr DESCRIPTION] (OPTIONAL) If not found, use HOSTNAME for"
  STDERR.puts "                             switch's description"
  STDERR.puts "    [-c|--community COMMUNITY] (REQUIRED) SNMP community to use"
  STDERR.puts ""
  STDERR.puts "  modify_switch: Modify a switch to the configuration.  Uses the"
  STDERR.puts "              following options (leaves unsupplied options unchanged):"
  STDERR.puts "    [-s|--switch-id SWITCH-ID] (REQUIRED) Switch ID to modify (use"
  STDERR.puts "                               list_switches to obtain switch ID)"
  STDERR.puts "    [-n|--hostname HOSTNAME] (OPTIONAL) Hostname to use for switch"
  STDERR.puts "    [-d|--descr DESCRIPTION] (OPTIONAL) If not found, use HOSTNAME for"
  STDERR.puts "                             switch's description"
  STDERR.puts "    [-c|--community COMMUNITY] (OPTIONAL) SNMP community to use"
  STDERR.puts ""
  STDERR.puts "  delete_switch: Delete switch from the configuration.  Uses the"
  STDERR.puts "                 following option:"
  STDERR.puts "    [-s|--switch-id SWITCH-ID] (REQUIRED) Switch ID to delete (use"
  STDERR.puts "                               list_switches to obtain switch ID)"
  STDERR.puts ""
  STDERR.puts "  list_switches: List all switches"
  STDERR.puts ""
  STDERR.puts "  list_switchports: List all switch ports"
  STDERR.puts ""
  STDERR.puts "  modify_switchport: Modifies a switchport.  Uses the following options:"
  STDERR.puts "    [-s|--switchport-id ID] (REQUIRED) Switchport ID to modify"
  STDERR.puts "    [-d|--descr] (OPTIONAL) New description to use for port"
  STDERR.puts "    [-u|--uplink] (OPTIONAL) Sets port as an uplink port. Cannot be used"
  STDERR.puts "                             with --not-uplink or -n"
  STDERR.puts "    [-n|--not-uplink] (OPTIONAL) Sets port as an NOT an uplink port."
  STDERR.puts "                                 Cannot be used with --uplink or -u"
  STDERR.puts ""
  STDERR.puts "  list_macs: List all active MACs"
  STDERR.puts ""
  STDERR.puts "  mac_history: Gets a history for a MAC address"
  STDERR.puts "    [-m|--mac-address MAC] (REQUIRED) MAC address to lookup"
  STDERR.puts ""
  STDERR.puts "  scan: Perform interface and MAC scan"
  STDERR.puts ""
  STDERR.puts "Options Applicable to All Actions:"
  STDERR.puts "  [--dbhost HOSTNAME] (Defautl: localhost) Hostname of database server"
  STDERR.puts "  [--dbuser USERNAME] (Default: switch) Username of database user"
  STDERR.puts "  [--dbpass PASSWORD] (Default: switch) Database password"
  STDERR.puts "  [--database DBNAME] (Default: switch) Database catalog name"
  STDERR.puts "  [--terse] Display short form of values"
  STDERR.puts "  [--long] Display long form of values"
  STDERR.puts ""
  STDERR.puts ""

  exit 1
end

def list_switches(switchconfig)
  results = switchconfig.list_switches

  pretty_print_table(results,
                     ['switch_id', 'hostname', 'descr', 'snmpcommunity'],
                     ['ID', 'Hostname', 'Description', 'Community'],
                     ['number', 'string', 'string', 'string'])
  puts ""

end

def list_switchports(switchconfig)
  results = switchconfig.list_switchports

  pretty_print_table(results,
                     ['switch_id', 'switchport_id', 'descr', 'name', 'portindex', 'bridgeport', 'uplink', 'active'],
                     ['Switch ID', 'Swithport ID', 'Description', 'Name', 'Port Index', 'Bridge Port', 'Uplink', 'Active'],
                     ['number', 'number', 'string', 'string', 'number', 'number', 'string', 'string'])
  puts ""

end

def list_macs(switchconfig)
  results = switchconfig.list_macs

  pretty_print_table(results,
                     ['switch_descr', 'switchport_descr', 'mac', 'mac_descr'],
                     ['Switch', 'Port', 'MAC', 'Description'],
                     ['string', 'string', 'string', 'string'])
  puts ""

end

def mac_history(history)
  results = history.mac_history(@options[:mac])

  pretty_print_table(results,
                     ['switch_descr', 'switchport_descr', 'start_dt', 'end_dt', 'duration'],
                     ['Switch', 'Port', 'First Seen', 'Last Seen', 'Duration'],
                     ['string', 'string', 'datetime', 'datetime', 'duration'])
  puts ""
end

def scan(switchconfig)
  
  switchconfig.startRun

  switchconfig.list_switches().each do |switchele|
    $USERDEBUG and puts switchele.inspect

    switch = Switch.new(switchele['hostname'], switchele['snmpcommunity'])


    switch.getPortDetailList.each do |port|
      switchconfig.renew_switchport(switchele['switch_id'],
                                    port[:name],
                                    port[:portindex],
                                    port[:bridgeport])
    end

    switch.getMacsWithBridgeports.each do |mac, portlist|
      portlist.each do |port|
        switchconfig.renew_mac(switchele['switch_id'],
                               port,
                               mac);
      end
    end
    
  end
  
  switchconfig.endRun
end

def valid_mac?(mac)
  m = mac.downcase

  m =~ /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/
end

def pretty_print_value(val, type)

  ret = ''

  case type
  when 'datetime'
    if val.to_s == '9999-12-31 00:00:00'
      ret = '-'
    else
      ret = val.to_s
    end

    if @options[:format] == :terse
      ret.sub!(/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}):[0-9\.]*$/, '\1');
    end
  when 'duration'
    ret = val.to_s
    if @options[:format] == :terse
      ret.sub!(/(\d{2}:\d{2}):[0-9\.]*$/, '\1');
    end
  else
    ret = val.to_s
  end

  return ret

end

def pretty_print_table(table, columns, alias_list, type_list)
  eternity = 'NONE'
  widths = {}

  aliases = {}
  (0..alias_list.size).each do |i|
    aliases[columns[i]] = alias_list[i]
  end

  typeinfo = {}
  (0..type_list.size).each do |i|
    typeinfo[columns[i]] = type_list[i]
  end

  aliases.each do |col,pretty|
    widths[col] = pretty.to_s.size
  end
 
  table.each do |row|
    columns.each do |col|
      ppv = pretty_print_value(row[col], typeinfo[col]).size
      if ppv > widths[col]
        widths[col] = ppv
      end
    end
  end

  # Make a 256 character space and hypen strings
  space = ' '
  seperator = '-'
  (0..7).each do |v|
    space += space
    seperator += seperator
  end

  line = []
  columns.each do |col|
    spaces_needed = widths[col] - aliases[col].size

    if spaces_needed > 0
      if typeinfo.has_key?(col) and typeinfo[col] == 'number'
        out = space[0,spaces_needed] + aliases[col].to_s
      else
        out = aliases[col].to_s + space[0,spaces_needed]
      end
    else
      out=aliases[col].to_s
    end
    line.push(out)
  end
  puts line.join(' | ')

  line = []
  columns.each do |col|
    line.push(seperator[0,widths[col]])
  end
  puts line.join('-+-')

  table.each do |row|
    line = []
    columns.each do |col|
      ppv = pretty_print_value(row[col], typeinfo[col])
      spaces_needed = widths[col] - ppv.length

      if typeinfo.has_key?(col) and typeinfo[col] == 'number'
        out = space[0,spaces_needed] + ppv
      else
        out = ppv + space[0,(spaces_needed)]
      end

      line.push(out)
    end
    puts line.join(' | ')
  end
end

def main

  parse_opts!

  sc = SwitchConfig.new(@options[:dbhost],
                        @options[:dbuser],
                        @options[:dbpass],
                        @options[:dbdatabase])

  hist = History.new(@options[:dbhost],
                     @options[:dbuser],
                     @options[:dbpass],
                     @options[:dbdatabase])

  case @options[:action]
  when 'add_switch'
    sc.add_switch(@options[:hostname],
                  @options[:descr],
                  @options[:community])
  when 'modify_switch'
    sc.modify_switch(@options[:switch_id],
                     @options[:hostname],
                     @options[:descr],
                     @options[:community])
  when 'delete_switch'
    sc.delete_switch(@options[:switch_id])
  when 'list_switches'
    list_switches(sc)
  when 'list_switchports'
    list_switchports(sc)
  when 'modify_switchport'
    sc.modify_switchport(@options[:switchport_id],
                         @options[:descr],
                         @options[:uplink])
  when 'list_macs'
    list_macs(sc)
  when 'mac_history'
    mac_history(hist)
  when 'scan'
    scan(sc)
  end
end

# $USERDEBUG=1
$USERDEBUG=nil
main
