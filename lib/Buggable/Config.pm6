unit module Buggable::Config;
use JSON::Tiny;
state $config = from-json 'config.json'.IO.slurp;
sub conf is export { $config }
