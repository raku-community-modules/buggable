use IRC::Client;
unit class Buggable::Plugin::CPANUploads does IRC::Client::Plugin;

use IRC::TextColor;
use lib:from<Perl5> <lib5>;
use Buggable::CPANUploads:from<Perl5>;

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
                    } by $upload<author  url>";
                    $.irc.send: :where($_), :$text for @!channels
                }
            }
            CATCH { default { say "Error: $_" } }
        }
    }
}
