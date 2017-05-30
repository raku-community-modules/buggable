unit class Buggable::Plugin::Speed;
use WWW;

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

    my $res = get $log-url orelse return 'Error accessing speed log';
    my @recent = $res.lines.tail: $items;
    my $date-range = @recent.map(*.words[0])[0,*-1].join: '–';
    @recent .= map(*.words[*-1]);
    @recent .= grep: * ne '999.999'; # filter out bogus results
    my %stats := simple-stats(@recent);
    my $close =    %stats<mean> - 2 * %stats<stddev>
                .. %stats<mean> + 2 * %stats<stddev>;
    my @close = @recent.grep($close);
    my ($min, $max) = @close.min, @close.max;
    my $range = max($max - $min, .1 * $min, .25);
    my @bar = (^8 + 0x2581)>>.chr;
    my $spark = @recent.map({
        $_ < $min          ?? '↓' !!
        $_ > $min + $range ?? '↑' !!
                              @bar[(($_ - $min) / $range * (@bar - 1)).round];
    }).join;

    $spark ~ " data for $date-range; range: %stats<min>s–%stats<max>s"
        ~ speed-diff @recent.head, @recent.tail
}

sub simple-stats (@data) {
    my $min      =  @data.min;
    my $max      =  @data.max;
    my $mean     = +@data R/ [+] @data;
    my $variance = +@data R/ [+] @data.map: (* - $mean)²;
    my $stddev   = $variance.sqrt;

    %( :$min, :$max, :$mean, :$variance, :$stddev )
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
