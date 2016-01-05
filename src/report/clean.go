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
	@EXPORT      = qw(&Report_clean);
}

use Hier::Meta;
use Hier::Option;

sub Report_clean {	#-- clean unused categories
	my $Yesterday = get_today(-1);

	meta_filter('+all', '^tid', 'task');
	my($done, $tickle, $type);
	
	for my $ref (meta_selected()) {
		$done = $ref->is_completed();
		if ($done) {
			set_active($ref);
			fix_done_0000($ref, $done);
			clear_next($ref);
			clear_tickle($ref);
		}

		$tickle = $ref->get_tickledate() <= $Yesterday;
		if ($tickle) {
			clear_next($ref);
			clear_tickle($ref);
		}

		$type = $ref->get_type();

		# all values and visions are active
		if ($type =~ /[mv]/) {	
			set_active($ref);
		}
	}
}

sub set_active {
	my($ref) = @_;

	if ($ref->is_someday()) {
		$ref->set_isSomeday('n');
		display_task($ref, 'active');
		return;
	}
	return;
}

sub fix_done_0000 {
	my($ref, $done) = @_;

	return unless $done =~ /^0000/;

	display_task($ref, 'clean done bug');
	$ref->set_completed(undef);
	return;
}

sub clear_next {
	my $ref = @_;

	return unless $ref->get_nextaction() eq 'y';

	display_task($ref, 'clear next action');
	$ref->set_nextaction('n');
}

sub clear_tickle {
	my $ref = @_;

	return unless $ref->get_tickledate();

	display_task($ref, 'clear tickle date');
	$ref->set_tickledate(undef);
}

1;  # don't forget to return a true value from the file
