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

my @tickets = $rt.search; #: :after(Date.today.earlier: :2days);
$db.add-ticket: :id(.id) :tags(.tags or ('UNTAGGED',)) :subject(.subject)
    for @tickets;

dd $db.all-tickets;
# dd $db.stats;
# dd $db.tagged('lta');
# select tickets.ticket_id, tickets.subject, GROUP_CONCAT(tags.name) from tickets JOIN tickets_tags ON tickets_tags.ticket_id = tickets.ticket_id JOIN tags on tickets_tags.tag_id = tags.tag_id GROUP BY tickets.ticket_id;
