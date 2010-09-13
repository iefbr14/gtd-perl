package Hier::Report::items;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_items);
}

use Hier::util;
use Hier::Tasks;

sub Report_items {	#-- list titles for any filtered class (actions/projects etc)
	add_filters('+any', '+all');	# everybody into the pool

	my($name) = meta_desc(@ARGV);
	if ($name) {
		my($want) = type_val($name);
		if ($want) {
			list_items($want, $name);
			return;
		}
		print "**** Can't understand Type $name\n";
		exit 1;
	}
	print "No items requested\n";
}

sub list_items {	#-- List projects with waiting-fors
	my($type, $typename) = @_;

	report_header($typename);

        my($tid, $title, $desc, @list);
        for my $ref (Hier::Tasks::matching_type($type)) {
		next if $ref->filtered();

                push(@list, $ref);
        }
        for my $ref (sort by_task @list) {
		$tid = $ref->get_tid();
		$title = $ref->get_title();
                $desc = summary_line($ref->get_description(), ' -- ');
                print "$tid\t  [_] $title$desc\n";
        }
        print "\n";
}

sub by_task {
	return $a->get_title() cmp $b->get_title()
	||     $a->get_tid()   <=> $b->get_tid();
}

1;  # don't forget to return a true value from the file
