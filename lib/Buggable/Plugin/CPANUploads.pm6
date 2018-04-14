use IRC::Client;
unit class Buggable::Plugin::CPANUploads does IRC::Client::Plugin;

use WWW;
use URI::Escape;
use IRC::TextColor;
use lib:from<Perl5> <lib5>;
use Buggable::CPANUploads:from<Perl5>;
constant MODULES-SITE-URL  = 'https://modules.perl6.org/s/';

constant $INTERVAL = %*ENV<BUGGABLE_DEBUG> ?? 20 !! 10*60;
has $.notifier = Buggable::CPANUploads.new;
has @.channels is required;

method irc-started {
    Promise.in(10).then: {
        react whenever Supply.interval($INTERVAL) {
            my @modules = $!notifier.poll<>;
            if @modules > 10 {
                $.irc.send: :where($_), :text(
                    "New CPAN upload: {
                        ircstyle :bold, ~+@modules
                    } modules were uploaded. Can someone teach me to pastebin?";
                ) for @!channels
            }
            else {
                for @modules -> $upload {
                    my $text = "New CPAN upload: {
                        ircstyle :bold, $upload<module>
                    } by $upload<author> &try-mp6o-url($upload)";
                    $.irc.send: :where($_), :$text for @!channels
                }
            }
            CATCH { default { say "Error: $_" } }
        }
    }
}

sub try-mp6o-url ($dist) {
    my $name = $dist<module>.subst(/'-' <-[-]>+ $/, '').subst: :g, '-', '::';
    my $url := [~] MODULES-SITE-URL,
        uri-escape("$name from:cpan author:$dist<author>"), '/.json';
    (.<dists>[0]<mpo6_dist_url> with jget $url) // $dist<url>
}
