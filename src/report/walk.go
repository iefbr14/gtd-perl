package report

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
	@EXPORT      = qw(&Report_walk);
}

use Hier::Util;
use Hier::Meta;
use Hier::Option;
use Hier::Format;
use Hier::Sort;

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

	meta_filter('+all', '^tid', 'simple');

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
			display_mode('list');
			next;
		}

		if ($task eq 'tid') {
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
		$ref->set_level(1);
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

	if ($val = option('Task')) {
		$ref->set_description($val);
	}

	$ref->update();
}

sub down {
	my($ref, $action) = @_;

	display_task($ref);

	foreach my $cref (sort_tasks $ref->get_children()) {
		down($cref, $action);
	}

	&$action($ref);
}

sub up {
	my($ref, $action) = @_;

	foreach my $cref (sort_tasks $ref->get_parents()) {
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
