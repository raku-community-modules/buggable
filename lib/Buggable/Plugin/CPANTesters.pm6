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

    # I don't think you need to use the ExtraRoles module, removed it
    # without comments this is just two or three lines long

    # hash prettier displays as 'key: value'
    my role ZR { multi method get_elements (Hash:D $h) { $h.sort(*.key)>>.kv.map: -> ($k, $v) {$k, ': ', $v} } }

    # giving a tile is a good idea for looks
    my $ddt_res = get_dump :title<Result:>, $res,

                           # UnicodeGlyph is the default in the latest ddt version if you want to remove it
                           :!color, :does[ZR, DDTR::UnicodeGlyphs],

                           # remove the type and address; they only add noise in this case
                           :!display_info,

                           # I notice that output is further wrapped after generation by another
                           # tool, let ddt limit rendering length to avoid wrongly double wrapped text
                           # you may have to lower the value
                           :width(120) ;

    "\x[2]$res<distribution><name>\x[2]"
    ~ ":ver(\x[2]$res<distribution><version>\x[2])"
    ~ " test result \x[2]$res<result><grade>.uc()\x[2]. See more at "
    ~ temp-page :ext<.txt>, $ddt_res
}
