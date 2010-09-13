package Hier::Report::projects;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_projects);
}

use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::Tasks;

sub Report_projects {	#-- List all projects with actions
	add_filters('+hier', '+task', '+live');
	report_projects(1, 'Projects', meta_desc(@ARGV));
}

sub report_projects {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($ref, $proj, %wanted);

	# find all next and remember there projects
	for my $tid (keys %Task) {
		$ref = $Task{$tid};

		next unless is_ref_task($ref);
		next if filtered($ref);

		my $pid = parent($ref);
		next unless $pid;
		next unless defined $Task{$pid};

		$wanted{$pid} = 1;
	}

### format:
### ==========================
### Value Vision Role
### -------------------------
### 99	Goal 999 Project
	my($cols) = columns() - 2;

	my($g_id) = 0;
	my($parent, $g_ref);
	for my $pid (sort by_goal_task keys %wanted) {

		$ref = $Task{$pid};
		next if filtered($ref);

		$parent = parent($ref);
		$g_ref = $Task{$parent};

		if ($g_id != $parent) {
			print '#', "=" x $cols, "\n" if $g_id != 0;
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
