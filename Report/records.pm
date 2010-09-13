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
use Hier::Tasks;

sub Report_records {	#-- detailed list all records for a type
	add_filters('+all', '+any');	# everybody into the pool

	my($name) = ucfirst(meta_desc(@ARGV));	# some out
	if ($name) {
		my($want) = type_val($name);
		unless ($want) {
			print "**** Can't understand Type $name\n";
			exit 1;
		}
		list_records($want, $name);
		return;
	}
	list_records('', 'All');
}

sub list_records {
	my($want_type, $typename) = @_;

	report_header($typename);

	my($tid, $proj, $type, $f, $kids, $acts);
	my($Dates) = '';

	# find all records.
	for my $ref (Hier::Tasks::sorted('^tid')) {
		$tid  = $ref->get_tid();
		$type = $ref->get_type();
		$kids = $ref->count_children();
		$acts = $ref->count_actions();

		next if $want_type && $type ne $want_type;

		my($flags) = $ref->task_mask_disp();

		$f = '';
		$f = 'X' if $ref->filtered();

		$f .= 'c' if cct_filtered($ref);
		$f .= 'h' if $ref->hier_filtered();
		$f .= 'a' if $ref->task_filtered();
		$f .= 'l' if $ref->list_filtered(); 

		printf ("%-6s %-4s %6d %s ", $f, $type, $tid, $flags);


		print " k:$kids" if $kids;
		print " a:$acts" if $acts;

		print "\t", $ref->get_task(), "\n";
	}
}

### format:
### 99	P:Title	[_] A:Title
sub disp {
	my($ref) = @_;
	my($tid) = $ref->get_tid();

	my($key) = '[ ]';

	$key = '[_]' if $ref->get_nextaction() eq 'y';
	$key = '[*]' if $ref->get_completed();

	$key =~ s/.(.)./($1)/ 	if $ref->get_isSomeday() eq 'y';
	$key =~ s/.{.}./($1)/ 	if $ref->get_tickledate();
	$key =~ s/(.)./$1w/ 	if $ref->get_type() eq 'w';

	my $pri = $ref->get_priority() || 3;
	my $type = uc($ref->get_type());

	return "$type:$tid $key <$pri> $ref->get_task()";
}

sub bulk_display {
	my($tag, $text) = @_;

	return unless defined $text;
	return if $text eq '';
	return if $text eq '-';

	for my $line (split("\n", $text)) {
		print "$tag\t$line\n";
	}
}

1;  # don't forget to return a true value from the file
