unit class Buggable::TempPage;

constant TEMP-DIR      = '/home/zoffix/temp/buggable/'.IO;
constant TEMP-DIR-URL  = 'https://temp.perl6.party/buggable/';

sub temp-page (Str:D $content, Str:D :$ext = '.html') is export {
    my $file = substr rand ~ time ~ $ext, 2;
    TEMP-DIR.add($file).spurt: $content;
    TEMP-DIR-URL ~ $file;
}
