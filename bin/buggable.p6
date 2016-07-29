#!/usr/bin/env perl6
use lib </home/zoffix/CPANPRC/IRC-Client/lib /var/www/tmp/IRC-Client/lib .>;

use IRC::Client;

class AlarmBot does IRC::Client::Plugin {
    method irc-connected ($) {
        start react {
            whenever Supply.interval(3) {
                $.irc.send: :where<#perl6> :text<Three seconds passed!>;
            }
        }
    }
}

.run with IRC::Client.new:
    :nick<MahBot>
    :host<localhost>
    :channels<#perl6>
    :debug
    :plugins[AlarmBot.new]
