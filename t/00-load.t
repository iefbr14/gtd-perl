#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'GTD' ) || print "Bail out!\n";
}

diag( "Testing GTD $GTD::VERSION, Perl $], $^X" );
