#!/usr/bin/env perl6
use lib <
    /home/zoffix/CPANPRC/IRC-Client/lib
    /var/www/tmp/IRC-Client/lib
    lib
    .
>;

use IRC::Client;
use Buggable::Plugin::TravisWatcher;

.run with IRC::Client.new:
    :nick<buggable>
    :host(%*ENV<BUGGABLE_IRC_HOST> // 'irc.freenode.net')
    :channels<#perl6-dev>
    :debug
    :plugins(
        Buggable::Plugin::TravisWatcher.new,
    )
