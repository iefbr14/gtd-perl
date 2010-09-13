#!/usr/bin/perl -w
use strict;

use Cos::auth qw(auth_prop);
use Cos::process;

use CGI qw/:standard/;

my( $user ) = param( 'user' );
my( $pass ) = param( 'pass' );
my( $retval ) = 0;

print "Content-type: text/plain\n\n";

auth_prop($user, $pass);
process_jobs($user);

print "returncode: 0\n";
