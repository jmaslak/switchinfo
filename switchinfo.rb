#!/usr/bin/ruby -w
#
# COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
# ALL RIGHTS RESERVED
#

require 'optparse'

require 'switch.rb'
require 'switchconfig.rb'


def parse_opts!

  @options = {}

  if ARGV.size > 0
    @options[:action] = ARGV.shift

    parse_global_opts!

    case @options[:action]
    when 'add_switch'
      parse_opts_add_switch!
    when 'modify_switch'
      parse_opts_modify_switch!
    when 'delete_switch'
      parse_opts_delete_switch!
    when 'list_switches'
      parse_opts_list_switches!
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

    left = opt[/^[^=]*=?/]
    right = opt[/=(.*)$/, 1]

    case left
    when '--dbhost='
      options[:dbhost] = right
      ARGV.delete[opt]
    when '--dbuser='
      options[:dbuser] = right
      ARGV.delete[opt]
    when '--dbpass='
      options[:dbpass] = right
      ARGV.delete[opt]
    when '--database='
      options[:dbdatabase] = right
      ARGV.delete[opt]
    end
  end

  @options[:dbhost] ||= 'localhost'
  @options[:dbuser] ||= 'switch'
  @options[:dbpass] ||= 'switch'
  @options[:dbdatabase] ||= 'switch'
end

def parse_opts_add_switch!
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

    @options[:help] = nil
    opts.on('--help', 'Display this screen') do
      usage!
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

    @options[:help] = nil
    opts.on('--help', 'Display this screen') do
      usage!
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

    @options[:help] = nil
    opts.on('--help', 'Display this screen') do
      usage!
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
  STDERR.puts "Options Applicable to All Actions:"
  STDERR.puts "  [--dbhost HOSTNAME] (Defautl: localhost) Hostname of database server"
  STDERR.puts "  [--dbuser USERNAME] (Default: switch) Username of database user"
  STDERR.puts "  [--dbpass PASSWORD] (Default: switch) Database password"
  STDERR.puts "  [--database DBNAME] (Default: switch) Database catalog name"
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

def pretty_print_table(table, columns, alias_list, type_list)
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
      if row[col].size > widths[col]
        widths[col] = row[col].to_s.size
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
      spaces_needed = widths[col] - row[col].length

      if typeinfo.has_key?(col) and typeinfo[col] == 'number'
        out = space[0,spaces_needed] + row[col].to_s
      else
        out = row[col] + space[0,(spaces_needed)]
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
  end
end

main

