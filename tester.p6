use lib <lib>;

use Buggable::Plugin::TravisWatcher;

say Buggable::Plugin::TravisWatcher.new.irc-privmsg-channel:
    'https://travis-ci.org/rakudo/rakudo/builds/148589867';
