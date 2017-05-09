use IRC::Client;
unit class Buggable::Plugin::Win does IRC::Client::Plugin;
use Number::Denominate;
use IRC::TextColor;

has IO::Path $.db where .rw;
has DateTime $.when;

my @channels = <#perl6 #perl6-dev #zofbot #moarvm>;

sub B { ircstyle :bold, ~$^text }
sub prize { B ('roll of duck tape', 'can of WD40').pick }

method irc-started { self!do-draw: :init-only }

multi method irc-privmsg-channel (
    $e where / ^ \s* [:i '/w' \s* | 'w/in' \s* | '/win' \s* | 'win' \s+ ] $<number>=\d+ $ /
) {
    $.db.spurt: :append, "$e.nick()\n$<number>\n";
    "Thank you for entering &B("Accidental /win Lottery")! "
        ~ "The next draw will happen in {self!draw-when: :human}"
}

multi method irc-to-me (
    $ where .host eq 'perl6.party' && /^\s* fake \s* draw \s* $/
) {
    self!do-draw: :no-promise;
    Nil
}

multi method irc-to-me ( $ where /:i ^\s* 'draw' 'status'? '?'? \s* $/ ) {
    my ($, $b, $u) = self!ballots;
    "The next &B("Accidental /win Lottery") draw will happen "
      ~ "in {self!draw-when: :human}. Currently have "
      ~ "&B($b) ballots submitted by &B($u) users!"
}

method !do-draw (:$init-only, :$no-promise) {
    unless $init-only {
        my (%ballots, $b, $u) := self!ballots;
        my $text = "🎺🎺🎺 It's time for the monthly "
          ~ "&B('Accidental /win Lottery') 😍😍😍 We have "
          ~ "&B($b) ballots submitted by &B($u) users! DRUM ROLL PLEASE!...";
        $.irc.send: :where($_), :$text for @channels;
        sleep 3;

        my $winning-number = %ballots.keys ?? %ballots.keys.pick !! 42;
        my $winner = %ballots{$winning-number}.join(', ') || 'Zoffix';
        $text = "And the winning number is &B($winning-number)! Congratulations"
          ~ " to &B($winner)! You win a &prize()!";
        $.irc.send: :where($_), :$text for @channels;
    }

    unless $no-promise {
        # Reset the lottery
        $.db.spurt: '' unless $init-only;
        $!when = DateTime.now.later(:month).clone:
            :0hour, :0minute, :0second, :0timezone;
        Promise.in(self!draw-when).then: { self!do-draw };
        say "The next Win lottery draw will happen in {self!draw-when: :human}"
    }
}

method !ballots {
    my %ballots.push: $.db.lines.pairup».antipair;
    # ballots; number of ballots; number of users;
    ($_, .map(*.value.elems).sum, +.values».List.flat.unique) with %ballots
}

method !draw-when (:$human) {
    $human ?? denominate .Int !! $_ with $!when - DateTime.now
}
