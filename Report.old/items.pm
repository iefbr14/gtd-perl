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

use Hier::header;
use Hier::globals;
use Hier::Tasks;

sub Report_items {
	add_filters('+any', '+all');	# everybody into the pool

	my($name) = meta_desc(@ARGV);
	if ($name) {
		my($want) = type_val($name);
		if ($want) {
			list_records($want, $name);
			return;
		}
		print "**** Can't understand Type $name\n";
		exit 1;
	}
	print "No items requested";
}

sub list_items {	#-- List projects with waiting-fors
	my($type, $typename) = @_;

	report_header($typename);

        my($tid, $ref, $desc, @list);
        for my $tid (keys %Task) {
                $ref = $Task{$tid};
                next if $ref->{type} ne $type;

		next if filtered($ref);

                push(@list, $tid);
        }
        for my $tid (sort by_task @list) {
                $ref = $Task{$tid};
                $desc = summary_line($ref->{description}, ' -- ');
                print "$tid\t  [_] $ref->{task}$desc\n";
        }
        print "\n";
}


1;  # don't forget to return a true value from the file
