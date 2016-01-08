package report

/*
NAME:

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

*/


import "gtd/task";
import "gtd/meta";
import "gtd/task";
import "gtd/option";
import "gtd/task";

my $Today = get_today(0);
my $Later = get_today(+7);
my $Priority = 0;
my $Limit = 2;

//## rethink totally
//## REWRITE --- scan list for \d+ and put in work list
//## if work list is empty  

//-- doit tracks which projects/actions have had movement
func Report_doit(args []string) {

	$Limit = option("Limit", 1);

	$= = lines();
	gtd.Meta_filter("+a:live", '^doitdate', "rpga");
	my($target) = 0;
	my($action) = \&doit_list;

	foreach my $arg (gtd.Meta_argv(@_)) {
		if ($arg =~ /^\d+$/) {
			my($ref) = meta.Find($arg);

			unless (defined $ref) {
				warn "$arg doesn't exits\n";
				next;
			}
			&$action($ref);
			++$target;
			next;
		}
		if ($arg eq "help") {
			doit_help();
			next;
		}
		if ($arg eq "list") {
			display_mode("d_lst");
			next;
		}
		if ($arg eq "task") {
			display_mode("task");
			next;
		}
		if ($arg eq "later") {
			$action = \&doit_later;
			next;
		}
		if ($arg eq "next") {
			$action = \&doit_next;
			next;
		}
		if ($arg eq "done") {
			$action = \&doit_done;
			next;
		}
		
		if ($arg eq "someday") {
			$action = \&doit_someday;
			next;
		}
		if ($arg eq "did") {
			$action = \&doit_now;
			next;
		}
		if ($arg eq "now") {
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
			set_option("Limit", $Limit);
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
		print $ref->get_tid() . ": " . $ref->get_description() . 
			" already at priority $Priority\n";
		return;
	}

	$ref->set_priority($Priority);
	$ref->update();
}

sub list_all {
	my($action) = @_;
	my(@list);

	for my $ref (gtd.Meta_sorted()) {
		next unless $ref->is_task();
//#FILTER	next if $ref->filtered();

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
		my($date) = $ref->get_doit() || $ref->get_created();
		display_task($ref, "{{doit|$date}}");

		last if $Limit-- <= 0;
	}

}


sub doit_help {
	print <<"EOF";
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
