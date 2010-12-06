package Hier::Report::renumber;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_renumber);
}

use Hier::Tasks;

sub Report_renumber { #-- Renumber task Ids 
	if (@ARGV) {
		foreach my $pair (@ARGV) {
			renumber_pair($pair);
		}
	} else {
		renumber_all();
	}
}

sub renumber_all { #-- Renumber task Ids 
	renumb(\&is_value,       1,    9, 'Values');
	renumb(\&is_vision,     10,   50, 'Vision');
	renumb(\&is_goals,      50,  199, 'Goals/Roles');
	renumb(\&is_project,   200,  999, 'Projects');
	renumb(\&is_task,     1000, 9999, 'Actions');
}

sub renumber_pair {
	my($pair) = @_;
	if ($pair =~ m/^(\d+)=(\d+)/) {
		my($to, $tid) = ($1, $2);

		renumber_task($tid, $to);
	} else {
		print "Can't yet renumber singletons($pair), use TO=FROM syntax\n";
	}
}

sub is_value {
	my($ref) = @_;

	return 1 if $ref->get_type() eq 'm';	# Value
	return 0;
}
sub is_vision {
	my($ref) = @_;

	return 1 if $ref->get_type() eq 'v';	# Vision
	return 0;
}
sub is_goals {
	my($ref) = @_;

	return 1 if $ref->get_type() eq 'o';	# Role
	return 1 if $ref->get_type() eq 'g';	# Goal
	return 0;
}

sub is_project {
	my($ref) = @_;

	return 1 if $ref->get_type() eq 'p';	# Project
	return 0;
}

sub is_task {
	my($ref) = @_;

	return $ref->is_ref_task();
}

sub renumb {
	my($test, $min, $max, $who) = @_;

	print "Processing $who range: $min $max\n";
	my(%inuse, $tid, @try);

	for my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid();

		if ($min <= $tid && $tid <= $max) {
			$inuse{$tid} = 1;
		}
		if ($tid < $min) {
			if (&$test($ref)) {
				push(@try, $tid);
				next;
			}
		}
		if ($tid > $max) {
			if (&$test($ref)) {
				push(@try, $tid);
				next;
			}
		}
	}
	TASK: 
	for my $tid (@try) {
		while ($min < $max) {
			if ($inuse{$min}) {
				++$min;
				next;
			}

			renumber_task($tid, $min);

			$inuse{$tid} = 0;
			$inuse{$min} = 1;
			++$min;
			next TASK;
		}
		print "Out of slots for $who.\n";
		return;
	}
	print "Completed $who.\n";
}

sub renumber_task {
	my($tid, $new) = @_;

	my $ref = Hier::Tasks::find($tid);

	die "Can't renumber task $tid (doesn't exists)\n" unless $ref;

	print "$tid => $new\n";
	$ref->set_tid($new);
}


1;  # don't forget to return a true value from the file
