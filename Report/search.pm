package Hier::Report::search;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_search);
}

use Hier::util;
use Hier::Format;
use Hier::Meta;

sub Report_search {	#-- Search for items
	my($found) = 0;

	my($tid, $title, $type);

	meta_filter('+all', '^title', 'simple');
	meta_desc(@ARGV);
# type filtering?
#	if ($name) {
#		my($want) = type_val($name);
#		if ($want) {
#			list_desc($want, $name);
#			return;
#		}
#		print "**** Can't understand Type $name\n";
#		exit 1;
#	}
#	print "No items requested\n";

	for my $name (split(/,/, $ARGV[0])) {
		for my $ref (meta_sorted()) {
			next unless match_desc($ref, $name);
			
			display_task($ref);
			$found = 1;
		}
	}
	exit($found ? 0 : 1);
}

sub match_desc {
	my($ref, $desc) = @_;

	return 1 if $ref->get_task() =~ m/$desc/i;
	return 1 if $ref->get_description() =~ m/$desc/i;
	return 1 if $ref->get_note() =~ m/$desc/i;
	return 0;
}

1;  # don't forget to return a true value from the file
