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
	my($p) = shift;
	if ($p) {
		$p = ucfirst($p);

		if (defined $Filter_map{$p}) {
			my($filter) = $Filter_map{$p};
			add_filters(@$filter);
			shift(@ARGV);
			list_tasks($p, meta_desc(@ARGV));
			return;
		}
		if ($p =~ s/s$// && defined $Filter_map{$p}) {
			my($filter) = $Filter_map{$p};
			add_filters(@$filter);
			shift(@ARGV);
			list_tasks($p, meta_desc(@ARGV));
			return;
		}
		print "Unknown request: $p\n";
	}

	add_filters('+live');	# Actions
	list_tasks('Actions', meta_desc(@ARGV));
}

sub list_tasks {
	my($head, $desc) = @_;

	report_header($head, $desc);

	# find all projects (next actions?)
	for my $ref (Hier::Tasks::all()) {
		next unless $ref->is_ref_task();
		next if $ref->filtered();

		print disp($ref), "\n";
	}
}

### format:
### 99	P:Title	[_] A:Title
sub disp {
	my($ref) = @_;

	my($tid) = $ref->get_tid();

	my($key) = action_disp($ref);

	my $pri = $ref->get_priority() || 3;
	my $type = uc($ref->get_type());

	$type = 'N' if $ref->get_nextaction() eq 'y';
	$type = 'S' if $ref->get_isSomeday() eq 'y';
	$type = 'T' if $ref->get_tickledate();

	my $title = $ref->get_title();
	return "$type:$tid $key <$pri> $title";
}

1;  # don't forget to return a true value from the file
