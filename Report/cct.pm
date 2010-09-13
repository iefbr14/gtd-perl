package Hier::Report::cct;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_cct);
}

use Hier::util;
use Hier::Tasks;

use Hier::CCT;		# DIRECT access to interals (Bleck)

my %Count;
my %Sub_Count;
my %Types;
my %Total;
my %Dups;

sub Report_cct {	#-- List Categories/Contexts/Time Frames
	count_items();

	cct_crosstab();
}

sub cct_crosstab {	#-- List Categories/Contexts/Time Frames
	report_counts("Categories",  'category');
	report_counts("Contexts",    'context');
	report_counts("Time Frames", 'timeframe');
	report_counts("Tags",        'tag');
}

sub count_items {
	foreach my $ref (Hier::Tasks::all()) {
		my $type = $ref->get_type();

		count_item('category',  $type, $ref->get_category());
		count_item('context',   $type, $ref->get_context());
		count_item('timeframe', $type, $ref->get_timeframe());

		foreach my $tag ($ref->get_tags()) {
			count_item('tag', $type, $tag);
		}
			

		$Types{$type}++;
	}
}

sub count_item {
	my($cct, $type, $value) = @_;
	
	if ($value) {
		$Total{$cct}++;
	} else {
		$value = "{no-$cct}";
	}

	$Count{$cct}{$value}++;
	$Sub_Count{$cct}{$value}{$type}++;

}

sub report_counts {
	my($header, $cct) = @_;

	my($tot) = $Total{$cct} || 0;
	report_header("$header -- $tot");

	my $hash = $Count{$cct};
	my(@keys) = sort keys %$hash;

	my($id, $dup, $cnt, $sk);

	print "Val  Vis  Role Goal Proj Action Total Id: Name\n";
	for my $key (@keys) {
		$id = Hier::CCT::get_id($cct, $key) || '0';
		$dup = $Dups{lc($key)}++ ? '*' : ':';
		$cnt = $Count{$cct}{$key} || 0;

		foreach my $type (qw(m v o g p a)) {
			$sk = $Sub_Count{$cct}{$key}{$type};

			$sk = '' unless defined $sk;

			printf "%4s ", $sk;
		}
	
		printf "= %4d  %2d%s %s\n", $cnt, $id, $dup, $key;
	}
}

1;  # don't forget to return a true value from the file
