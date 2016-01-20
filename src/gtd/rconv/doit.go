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

import "gtd/meta"
import "gtd/option"
import "gtd/task"

/*?

my $Today = get_today(0)
my $Later = get_today(+7)
my $Priority = 0
my $Limit = 2

//## rethink totally
//## REWRITE --- scan list for \d+ and put in work list
//## if work list is empty

?*/
//-- doit tracks which projects/actions have had movement
func Report_doit(args []string) int {
	meta.Filter("+a:live", "^doitdate", "rpga")

	Limit = option("Limit", 1)
	/*?
	$= = lines()
	my($target) = 0
	my($action) = \&doit_list

	foreach my $arg (meta.Argv(args))) {
		if ($arg =~ /^\d+$/) {
			my(t) = meta.Find($arg)

			unless (defined t) {
				warn "$arg doesn't exits\n"
				next
			}
			&$action(t)
			++$target
			next
		}
		if ($arg == "help") {
			doit_help()
			next
		}
		if ($arg == "list") {
			display_mode("d_lst")
			next
		}
		if ($arg == "task") {
			display_mode("task")
			next
		}
		if ($arg == "later") {
			$action = \&doit_later
			next
		}
		if ($arg == "next") {
			$action = \&doit_next
			next
		}
		if ($arg == "done") {
			$action = \&doit_done
			next
		}

		if ($arg == "someday") {
			$action = \&doit_someday
			next
		}
		if ($arg == "did") {
			$action = \&doit_now
			next
		}
		if ($arg == "now") {
			$action = \&doit_now
			next
		}
		if ($arg =~ /pri\D+(\d+)/) {
			$Priority = $1
			$action = \&doit_priority
			next
		}
		if ($arg =~ /limit\D+(\d+)/) {
			$Limit = $1
			set_option("Limit", $Limit)
			next
		}
		print "Unknown option: $arg (ignored) (try help)\n"
	}
	if ($target == 0) {
		list_all($action)
	}
	?*/
}

func doit_later(t *task.Task) {
	t.Set_doit(Later)
	t.Update()
}
func doit_next(t *task.Task) {
	t.Set_doit(Today)
	t.Update()
}
func doit_done(t *task.Task) {
	t.Set_completed(Today)
	t.Update()
}

func doit_someday(t *task.Task) {
	t.Set_isSomeday(true)
	t.Set_doit(Later)
	t.Update()
}

func doit_now(t *task.Task) {
	t.Set_IsSomeday(true)
	t.Set_doit(Today)
	t.Update()
}

func doit_priority(t *task.Task) {
	/*?
	my(t) = @_

	if (t->get_priority() == $Priority) {
		print t->get_tid() . ": " . t->get_description() .
			" already at priority $Priority\n"
		return
	}

	t->set_priority($Priority)
	t->update()
	?*/
}

func list_all() {
	/*?
	  	my($action) = @_
	  	my(@list)

	  	for my t (meta.orted()) {
	  		next unless t->is_task()
	  //#FILTER	next if t->filtered()

	  		my $pref = t->get_parent()
	  		next unless defined $pref
	  		next if $pref->filtered()
	  		push(@list, t)

	  		last if (scalar @list >= $Limit)
	  	}

	  	&$action(@list)
	  ?*/
}

func doit_list() {
	/*?
		foreach my t (@_) {
			my($date) = t->get_doit() || t->get_created()
			display_task(t, "{{doit|$date}}")

			last if $Limit-- <= 0
		}

	?*/
}

func doit_help() {
	display.Text(`
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
`)
}
