#!/usr/local/bin/ruby

require "basebot"

class Rodillitas < IRC
    def on_command(command, who, where)
        case command
        when /^art\s(.*)$/
            puts $1
        else 
            write_to_chan("Ajá.")
            puts command
        end
    end

    def on_pub_msg(what, who, where)
        case what
        when /rodillitas/
            write_to_chan("Oh, bésame", where)
        else
            what.scan(/\[\[([^|\]]+)\|?([^\]]*)\]\]/) {|s, s2| write_to_chan("http://es.wikipedia.org/wiki/#{s.sub(" ","_")}", where) }
            what.scan(/\{\{([^|\}]+)\|?([^\}]*)\}\}/) {|s, s2| write_to_chan("http://es.wikipedia.org/wiki/Plantilla:#{s.sub(" ","_")}", where) }
        end
    end
end

require 'yaml'

Config = YAML::load(File.open("config.yml"))
puts Config['server']
# The main program
# If we get an exception, then print it out and keep going (we do NOT want
# to disconnect unexpectedly!)
bot = Rodillitas.new("irc.freenode.org", Config['port'], Config['nick'], "#wikipedia-es", Config['user'])

bot.connect()
begin
    bot.main_loop()
rescue Interrupt
rescue Exception => detail
    puts detail.message()
    print detail.backtrace.join("\n")
    retry
end
