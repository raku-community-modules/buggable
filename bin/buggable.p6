#!/usr/bin/env perl6
use lib </home/zoffix/CPANPRC/IRC-Client/lib .>;

use IRC::Client;
use Pastebin::Shadowcat;
use Mojo::UserAgent:from<Perl5>;

class Bash {
    constant $BASH_URL = 'http://bash.org/?random1';
    constant $cache    = Channel.new;
    has        $!ua    = Mojo::UserAgent.new;

    multi method irc-to-me ($ where /bash/) {
        start $cache.poll or do { self!fetch-quotes; $cache.poll };
    }

    method !fetch-quotes {
        $cache.send: $_ for $!ua.get($BASH_URL).res.dom.find('.qt').each».all_text;
    }
}

.run with IRC::Client.new:
    :nick<MahBot>
    # :host<irc.freenode.net>
    :channels<#perl6>
    :debug
    :plugins(Bash.new)
    :filters(
        -> $text where .chars > 20 {
            Pastebin::Shadowcat.new.paste: $text;
        }
    )
