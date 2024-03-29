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

my $Debug = 0;
my %Depth;

sub Report_tsort {	#-- write out hier as as set of nodes
	for my $ref (meta_matching_type('a')) {
		up($ref);
	}

	if (@_ == 0) {
		for my $ref (meta_matching_type('m')) {
			dpos($ref, 1);
		}
		exit 0;
	}


	for my $task (@_) {
		my $ref = meta_find($task);
#		down($ref, 1);
		dpos($ref, 1);
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

sub dpos {
	my($ref, $level) = @_;

	my $id = $ref->get_tid();
	my $type = $ref->get_type();

	print "$id\t$type $level:\t";

	if ($Depth{$id} && $level != $Depth{$id}) {
		warn "Recurson: $id at $level (was $Depth{$id})\n";
		return;
	}
	$Depth{$id} = $level;

	my($join) = ' ';
	foreach my $pref ($ref->get_parents()) {
		my $pid = $pref->get_tid();

		$Depth{$pid} = '0' unless defined $Depth{$pid};
		if ($Depth{$pid} > $level) {
			warn "Depth: $id at $level (pid $pid > $Depth{$pid})\n";
		}

		print "$join$pid";
		$join = ',';
	}
	print " <$id>";

	foreach my $cref ($ref->get_children()) {
		my $cid = $cref->get_tid();
		print " $cid";
	}
	print "\n";

	foreach my $cref ($ref->get_children()) {
		dpos($cref, $level+1);
	}
}

sub up {
	my($ref) = shift @_;

	my $id = $ref->get_tid();

	print "up: $id @_\n" if $Debug;

	for my $cid (@_) {
		next if $id != $cid;

		die "Stack fault: $id in @_\n";
	}
		

	foreach my $pref ($ref->get_parents()) {
		up($pref, $id, @_);

	}
}

1;  # don't forget to return a true value from the file
