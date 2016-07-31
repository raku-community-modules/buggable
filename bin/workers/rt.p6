#!/usr/bin/env perl6
use lib <
    /home/zoffix/CPANPRC/RT-REST-Client/lib
    /home/zoffix/services/lib/RT-REST-Client/lib
    lib
>;

use RT::REST::Client;
use Buggable::Config;
use Buggable::DB;

my RT::REST::Client $rt .= new: :user(conf<rt-user>) :pass(conf<rt-pass>);
my $db = Buggable::DB.new(db-file => conf<db-file>);

# my @tickets = $rt.search:
    # :after(Date.new('2013-02-20'))
    # :before(Date.new('2013-02-22'));

# dd @tickets;

my @tickets = $rt.search;
$db.add-ticket: :id(.id) :tags(.tags or ('UNTAGGED',)) :subject(.subject)
    for @tickets;

say "Loaded {+@tickets} at {DateTime.now}";
