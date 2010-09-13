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

use Hier::globals;
use Hier::Tasks;

sub Report_renumber { #-- Renumber task Ids 
	renumb(\&is_value,       1,    9, 'Values');
	renumb(\&is_vision,     10,   50, 'Vision');
	renumb(\&is_goals,      50,  199, 'Goals/Roles');
	renumb(\&is_project,   200,  999, 'Projects');
	renumb(\&is_task,     1000, 9999, 'Actions');
}

sub is_value {
	my($ref) = @_;

	return 1 if $ref->{type} eq 'm';	# Value
	return 0;
}
sub is_vision {
	my($ref) = @_;

	return 1 if $ref->{type} eq 'v';	# Vision
	return 0;
}
sub is_goals {
	my($ref) = @_;

	return 1 if is_ref_hier($ref) && $ref->{type} eq 'o';	# Role
	return 1 if is_ref_hier($ref) && $ref->{type} eq 'g';	# Goal
	return 0;
}

sub is_project {
	my($ref) = @_;

	return 1 if is_ref_hier($ref) && $ref->{type} eq 'p';	# Project
	return 0;
}

sub is_task {
	return !is_ref_hier(@_);
}

sub renumb {
	my($test, $min, $max, $who) = @_;

	print "Processing $who range: $min $max\n";
	my(%inuse, @try);

	for my $tid (keys %Task) {
		if ($min <= $tid && $tid <= $max) {
			$inuse{$tid} = 1;
		}
		if ($tid < $min) {
			if (&$test($Task{$tid})) {
				push(@try, $tid);
				next;
			}
		}
		if ($tid > $max) {
			if (&$test($Task{$tid})) {
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

	my(@list) = qw(itemattributes items itemstatus tagmap);
	print "$tid => $new\n";
	for my $table (@list) {
		G_sql("update gtd_$table set itemId=$new where itemId=$tid");
	}
	G_sql("update gtd_lookup set itemId=$new where itemId=$tid");
	G_sql("update gtd_lookup set parentId=$new where parentId=$tid");
	G_sql("update gtd_tagmap set itemId=$new where itemId=$tid");

	set($Task{$tid}, todo_id => $new, 1);
	delete $Task{$tid}->{_dirty};
	$Task{$new} = $Task{$tid};
	delete $Task{$tid};
}


1;  # don't forget to return a true value from the file
