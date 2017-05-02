#!/usr/bin/env perl6
use lib <
    /home/zoffix/CPANPRC/IRC-Client/lib
    /home/zoffix/services/lib/IRC-Client/lib
    lib
>;

use IRC::Client;
use Buggable::Config;
use Buggable::Plugin::TravisWatcher;
use Buggable::Plugin::RT;
use Buggable::Plugin::Eco;
use Buggable::Plugin::Speed;
use Buggable::Plugin::Win;

class Buggable::Info {
    multi method irc-to-me ($ where /^\s* help \s*$/) {
        "\x[2]tags\x[2] | \x[2]tag SOMETAG\x[2] | \x[2]eco\x[2] | "
            ~ "\x[2]eco\x[2] Some search term | \x[2]speed\x[2]";
    }
    multi method irc-to-me ($ where /^\s* source \s*$/) {
        "See: https://github.com/zoffixznet/perl6-buggable";
    }

    multi method irc-to-me ($ where /'bot' \s* 'snack'/) { "om nom nom nom"; }
}

.run with IRC::Client.new:
    :nick<buggable>,
    :username<zofbot-buggable>,
    :host(%*ENV<BUGGABLE_IRC_HOST> // 'irc.freenode.net'),
    :channels( %*ENV<BUGGABLE_DEBUG> ?? '#zofbot' !! |<#perl6  #perl6-dev  #zofbot  #moarvm>),
#    |(:password(conf<irc-pass>)
 #       if conf<irc-pass> and not %*ENV<BUGGABLE_DEBUG>
  #  ),
    :debug,
    :plugins(
        Buggable::Info.new,
        Buggable::Plugin::TravisWatcher.new,
        Buggable::Plugin::RT.new,
        Buggable::Plugin::Eco.new,
        Buggable::Plugin::Speed.new,
        Buggable::Plugin::Win.new(db => conf<win-db-file>.IO),
    );
