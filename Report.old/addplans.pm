package Hier::Report::addplans;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_addplans);
}

use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::Tasks;

sub Report_addplans {
	add_filters('+task', '+hier', '+live');
	report_addplans(1, 'Projects', meta_desc(@ARGV));
}

sub report_addplans {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($ref, $proj);

	my(%has_children);
	my(%want_child);

	# find all next and remember there projects
	for my $tid (keys %Task) {
		$ref = $Task{$tid};

		next unless filtered($ref);

		my $pid = parent($ref);
		next unless $pid;
		next unless defined $Task{$pid};

		$has_children{$pid}++;
	}

	for my $pid (keys %Hier) {
		$ref = $Hier{$pid};

		next if $has_children{$pid};
		next if $ref->{type} ne 'p';
		
		next if filtered($ref);
		next if hier_filtered($ref);

		$want_child{$pid} = 1;
	}

### format:
### ==========================
### Value Vision Role
### -------------------------
### 99	Goal 999 Project
	my($cols) = columns() - 2;

	my($g_id) = 0;
	my($parent, $g_ref);
	for my $pid (sort by_goal_task keys %want_child) {
		$ref = $Task{$pid};

		$parent = parent($ref);
		$g_ref = $Task{$parent};

		if ($g_id != $parent) {
			print '#', "=" x $cols, "\n";
			print "$parent:\tG:$g_ref->{task}\n";
			$g_id = $parent;
		} else {
#			print '#', "-" x $cols, "\n";
		}

		print "$pid:\tP:$ref->{task}\n";

	}
}

sub by_goal_task {
	my $rc;

	$rc = parent($Task{$a}) <=> parent($Task{$b});
	return $rc if $rc;

	$rc = $Task{$a}->{task} cmp $Task{$b}->{task};
	return $rc if $rc;
	return $a <=> $b;
}

1;  # don't forget to return a true value from the file
