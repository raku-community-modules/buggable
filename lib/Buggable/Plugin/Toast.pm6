unit class Buggable::Plugin::Toast;
use WWW;

constant TOAST_API = 'https://toast.perl6.party/.json?stats_only';

multi method irc-to-me (
    $e where /:i ^ \s* 'toast' 'er'? '?'? \s* $ /
) {
    my $res = jget TOAST_API orelse return 'Error accessing Toaster API';
    return "Between \x[2]$res<commits>[*-1]\x[2] and $res<commits>[0]: "
        ~ " \x[2]$res<burnt_num>\x[2] ($res<burnt>%) modules got burnt."
        ~ " \x[2]$res<unsucced_num>\x[2] ($res<unsucced>%) got unsucced."
        ~ " Currently \x[2]$res<unusable_num>\x[2] ($res<unusable>%)"
        ~ " out of \x[2]$res<total_num>\x[2] modules appear unusable."
}
