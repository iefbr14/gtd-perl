package Hier::Report::status;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_status );
}

my %Types = (
        'Value'         => 'm',
        'Vision'        => 'v',

        'Role'          => 'o',
        'Goal'          => 'g',

        'Project'       => 'p',

        'Action'        => 'a',
        'Inbox'         => 'i',
        'Waiting'       => 'w',

        'Reference'     => 'r',

        'List'          => 'L',
        'Checklist'     => 'C',
        'Item'          => 'T',
);


use Hier::header;
use Hier::globals;
use Hier::util;
use Hier::Tasks;

sub Report_status {	#-- List all projects with actions
	set_filters("+live");	# counts use it and it give a context

	list_argv() if (@ARGV);
#	meta_argv();
#	list_argv() if (@ARGV);

	my $desc = meta_desc(@ARGV);
	
	my $hier = count_hier();
	my $proj = count_proj();
	my $task = count_task();
	my $next = count_next();

	print "Options:\n";
	for my $option (qw(pri debug db title report)) {
		printf "%10s %s\n", $option, get_info($option);
	}
	print "\n";

	print "Would find hier:$hier, proj:$proj, actions:$task, next:$next\n";
}

sub count_hier {
	my($ref);
	my($count) = 0;
	# find all records.
	foreach my $tid (sort keys %Hier) {
		$ref = $Hier{$tid};

		next unless is_ref_hier($ref);
		next if filtered($ref);
		next if hier_filtered($ref);
		++$count;
	}
	return $count;
}

sub count_proj {
	my($ref);
	my($count) = 0;
	# find all records.
	foreach my $tid (sort keys %Hier) {
		$ref = $Hier{$tid};

		next unless is_ref_hier($ref);
		next if $ref->{type} ne 'p';

		next if filtered($ref);
		next if hier_filtered($ref);
		++$count;
	}
	return $count;
}

sub count_liveproj {
	my($ref);
	my($count) = 0;
	# find all records.
	foreach my $tid (sort keys %Hier) {
		$ref = $Hier{$tid};

		next unless is_ref_hier($ref);
		next if $ref->{type} ne 'p';

		next if filtered($ref);
		next if hier_filtered($ref);
		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub count_task {
	my($ref);
	my($count) = 0;
	# find all records.
	foreach my $tid (sort keys %Task) {
		$ref = $Task{$tid};

		next unless is_ref_task($ref);

		next if filtered($ref);
		next if hier_filtered($ref);
		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub count_tasklive {
	my($ref);
	my($count) = 0;
	# find all records.
	foreach my $tid (sort keys %Task) {
		$ref = $Task{$tid};

		next unless is_ref_task($ref);

		next if filtered($ref);
		next if hier_filtered($ref);
		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub project_live {
	my($ref) = @_;

	return $ref->{live} if defined $ref->{live};

	my($type) = $ref->{type};

	if (is_ref_task($ref)) {
		$ref->{live} = ! task_filtered($ref);
		return $ref->{live};
	}

	if (is_ref_hier($ref)) {
		foreach my $pid (parents($ref)) {
			$ref->{live} |= project_live($Hier{$pid});
		}
		foreach my $cid (children($ref)) {
			$ref->{live} |= project_live($Hier{$cid});
		}
	
		$ref->{live} = ! task_filtered($ref);
		return $ref->{live};
	}

	return 0;
}

1;
