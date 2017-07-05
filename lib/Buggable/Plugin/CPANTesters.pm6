unit class Buggable::Plugin::CPANTesters;
use Data::Dump::Tree;
use URI::Escape;
use WWW;
use Buggable::TempPage;

constant API = 'http://api.cpantesters.org/v3';

multi method irc-to-me (
    $e where /:i ^ 'cpan'? \s* 'test' 'ers'? \s+ $<report-id>=\S+ \s* $ /
) {
    my $url = API ~ '/report/' ~ uri-escape ~$<report-id>;
    my $res = jget $url orelse return "Cound not find that ID or API is down."
        ~ " Try manually: $url";

    "\x[2]$res<distribution><name>\x[2]"
    ~ ":ver(\x[2]$res<distribution><version>\x[2])"
    ~ " test result \x[2]$res<result><grade>.uc()\x[2]. See more at "
    ~ temp-page Data::Dump::Tree.new(:!color).dump: $res;
}
