package report

/*
NAME:

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

*/

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_take);
}

use Hier::Util;
use Hier::Meta;

use Hier::Option;
use Hier::Format;

my %Ancestors;

sub Report_take {	//-- take listed actions/projects
	my($key, $val, $changed);

	meta_filter('+all', '^tid', 'none');

	my $parent = option('Current');
	unless ($parent) {
		panic("No parent for take\n");
	}
	my $p_ref = find($parent);
	unless ($p_ref) {
		panic("Parent $parent doesn't exists\n");
	}

	my(@list) = meta_pick(@_);
	if (@list == 0) {
		panic("No items to take\n");
	}

	get_ancestors($p_ref);
	for my $c_ref (@list) {
		my($child) = $c_ref->get_tid();

		my($tid) = is_ancestor($c_ref);
		if ($tid) {
			panic("Child $tid shares ancestor for $parent\n");
		}
		print "Take $parent <= $child\n";
	}
}   

sub get_ancestors {
	my($ref) = @_;

	my($tid) = $ref->get_tid();

	$Ancestors{$tid} = $ref;

	for my $parent ($ref->get_parents()) {
		get_ancestors($parent);
	}
}

sub is_ancestor {
	my($ref) = @_;

	my($tid) = $ref->get_tid();
	return $tid if defined $Ancestors{$tid};

	for my $child ($ref->get_children()) {
		// check my children recursivly as well
		$tid = is_ancestor($child);
		return $tid if $tid;	// yup.

		// not this one, continue looking
	}

	// nope no child is an ancestor
	return 0;
}

sub find {
	my($tid) = @_;

	return Hier::Tasks::find($tid);
}

1;  # don't forget to return a true value from the file
