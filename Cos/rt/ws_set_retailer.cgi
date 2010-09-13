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
my($retail_id) = $FORM{'retail_id'};
unless ($retail_id) {
	$href->{status} = 'FAIL no retail_id specified';
	print Dump($href);
	exit 0;
}
if ($retail_id eq 'NEW') {
	$href->{retail_id} = 301001;
}
$href->{status} = 'OK';

print Dump($href);
