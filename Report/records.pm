package Hier::Report::records;

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
	@EXPORT      = qw( &Report_records );
}

use Hier::util;
use Hier::Meta;
use Hier::Filter;	# task_mask_disp
use Hier::Format;
use Hier::Sort;

sub Report_records {	#-- detailed list all records for a type
	# everybody into the pool
	meta_filter('+active', '^tid', 'simple');

	my($desc) = join(' ', @_);

	my($name) = ucfirst(meta_desc(@_));	# some out
	if ($name) {
		my($want) = type_val($name);
		unless ($want) {
			die "**** Can't understand Type $name\n";
		}
		list_records($want, $name.' '.$desc);
		return;
	}
	list_records('', 'All '.$desc);
}

sub list_records {
	my($want_type, $typename) = @_;

	report_header($typename);

	my($tid, $proj, $type, $f, $reason, $kids, $acts);
	my($Dates) = '';

	# find all records.
	for my $ref (sort_tasks meta_all()) {
		$tid  = $ref->get_tid();
		$type = $ref->get_type();

		next if $want_type && $type ne $want_type;

		my($flags) = $ref->Hier::Filter::task_mask_disp();

		if ($reason = $ref->filtered()) {
			$f = "X $type $reason";
		} elsif ($reason = $ref->filtered_reason()) {
			$f = "+ $type $reason";
		} else {
			$f = "  $type";
		}

		printf ("%-15s %6d %s ", $f, $tid, $flags);

		print "\t", $ref->get_title(), "\n";
	}
}

sub disp {
	my($ref) = @_;
	my($tid) = $ref->get_tid();

	my($key) = action_disp($ref);

	my $pri = $ref->get_priority();
	my $type = uc($ref->get_type());

	return "$type:$tid $key <$pri> $ref->get_title()";
}

1;  # don't forget to return a true value from the file
