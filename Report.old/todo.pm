package Hier::Report::todo;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_todo);
}

use Hier::globals;
use Hier::header;
use Hier::util;
use Hier::Tasks;

my $List = 0;

sub Report_todo {	#-- List top level next actions
	add_filters('+task', '+live');
	my($title) = meta_desc(@ARGV);

	my($tid, $ref, $pri, $task, $cat, $created, $modified, $due, $desc);

print <<"EOF";
  Id   Pri Category  Due         Task/Description: $title
==== === = ========= =========== ==============================================
EOF

format STDOUT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,        $due,    $task
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                                  $desc
.

	my($count) = 0;
	for my $id (sort by_priority keys %Task) {
		$tid = $id;
		$ref = $Task{$id};
		
		next unless is_ref_task($ref);
		next if filtered($ref);
		next if parent_filtered($ref);

		$pri       = $ref->{priority};

		$task      = $ref->{task} || $ref->{context} || '';
		$cat       = $ref->{category} || '';
		$created   = $ref->{created};
		$modified  = $ref->{modified} || $created;
		$due       = $ref->{due};
		$desc      = $ref->{description} || '';

		if ($List) {
			$desc =~ s/\n.*//s;
			print join("\t", $tid, $pri, $cat, $task, $due, $desc), "\n";
		} else {
			write;
		}
		last if ++$count >= $Limit;
	}
}

sub parent_filtered {
	my($ref) = @_;

	my($filtered) = 0; # asssume not filtered by default

	for my $pid (parents($ref)) {
		if ( filtered( $Task{$pid} ) ) {
			$filtered++;
		} else {
			return 0; # some parent not filtered.
		}
	}
	return $filtered; # only 1 if all parents filtered.
}

1;  # don't forget to return a true value from the file
