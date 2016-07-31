#!/usr/bin/env perl6
use lib <
    /home/zoffix/CPANPRC/IRC-Client/lib
    /home/zoffix/services/lib/IRC-Client/lib
    lib
    .
>;

use IRC::Client;
use Buggable::Plugin::TravisWatcher;

my $password;
$password = "password".IO.slurp.trim if "password".IO.e;

.run with IRC::Client.new:
    :nick<buggable>,
    :host(%*ENV<BUGGABLE_IRC_HOST> // 'irc.freenode.net'),
    :channels<#perl6-dev>,
    |(:$password if $password),
    :debug,
    :plugins(
        Buggable::Plugin::TravisWatcher.new,
    );
