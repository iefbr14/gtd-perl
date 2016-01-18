package rc

/*
NAME:

rc

=head1 USAGE

rc

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

rc is

=head1 DIAGNOSTICS

=head1 EXIT STATUS

none

=head1 CONFIGURATION

=item format

=item option

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR,  LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

Started life as a copy of the bulkload but tuned for more interactive processing

*/

import "os"
import "os/exec"
import "fmt"
import "regexp"
import "strings"

import "gtd/task"
import "gtd/meta"
import "gtd/display"
import "gtd/option"

//? use Term::ReadLine
import "github.com/chzyer/readline"

//? use Hier::Prompt

var Parent *task.Task
var Child *task.Task
var Type byte
var Info = map[string]string{}

var Mode = option.Get("Mode", "task")

var Filter string = "-"
var Format string = "-"
var Header string = "-"
var Sort_mode string = "-"

var Prompt string = "> "
var Debug bool = true

var Pid int = 0     // current Parrent task
var Pref *task.Task // current Parrent task reference

var Parents = map[byte]*task.Task{} // parents we know about

var rc_cmds_map = map[string]func(...string){
	"help": rc_help,

	"up": rc_up,
	"p":  rc_print,

	"option": rc_option,
	"filter": rc_filter,
	"format": rc_format,
	"sort":   rc_sort,
}

//-- rc - Run Commands
func Report_rc(args []string) int {
	// init from command line.
	// there are commands to override later
	Filter = option.Get("Filter", "-")
	Format = option.Get("Format", "-")
	Sort_mode = option.Get("Sort", "-")

	rl, err := readline.New(Prompt)
	if err != nil {
		panic(err)
	}
	defer rl.Close()

	for {
		line, err := rl.Readline()
		if err != nil { // io.EOF
			break
		}
		rc(line)
	}
	rc_save()
	return 0
}

func rc(line string) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("Recovered from: %v\n", line)
		}
	}()

	//## skip blank lines, comments
	if task.EmptyLine(line) {
		return
	}

	//## remove leading white space from commands.
	line = strings.Trim(line, " \t")

	//##   :cmd  =>  rc command mode (noop here)
	if line[0] == ':' {
		line = line[1:]
		//## continue this is redundent
	}

	if line[0] == '?' {
		rc_help(line[1:])
		return
	}

	//##   .tid  =>  kanban .tid
	if line[0] == '.' {
		args := strings.Split(line, " \t")
		Do_report("kanban", args)
		return
	}

	//##   /key  =>  search  key
	if line[0] == '/' {
		rc_find_tasks(line)
		return
	}

	//##   !cmd  =>  shell out for cmd
	if line[0] == '!' {
		if err := exec.Command(line[1:]).Run(); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		return
	}

	// check for task member updates ie: "key:value" pairs
	if key, _ := task.IsKeyValue(line); key != "" {
		fmt.Println("key:val not supported")
		//?if (line =~ s/^(\w+)\:\s*//)
		//?rc_set_key(r[0], line)
		return
	}

	args := strings.SplitN(line, " \t:", 2)
	cmd := args[0]

	if cmd == "clear" {
		fmt.Print("\x1b[H\x1b[2J")

		args = strings.SplitN(args[1], " \t", 2)
		cmd = args[0]
		//# continue as if gtd or clear  wasn't said
	}

	if cmd == "set" || cmd == "gtd" {
		args = strings.SplitN(args[1], " \t", 2)
		cmd = args[0]
		//# continue as if set wasn't said
	}

	if cmd == "debug" {
		if len(args) > 0 {
			option.Debug(args[0])
			return
		}

		Debug = true
		fmt.Print("Debug rc on\n")
		return
	}

	if rc, ok := rc_cmds_map[cmd]; ok {
		rc(args[1])
		return
	}

	if task.IsTask(cmd) {
		load_task(cmd)
		return
	}

	rc_save()
	args = strings.Split(args[1], " \t")
	Do_report(args[0], args[1:])
}

func rc_set_key(args ...string) {
	key := args[0]

	if Pref == nil {
		fmt.Print("No task set.\n")
		return
	}
	//Pref.set_KEY(key, task.Join(args[1:]...)
	Pref.Set_KEY(key, args[1])
}

func rc_save() {
	if Pref == nil {
		return
	}

	if Pref.Is_dirty() {
		Pref.Update()
	}
}

