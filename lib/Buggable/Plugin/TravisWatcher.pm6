use IRC::Client;
unit class Buggable::Plugin::TravisWatcher does IRC::Client::Plugin;
use Buggable::UA;

method irc-privmsg-channel (
    $e where /^ 'https://travis-ci.org/rakudo/rakudo/builds/' $<id>=\d+/
) {
    my $result = self!process: ~$<id> or return;
    $e.reply: $result;
}

method !process ($build-id) {
    say 'TravisWatcher: fetching travis build info';
    my $build = ua-get-json
        'https://api.travis-ci.org/repos/rakudo/rakudo/builds/' ~ $build-id;

    my @failed = $build<matrix>.grep({
        .<result> ~~ Any:U or .<result> != 0
    }).map: *.<id>;
    say "TravisWatcher: got {+@failed} builds [@failed.join(', ')]";
    return unless @failed;

    my @timeout;
    for @failed -> $id {
        say "Fetching job $id";
        my $job = ua-get-json 'https://api.travis-ci.org/jobs/' ~ $id;
        say "Fetched job $id";

        return "build log missing from at least one job."
            ~ " Check results manually." unless $job<log>;

        @timeout.push: $id
            if $job<log>.lc ~~ m/
                "no output has been received in the last 10m0s, this"
                " potentially indicates a stalled build or something wrong"
                " with the build itself.\n\nthe build has been terminated\n\n"
            \s* $/;
    }

    if @failed == 1 {
        return @timeout == @failed
            ?? "one build failed due to the timeout. No other failures."
            !! "one build failed but NOT due to the timeout.";
    }

    return "{+@failed} builds failed. "
        ~ (
            @timeout == @failed ?? "All"
                !! @timeout == 0 ?? "NONE" !! "ONLY {+@timeout}"
        ) ~ " due to the timeout";
}
