unit class Buggable::Plugin::Eco;
use WWW;
use URI::Escape;
use Buggable::TempPage;

constant META-LIST
= 'https://raw.githubusercontent.com/perl6/ecosystem/master/META.list';
constant MODULES-SITE  = 'https://modules.perl6.org';
has $.log-url          = MODULES-SITE ~ '/update.log';
has $.search-url       = MODULES-SITE ~ '/s/';
has $.search-url-human = MODULES-SITE ~ '/#q=';

multi method irc-to-me (
    $e where /:i ^ [ 'eco' 'system'? | 'module' 's'? ] '?'? \s* $ /
) {
    my $res = get $!log-url orelse return 'Error accessing Ecosystem build log';
    say "Fetched build log";
    my @dists = (split /'---'/, (split /"---\n---"/, $res, 2)[0])[1..*];
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
    my $term = ~$<term>;
    my @dists = |(
        jget $.search-url ~ uri-escape($term) ~ '/.json'
            orelse return "Failed to decode result JSON: $!"
    )<dists>;

    if @dists == 1 {
        my $dist = @dists[0];
        return "\x[2]$dist<name>\x[2] '$dist<description>': $dist<url>";
    }
    elsif @dists.grep({.<name> eq $term}) -> $exact {
        return "\x[2]$exact[0]<name>\x[2] '$exact[0]<description>'"
            ~ ": $exact[0]<url> \x[2]{+@dists}\x[2] other matching results: "
            ~ $.search-url-human ~ uri-escape(~$<term>);
    }
    elsif @dists {
        my $total = +@dists;
        @dists = @dists[lazy ^5];
        return "Found \x[2]$total\x[2] results: "
            ~ @dists.map({"\x[2]{.<name>}\x[2]"}).join(', ')
            ~ (", and others" if @dists > 5)
            ~ ". See " ~ $.search-url-human ~ uri-escape($term);
    }
    else {
        return "Nothing found";
    }
}

multi method irc-to-me ( $e where
    /:i ^ [ 'author' 's'? ] '?'? \s+ $<name>=.+ \s* $/
) {
    my $author = ~$<name>;
    my $res = get META-LIST orelse return 'Error accessing ' ~ META-LIST;
    my @metas = $res.lines.map({
        m{ # GitHub URL
          'https://raw.githubusercontent.com/'
          $<author>=<-[/]>+ '/' $<repo>=<-[/]>+ '/' $<branch>=<-[/]>+
        } and $/.hash».Str.push: 'github' => True
        or m{ # GitLab URL
          'https://gitlab.com/'
          $<author>=<-[/]>+ '/' $<repo>=<-[/]>+ '/'
        } and $/.hash».Str.push: 'gitlab' => True
        or next
    }).grep: *.<author> eq $author
    or return "Did not find any dists for $author";

    "Found {+@metas} dists for $author. See " ~ temp-page
        "<style>body \{ width: 500px; margin: 20px auto; };
            a \{ line-height: 1.9em } </style>
        " ~ @metas.map({
            my $url = .<github>
              ?? "https://github.com/{.<author>}/{.<repo>}/tree/{.<branch>}"
              !! .<gitlab>
                ?? "https://gitlab.com/{.<author>}/{.<repo>}/"
                !! 'UNKNOWN';
            qq|<a href="$url">{.<repo>}</a>|
        }).join("\n<br>");
}
