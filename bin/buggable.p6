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
        "\x[1]rt\x[1] | \x[1]rt TAG\x[1]";
    }
    multi method irc-to-me ($ where /^\s* source \s*$/) {
        "See: https://github.com/zoffixznet/perl6-buggable";
    }
}

.run with IRC::Client.new:
    :nick<buggable>,
    :host(%*ENV<BUGGABLE_IRC_HOST> // 'irc.freenode.net'),
    :channels<#perl6-dev  #zofbot>,
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
