package Hier::Report::records;

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
use Hier::Filter;
use Hier::Format;
use Hier::Selection;

sub Report_records {	#-- detailed list all records for a type
	# everybody into the pool
	meta_filter('+any', '^tid', 'simple');

	my($desc) = join(' ', @ARGV);

	my($name) = ucfirst(meta_desc(@ARGV));	# some out
	if ($name) {
		my($want) = type_val($name);
		unless ($want) {
			print "**** Can't understand Type $name\n";
			exit 1;
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
	for my $ref (meta_sorted('^tid')) {
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

		print "\t", $ref->get_task(), "\n";
	}
}

sub disp {
	my($ref) = @_;
	my($tid) = $ref->get_tid();

	my($key) = action_disp($ref);

	my $pri = $ref->get_priority() || 3;
	my $type = uc($ref->get_type());

	return "$type:$tid $key <$pri> $ref->get_task()";
}

1;  # don't forget to return a true value from the file
