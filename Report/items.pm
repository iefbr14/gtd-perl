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
use Hier::Meta;
use Hier::Filter;
use Hier::Format;
use Hier::Option;
use Hier::Sort;

sub Report_items {	#-- list titles for any filtered class (actions/projects etc)
	# everybody into the pool by name
	meta_filter('+any', '^title', 'item');	

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
        for my $ref (meta_matching_type($type)) {
##FILTER	next if $ref->filtered();

                push(@list, $ref);
        }
        for my $ref (sort_tasks @list) {
		display_task($ref);
        }
}

1;  # don't forget to return a true value from the file
