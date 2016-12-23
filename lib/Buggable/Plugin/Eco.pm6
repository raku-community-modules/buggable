unit class Buggable::Plugin::Eco;
use HTTP::UserAgent;
use URI::Escape;
use JSON::Fast;

has $.log-url    = 'https://modules.perl6.org/update.log';
has $.search-url = 'https://modules.perl6.org/s/';
has $.search-url-human = 'http://modules.perl6.org/#q=';

multi method irc-to-me (
    $e where /:i ^ [ 'eco' 'system'? | 'module' 's'? ] '?'? \s* $ /
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

multi method irc-to-me ( $e where
    /:i ^ [ 'eco' 'system'? | 'module' 's'? ] '?'? \s+ $<term>=.+ \s* $/
) {
    my $res = HTTP::UserAgent.new.get:
        $.search-url ~ uri-escape(~$<term>) ~ '.json';

    return 'Error accessing modules.perl6.org: ' ~ $res.status-line
        unless $res.is-success;

    my @dists = |(try { from-json $res.content } //
        return "Failed to decode result JSON: $!")<dists>;

    if @dists == 1 {
        my $dist = @dists[0];
        return "\x[2]$dist<name>\x[2] '$dist<description>': $dist<url>";
    }
    elsif @dists {
        @dists = @dists[lazy ^5];
        return "Found \x[2]{+@dists}\x[2] results: "
            ~ @dists.map({"\x[2]{.<name>}\x[2]"}).join(', ')
            ~ (", and others" if @dists > 5)
            ~ ". See " ~ $.search-url-human ~ uri-escape(~$<term>);
    }
    else {
        return "Nothing found";
    }
}
