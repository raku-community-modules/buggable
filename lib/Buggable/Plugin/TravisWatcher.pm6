unit class Buggable::Plugin::TravisWatcher;
use Buggable::UA;

method irc-privmsg-channel (
    $ where /^ 'https://travis-ci.org/rakudo/rakudo/builds/' $<id>=\d+/
) {
    say 'TravisWatcher: fetching travis build info';
    my $build = ua-get-json
        'https://api.travis-ci.org/repos/rakudo/rakudo/builds/' ~ $<id>;

    my @failed = $build<matrix>.grep({ .<result> ~~ Any:U }).map: *.<id>;
    say "TravisWatcher: got {+@failed} builds [@failed.join(', ')]";
    return unless @failed;

    my @timeout;
    for @failed -> $id {
        my $job = ua-get-json 'https://api.travis-ci.org/jobs/' ~ $id;

        @timeout.push: $id
            if $job<log> ~~ /
                "No output has been received in the last 10m0s, this"
                " potentially indicates a stalled build or something wrong"
                " with the build itself.\n\nThe build has been terminated\n\n"
            $/;
    }

    if @failed == 1 {
        return @timeout == @failed
            ?? "One build failed due to timeout."
            !! "One build failed but NOT due to timeout.";
    }

    return "{+@failed} build failed. "
        ~ (@timeout == @failed ?? "All" !! "ONLY {+@timeout}" )
        ~ " due to timeout";
}
