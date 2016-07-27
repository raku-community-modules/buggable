#!/usr/bin/env perl6
use lib </home/zoffix/CPANPRC/IRC-Client/lib /var/www/tmp/IRC-Client/lib .>;

use IRC::Client;

class JoinerBot {
    method irc-to-me ( $e where /^nick \s+ $<name>=(\S+)/ ) {
        $e.irc.nick: $<name>;
    }
}

.run with IRC::Client.new:
    :nick<MahBot>
    :host(%*ENV<IRC_HOST> // 'localhost')
    :channels<#perl6>
    :debug
    :plugins(JoinerBot.new)
