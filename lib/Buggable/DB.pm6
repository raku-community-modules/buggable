unit class Buggable::DB;
use DBIish;
has $.db-file;
has $!dbh;

submethod BUILD (:$!db-file) {
    my $existing-db = $!db-file.IO.e;
    $!dbh = DBIish.connect: 'SQLite', :database($!db-file);
    $!dbh.do: 'PRAGMA foreign_keys=ON';
    return if $existing-db;

    $!dbh.do: q:to/END/;
        CREATE TABLE tickets (
            ticket_id INTEGER PRIMARY KEY,
            subject   TEXT NOT NULL
        )
    END

    $!dbh.do: q:to/END/;
        CREATE TABLE tags (
            tag_id INTEGER PRIMARY KEY,
            name   TEXT NOT NULL,
            UNIQUE(name)
        )
    END

    $!dbh.do: q:to/END/;
        CREATE TABLE tickets_tags (
            ticket_tag_id INTEGER PRIMARY KEY,
            ticket_id     INTEGER NOT NULL,
            tag_id        INTEGER NOT NULL,

            UNIQUE(ticket_tag_id, ticket_id),
            FOREIGN KEY(ticket_id)
                REFERENCES tickets(ticket_id)
                ON UPDATE CASCADE
                ON DELETE CASCADE,
            FOREIGN KEY(tag_id)
                REFERENCES tags(tag_id)
                ON UPDATE CASCADE
                ON DELETE CASCADE
        )
    END
}

method add-ticket (:$id, :$subject, :$tags) {
    $!dbh.do: 'DELETE FROM tickets WHERE ticket_id = ?', $id;
    $!dbh.do: 'INSERT INTO tickets (ticket_id, subject) VALUES(?, ?)',
        $id, $subject;
    $!dbh.do: 'INSERT OR IGNORE INTO tags (name) VALUES(?)', $_  for @$tags;
    $!dbh.do(
        'INSERT INTO tickets_tags (ticket_id, tag_id)
            VALUES (?, (SELECT tag_id from tags WHERE name = ?))',
        $id, $_
    ) for @$tags;
}

method all-tickets {
    my $sth = $!dbh.prepare: q:to/END/;
        SELECT
            tickets.ticket_id,
            tickets.subject,
            GROUP_CONCAT(tags.name)
        FROM tickets
        JOIN tickets_tags
            ON tickets_tags.ticket_id = tickets.ticket_id
        JOIN tags
            ON tickets_tags.tag_id = tags.tag_id
        GROUP BY tickets.ticket_id
    END
    $sth.execute;
    return $sth.allrows.map: {%(
        id      => $_[0],
        subject => $_[1],
        tags    => $_[2].split(','),
    )};
}

method stats {
    my @tickets    = self.all-tickets;
    my $tag-counts = bag @tickets.map: { |.<tags> };
    return join ', ',
        reverse $tag-counts.sort(*.value).map: {"[{.key}]: {.value}"};
}

method tagged ($tags is copy = ('UNTAGGED',)) {
    $tags = $tags.flat».uc;
    self.all-tickets.grep: { .<tags> ⊆ @$tags };
}

=finish

Tickets
    id
    subject
    content

Tags
    name

One ticket can have many tags and many tickets can have the same tag [many to many]

-----
