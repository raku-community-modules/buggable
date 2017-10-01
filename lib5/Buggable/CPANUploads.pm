package Buggable::CPANUploads;

use 5.026;
use strict;
use warnings;

use constant CPAN_URL => 'https://www.cpan.org/authors/id/';
use constant STORE    => 'cpan-last-reported';

use Net::NNTP;
use Mew;
use Mojo::File qw/path/;

has _url   => Maybe[Str], is => 'lazy', default => 'nntp.perl.org';
has _group => Maybe[Str], is => 'lazy', default => 'perl.cpan.uploads';
has _last => Int, default => sub { 0 + path(STORE)->slurp }, is => 'rw';

sub poll {
    my $self = shift;
    my $nntp = Net::NNTP->new($self->_url);
    my ($s, $y, $last) = $nntp->group($self->_group);
    use Data::Dumper;
    print Dumper [$s, $y, $last];
    return [] if $last <= $self->_last;

    my @uploads;
    for ($self->_last+1 .. $last) {
        next unless (join "\n", $self->_nntp->head($_)->@*)
            =~ m{^Subject: CPAN Upload:\s*(\S/\S\S/([^/]+)/Perl6/(\S+))}m;
        push @uploads, {
            url    => CPAN_URL . $1,
            author => $2,
            module => $3,
        };
        say "Found ID#$_ is $uploads[-1]{url}";
    }
    path(STORE)->spurt($self->_last($last)) if $last;
    return \@uploads;
}

1;
__END__
