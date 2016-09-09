unit class Buggable::Plugin::RT;
use Buggable::UA;
use URI::Escape;

has $.r6-url = %*ENV<BUGGABLE_R6_HOST> || 'http://perl6.fail/';

multi method irc-to-me ($e where /:i ^ [tag|rt|bug] s? '?'? $ /) {
    my $res = try { ua-get-json "$!r6-url.json"
    } or return 'Error accessing R6 API';

    return join '; ',
        "\x[2]Total: $res<total>\x[2]",
        $res<tags>.map({"\x[2]$_<tag>:\x[2] $_<count>"}),
        "See $res<url> for details";
}

multi method irc-to-me ($e where /:i ^ [tag|rt|bug] s? '?'? \s+ $<tag>=(\S.*)/) {
    my $res = try {ua-get-json $!r6-url ~ 't/' ~ uri-escape(~$<tag>) ~ '.json'
    } or return 'Error accessing R6 API';

    return "There are \x[2]no tickets\x[2] tagged with \x[2]$res<tag>\x[2]"
        unless $res<total>;

    return 'There ' ~ (
        $res<total> == 1
            ?? "is \x[2]1 ticket\x[2]" !! "are \x[2]$res<total> tickets\x[2]"
    ) ~ " tagged with \x[2]$res<tag>\x[2]; See $res<url> for details";
}
