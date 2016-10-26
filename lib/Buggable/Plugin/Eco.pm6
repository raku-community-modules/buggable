unit class Buggable::Plugin::Eco;
use HTTP::UserAgent;

has $.log-url = 'https://modules.perl6.org/update.log';

multi method irc-to-me (
    $e where /:i ^ [ 'eco' 'system'? | 'module' 's'? ] '?'? $ /
) {
    my $res = HTTP::UserAgent.new.get: $!log-url;
    return 'Error accessing Ecosystem build log: ' ~ $res.status-line
        unless $res.is-success;

    say "Fetched build log";
    my @dists = (split /'---'/, (split /"---\n---"/, $res.content, 2)[0])[1..*];
    say "Finished splitting log into dists";
    my ($dists-error, $dists-warning) = (0, 0);
    say @dists[0];
    for @dists -> $dist {
        $dists-warning++ if $dist.contains: '[warn]';
        $dists-error++   if $dist.contains: '[error]';
    }

    return "Out of {+@dists} Ecosystem dists, $dists-warning have warnings "
        ~ "and $dists-error have errors. See $!log-url for details";
}
