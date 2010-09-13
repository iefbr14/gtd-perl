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

use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::sort;
use Hier::Tasks;

sub Report_records {	#-- List all projects with actions
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

	my($ref, $proj, $type, $f, $kids, $acts);
	my($Dates) = '';

	# find all records.
	for my $tid (sort by_tid keys %Task) {
		$ref = $Task{$tid};

		$type = $ref->{type};
		$kids = $ref->{_child};
		$acts = $ref->{_actions};

		next if $want_type && $type ne $want_type;

		my($flags) = dispflags(task_mask($ref));

		$f = '';
		$f = 'X' if filtered($ref);

		$f .= 'c' if cct_filtered($ref);
		$f .= 'h' if hier_filtered($ref);
		$f .= 'a' if task_filtered($ref);
		$f .= 'l' if list_filtered($ref); 

		printf ("%-6s %s %6d %s ", $f, $type, $tid, $flags);


		print " k:$kids" if $kids;
		print " a:$acts" if $acts;

		print "\t", $ref->{task}, "\n";
#		print $flags, " ", disp($tid), "\n";
#		print disp($ref->{parent}), ' ' disp($tid}, "\n";

#		my $pid = parent($ref);
#		next unless $pid;
#		next unless defined $Task{$pid};
#
#		next if hier_filtered($ref);
#		$proj->{$pid}{$tid} = $ref->{nextaction};
	}
}

### format:
### 99	P:Title	[_] A:Title
sub disp {
	my($tid) = @_;

	my($ref) = $Task{$tid};

	my($key) = '[ ]';

	$key = '[_]' if $ref->{nextaction} eq 'y';
	$key = '[*]' if $ref->{completed};

	$key =~ s/.(.)./($1)/ 	if $ref->{isSomeday} eq 'y';
	$key =~ s/.{.}./($1)/ 	if $ref->{tickledate};
	$key =~ s/(.)./$1w/ 	if $ref->{type} eq 'w';

	my $pri = $ref->{priority} || 3;
	my $type = uc($ref->{type});

	return "$type:$tid $key <$pri> $ref->{task}";
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
