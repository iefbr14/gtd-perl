package Hier::Report::list;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_list);
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Filter;
use Hier::Option;
use Hier::Format;

sub Report_list {	#-- list titles for any filtered class (actions/projects etc)
	meta_filter('+live', '^title', 'title');

	my($name) = meta_desc(@_);
	if ($name) {
		my($want) = type_val($name);
		if ($want) {
			list_desc($want, $name);
			return;
		}
		print "**** Can't understand Type $name\n";
		exit 1;
	}
	print "No items requested\n";
}

sub list_desc {	#-- List projects with waiting-fors
	my($type, $typename) = @_;

	report_header($typename);

        my(@list);
        for my $ref (meta_matching_type($type)) {
		next if $ref->filtered($ref);

                push(@list, $ref);
        }

	for my $ref (sort_tasks @list) {
		display_task($ref);
	}
}


1;  # don't forget to return a true value from the file
