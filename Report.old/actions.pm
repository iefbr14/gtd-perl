package Hier::Report::actions;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_actions report_actions);
}

use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::Tasks;

sub Report_actions {	#-- List all projects with actions
	add_filters('+task', '+hier', '+next');
	report_actions(1, 'Actions', meta_desc(@ARGV));
}

sub report_actions {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($ref, $pid, $pref, $proj, %active);

	# find all projects (next actions?)
	for my $tid (keys %Task) {
		$ref = $Task{$tid};

		next unless is_ref_task($ref);
		next if filtered($ref);

		$pid = parent($ref);
		next unless defined $Task{$pid};
		$pref = $Task{$pid};

		next if filtered($pref);

		$active{$pid} = '1';
		$proj->{$pid}{$tid} = $ref->{nextaction};
	}

### format:
### 99	P:Title
### +	Description
### =	Outcome
### 222	[_] Action
### +	Description
### =	Outcome
	my($cols) = columns() - 2;
	my($gid, $gref);

	my($last_goal) = 0;
	for my $pid (sort by_task keys %$proj) {
		next unless $active{$pid};

		$pref = $Task{$pid};
		next if filtered($pref);

		$gid = parent($pref);
		$gref = $Task{$gid};

		if ($last_goal != $gid) {
			print '#', "=" x $cols, "\n" if $last_goal;
			print "$gid:\tG:$gref->{task}\n";
			$last_goal = $gid;
		} 
		print "$pid:\tP:$pref->{task}\n";

		bulk_display('+', $pref->{description});
		bulk_display('=', $pref->{note});

		for my $tid (sort by_task keys %{$proj->{$pid}}) {

			$ref = $Task{$tid};
			if ($ref->{completed}) {
				print "$tid:\t     [*] $ref->{task}\n";
				next;
			}
			if ($ref->{later}) {
				print "$tid:\t     [-] $ref->{task}\n";
				next;
			}
			if ($ref->{isSomeday} eq 'y') {
				print "$tid:\t     {_} $ref->{task}\n";
				next;
			}
			if ($proj->{$pid}{$tid} eq 'y') {
				print "$tid:\t     [_] $ref->{task}\n";
			} else {
				print "$tid:\t     {_} $ref->{task}\n";
			}
			bulk_display('+', $ref->{description});
			bulk_display('=', $ref->{note});
			print "\n";
		}
		print '#', "-" x $cols, "\n";
	}
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
package Hier::Report::nextactions;

use strict;
use warnings;


# Actions:
#	completed == null
#	isSomeday == no
#	nextaction == y
#	tickledate == null

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_nextactions);
}

use Hier::header;
use Hier::globals;
use Hier::util;

sub Report_nextactions {	#-- List all projects with actions
	add_filter('+next');
	report_nextactions(1, 'Next Actions', meta_desc(@ARGV));
}

sub report_nextactions {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($ref, $pref, $projects);

	# find all projects (next actions?)
	for my $tid (keys %Task) {
		$ref = $Task{$tid};

		next if $ref->{type} ne 'a';

		next if filtered($ref);
		next if task_filtered($ref);

		my $pid = parent($ref);
		next unless $pid;
		next unless defined $Task{$pid};

		$pref = $Task{$pid};
		next if hier_filtered($ref);

		$projects->{$pid}{$tid} = $ref->{nextaction};
	}

### format:
### 999 Project 9999 [_] Next Action

	my($proj);
	
	for my $pid (sort by_task keys %$projects) {
		$pref = $Task{$pid};
		next if filtered($pref);

		$proj = sprintf("%4d: %-16.16s", $pid, $pref->{task});

		for my $tid (sort by_task keys %{$projects->{$pid}}) {
			$ref = $Task{$tid};
			if ($ref->{completed}) {
				print "$proj $tid: [*] $ref->{task}\n";

			} elsif ($ref->{tickledate}) {
				print "$proj $tid: [-] $ref->{task}\n";

			} elsif ($ref->{isSomeday} eq 'y') {
				print "$proj $tid: {_} $ref->{task}\n";

			} elsif ($projects->{$pid}{$tid} eq 'y') {
				print "$proj $tid: [_] $ref->{task}\n";
			} else {
				print "$proj $tid: {_} $ref->{task}\n";
			}

			$proj = ' ' x (4+2+16);
		}
	}
}

sub by_task {
	my $rc = $Task{$a}->{task} cmp $Task{$b}->{task};
	return $rc if $rc;
	return $a <=> $b;
}

1;  # don't forget to return a true value from the file
