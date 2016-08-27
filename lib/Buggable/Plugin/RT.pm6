unit class Buggable::Plugin::RT;
use Buggable::UA;
use URI::Escape;

has $.r6-url = %*ENV<BUGGABLE_R6_HOST> || 'https://perl6.fail/';

multi method irc-to-me ($e where /:i ^ 'tag' s? $ /) {
    my $res = ua-get-json "$!r6-url.json" or return 'Error accessing R6 API';
    return join '; ',
        "\x[2]Total: $res<total>\x[2]",
        $res<tags>.map({"\x[2]$_<tag>:\x[2] $_<count>"}),
        "See $res<url> for details";
}

multi method irc-to-me ($e where /:i ^ 'tag' s? \s+ $<tag>=(\S.*)/) {
    my $res = ua-get-json $!r6-url ~ 't/' ~ uri-escape(~$<tag>) ~ '.json'
        or return 'Error accessing R6 API';

    return "There are no tickets tagged with $res<tag>" unless $res<total>;
    return 'There '
        ~ ($res<total> == 1  ?? 'is 1 ticket' !! "are $res<total> tickets")
        ~ " tagged with $res<tag>; See $res<url> for details";
}
