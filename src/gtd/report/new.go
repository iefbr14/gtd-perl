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
import "gtd/task"
import "gtd/prompt"
import "gtd/display"

var new_First = ""
var new_Parent *task.Task

//##BUG### ^c in new kills report rc

// Usage:
//    new                               # type: inbox
//    new task                          # type: task
//    new proj                          # type: proj
//    new        I have to do this      # type: inbox (done)
//    new task   I have to do this      # type: task (done)
// and we mix in with a parent:
//    new				// type: map parent
//    new task				// type: is task
//    new proj                           # type: is sub-project
//    new        I have to do this       # type: map parent (done)
//    new task   I have to do this       # type: is task (done)
//    new proj   I have to do this       # type: is proj (done)
//
// there are two paths here.  The first is the command line
// where everything is on the command line and is a one shot
// the other is the prompter version with defaults
//

//-- create a new action or project
func Report_new(args []string) int {
	meta.Filter("+all", "^tid", "none")

	var want byte = 0

	if len(args) > 0 {
		type_arg := task.Type_val(args[0])
		if type_arg != 0 {
			want = type_arg
			args = args[:1]
		}
	}

	parent := meta.Current()
	if len(parent) > 0 {
		new_Parent = parent[0]
		if want == 0 {
			want = new_Parent.Type
			switch want {
			case 'm':
				want = 'v'
			case 'v':
				want = 'o'
			case 'o':
				want = 'g'
			case 'g':
				want = 'p'
			case 'p':
				want = 'a'
			default:
				fmt.Printf("Won't create sub-actions of actions")
				return 1
			}
		}
	}

	if want == 0 {
		want = 'i' // still unknown at this point!
	}

	title := meta.Desc(args)
	//? title =~ s=^--\s*==

	fmt.Printf("new: want=%s title=%s\n", want, title)

	// command line path
	if title != "" {
		new_item(want, title)
		return 0
	}

	if want == 'a' || want == 'w' {
		New_action(want, "")
	} else {
		New_project(want, "")
	}
	return 0
}

// command line version, no prompting
func new_item(kind byte, title_parm string) {
	title := option.Get("Title", "")
	if title == "" {
		title = title_parm
	}
	pri := option.Int("Priority", 4)
	desc := option.Get("Desc", "")

	category := option.Get("Category", "")
	note := option.Get("Note", "")

	tid := next_avail_task(kind)
	t := task.New(tid)

	if pri > 5 {
		pri -= 5
		t.Set_isSomeday("y")
	} else {
		t.Set_isSomeday("n")
	}

	if kind == 'n' {
		kind = 'a'
		t.Set_nextaction("y")
	} else {
		t.Set_nextaction("n")
	}

	t.Set_type(string(kind))

	t.Set_priority(pri)

	t.Set_category(category)
	t.Set_title(title)
	t.Set_description(desc)
	t.Set_note(note)

	if new_Parent != nil {
		t.Add_parent(new_Parent)
	}
	t.Insert()

	fmt.Printf("Created: %d\n", t.Tid)
}

// detailed task
func New_action(kind byte, title_dflt string) {

	type_name := task.Type_name(kind)

	first("Enter " + type_name + ": Task, Desc, Category, Notes...")

	title := input("Title", option.Get("Title", title_dflt))
	//pri := input("Priority", option.Get("Priority", "4"))
	pri := 4
	desc := prompt_desc("Desc", "")

	category := input("Category", option.Get("Category", ""))
	note := prompt_desc("Note", option.Get("Note", ""))

	tid := next_avail_task('a')
	t := task.New(tid)

	if kind == 'n' {
		kind = 'a'
		t.Set_nextaction("y")
	} else {
		t.Set_nextaction("n")
	}
	t.Set_type(string(kind)) // action/inbox/wait

	if pri > 5 {
		pri -= 5
		t.Set_isSomeday("y")
	} else {
		t.Set_isSomeday("n")
	}
	t.Set_priority(pri)
	t.Set_category(category)
	t.Set_title(title)
	t.Set_description(desc)
	t.Set_note(note)

	if new_Parent != nil {
		t.Add_parent(new_Parent)
	}
	t.Insert()

	fmt.Printf("Created: %d\n", t.Tid)
}

func New_project(kind byte, title_dflt string) {

	kind_name := task.Type_name(kind)

	first("Enter " + kind_name + ": Category, Title, Description, Outcome...")

	category := input("Category", option.Get("Category", ""))
	title := input("Title", option.Get("Title", title_dflt))
	//pri := option.Get("Priority", "4")
	pri := 4

	desc := prompt_desc("Description", option.Get("Desc", ""))
	note := prompt_desc("Outcome", option.Get("Note", ""))

	tid := next_avail_task(kind)
	t := task.New(tid)

	t.Set_type(string(kind))
	t.Set_nextaction("n")
	t.Set_isSomeday("n")

	t.Set_priority(pri)
	t.Set_category(category)
	t.Set_title(title)
	t.Set_description(desc)
	t.Set_note(note)

	if new_Parent != nil {
		t.Add_parent(new_Parent)
	}
	t.Insert()

	fmt.Printf("Created: %d\n", t.Tid)
}

func first(text string) {
	new_First = text + "\n" +
		"  enter ^D to stop, entry not added\n" +
		"  use '.' to stop adding notes.\n"
}

func prompt_desc(p string, dflt string) string {
	if dflt != "" {
		return dflt
	}
	text := ""

	line, err := prompt.Prompt(p, false)
	for ; err != nil; line, err = prompt.Prompt("+", false) {
		if line == "." {
			break
		}

		text += line + "\n"
	}
	return display.Chomp(text)
}

func input(p string, dflt string) string {
	if dflt != "" {
		return dflt
	}

	p = fmt.Sprintf("Add %-9s", p+":")

	if new_First != "" {
		fmt.Print(new_First)
		new_First = ""
	}

	line, err := prompt.Prompt(p, true)
	if err != nil {
		return dflt
	}
	return line
}
