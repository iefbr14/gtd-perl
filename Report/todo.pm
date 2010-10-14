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

use Hier::util;
use Hier::Tasks;


sub Report_todo {	#-- List top level next actions
	my($limit) = option('Limit', 10);
	my($list)  = option('List', 0);

	add_filters('+live');
	my($title) = meta_desc(@ARGV);

	my($tid, $key, $pri, $task, $cat, $created, $modified, $due, $desc);

print <<"EOF";
  Id   Pri Category  Due         Task/Description: $title
==== === = ========= =========== ==============================================
EOF

format STDOUT =
@>>> @<< @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,$key,$pri, $cat,        $due,    $task
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                                  $desc
.

	my($count) = 0;
	for my $ref (Hier::Tasks::sorted('^pri')) {
		next unless $ref->is_ref_task();	# only actions
		next if $ref->filtered();		# other filterings

		$tid       = $ref->get_tid();
		$pri       = $ref->get_priority();

		$task      = $ref->get_task() || $ref->get_context() || '';
		$cat       = $ref->get_category() || '';
		$created   = $ref->get_created();
		$modified  = $ref->get_modified() || $created;
		$due       = $ref->get_due();
		$desc      = $ref->get_description() || '';

		$key       = action_disp($ref);

		if ($list) {
			$desc =~ s/\n.*//s;
			print join("\t", $tid, $pri, $cat, $task, $due, $desc), "\n";
		} else {
			write;
		}
		last if ++$count >= $limit;
	}
}

sub parent_filtered {
	my($ref) = @_;

	my($filtered) = 0; # asssume not filtered by default

	for my $pref ($ref->get_parents()) {
		if ( $pref->filtered() ) {
			$filtered++;
		} else {
			return 0; # some parent not filtered.
		}
	}
	return $filtered; # only 1 if all parents filtered.
}

1;  # don't forget to return a true value from the file
