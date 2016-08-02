#!/usr/bin/env perl

use FindBin;
use 5.014;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

require Mojolicious::Commands;
Mojolicious::Commands->start_app('SRT');