package Hier::Report::dump;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( &Report_dump &dump_ordered_ref );
}

use Hier::util;
use Hier::Meta;
use Hier::Filter;
use Hier::Format;


sub Report_dump {	#-- dump records in edit format
	# everybody into the pool by id 
	meta_filter('+any', '^tid', 'dump');	

	my($name) = ucfirst(meta_desc(@ARGV));	# some out
	if ($name) {
		if ($name =~ /^\d+/) {
			dump_list($name);
			return;
		}
		my($want) = type_val($name);
		unless ($want) {
			warn "**** Can't understand Type $name\n";
			exit 1;
		}
		list_dump($want, $name);
		return;
	}
	list_dump('', 'All');
}

sub dump_list {
	my($list) = @_;

	my @list = split(/[^\d]+/, $list);

	for my $tid (@list) {
		my $ref = meta_find($tid);
		unless (defined $ref) {
			warn "#*** No task: $tid\n";
			next;
		}
		display_task($ref);
	}
}

sub list_dump {
	my($want_type, $typename) = @_;

	report_header($typename);

	my($pid, $ref, $proj, $type, $f, $kids, $acts);
	my($Dates) = '';

	# find all records.
	for my $ref (meta_sorted('^tid')) {
		$type = $ref->get_type();
		next if $want_type && $type ne $want_type;

##FILTER	next if $ref->filtered();
	
		display_task($ref);
	}
}

1;  # don't forget to return a true value from the file
