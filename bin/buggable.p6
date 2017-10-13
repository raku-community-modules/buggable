#!/usr/bin/env perl6
use lib <lib>;

use IRC::Client;
use Buggable::Config;
use Buggable::Plugin::TravisWatcher;
use Buggable::Plugin::RT;
use Buggable::Plugin::Eco;
use Buggable::Plugin::Speed;
use Buggable::Plugin::Win;
use Buggable::Plugin::Toast;
use Buggable::Plugin::CPANUploads;
use Buggable::Plugin::Zen;
#use Buggable::Plugin::CPANTesters;
use Number::Denominate;

class Buggable::Info {
    multi method irc-to-me ($ where /^\s* help \s*$/) {
        "\x[2]tags\x[2] | \x[2]tag SOMETAG\x[2] | \x[2]eco\x[2] | "
            ~ "\x[2]eco\x[2] Some search term | \x[2]author\x[2] "
            ~ "github username | \x[2]speed\x[2] | \x[2]testers\x[2] "
            ~ "CPANTesters report ID";
    }
    multi method irc-to-me ($ where /^\s* source \s*$/) {
        "See: https://github.com/zoffixznet/perl6-buggable";
    }
    multi method irc-to-me ($ where /:i ^ \s* christmas \s* $/) {
        "Christmas is in " ~ denominate Date.new("2017-12-25").DateTime - DateTime.now
    }

    multi method irc-to-me ($ where /'bot' \s* 'snack'/) { "om nom nom nom"; }
}

my @channels = %*ENV<BUGGABLE_DEBUG>
    ?? '#zofbot' !! <#perl6  #perl6-dev  #zofbot  #moarvm>;

.run with IRC::Client.new:
    :nick<buggable>,
    :username<zofbot-buggable>,
    :host(%*ENV<BUGGABLE_IRC_HOST> // 'irc.freenode.net'),
    :@channels,
#    |(:password(conf<irc-pass>)
 #       if conf<irc-pass> and not %*ENV<BUGGABLE_DEBUG>
  #  ),
    :debug,
    :plugins(
        Buggable::Info.new,
        Buggable::Plugin::TravisWatcher.new,
        Buggable::Plugin::RT.new,
        Buggable::Plugin::Eco.new,
        Buggable::Plugin::Toast.new,
        Buggable::Plugin::Speed.new,
        Buggable::Plugin::Zen.new,
        Buggable::Plugin::CPANUploads.new(:channels[
            %*ENV<BUGGABLE_DEBUG> ?? '#zofbot' !! <#perl6  #perl6-dev>;
        ]),
        Buggable::Plugin::Win.new(db => (
          (conf<win-db-file> || die 'Win lottery database file is missing').IO
        )),
 #       Buggable::Plugin::CPANTesters.new,
        class {
            multi method irc-to-me (
                $e where /:i ^ 6 \.? d '?'? \s* $ /
            ) {
                "¯\\_(ツ)_/¯"
                #"I think 6.d Diwali will be released in about "
                #~ denominate Date.new('2017-10-19').DateTime - DateTime.now
            }
        },
        class :: does IRC::Client::Plugin {
            multi method irc-to-me ($e where /:i ^ \s* pizza [\s+ $<who> = \S+]?/) {
                my $who = $<who> ?? ~$<who> !! $e.nick;
                $who = $e.nick if $who.lc eq 'me';
                my @pizza = 'Double Cheese', 'Gourmet', 'Mexican Green Wave', 'Peppy Paneer',
                    'Margherita', 'Meatzaa', 'Cheese and Barbeque Chicken',
                    'Chicken Mexican Red Wave', 'Cheese and Pepperoni',
                    'Golden Chicken Delight', 'Four Cheese', 'Deluxe', 'Pepperoni and Mushrooms',
                    'Hawaiian', 'Vegan';
                $.irc.send: :where($e.?channel // $e.nick),
                    :text("$who, enjoy this slice of @pizza.pick() pizza, my friend! Yummy 🍕")
            }
        }.new
    );
