unit class Buggable::Plugin::RT;
use HTML::Entity;
use Buggable::DB;

constant $ticket-url = 'https://rt.perl.org/Ticket/Display.html';
constant $report-url = %*ENV<REPORT_URL> // 'http://bug.perl6.party/';

has $!db;
has $!report-dir;

submethod BUILD (:$!report-dir, :$db-file) {
    $!db = Buggable::DB.new: :$db-file;
}

multi method irc-to-me ($e where /:i ^ 'rt' $ /) {
    my @tickets = $!db.all-tickets.sort({.<tags>});
    my $file = self!save-ticket-report: @tickets, :nick($e.nick);

    $!db.stats(@tickets).subst(/('TOTAL:' \s+ \d+)/, -> $/ { "\x[2]$/\x[2]" })
        ~ "   \x[1D]Details: $report-url$file.html\x[1D]";
}

multi method irc-to-me ($e where /:i ^'rt' \s+ $<tag>=(\S+.*)\s*$ /) {
    my $tag = $<tag>.uc.trim;
    my @tickets = $!db.tagged: $tag;
    my $file = self!save-ticket-report: @tickets, :nick($e.nick), :$tag;

    return "Found no tickets with tag \x[2]$tag\x[2]" unless @tickets;

    my $n = +@tickets;
    my $t-name = $n > 1 ?? 'tickets' !! 'ticket';
    return (
        $tag eq 'UNTAGGED'
            ?? "Found $n untagged $t-name"
            !! "Found $n $t-name tagged with \x[2]$tag\x[2]"
    ) ~ ". Details: $report-url$file.html";
}

method !save-ticket-report (@tickets, :$tag, :$nick = '<anon>') {
    my $css = Q:to/CSS/;
        body {
            max-width: 1200px;
            margin: 10px auto;
            font: .85em "Trebuchet MS", Arial, Helvetica, sans-serif;
            color: #444;
            opacity: .9;
        }

        table, tr, td {
            border-collapse: collapse;
            border: 1px solid #ccc;
        }

        h1 {
            font-size: 160%;
            text-align: center;
        }

        h1 small { font-weight: normal; }
        .tags { color: #999; }
        td { padding: 5px 10px; }
  		a { color: #44a; }
    CSS

    my $out = qq:to/HTML/;
        <style> $css </style>
        <body>
            <h1>
                {+@tickets} ticket{@tickets > 1 ?? 's' !! ''}
                <small>
                    ({$tag ?? "tagged [$tag]" !! "all tickets"},
                    requested by { encode-entities $nick } at
                    { DateTime.now.Str.split('.')[0].subst('T', ' ') })
                </small>
            </h1>
            <table><tbody>
    HTML

    $out ~= join "\n", @tickets.map: {
        qq:to/HTML/
        <tr>
            <td><a target="_blank"
                href="$ticket-url?id={.<id>}#ticket-history">
                    RT#{.<id>}
                </a></td>
            <td>
                {
                    $tag ?? '' !!
                        '<span class="tags">'
                        ~ encode-entities(.<tags>.map({"[$_]"}).join)
                        ~ '</span>'
                }
                { encode-entities .<subject>                 }
            </td>
        </tr>
        HTML
    };

    $out ~= q:to/HTML/;
        </tbody></table>
    HTML

    my $file = time;
    loop {
        my $f = ($!report-dir ~ '/' ~ $file ~ '.html').IO;
        if $f.e {
            $file ~= '_';
            redo;
        }
        $f.IO.spurt: $out;
        last;
    }

    return $file;
}
