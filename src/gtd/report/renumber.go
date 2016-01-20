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

//?	@EXPORT      = qw(&Report_renumber &next_avail_task)

import "fmt"
import "regexp"
import "strconv"
import "strings"

import "gtd/meta"
import "gtd/task"

type renumber_Dep_T struct {
	test func(*task.Task) bool
	min  int
	max  int
	who  string
}

var renumber_Dep_info = map[byte]renumber_Dep_T{
	'a': {is_action, 2000, 9999, "Actions"},
	's': {is_subject, 1000, 1999, "Sub-Projects"},
	'p': {is_project, 200, 999, "Projects"},
	'g': {is_goals, 30, 199, "Goals"},
	'o': {is_roles, 10, 29, "Roles"},
	'v': {is_vision, 5, 9, "Vision"},
	'm': {is_value, 1, 4, "Values"},
}

var Dep_map = map[int]bool{}

//-- Renumber task Ids
func Report_renumber(args []string) int {
	meta.Filter("+any", "^tid", "none")

	list := meta.Argv(args)

	if len(list) > 0 {
		for _, pair := range list {
			renumber_pair(pair)
		}
	} else {
		renumber_all()
	}
	return 0
}

func renumber_all() {
	// -- Renumber task Ids
	renumb('a') // Actions
	renumb('s') // Sub-Projects
	renumb('p') // Projects
	renumb('g') // Goals
	renumb('o') // roles
	renumb('v') // Vision
	renumb('m') // Values
}

func renumber_pair(pair string) {
	re := regexp.MustCompile(`^(\d+)=(\d+)`)

	r := re.FindStringSubmatch(pair)
	if len(r) == 2 {
		to, tid := r[0], r[1]

		renumber_task_id(tid, to)
	} else {
		renumber_a_task(pair)
	}
}

func is_value(t *task.Task) bool {
	if t.Type == 'm' { // Value
		return true
	}
	return false
}

func is_vision(t *task.Task) bool {
	if t.Type == 'v' { // Vision
		return true
	}
	return false
}

func is_roles(t *task.Task) bool {
	if t.Type == 'o' { // Role
		return true
	}
	return false
}

func is_goals(t *task.Task) bool {
	if t.Type == 'g' { // Goal
		return true
	}
	return false
}

func is_project(t *task.Task) bool {
	if t.Type != 'p' { // Project
		return false
	}

	// return 1 iff any parents are not project
	for _, pt := range t.Parents {
		if pt.Type != 'p' { // Project
			// a Parrent != Project
			return true
		}
	}

	// is a project and some parent is not projects
	return false
}

func is_subject(t *task.Task) bool {
	if t.Type != 'p' { // ! Project
		return false
	}

	// return true iff all parents are projects
	for _, pt := range t.Parents {
		if pt.Type != 'p' { // Parrent is project
			return false
		}
	}

	// is a project and all parents are projects
	return true
}

func is_action(t *task.Task) bool {
	return t.Is_task()
}

func next_avail_task(kind byte) int {
	switch kind {
	case 'n':
		kind = 'a' // next action => min action
	case 'w':
		kind = 'a' // wait        => min action
	}

	r, ok := renumber_Dep_info[kind]
	if !ok {
		panic(fmt.Sprintf("***BUG*** next_avail_task: Unknown type %c", kind))
	}

	for tid := r.min; tid <= r.max; tid++ {
		if t := task.Find(tid); t != nil {
			continue
		}

		return tid
	}
	return 0
}

func renumb(kind byte) {
	r, ok := renumber_Dep_info[kind]
	if !ok {
		panic(fmt.Sprintf("***BUG*** renumb: Unknown type %c", kind))
	}

	fmt.Printf("Processing %c range %d %d\n", r.who, r.min, r.max)

	test := r.test
	inuse := map[int]bool{}

	try := make([]int, 0, 10)
	for _, t := range task.All() {
		tid := t.Tid

		if r.min <= tid && tid <= r.max {
			inuse[tid] = true
		}

		//##BUG### need to check if filtered
		if tid < r.min {
			if test(t) {
				try = append(try, tid)
				continue
			}
		}
		if tid > r.max {
			if test(t) {
				try = append(try, tid)
				continue
			}
		}
	}
TASK:
	for _, tid := range try {
		for min := r.min; min < r.max; {
			if inuse[min] {
				min++
				continue
			}

			renumber_task(tid, min)

			inuse[tid] = false
			inuse[min] = true
			min++
			continue TASK
		}
		fmt.Printf("Out of slots for %d\n", r.who)
		return
	}
	fmt.Printf("Completed %d\n", r.who)
}

func renumber_a_task(task_id string) {

	t := meta.Find(task_id)
	if t == nil {
		panic("Can't renumber task $task_id (doesn't exists)\n")
	}

	if dependent(t) {
		panic("Can't renumber task $task_id (has depedencies)\n")
	}

	kind := t.Type

	new := next_avail_task(kind)

	if t.Tid < new {
		fmt.Printf("First slot %d > task %d tid (skipped)\n", new, task_id)
		return
	}

	fmt.Printf("%d => %d\n", t.Tid, new)

	t.Set_tid(new)
	t.Update()
}

func renumber_task_id(task_id, new_id string) {

	t := meta.Find(task_id)
	if t == nil {
		panic("Can't renumber task $task_id (doesn't exists)\n")
	}
	if dependent(t) {
		panic("Can't renumber task $task_id (has depedencies)\n")
	}
	fmt.Printf("%s => %d\n", task_id, new_id)
	new, _ := strconv.Atoi(new_id)
	renumber_task(t.Tid, new)
}

func renumber_task(tid, new int) {
	t := task.Find(tid)
	t.Set_tid(new)
	t.Update()
}

func dependent(t *task.Task) bool {

	id := t.Tid

	if len(Dep_map) > 0 {
		return Dep_map[id]
	}
	fmt.Printf("Building Dep_map\n")

	//		my($pt, $pid, $depends)
	for _, pt := range meta.All() {

		depends := pt.Depends
		// pid := pt.Tid

		for _, depend := range strings.Split(depends, " ,") {
			did, _ := strconv.Atoi(depend)
			Dep_map[did] = true // .= ','.$pid
		}
	}

	return Dep_map[id]
}
