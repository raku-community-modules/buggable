package SRT;

use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->plugin('AssetPack' => { pipes => [qw/Sass JavaScript Combine/] });

    $self->asset->process( 'app.css' => 'sass/main.scss' );
    $self->asset->process( 'app.js' => qw{
            js/main.js
        }
    );

    my $r = $self->routes;
    $r->get('/')->to('root#index')
}

1;
