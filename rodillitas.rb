#!/usr/bin/ruby

require "basebot"
require "date"
require "yaml"
require "net/http"
require "rexml/document"


Config = YAML::load(File.open("config.yml"))
Constants = YAML::load(File.open("const.yml"))

class Rodillitas < IRC
    #Gestionamos los comandos y sus argumentos
    def on_command(command, args, who, where)
        case command
        when /^all$/: show_help(where)
        when /^todo$/: show_help(where)
        when /^ayuda$/: show_help(where)
        when /^help$/: show_help(where)
        when /^art$/
            lang = Constants['site'].has_key?(args) ? args : "es"
            url = URI.parse("http://#{lang}.wikipedia.org")
            url.host.untaint
            Net::HTTP.start(url.host, url.port) do |http|
                response =  http.get("/w/index.php?title=Special:statistics&action=raw")
                case response
                when Net::HTTPSuccess     then response
                when Net::HTTPRedirection 
                    response = http.get(response['location'])
                end
                if response.body =~ /good=(\d+)/
                    write_to_chan("#{lang} tiene #{$1} artículos", where)
                end 
            end


        when /^c$/
            lang, proj, who = get_lang_site(args)
            url = URI.parse("http://#{lang}.#{proj}.org/")
            url.host.untaint
            Net::HTTP.start(url.host, url.port) do |http|
                str =  http.get("/w/api.php?action=query&list=users&ususers=#{who}&usprop=groups|editcount|blockinfo|registration&format=yaml")
                resp = YAML::each_document(str.body) do |ydoc|
                    data = ydoc['query']['users'][0]
                    editcount = data['editcount']
                    write_to_chan("#{lang}:#{proj}:#{who} ha hecho #{editcount} ediciones", where)
                end
            end
        when /^calc$/
            args.untaint
            if args =~ /pi/
                write_to_chan("¿para qué narices necesitas PI en wikipedia? Wikifica un poco, anda", where)
            else
                calculated = eval(args).to_s
                if calculated.length > 20
                    write_to_chan("ACTION mira el resultado y se pregunta qué tendrá que ver con Wikipedia", where)
                else
                    write_to_chan(eval(args).to_s ,where)
                end
            end
        when /^cb$/
            write_to_chan("http://es.wikipedia.org/wiki/Special:contributions/#{args}", where)
            write_to_chan("http://es.wikipedia.org/wiki/Special:blockip/#{args}", where)
        when /^cdb$/
            write_to_chan("http://es.wikipedia.org/wiki/Categoría:Wikipedia:Consultas_de_borrado", where)

        when /^dest$/
            write_to_chan("http://es.wikipedia.org/wiki/WP:BORRAR", where)

        when /^fetch$/
            lang, proj, what = get_lang_site(args)
            url = URI.parse("http://#{lang}.#{proj}.org")
            url.host.untaint
            Net::HTTP.start(url.host, url.port) do |http|
                response =  http.get("/w/index.php?title=#{what.gsub(" ","_")}&action=raw")
                case response
                when Net::HTTPSuccess     then response
                when Net::HTTPRedirection 
                    response = http.get(response['location'])
                end
                write_to_chan(response.body[0..200].gsub("\n", " "), where)
            end
            
        when /^info$/
            lang, proj, who = get_lang_site(args)
            url = URI.parse("http://#{lang}.#{proj}.org/")
            url.host.untaint
            Net::HTTP.start(url.host, url.port) do |http|
                str =  http.get("/w/api.php?action=query&list=users&ususers=#{who}&usprop=groups|editcount|blockinfo|registration&format=yaml")
                resp = YAML::each_document(str.body) do |ydoc|
                    data = ydoc['query']['users'][0]
                    editcount = data['editcount']
                    registration = data['registration']
                    if registration 
                        registration = registration.chomp!.split("T")[0]
                    end
                    blockedby = data['blockedby']
                    blockreason = data['blockreason']
                    bloqueado = ""
                    if blockedby
                        bloqueado = "Bloqueado por #{blockedby}: #{blockreason.chomp} . "
                    end
                    groupsarr = data['groups']
                    groups = ""
                    if groupsarr
                        groups ="Grupos: "
                        groupsarr.each {|g| groups += "#{g}, " }
                        groups.chomp!(", ")
                        groups += ". "
                    end
                    write_to_chan("#{lang}:#{proj}:#{who} #{editcount} ediciones desde #{registration}. #{groups}#{bloqueado}http://#{lang}.#{proj}.org/wiki/Special:Contributions/#{who}", where)
                end
            end

        when /^mant$/
            today = Date::today
            write_to_chan("http://es.wikipedia.org/wiki/Categoría:Wikipedia:Mantenimiento:#{today.day}_de_#{Constants['month'][today.month]}", where)

        when /^site$/
            write_to_chan(Constants['site'][args], where)

        when /^sugus$/
            write_to_chan("pasa por ventanilla: http://code.google.com/p/rodillitas/issues/entry", where)
        when /^tam$/
            lang, proj, what = get_lang_site(args)
            url = URI.parse("http://#{lang}.#{proj}.org")
            url.host.untaint
            Net::HTTP.start(url.host, url.port) do |http|
                response =  http.get("/w/index.php?title=#{what.gsub(" ","_")}&action=raw")
                case response
                when Net::HTTPSuccess     then response
                when Net::HTTPRedirection 
                    response = http.get(response['location'])
                end
                write_to_chan(response.body.length.to_s + " bytes", where)
            end

        when /^vec$/
            write_to_chan("http://es.wikipedia.org/wiki/WP:VEC", where)

        else 
            write_to_chan("Ajá.", where)
            puts command

        end
    end

    def show_help(where)
        write_to_chan("&art, &cb, &cdb, &dest, &fetch, &info, &mant, &site, &sugus, &vec" , where)
    end

    def on_pub_msg(what, who, where)
        case what
        when /rodillitas/
            write_to_chan(Constants['mention'][rand(Constants['mention'].length)], where)
        else
            what.scan(/\[\[([^|\]]+)\|?([^\]]*)\]\]/) {|s, s2| wikilink(s, where, false)}
            what.scan(/\{\{([^|\}]+)\|?([^\}]*)\}\}/) {|s, s2| wikilink(s, where, true)}
        end
    end

    def get_lang_site(str)
        splitted = str.split(":")
        tmp = ""
        lang = "es"
        project = "wikipedia"

        if splitted.length > 1
            if Constants['multilingual_project'].has_key?(splitted[0])
                splitted[1..-1].each { |s| tmp += "#{s}:"}
                tmp.chomp!(":")
                return splitted[0], "wikimedia", tmp
            elsif Constants['project'].has_key?(splitted[0])
                project = splitted[0]
                if Constants['site'].has_key?(splitted[1])
                    lang = splitted[1]
                    puts project
                    splitted[2..-1].each { |s| tmp += "#{s}:"}
                    tmp.chomp!(":")
                else
                    splitted[1..-1].each { |s| tmp += "#{s}:"}
                    tmp.chomp!(":")
                end
                return lang, Constants['project'][project], tmp
            elsif Constants['site'].has_key?(splitted[0])
                lang = splitted[0]
                if Constants['project'].has_key?(splitted[1])
                    project = splitted[1]
                    splitted[2..-1].each { |s| tmp += "#{s}:"}
                    tmp.chomp!(":")
                else
                    splitted[1..-1].each { |s| tmp += "#{s}:"}
                    tmp.chomp!(":")
                end
                return lang, Constants['project'][project], tmp
            end
        end
        return lang, Constants['project'][project], str
    end

    def wikilink(str, where, template)
        lang, site, what = get_lang_site(str)
        pref = template ? "Template:" : ""
        write_to_chan("http://#{lang}.#{site}.org/wiki/#{pref}#{what.gsub(" ","_")}", where)
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