func rc_help(args ...string) {
	if len(args) > 0 {
		//		Do_report("help", args)
		return
	}

	fmt.Print(`
   #        comments (and blank lines ignored)
   !        shell commands
   /        search and set task
   .tid     kanban bump tid

   clear     clear screen before running command
   option    set option
   format    to set default formats
   sort      to set default sort order

   999       to set current task
   p         to print current task
   up        to go to current task's parent
   field:    to change any field in the current task

   ....      to run any current report
`)
}

func rc_up(args ...string) {
	if Pref == nil {
		fmt.Print("No task set.\n")
		return
	}

	load_task_ref("Parent", Pref.Parent())
}

func rc_option(args ...string) {
	key := args[0]
	val := args[1]

	old := option.Get(key, val)

	fmt.Printf("Option option: %s => %s\n", old, val)
}

func rc_print(args ...string) {
	if len(args) == 0 {
		display.Task(Pref, "")
		return
	}

	for _, task_id := range args {
		t := meta.Find(task_id)

		if t == nil {
			fmt.Print("? not found: ref\n")
			continue
		}
		display.Task(t, "")
	}
}

//==============================================================================
// Mode setting
//------------------------------------------------------------------------------
func rc_filter(args ...string) {
	if len(args) == 0 {
		fmt.Printf("Filter: %s\n", Filter)
		return
	}

	mode := args[0]

	fmt.Printf("Filter %s => %s\n", Filter, mode)

	option.Set("Filter", dash_null(mode))
	if mode == "-" {
		//? meta.Reset_filters("+live")
	} else {
		//? meta.Reset_filters(mode)
	}

	Filter = mode
}

func rc_format(args ...string) {
	if len(args) == 0 {
		fmt.Printf("Format: %s\n", Format)
		return
	}

	mode := args[0]

	fmt.Printf("Format %s => %s\n", Format, mode)

	option.Set("Format", dash_null(mode))

	if mode == "-" {
		display.Mode("task")
	} else {
		display.Mode(mode)
	}

	Format = mode
}

func rc_header(args ...string) {
	if len(args) == 0 {
		fmt.Printf("Header: %s\n", Header)
		return
	}

	mode := args[0]

	fmt.Printf("Header %s => %s\n", Header, mode)

	option.Set("Header", dash_null(mode))

	/*
		if mode == "-" {
			display.Mode("task")
		} else {
			display.Mode(mode)
		}
	*/

	Header = mode
}

func rc_sort(args ...string) {
	if len(args) == 0 {
		fmt.Print("Sort: %s\n", Sort_mode)
		return
	}
	mode := args[0]

	fmt.Printf("Sort %s => %s\n", Sort_mode, mode)

	option.Set("Sort", dash_null(mode))
	//?sort_mode(mode == '-" ? "^title' : mode)

	Sort_mode = mode
}

//==============================================================================
// Utility builtins
//------------------------------------------------------------------------------

func rc_prompt(args ...string) {
	Prompt = args[0]
}

func load_task(tid string) {
	rc_save()

	// get context
	t := meta.Find(tid)
	if t == nil {
		fmt.Print("Can't find tid: tid\n")
		return
	}

	meta.Set_current(task.Tasks{t})
}

func load_task_ref(why string, t *task.Task) {
	Pref = t
	Pid = t.Tid

	kind := t.Type
	title := t.Title

	Parents[kind] = Pref

	Prompt = fmt.Sprintf("%d> ")
	// rb.SetPrompt(Prompt)
	meta.Set_current(task.Tasks{Pref})
	//	option.Set("Current", Pid)

	fmt.Printf("%s(%c): %s - %s\n", why, kind, Pid, title)
}

//==============================================================================

func fixme() {
	/*?
	my(action) = \&add_nothing
	my(desc) = ''

	my(@lines)

	//---------------------------------------------------
	// default values
	if (/^pri\D+(\d+)/) {
		option.Set("Priority", 1)
		next
	}
	if (/^limit\D+(\d+)/) {
		option.Set("Limit", 1)
		next
	}
	if (/^format\s(\S+)/) {
		option.Set("Format", 1)
		next
	}
	if (/^header\s(\S+)/) {
		option.Set("Header", 1)
		next
	}

	if (/^sort\s(\S+)/) {
		option.Set("Header", 1)
		next
	}

	//---------------------------------------------------


	if (s=^([a-z]+):\s*==) {
		Info->{1} = _
		next
	}

	if (s==(\d+)\t[A-Z]:\s*==) {
		&action(Parents, desc)
		action = \&add_update
		Pid = 1
		Parents->{me} = Pid
		next
	}
	if (s=^R:\s*==) {
		&action(Parents, desc)

		Pid = find_hier('r', _)
		panic("No parge _") unless Pid
		Parents->{r} = Pid
		next
	}
	if (s=^G:\s*==) {
		&action(Parents, desc)

		Pid = find_hier('g', _)
		if (Pid) {
			action = \&add_nothing
			Parents->{g} = Pid
		} else {
			action = \&add_goal
		}
		next
	}
	if (s=^[P]:\s*==) {
		&action(Parents, desc)

		action = \&add_project
		option.Set(Title => _)
		desc = ''
		next
	}
	if (s=^\[_*\]\s*==) {
		&action(Parents, desc)

		action = \&add_action
		option.Set(Title => _)
		desc = ''
		next
	}
	desc .= "\n" . _
	*/
}

