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

use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::Tasks;

my %Count;
my %Dups;

sub Report_cct {	#-- List Categories/Contexts/Time Frames
	my($key);

	count_items();

	report_counts("Categories", \%Categories);
	report_counts("Contexts", \%Contexts);
	report_counts("Time Frames", \%Timeframes);
return;	###BUG### -- add tags
return;	###ToDo -- add cross hatch
	report_header("Not Identified");
	my($id, $dup, $cnt);
	for my $key (sort keys %Count) {
		$id = '';
		$dup = ':';
		$cnt = $Count{$key} || 0;
		printf "%2s%s %3d -- %s\n", $id, $dup, $cnt, $key;
	}
	print "\n";
}

sub count_items {
	my($ref);

	foreach my $tid (keys %Task) {
		$ref = $Task{$tid};

		count_item($ref, 'category');
		count_item($ref, 'context');
		count_item($ref, 'timeframe');
	}
}

sub count_item {
	my($ref, $type) = @_;
	
	my $it = type_name($ref->{type});
	
	if ($it) {
		$Count{$ref->{$type} || "<$type-$it>"}++;
	} else {
		$Count{$ref->{$type} || "{null-$type}"}++;
	}
}

sub report_counts {
	my($header, $hash) = @_;

	report_header($header);
	my($tot) = 0;
	my(@keys) = sort keys %$hash;

	my($id, $dup, $cnt);

	for my $key (@keys) {
		next if $key =~ /^\d+$/;
		$id = $hash->{$key} || '';
		$dup = $Dups{$key}++ ? '*' : ':';
		$cnt = $Count{$key} || 0;
		$tot += $cnt;
		delete $Count{$key};
		printf "%2s%s %3d -- %s\n", $id, $dup, $cnt, $key;
	}
	print "==: $tot\n";
}

1;  # don't forget to return a true value from the file
