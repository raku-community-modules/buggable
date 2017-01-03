unit class Buggable::Plugin::Speed;
use HTTP::UserAgent;

has $.log-url = 'http://tux.nl/Talks/CSV6/speed.log';

multi method irc-to-me (
    $e where /:i ^ [ 'speed' | 'performance' ] '?'? $ /
) {
    my $res = HTTP::UserAgent.new.get: $!log-url;
    return 'Error accessing speed log: ' ~ $res.status-line
        unless $res.is-success;

    say "Fetched speed log";
    my @recent = $res.content.lines[(*-50)..Inf];
    my $date-range = @recent.map(*.words[0])[0,*-1].join: '–';
    @recent .= map(*.words[*-1]);
    my ($min, $max) = @recent.min, @recent.max;
    my $range = max($max - $min, .1 * $min, .25);
    my @bar = (^8 + 0x2581)>>.chr;
    my $spark = @recent.map({
        @bar[(($_ - $min) / $range * (@bar - 1)).round]
    }).join;
    return $spark ~ " data for $date-range; range: {$min}s–{$min + $range}s";
}
