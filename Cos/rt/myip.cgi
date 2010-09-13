#!/usr/bin/perl -w

use strict;
my($ip) = $ENV{'REMOTE_ADDR'} || '';

print "Content-type: text/plain\n\nIP-ADDR: $ip\n";


