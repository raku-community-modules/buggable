unit class Buggable::Plugin::Eco;
use HTTP::UserAgent;
use URI::Escape;
use JSON::Tiny;

has $.log-url    = 'https://modules.perl6.org/update.log';
has $.search-url = 'https://modules.perl6.org/s/';
has $.search-url-human = 'https://modules.perl6.org/#q=';

multi method irc-to-me (
    $e where /:i ^ [ 'eco' 'system'? | 'module' 's'? ] '?'? \s* $ /
) {
    my $res = HTTP::UserAgent.new.get: $!log-url;
    return 'Error accessing Ecosystem build log: ' ~ $res.status-line
        unless $res.is-success;

    say "Fetched build log";
    my @dists = (split /'---'/, (split /"---\n---"/, $res.content, 2)[0])[1..*];
    say "Finished splitting log into dists";
    my ($dists-error, $dists-warning, $dists-no-tags) = (0, 0, 0);
    say @dists[0];
    for @dists {
        $dists-error++   if .contains: '[error]';
        my ($seen-warning, $seen-missing-tag) = False, False;
        for .lines {
            next unless .contains: '[warn]';
            .contains('does not have any tags')
                ?? $seen-missing-tag++
                !! $seen-warning++;
        }
        $dists-warning++ if $seen-warning;
        $dists-no-tags++ if $seen-missing-tag;
    }

    return "Out of {+@dists} Ecosystem dists, $dists-warning have warnings,"
        ~ " $dists-error have errors, and $dists-no-tags have no tags in META"
        ~ " file. See $!log-url for details";
}

multi method irc-to-me ( $e where
    /:i ^ [ 'eco' 'system'? | 'module' 's'? ] '?'? \s+ $<term>=.+ \s* $/
) {
    my $res = HTTP::UserAgent.new.get:
        $.search-url ~ uri-escape(~$<term>) ~ '/.json';

    return 'Error accessing modules.perl6.org: ' ~ $res.status-line
        unless $res.is-success;

    my @dists = |(try { from-json $res.content } //
        return "Failed to decode result JSON: $!")<dists>;

    if @dists == 1 {
        my $dist = @dists[0];
        return "\x[2]$dist<name>\x[2] '$dist<description>': $dist<url>";
    }
    elsif @dists {
        my $total = +@dists;
        @dists = @dists[lazy ^5];
        return "Found \x[2]$total\x[2] results: "
            ~ @dists.map({"\x[2]{.<name>}\x[2]"}).join(', ')
            ~ (", and others" if @dists > 5)
            ~ ". See " ~ $.search-url-human ~ uri-escape(~$<term>);
    }
    else {
        return "Nothing found";
    }
}
