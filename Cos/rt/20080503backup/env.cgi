#!/usr/bin/perl

print "Content-type: text/plain\n\n";

foreach $key (sort keys %ENV) {
	print "$key\t$ENV{$key}\n";
}
