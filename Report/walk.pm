package Hier::Report::walk;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_walk);
}

use Hier::util;
use Hier::Meta;
use Hier::Option;
use Hier::Format;

my $List = 0;
my $Doit = 0;

sub Report_walk {	#-- Command line walk of a hier
	unless (@_) {
		print "NO task specified to walk\n";
		return;
	}
	my($dir) = \&down;
	my($action) = \&noop;
	my($val) = '';

	display_mode(option('Format', 'simple'));

	while (@_) {
		my($task) = shift @_;

		if ($task eq 'set') {
			$action = \&set;
			next;
		}

		if ($task eq 'active') {
			$action = \&active;
			next;
		}
		if ($task eq 'someday') {
			$action = \&someday;
			next;
		}

		if ($task eq 'doit'  or $task eq 'task') {
			display_mode('doit');
			next;
		}
		if ($task eq 'wiki') {
			display_mode('wiki');
			next;
		}
		if ($task eq 'list') {
			display_mode('tid');
			next;
		}

		if ($task eq 'up') {
			$dir = \&up;
			next;
		}
		if ($task eq 'down') {
			$dir = \&down;
			next;
		}

		if ($task !~ /^\d+$/) {
			die "Unknown command: $task\n";
		}

		my $ref = meta_find($task);
		unless (defined $ref) {
			die "Task $task not found to walk\n";
			#return;
		}

		# apply all actions to task in direction specified
		&$dir($ref, $action);
	}
}

sub set {
	my($ref) = @_;

	my $val;

	if ($val = option('Category')) {
		$ref->set_category($val);
	}

	if ($val = option('Context')) {
		$ref->set_context($val);
	}

	if ($val = option('Timeframe')) {
		$ref->set_timeframe($val);
	}

	if ($val = option('Note')) {
		$ref->set_note($val);
	}

	if ($val = option('Priority')) {
		$ref->set_priority($val);
	}

	if ($val = option('Complete')) {
		$ref->set_priority($val);
	}

	if ($val = option('Description')) {
		$ref->set_description($val);
	}

	$ref->update();
}

sub down {
	my($ref, $action) = @_;

	display_task($ref);

	foreach my $cref ($ref->get_children()) {
		down($cref, $action);
	}

	&$action($ref);
}

sub up {
	my($ref, $action) = @_;

	foreach my $cref ($ref->get_parents()) {
		up($cref, $action);
	}
	display_task($ref);

	&$action($ref);
}

sub noop {
	my($ref) = @_;

	return;
}

sub someday {
	my($ref) = @_;

	$ref->set_isSomeday('y');
	return;
}
sub active {
	my($ref) = @_;

	$ref->set_isSomeday('n');
	return;
}

1;  # don't forget to return a true value from the file
