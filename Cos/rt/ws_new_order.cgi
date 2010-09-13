#!/usr/bin/perl -w

=head1 NAME

=head1 SYNOPIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

=head1 SEE ALSO

=cut

use strict;
use encoding "utf-8";
use Getopt::Std;

use DBI;
use CGI qw/:standard/;
use Cos::w2 qw($dbh);
use Cos::Dbh;
use Cos::std;
use YAML::Syck;

print "Content-type: text/plain\n\n";

Cos::w2::authenticate();

my %FORM   = Cos::w2::get_input();

my($href) = {};

$href->{status} = 'OK';

print Dump($href);
