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

class Buggable::Info {
    multi method irc-to-me ($ where /^\s* help \s*$/) {
        "\x[2]rt\x[2] | \x[2]rt TAG\x[2]";
    }
    multi method irc-to-me ($ where /^\s* source \s*$/) {
        "See: https://github.com/zoffixznet/perl6-buggable";
    }

    multi method irc-to-me ($ where /'bot' \s* 'snack'/) { "om nom nom nom"; }
}

.run with IRC::Client.new:
    :nick<buggable>,
    :host(%*ENV<BUGGABLE_IRC_HOST> // 'irc.freenode.net'),
    :channels( %*ENV<BUGGABLE_DEBUG> ?? '#zofbot' !! |<#perl6  #perl6-dev  #zofbot>),
    |(:password(conf<irc-pass>) if conf<irc-pass>),
    :debug,
    :plugins(
        Buggable::Info.new,
        Buggable::Plugin::TravisWatcher.new,
        Buggable::Plugin::RT.new(
            db-file    => conf<db-file>,
            report-dir => conf<rt-report-file-dir>,
        ),
    );
