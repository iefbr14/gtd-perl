package Hier::Report::clean;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_clean);
}

use Hier::Meta;

sub Report_clean {	#-- clean unused categories

	my($done, $tickle, $type);
	
	for my $ref (meta_selected()) {
		$done = $ref->get_completed();
		if ($done) {
			set_active($ref);
			fix_done_0000($ref, $done);
			# clean next action
			# clean tickles
		}
		if ($tickle) {
			# clean next action
			# clean tickles
		}

		$type = $ref->get_type();

		# all values,visions,roles and goals are acive
		if ($type =~ /[mvog]/) {	
			set_active($ref);
		}
	}
}

sub set_active {
	my($ref) = @_;

	if ($ref->get_isSomeday() eq 'y') {
		$ref->set_isSomeday('n');
	}
	return;
}

sub fix_done_0000 {
	my($ref, $done) = @_;

	return unless $done =~ /^0000/;
	$ref->set_completed(undef);
	return;
}

1;  # don't forget to return a true value from the file
