#!/usr/local/bin/ruby

require "socket"
#Basado en http://snippets.dzone.com/posts/show/1785

# Don't allow use of "tainted" data by potentially dangerous operations
$SAFE=1

# La clase IRC se comunica con el servidor y alberga el bucle principal
class IRC
    def initialize(server, port, nick, channel, user)
        @server = server
        @port = port
        @nick = nick
        @channel = channel
    end
    def send(s)
        # Envía un mensaje al servidor de IRC y lo muestra en pantalla
        puts "--> #{s}"
        @irc.send "#{s}\n", 0 
    end
    def connect()
        # Conectarse al servidor
        @irc = TCPSocket.open(@server, @port)
        send "USER rodillitas rodillitas rodillitas: rodillitas rodillitas"
        send "NICK #{@nick}"
        send "JOIN #{@channel}"
    end
    def evaluate(s)
        # Make sure we have a valid expression (for security reasons), and
        # evaluate it if we do, otherwise return an error message
        if s =~ /^[-+*\/\d\s\eE.()]*$/ then
            begin
                s.untaint
                return eval(s).to_s
            rescue Exception => detail
                puts detail.message()
            end
        end
        return "Error"
    end
    def handle_server_input(s)
        #la batería de regexps de cosas que nos manda el server
        case s.strip
            when /^PING :(.+)$/i
                puts "[ Server ping ]"
                send "PONG :#{$1}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
                puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001PING #{$4}\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
                puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
                send "NOTICE #{$1} :\001VERSION Rodillitas\001"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
                puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
                send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s#(.+)\s:(.+)$/i
                on_msg($5, $1, $4)
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/i
                on_priv_msg($5, $1, $4)
            when /^:(.+?)!(.+?)@(.+?)\sKICK\s#(.+)\s(\S+)\s:(.+)$/i 
                on_kick($1, $5, $4)
            else
                puts s
        end
    end

    #FUNCIONES A SOBRECARGAR CUANDO SE HEREDE
    def write_to_chan(what, where)
        send "PRIVMSG ##{where} :#{what}"
    end

    def action_to_chan(what, where)
        send "PRIVMSG ##{where} :ACTION #{what}"
    end

    def on_msg(what, who, where)
        #mirar si es un comando (que empieza por @)
        if what =~ /^@(\S+)\s?(.*)$/
            on_command($1, $2, who, where)
        else 
            on_pub_msg(what, who, where)
        end
    end

    def on_pub_msg(what, who, where)
        puts "#{who} says #{what} at #{where}"
    end

    def on_command(command, args, who, where)
        puts "Command #{command}"
    end
    
    def on_priv_msg(what, who, where)
        puts "#{who} says #{what} in private"
    end

    def on_kick(who, to_who, where)
        puts "#{who} kicks #{to_who} from #{where}"
    end

    def main_loop()
        # Just keep on truckin' until we disconnect
        while true
            ready = select([@irc, $stdin], nil, nil, nil)
            next if !ready
            for s in ready[0]
                if s == $stdin then
                    return if $stdin.eof
                    s = $stdin.gets
                    send s
                elsif s == @irc then
                    return if @irc.eof
                    s = @irc.gets
                    handle_server_input(s)
                end
            end
        end
    end
end

