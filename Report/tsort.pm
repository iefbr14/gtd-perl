package Hier::Report::tsort;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_tsort);
}

use Hier::util;
use Hier::Meta;
use Hier::Option;
use Hier::Format;

my $List = 0;
my $Doit = 0;

my %Depth;

sub Report_tsort {	#-- Command line walk of a hier
	unless (@_) {
		print "NO task specified to walk\n";
		return;
	}
	
	for my $task (@_) {
		my $ref = meta_find($task);
		down($ref, 1);
	}

}

sub down {
	my($ref, $level) = @_;

	my $id = $ref->get_tid();

	if ($Depth{$id} && $level != $Depth{$id}) {
		warn "Recurson: $id at $level (was $Depth{$id})\n";
		return;
	}
	$Depth{$id} = $level;

	foreach my $pref ($ref->get_parents()) {
		my $pid = $pref->get_tid();

		if ($Depth{$pid} > $level) {
			warn "Depth: $id at $level (pid $pid > $Depth{$pid})\n";
		}

		print $pid, ' ', $ref->get_tid(), "\n";
	}

	foreach my $cref ($ref->get_children()) {
		down($cref, $level+1);
	}
}

1;  # don't forget to return a true value from the file
