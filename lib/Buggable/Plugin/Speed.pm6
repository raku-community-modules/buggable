unit class Buggable::Plugin::Speed;
use HTTP::UserAgent;

constant $log-url = 'http://tux.nl/Talks/CSV6/speed.log';

multi method irc-to-me (
    $e where /:i ^ [ 'speed' | 'perf' 'ormance'? ] [ \s* $<last>=\d+ ]?
                   [ \s* ':' $<rows>=\d+ ]? [ \s* '?' ]? \s* $ /
) {
    make-spark $e, +($<last> // 0) || 50, +($<rows> // 0) || 1
}

sub make-spark ($e, $items, $rows) {
    $rows  > 4   and return "Refusing to draw more than 4 rows";
    $items > 100 and return "Refusing to do more than 100 last entries";

    my $res = HTTP::UserAgent.new.get: $log-url;
    return 'Error accessing speed log: ' ~ $res.status-line
        unless $res.is-success;

    my @recent = $res.content.lines.tail: $items;
    my $date-range = @recent.map(*.words[0])[0,*-1].join: '–';
    @recent .= map(*.words[*-1]);
    @recent .= grep: * ne '999.999'; # filter out bogus results
    my %stats := simple-stats(@recent);
    my $close =    %stats<mean> - 2 * %stats<stddev>
                .. %stats<mean> + 2 * %stats<stddev>;
    my @close = @recent.grep($close);
    my ($min, $max) = @close.min, @close.max;
    my $range = max($max - $min, .1 * $min, .25);

    my @spark = draw-spark(:$rows, :$min, :$range, :data(@recent));
    my @info  = "dates: $date-range",
                "range: %stats<min>s–%stats<max>s",
                "speed: " ~ speed-diff @recent.head, @recent.tail;

    $e.reply($_) for do given $rows {
        when 1  { "@spark[0] @info.join('; ')" }
        when 2  { "@spark[0] @info[0]", "@spark[1] @info[1..2].join('; ')" }
        when 3  { "@spark[0] @info[0]", "@spark[1] @info[1]", "@spark[2] @info[2]" }
        default { "@spark[0] @info[0]", "@spark[1] @info[1]", "@spark[2] @info[2]",
                  @spark[3..*] }
    }

    Nil
}

sub simple-stats (@data) {
    my $min      =  @data.min;
    my $max      =  @data.max;
    my $mean     = +@data R/ [+] @data;
    my $variance = +@data R/ [+] @data.map: (* - $mean)²;
    my $stddev   = $variance.sqrt;

    %( :$min, :$max, :$mean, :$variance, :$stddev )
}

sub draw-spark (:$rows, :$min, :$range, :@data) {
    my @bar       = (^8 + 0x2581)>>.chr;
    my $max       = $min + $range;
    my $row-range = $range / $rows;

    (^$rows).reverse.map: -> $row {
        my $lo = $min + $row-range *  $row;
        my $hi = $min + $row-range * ($row + 1);
        @data.map({
            $_ < $min && $lo == $min ?? '↓'       !!
            $_ > $max && $hi == $max ?? '↑'       !!
            $_ < $lo                 ?? ' '       !!
            $_ > $hi                 ?? @bar[*-1] !!
            @bar[(($_ - $lo) / $row-range * (@bar - 1)).round]
        }).join
    }
}

sub speed-diff ($before, $after) {
    my ($diff, $how);
    if ($before/$after).round(.01) == 1 {
        return "~0% difference"
    }
    elsif $before > $after {
        $diff = $before/$after;
        $how = 'faster';
    }
    else {
        $diff = $after/$before;
        $how = 'slower';
    }
    $diff >= 2 ?? "{($diff).round: .01   }x $how"
               !! "{(($diff-1)*100).round}% $how"
}
