package Hier::Report::checklist;

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
use Hier::Tasks;

sub Report_records {	#-- List all projects with actions
#	meta_argv();
	my($p) = shift @ARGV;
	
	my($id);
	if ($p =~ /^\d+$/) {
		list_records($id, "List: $p", meta_desc(@ARGV));

	} elsif ($id = find_list($p)) {
		list_records($id, 'All', meta_desc(@ARGV));

	} else {
		print "*** Can't find a list called: $p\n";
	}
}

sub find_list {
	my($list_name) = @_;

	my($pid, $ref, $proj, $type, $f);
	my($Dates) = '';

	# find all records.
	for my $tid (sort keys %Task) {
		$ref = $Task{$tid};

		$type = $ref->{type};

		next unless $type =~ /[LC]/;

		my($flags) = dispflags(task_mask($ref));

		printf ("%5d %s %s", $tid, $type, $flags);
		if ($Dates) {
		}
		$f = '';
		$f = 'c' if filtered($ref);

		if (is_ref_hier($ref)) {
			$f .= 'h' if hier_filtered($ref);
		} elsif (is_ref_task($ref)) {
			$f .= 'a' if task_filtered($ref);
		} else {
			$f .= 'r'; # reference);
		}
		print " x($f)" if $f;

		print "\t", $ref->{task}, "\n";
#		print $flags, " ", disp($tid), "\n";
#		print disp($ref->{parent}), ' ' disp($tid}, "\n";

#		$pid = parent($ref);
#		next unless $pid;
#		next unless defined $Task{$pid};
#
#		next if hier_filtered($ref);
#		$proj->{$pid}{$tid} = $ref->{nextaction};
	}
}
sub list_records {
	my($list_name, $typename, $desc) = @_;

	report_header($typename, $desc);

	my($pid, $ref, $proj, $type, $f);
	my($Dates) = '';

	my($want_type) = 'L'; ###BUG###
	# find all records.
	for my $tid (sort keys %Task) {
		$ref = $Task{$tid};

		$type = $ref->{type};

		next if $want_type && $type ne $want_type;

		my($flags) = dispflags(task_mask($ref));

		printf ("%5d %s %s", $tid, $type, $flags);
		if ($Dates) {
		}
		$f = '';
		$f = 'c' if filtered($ref);

		if (is_ref_hier($ref)) {
			$f .= 'h' if hier_filtered($ref);
		} elsif (is_ref_task($ref)) {
			$f .= 'a' if task_filtered($ref);
		} else {
			$f .= 'r'; # reference);
		}
		print " x($f)" if $f;

		print "\t", $ref->{task}, "\n";
#		print $flags, " ", disp($tid), "\n";
#		print disp($ref->{parent}), ' ' disp($tid}, "\n";

#		$pid = parent($ref);
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

sub by_task {
	my $rc = $Task{$a}->{task} cmp $Task{$b}->{task};
	return $rc if $rc;
	return $a <=> $b;
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
