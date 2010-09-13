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
use Cos::Retailer;
use YAML::Syck;

print "Content-type: text/plain\n\n";

Cos::w2::authenticate();

my %FORM   = Cos::w2::get_input();
my($retail_id) = $FORM{'retail_id'};
my($UTF) = $FORM{'UTF8'} || 0;

my($ref);

my($retailer) = new Cos::Retailer;
my($href) = {};

unless ($retail_id) {
	$href->{status} = 'FAIL no retail_id specified';
	print Dump($href);
	exit 0;
}

$retailer->find("retail_id" => $retail_id);
$href = $retailer->hashref();
if ($href) {
	$href->{status} = 'OK';
	print Dump($href);
} else {
	$href = {};
	$href->{status} = 'FAIL No such retailer';
	print Dump($href);
}
