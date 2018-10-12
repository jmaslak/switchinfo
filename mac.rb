#
# COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
# ALL RIGHTS RESERVED
#

# Access switch configuration database
class Mac

  # Set initial MAC
  def initialize(*args)
    case args.size
    when 0
      @mac = nil
    when 1
      self.mac=args[0]
    else
      raise 'Invalid number of arguments'
    end
  end

  # Setter
  def mac=(value)
    if ! self.valid_mac?(value)
      raise 'Invalid MAC format'
    end
    @mac = Mac.cannonize_mac(value)
  end

  # Getter
  def mac
    @mac
  end

  # MAC Cannonization
  def cannonize_mac
    self.cannonize_mac(@mac)
  end

  def cannonize_mac!
    @mac = Mac.cannonize_mac(@mac)
  end

  def self.cannonize_mac(mac_address)
    m = mac_address.to_s.downcase
    m.gsub!(/[:\.]/, '')

    m.sub(/^(..)(..)(..)(..)(..)(..)$/, '\1:\2:\3:\4:\5:\6')
  end

  # MAC Validation
  def self.valid_mac?(mac_address)
    m = mac_address.downcase

    # 01:23:45:67:89:ab
    if (m =~ /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/)
      return true
    end

    # 0123.4567.89ab
    if (m =~ /^([0-9a-f]{4}\.){2}[0-9a-f]{4}$/)
      return true
    end

    # 0123456789ab
    if (m =~ /^[0-9a-f]{12}$/)
      return true
    end

    return false
  end

  def valid_mac?(mac_address)
    Mac.valid_mac?(mac_address)
  end

  # to_s
  def to_s
    @mac.to_s
  end

end

