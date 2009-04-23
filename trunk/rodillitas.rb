#!/usr/bin/ruby

require "basebot"
require "date"
require "yaml"

Config = YAML::load(File.open("config.yml"))
Constants = YAML::load(File.open("const.yml"))

class Rodillitas < IRC
    def on_command(command, args, who, where)
        case command
        when /^all$/
        when /^todo$/
        when /^ayuda$/
        when /^help$/
            write_to_chan("art, cb, cdb, dest, fetch, info, mant, site, sugus, vec" , where)
        when /^art$/
            if args != ""
               write_to_chan("¿qué más te da cuántos artículos tenga #{args}.wiki?",where)
            else
               write_to_chan("¿Para qué?",where)
            end
        when /^info$/
# Ver            http://es.wikipedia.org/w/api.php?action=query&list=users&ususers=al59&usprop=groups|blockinfo|editcount|registration
        when /^cb$/
            write_to_chan("http://es.wikipedia.org/wiki/Special:contributions/#{args}", where)
            write_to_chan("http://es.wikipedia.org/wiki/Special:blockip/#{args}", where)
        when /^fetch$/
            #http://es.wikipedia.org/w/index.php?title=Papa&action=raw
        when /^vec$/
            write_to_chan("http://es.wikipedia.org/wiki/WP:VEC", where)

        when /^mant$/
            today = Date::today
            write_to_chan("http://es.wikipedia.org/wiki/Categoría:Wikipedia:Mantenimiento:#{today.day}_de_#{Constants['month'][today.month]}", where)
        when /^dest$/
            write_to_chan("http://es.wikipedia.org/wiki/WP:BORRAR", where)

        when /^cdb$/
            write_to_chan("http://es.wikipedia.org/wiki/Categoría:Wikipedia:Consultas_de_borrado", where)
        when /^c$/
            write_to_chan("http://es.wikipedia.org/wiki/Special:contributions/#{args}", where)
        when /^site$/
            write_to_chan(Constants['site'][args], where)
        when /^sugus$/
            write_to_chan("pasa por ventanilla: http://code.google.com/p/rodillitas/issues/entry", where)
        else 
            write_to_chan("Ajá.", where)
            puts command
        end
    end

    def on_pub_msg(what, who, where)
        case what
        when /rodillitas/
            write_to_chan(Constants['mention'][rand(Constants['mention'].length)], where)
        else
            what.scan(/\[\[([^|\]]+)\|?([^\]]*)\]\]/) {|s, s2| wikilink(s)}
            what.scan(/\{\{([^|\}]+)\|?([^\}]*)\}\}/) {|s, s2| write_to_chan("http://es.wikipedia.org/wiki/Plantilla:#{s.sub(" ","_")}", where) }
        end
    end
    def wikilink(str)
        write_to_chan("http://es.wikipedia.org/wiki/#{str.sub(" ","_")}", where) 
    end
end


# The main program
# If we get an exception, then print it out and keep going (we do NOT want
# to disconnect unexpectedly!)
bot = Rodillitas.new("irc.freenode.org", Config['port'], Config['nick'], Config['channel'], Config['user'])

bot.connect()
begin
    bot.main_loop()
rescue Interrupt
rescue Exception => detail
    puts detail.message()
    print detail.backtrace.join("\n")
    retry
end
