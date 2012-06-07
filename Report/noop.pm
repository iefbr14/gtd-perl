package Hier::Report::noop;

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

use Hier::util;
use Hier::Walk;
use Hier::Meta;
use Hier::Option;
use Hier::Filter;

my $Mask = 0;

sub Report_noop {	#-- No Operation
	meta_filter('+any', '^tid', 'none');

	my($criteria) = meta_desc(@ARGV);

	my($walk) = new Hier::Walk();
	$walk->filter();

	return;
}

1;
