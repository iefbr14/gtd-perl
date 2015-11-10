package Hier::Report::renumber;

=head1 NAME

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

=cut

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_renumber &next_avail_task);
}

use Hier::Meta;
use Hier::Tasks;

my %Dep_info = (
  'a' => [ \&is_action,   2000, 9999, 'Actions' ],
  's' => [ \&is_subject,  1000, 1999, 'Sub-Projects' ],
  'p' => [ \&is_project,   200,  999, 'Projects' ],
  'g' => [ \&is_goals,      30,  199, 'Goals' ],
  'o' => [ \&is_roles,      10,   29, 'Roles' ],
  'v' => [ \&is_vision,      5,    9, 'Vision' ],
  'm' => [ \&is_value,       1,    4, 'Values' ],
);

my %Dep_map;

sub Report_renumber { #-- Renumber task Ids 
	meta_filter('+any', '^tid', 'none');
	my(@list) = meta_argv(@_);

	if (@list) {
		foreach my $pair (@list) {
			renumber_pair($pair);
		}
	} else {
		renumber_all();
	}
}

sub renumber_all { #-- Renumber task Ids 
	## for i in qw(a s p g o v m) 
	renumb('a');	# Actions
 	renumb('s');	# Sub-Projects
	renumb('p');	# Projects
	renumb('g');	# Goals
	renumb('o');	# roles
	renumb('v');	# Vision
	renumb('m');	# Values
}

sub renumber_pair {
	my($pair) = @_;
	if ($pair =~ m/^(\d+)=(\d+)/) {
		my($to, $tid) = ($1, $2);

		renumber_task($tid, $to);
	} else {
		renumber_a_task($pair);
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
sub is_roles {
	my($ref) = @_;

	return 1 if $ref->get_type() eq 'o';	# Role
	return 0;
}
sub is_goals {
	my($ref) = @_;

	return 1 if $ref->get_type() eq 'g';	# Goal
	return 0;
}

sub is_project {
	my($ref) = @_;

	return 0 if $ref->get_type() ne 'p';	# ! Project

	# return 1 iff any parents are not project
	for my $pref ($ref->get_parents()) {
		return 1 if $pref->get_type() ne 'p';	# Parrent ! Project
	}

	# is a project and some parent is not projects
	return 0;
}

sub is_subject {
	my($ref) = @_;

	return 0 if $ref->get_type() ne 'p';	# ! Project

	# return 1 iff all parents are projects
	for my $pref ($ref->get_parents()) {
		return 0 if $pref->get_type() ne 'p';	# Parrent is project
	}

	# is a project and all parents are projects
	return 1;
}

sub is_action {
	my($ref) = @_;

	return $ref->is_task();
}


sub next_avail_task {
	my($type) = @_;

	$type = 'a' if $type eq 'n';	# next action => min action
	$type = 'a' if $type eq 'w';	# wait        => min action

	my($test, $min, $max, $who) = @{ $Dep_info{$type} };

	die "***BUG*** next_avail_task: Unknown type '$type'\n" unless $test;

	for (my $tid=$min; $tid <= $max; ++$tid) {
		next if Hier::Tasks::find($tid);

		return $tid;
	}
	return undef;
}

sub renumb {
	my($type) = @_;

	my($test, $min, $max, $who) = @{ $Dep_info{$type} };

	print "Processing $who range: $min $max\n";
	my(%inuse, $tid, @try);

	for my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid();

		if ($min <= $tid && $tid <= $max) {
			$inuse{$tid} = 1;
		}

		###BUG### need to check if filtered
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

sub renumber_a_task {
	my($tid) = @_;

	my $ref = meta_find($tid);

	die "Can't renumber task $tid (doesn't exists)\n" unless $ref;

	die "Can't renumber task $tid (has depedencies)\n" if dependent($ref);

	my($type) = $ref->get_type();

	my($new) = next_avail_task($type);

	if ($tid < $new) {
		print "First slot $new > task $tid (skipped)\n";
		return;
	}

	print "$tid => $new\n";

#	print "Can't yet renumber singletons($tid), use TO=FROM syntax\n";
#	return;
	$ref->set_tid($new);
	$ref->update();
}

sub renumber_task {
	my($tid, $new) = @_;

	my $ref = meta_find($tid);

	die "Can't renumber task $tid (doesn't exists)\n" unless $ref;

	die "Can't renumber task $tid (has depedencies)\n" if dependent($ref);
	print "$tid => $new\n";

	$ref->set_tid($new);
	$ref->update();
}

sub dependent {
	my($ref) = @_;

	my($id) = $ref->get_tid();

	unless (%Dep_map) {
		return $Dep_map{$id};
	}
	warn "Building Dep_map\n";
		
	my($pref, $pid, $depends);
	foreach my $pref ( meta_all()) {
		$depends = $pref->get_depends();
		$pid = $pref->get_tid();

		foreach my $depend (split(/[ ,]/, $depends)) {
			$Dep_map{$depend} .= ','.$pid;
		}
	}

	
	return $Dep_map{$id};
}


1;  # don't forget to return a true value from the file
