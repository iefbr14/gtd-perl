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
use Cos::Lab;
use YAML::Syck;

print "Content-type: text/plain\n\n";

Cos::w2::authenticate();

my %FORM   = Cos::w2::get_input();
my($lab_id) = $FORM{'lab_id'};
my($UTF) = $FORM{'UTF8'} || 0;

my($ref);

my($lab) = new Cos::Lab;
my($href) = {};

unless ($lab_id) {
	$href->{status} = 'FAIL no lab specified';
	print Dump($href);
	exit 0;
}

$lab->find("lab_id" => $lab_id);
$href = $lab->hashref();
if ($href) {
	$href->{status} = 'OK';
	print Dump($href);
} else {
	$href = {};
	$href->{status} = 'FAIL No such lab';
	print Dump($href);
}
