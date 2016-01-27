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

import "fmt"

import "gtd/meta"
import "gtd/option"
import "gtd/display"
import "gtd/task"

var (
	doit_Today    string
	doit_Later    string
	doit_Priority int
	doit_Limit    int
)

//## rethink totally
//## REWRITE --- scan list for \d+ and put in work list
//## if work list is empty

//-- doit tracks which projects/actions have had movement
func Report_doit(args []string) int {
	meta.Filter("+a:live", "^doitdate", "rpga")

	doit_Today = option.Today(0)
	doit_Later = option.Today(+7)
	doit_Priority = option.Int("Priority", 4)
	doit_Limit = option.Int("Limit", 1)

	//? $= = lines()
	target := 0
	var action func(*task.Task) = doit_list

	for _, arg := range meta.Argv(args) {
		if task.MatchId(arg) {
			t := meta.Find(arg)
			if t == nil {
				continue
			}

			action(t)
			target++
			continue
		}
		if arg == "help" {
			doit_help()
			continue
		}
		if arg == "list" {
			display.Mode("d_lst")
			continue
		}
		if arg == "task" {
			display.Mode("task")
			continue
		}
		if arg == "later" {
			action = doit_later
			continue
		}
		if arg == "next" {
			action = doit_next
			continue
		}
		if arg == "done" {
			action = doit_done
			continue
		}

		if arg == "someday" {
			action = doit_someday
			continue
		}
		if arg == "did" {
			action = doit_now
			continue
		}
		if arg == "now" {
			action = doit_now
			continue
		}
		/*?
		if (arg =~ /pri\D+(\d+)/) {
			$Priority = $1
			action = doit_priority
			continue
		}
		if (arg =~ /limit\D+(\d+)/) {
			$Limit = $1
			set_option("Limit", $Limit)
			continue
		}
		?*/
		fmt.Printf("Unknown option: %s (ignored) (try help)\n", arg)
	}
	if target == 0 {
		list_all(action)
	}
	return 0
}

func doit_later(t *task.Task) {
	t.Set_doit(doit_Later)
	t.Update()
}
func doit_next(t *task.Task) {
	t.Set_isSomeday("n")
	t.Set_doit(doit_Today)
	t.Update()
}
func doit_done(t *task.Task) {
	t.Set_completed(doit_Today)
	t.Update()
}

func doit_someday(t *task.Task) {
	t.Set_isSomeday("y")
	t.Set_doit(doit_Later)
	t.Update()
}

func doit_now(t *task.Task) {
	t.Set_isSomeday("n")
	t.Set_doit(doit_Today)
	t.Update()
}

func doit_priority(t *task.Task) {
	if t.Priority == doit_Priority {
		fmt.Printf("%d: %s already at priority %d\n",
			t.Tid, t.Title, doit_Priority)
		return
	}

	t.Set_priority(doit_Priority)
	t.Update()
}

func list_all(action func(*task.Task)) {
	list := task.Tasks{}

	for _, t := range meta.Selected() {
		if !t.Is_task() {
			continue
		}
		//#FILTER	next if t->filtered()

		pref := t.Parent()
		if pref == nil {
			continue
		}
		if pref.Filtered() {
			continue
		}
		list = append(list, t)

		if len(list) >= doit_Limit {
			break
		}
	}

	for _, t := range list {
		action(t)
	}
}

func doit_list(t *task.Task) {
	date := t.Doit
	if date == "" {
		date = t.Created
	}
	display.Task(t, "{{doit|"+date+"}}")
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
