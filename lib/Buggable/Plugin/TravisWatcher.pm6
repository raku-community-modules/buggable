use IRC::Client;
unit class Buggable::Plugin::TravisWatcher does IRC::Client::Plugin;
use Buggable::UA;

method irc-privmsg-channel (
    $e where /^ 'https://travis-ci.org/rakudo/rakudo/builds/' $<id>=\d+/
) {
    my $result = self!process: ~$<id> or return;
    $.irc.send: :where($e.channel), :text($result);
}

method !process ($build-id) {
    say 'TravisWatcher: fetching travis build info';
    my $build = ua-get-json
        'https://api.travis-ci.org/repos/rakudo/rakudo/builds/' ~ $build-id;

    my @failed = $build<matrix>.grep({
        (.<result> ~~ Any:U or .<result> != 0) and not .<allow_failure>
    }).map: *.<id>;
    say "TravisWatcher: got {+@failed} builds [@failed.join(', ')]";
    return unless @failed;

    my $state = class {
        has int $.total         = +@failed;
        has int $.timeout  is rw = 0;
        has int $.no-log   is rw = 0;
        has int $.github   is rw = 0;
        has int $.jvm-only is rw = 0;
        has int $.test-fail is rw = 0;
        has @.failures;
        method Str {
            ( $!timeout + $!no-log + $!github != $!total
                ?? "☠ Did not recognize some failures. Check results manually."
                !! "✓ All failures are due to timeout ($!timeout), missing"
                    ~ " build log ($!no-log), or GitHub connectivity "
                    ~ "($!github)."
            ) ~ ( " All failures are on JVM only." if $!jvm-only )
            ~   ( if $!test-fail {
                    $!test-fail == 1 ?? " Failed @!failures[0]"
                                     !!" Failed {self.test-fail} test(s)"
              } )

        }
    }.new;

    my int $num-jvm-fails = 0;
    for @failed -> $id {
        say "Processing Job ID $id";
        my $job = ua-get-json 'https://api.travis-ci.org/jobs/' ~ $id;
        say "Done!";
        $num-jvm-fails++ if $job<config><env>.?contains: '--backends=jvm';
        unless $job<log> {
            $state.no-log++;
            next;
        }

        $state.timeout++ if $job<log>.lc ~~ m/
            "no output has been received in the last 10m0s, this"
            " potentially indicates a stalled build or something wrong"
            " with the build itself."
            <ws>
            [
                "check the details on how to adjust your build"
                " configuration on: https://docs.travis-ci.com/user"
                "/common-build-problems/#build-times-out-because-no-"
                "output-was-received\n\n"
                <ws>
            ]?
            "the build has been terminated\n\n"
            \s*
        $/;

        $state.github++ if $job<log>.lc ~~ m/
            [
                  "git error: fatal: unable to access"
                | "git error: error: rpc failed"
                | 'the command "git fetch origin +refs/pull/' \d+ '/merge:" failed and exited with 128 during .'
            ]
        /;
        if $job<log> ~~ m/ ^ "t/"( \d+ \S+ ".t") \s* '.'+ \s* "Failed" / {
            $state.test-fail++;
            $state.failures.push(~$0);            
        }
    }
    $state.jvm-only = 1 if $num-jvm-fails == @failed;

    return "[travis build above] $state";
}
