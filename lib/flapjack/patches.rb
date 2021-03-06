require 'ostruct'
require 'daemons'
require 'log4r'

class OpenStruct
  def to_h
    @table
  end
end

module Daemons
  class PidFile
    # we override this method so creating pid files is fork-safe
    def filename
      File.join(@dir, "#{@progname}#{Process.pid}.pid")
    end
  end
end

#module Log4r
#  class Logger
#    def error(args)
#      err(args)
#    end
#
#    def warning(args)
#      warn(args)
#    end
#  end
#end

# extracted from Extlib.
# FIXME: what's the licensing here?
class String
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
end

# http://gist.github.com/151324
class Hash
  def symbolize_keys
    inject({}) do |acc, (k,v)|
      key = String === k ? k.to_sym : k
      value = Hash === v ? v.symbolize_keys : v
      acc[key] = value
      acc
    end
  end
end
