package Hier::Report::doit;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_doit);
}


use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Option;
use Hier::Filter;
use Hier::Format;

my $Today = get_today(0);
my $Later = get_today(+7);
my $Priority = 0;
my $Limit = 2;

my($List) = 0; ###BUG### should be an option



### rethink totally
### REWRITE --- scan list for \d+ and put in work list
### if work list is empty  

sub Report_doit {	#-- doit tracks which projects/actions have had movement

	$List = option('List', 0);
	$Limit = option('Limit', 2);

	$= = lines();
	meta_filter('+a:live', '^doitdate', 'simple');
	my($target) = 0;
	my($action) = \&doit_list;

	foreach my $arg (meta_argv(@ARGV)) {
		if ($arg =~ /^\d+$/) {
			my($ref) = meta_find($arg);

			unless (defined $ref) {
				warn "$arg doesn't exits\n";
				next;
			}
			&$action($ref);
			++$target;
			next;
		}
		if ($arg eq 'help') {
			doit_help();
			next;
		}
		if ($arg eq 'list') {
			display_mode('d_lst');
			next;
		}
		if ($arg eq 'task') {
			display_mode('task');
			next;
		}
		if ($arg eq 'later') {
			$action = \&doit_later;
			next;
		}
		if ($arg eq 'next') {
			$action = \&doit_next;
			next;
		}
		if ($arg eq 'done') {
			$action = \&doit_done;
			next;
		}
		
		if ($arg eq 'someday') {
			$action = \&doit_someday;
			next;
		}
		if ($arg eq 'now') {
			$action = \&doit_now;
			next;
		}
		if ($arg =~ /pri\D+(\d+)/) {
			$Priority = $1;
			$action = \&doit_priority;
			next;
		}
		if ($arg =~ /limit\D+(\d+)/) {
			$Limit = $1;
			set_option('Limit', $Limit);
			next;
		}
		print "Unknown option: $arg (ignored) (try help)\n";
	}
	if ($target == 0) {
		list_all($action);
	}
}

sub doit_later {
	my($ref) = @_;

	$ref->set_doit($Later);
	$ref->update();
}
sub doit_next {
	my($ref) = @_;

	$ref->set_doit($Today);
	$ref->update();
}
sub doit_done {
	my($ref) = @_;

	$ref->set_completed($Today);
	$ref->update();
}

sub doit_someday {
	my($ref) = @_;

	$ref->set_isSomeday('y');
	$ref->set_doit($Later);
	$ref->update();
}

sub doit_now {
	my($ref) = @_;

	$ref->set_isSomeday('n');
	$ref->set_doit($Today);
	$ref->update();
}

sub doit_priority {
	my($ref) = @_;

	if ($ref->get_priority() == $Priority) {
		print $ref->get_tid() . ': ' . $ref->get_description() . 
			" already at priority $Priority\n";
		return;
	}

	$ref->set_priority($Priority);
	$ref->update();
}

sub list_all {
	my($action) = @_;
	my(@list);

	for my $ref (meta_sorted()) {
		next unless $ref->is_task();
##FILTER	next if $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;
		next if $pref->filtered();
		push(@list, $ref);

		last if (scalar @list >= $Limit);
	}

	&$action(@list);
}

		
sub doit_list {
	foreach my $ref (@_) {
		display_task($ref);

		last if $Limit-- <= 0;
	}

}


sub doit_help {
	print <<'EOF';
help    -- this help text
list    -- list next
later   -- skip this for a week
next    -- skip this for now
done    -- set them to done
someday -- set them to someday
now     -- set them to from someday

Options: 

pri :    -- Set priority
limit :  -- Set the doit limit to this number of items

EOF
}

1;  # don't forget to return a true value from the file
