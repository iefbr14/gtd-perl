package Hier::Report::done;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_done);
}

use Hier::Option;
use Hier::Meta;

sub Report_done {	#-- Tag listed projects/actions as done
	my($date) = get_today();

	my($o_date) = option('Date', '');
	if ($o_date) {
		$date = $o_date;
	}

	for my $tid (@_) {
		my $ref = meta_find($tid);

		unless (defined $ref) {
			print "Task $tid not found to tag done\n";
			next;
		}
		print "Task $tid completed $date\n";

		$ref->set_completed($date);
		$ref->update();
	}
}

1;  # don't forget to return a true value from the file
