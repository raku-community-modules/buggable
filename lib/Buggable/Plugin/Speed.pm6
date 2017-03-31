unit class Buggable::Plugin::Speed;
use HTTP::UserAgent;

constant $log-url = 'http://tux.nl/Talks/CSV6/speed.log';

multi method irc-to-me (
    $ where /:i ^ [ 'speed' | 'perf' 'ormance'? ] '?'? $ /
) {
    make-spark
}

multi method irc-to-me (
    $ where /:i ^ [ 'speed' | 'perf' 'ormance'? ] \s* $<last>=\d+ \s*$ /
) {
    make-spark +$<last>
}

sub make-spark ($items = 50) {
    $items > 100 and return "Refusing to do more than 100 last entries";

    my $res = HTTP::UserAgent.new.get: $log-url;
    return 'Error accessing speed log: ' ~ $res.status-line
        unless $res.is-success;

    my @recent = $res.content.lines.tail: $items;
    my $date-range = @recent.map(*.words[0])[0,*-1].join: '–';
    @recent .= map(*.words[*-1]);
    @recent .= grep: * ne '999.999'; # filter out bogus results
    my ($min, $max) = @recent.min, @recent.max;
    my $range = max($max - $min, .1 * $min, .25);
    my @bar = (^8 + 0x2581)>>.chr;
    my $spark = @recent.map({
        @bar[(($_ - $min) / $range * (@bar - 1)).round]
    }).join;

    $spark ~ " data for $date-range; range: {$min}s–{$max}s"
        ~ speed-diff @recent.head, @recent.tail
}

sub speed-diff ($before, $after) {
    my ($diff, $how);
    if ($before/$after).round(.01) == 1 {
        return "; ~0% difference"
    }
    elsif $before > $after {
        $diff = $before/$after;
        $how = 'faster';
    }
    else {
        $diff = $after/$before;
        $how = 'slower';
    }
    $diff >= 2 ?? "; {($diff).round: .01   }x $how"
               !! "; {(($diff-1)*100).round}% $how"
}
