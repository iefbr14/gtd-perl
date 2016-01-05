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

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_noop);
}

use Hier::Util;
use Hier::Walk;
use Hier::Meta;
use Hier::Option;

my $Mask = 0;

our $Debug = 0;

sub Noop {	#-- No Operation
	print "### Debug noop = $Debug\n" if $Debug;

	meta_filter('+live', '^tid', 'tid');

	my($list) = meta_pick(@_);

	my($walk) = new Hier::Walk();

	$walk->filter();

	if ($Debug) {
		print "noop: ", join(' ', @_), "\n";
	}
	return;
}

1;
