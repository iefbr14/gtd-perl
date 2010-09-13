package Hier::Report::tasks;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		&Report_tasks
		&Report_nexts
		&Report_dones
		&Report_lates
		&Report_tickles
	);
}

use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::Tasks;

my(%Filter_map) = (
	Action 	=> [ qw( +current +next ~done ~later ) ],
	Next	=> [ qw(          +next ~done ~later ) ],
	Done	=> [ qw( +done ) ],
	Late	=> [ qw( +late ~done ) ],
	Tickle	=> [ qw( +tickle ~done ) ],
	Slow	=> [ qw( +slow ~done ) ],
	Idea	=> [ qw( +idea ~done ) ],
	Due	=> [ qw( +due ~done ~later ) ],
	Someday	=> [ qw( +someday ~done ) ],
	Future	=> [ qw( +someday +tickle ~done ) ],
);

sub Report_tasks {	#-- List all projects with actions
	add_filters('+task');

	my($p) = $ARGV[0];
	if ($p) {
		if (defined $Filter_map{$p}) {
			my($ref) = $Filter_map{$p};
			add_filters(@$ref);
			shift(@ARGV);
			list_tasks(1, $p, meta_desc(@ARGV));
			return;
		}
		if ($p =~ s/s$// && defined $Filter_map{$p}) {
			my($ref) = $Filter_map{$p};
			add_filters(@$ref);
			shift(@ARGV);
			list_tasks(1, $p, meta_desc(@ARGV));
			return;
		}
		print "Unknown request: $p\n";
	}

	add_filters('+live');	# Actions
	list_tasks(1, 'Actions', meta_desc(@ARGV));
}

sub list_tasks {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($ref, $proj, %active);

	# find all projects (next actions?)
	for my $tid (keys %Task) {
		$ref = $Task{$tid};

#		print "$tid ::: ", disp($tid), ":::\n";

		next if is_ref_hier($ref);
		next if filtered($ref);
		next if task_filtered($ref);

		my($flags) = dispflags($ref->{mask});

		print $flags, " ", disp($tid), "\n";
#		print disp($ref->{parent}), ' ' disp($tid}, "\n";

#		$pid = parent($ref);
#		next unless $pid;
#		next unless defined $Task{$pid};
#
#		next if hier_filtered($ref);
#		$proj->{$pid}{$tid} = $ref->{nextaction};
	}
return;

	for my $pid (sort by_task keys %$proj) {
		next unless $active{$pid};

		$ref = $Task{$pid};
		next if filtered($ref);

		print "$pid:\tP:$ref->{task}\n";

		for my $tid (sort by_task keys %{$proj->{$pid}}) {
			disp($tid);
		}
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