func rc_find_tasks(pattern string) {
	//***BUG*** remove trailing slash not correct in perl code
	// pattern =~ s=/==;	// remove trailing /

	re, err := regexp.Compile("(?i)" + pattern)
	if err != nil {
		fmt.Printf("RE Compile error %s: %s", pattern, err)
		return
	}

	for _, t := range task.All() {
		if re.MatchString(t.Title) {
			display.Task(t, "")
		}
	}
}

/*
func find_hier(kind, goal string) {

	for _, ref := meta.Hier() {
		if t.Type == kind && t.Title == goal {
			return t.Tid
		}
	}

	goal = strings.ToLower(goal)
	for _, ref := meta.Hier() {
		if t.Type == kind && t.Title == goal {
			return t.Tid
		}
	}

	for _, ref := meta.Hier() {
		if t.Title != goal {
			continue
		}

		fmt.Printf("Found: something close(%c) %d: %s\n" , t.Type, t.Tid, t.Title)
		return t.Tid
	}
	panic("Can"t find a hier item for "goal' let alone a type.\n")
}

func add_nothing() {
	my(parents, desc) = args

	// do nothing
	fmt.Print("# nothing pending\n" if Debug

	if desc != "" {
		fmt.Print("Lost description\n" if desc
	}
}

func add_goal() {
	my(parents, desc) = args
	my(tid)

	desc =~ s=^\n*==s

	Parent = parents->{'r'}

	tid = add_task('g', desc)

	parents->{'g'} = tid
}

func add_project() {
	my(parents, desc) = args
	my(tid)

	desc =~ s=^\n*==s

	Parent = parents->{'g'}

	tid = add_task('p', desc)

	parents->{'p'} = tid
}

func add_action() {
	my(parents, desc) = args
	my(tid)

	desc =~ s=^\n*==s
	Parent = parents->{'p'}

	tid = add_task('a', desc)
}

func add_task() {
	my(kind, desc) = args

	my(pri, title, category, note, line)

	title    = option("Title")
	pri      = option("Priority") || 4
	desc     = option("Desc") || desc

	category = option("Category") || ''
	note     = option("Note");

	my ref = Hier::Tasks->new(nil)

	t.set_category(category)
	t.set_title(title)
	t.set_description(desc)
	t.set_note(note)

	t.set_type(kind)

	if (pri > 5) {
		pri -= 5
		t.set_isSomeday('y')
	}
	t.set_nextaction('y') if pri < 3
	t.set_priority(pri)

	fmt.Print("Parent: Parent\n")

	Child = t.get_tid()

	t.set_parent_ids(Parent)

	fmt.Print("Created (type): ", t.get_tid(), "\n")

	for my key (keys %Info) {
		t.set_KEY(key, Info->{key})
	}
	Info = {}

	t.insert()
	return t.get_tid()
}

?*/
func Do_report(cmd string, args []string) {

	//?Hier::Tasks::clean_up_database()
	rfunc := Load_report(cmd)
	if rfunc == nil {
		return
	}

	if Debug {
		fmt.Printf("### Report %s args: %v\n", cmd, args)
	}

	// force options back to our defaults (including no defaults)
	option.Set("Filter", dash_null(Filter))
	option.Set("Format", dash_null(Format))
	option.Set("Header", dash_null(Header))
	option.Set("Sort", dash_null(Sort_mode))

	//	Cmds->{report} = \&"Report_report"

	Run_report(cmd, args)

	display.Mode(option.Get("Mode", "task"))
	//Hier::Tasks::reload_if_needed_database()
}

func dash_null(val string) string {

	if val == "-" {
		return ""
	}
	return val
}
func prepend(slice []string, new string) []string {
	return append([]string{new}, slice...)
}
