unit class Buggable::UA;

use JSON::Tiny;
use HTTP::UserAgent;

sub ua-get-json ($url) is export {
    my $res = HTTP::UserAgent.new.get: $url;
    fail $res.status-line unless $res.is-success;
    from-json $res.content;
}
