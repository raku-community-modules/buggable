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

.run with IRC::Client.new:
    :nick<buggable>,
    :host(%*ENV<BUGGABLE_IRC_HOST> // 'irc.freenode.net'),
    :channels<#perl6-dev  #zofbot>,
    |(:password(conf<irc-pass>) if conf<irc-pass>),
    :debug,
    :plugins(
        Buggable::Plugin::TravisWatcher.new,
        Buggable::Plugin::RT.new(
            db-file    => conf<db-file>,
            report-dir => conf<rt-report-file-dir>,
        ),
    );
