package meta

import "fmt"
import "log"
import "regexp"
import "sort"
import "strconv"
import "strings"

import "gtd/task"
import "gtd/option"
import "gtd/display"

//?	@EXPORT      = qw(
//?		&tasks_by_type
//?		&meta_matching_type
//?		&meta_selected &meta_sorted
//?		&meta_find &meta_all
//?		&meta_filter &meta_desc &meta_argv
//?		&meta_reset_filters
//?		&meta_pick

var meta_Debug = false
var _ = option.DebugVar("meta", &meta_Debug)

//var meta_Filter = "+live"

// use base qw(Hier::Hier Hier::Fields Hier::Filter)

//==============================================================================
//==== Top level filter/sort/selection
//==============================================================================
var meta_Selected task.Tasks
var Default_filter string

/*?
sub hier {
	return grep { $_->is_hier() } selected()
}
?*/

// meta.Reset_filters clears the set of filtered tasks
func Reset_filters() {
	// nothing is selected/sorted.
	meta_Selected = task.Tasks{}
}

// meta.Selected returns the set of filtered/sorted tasks
func Selected() task.Tasks {
	if len(meta_Selected) > 0 {
		return meta_Selected
	}

	all := task.All()
	selected := make(task.Tasks, 0, len(all))

	for _, t := range all {
		if t.Filtered() {
			continue
		}
		selected = append(selected, t)
	}

	meta_Selected = selected
	sort.Sort(meta_Selected)

	return meta_Selected
}

func Sort(list task.Tasks) task.Tasks {
	sort.Sort(list)
	return list
}

// meta.Matching_type return a set of tasks matching the requested type
func Matching_type(kind byte) task.Tasks {
	selected := Selected()
	list := make(task.Tasks, 0, len(selected))

	for _, t := range selected {
		if t.Type == kind {
			list = append(list, t)
		}
	}
	sort.Sort(list)
	return list
}

func All() task.Tasks {
	return task.All()
}

// meta.Find map a string taskid to a Task * reporting on errors
func Find(task_id string) *task.Task {
	re_is_task_colon := regexp.MustCompile("^[0-9]+:$")

	if re_is_task_colon.MatchString(task_id) {
		task_id = task_id[:len(task_id)-1]
	}
	if task.MatchId(task_id) {
		tid, err := strconv.Atoi(task_id)
		if err != nil {
			fmt.Printf("Invalid task id: %s", task_id)
			return nil
		}
		if t := task.Find(tid); t != nil {
			return t
		}

		fmt.Printf("No such task: %s", task_id)
		return nil
	}

	fmt.Printf("Invalid task id: %s", task_id)
	return nil
}

//==============================================================================

/*?
sub delete_hier {
	panic("###ToDo Broked, should be deleting by categories?\n")
	foreach my $tid (@_) {
		my $ref = Hier::Tasks::find{$tid}
		if (defined $ref) {
			warn "Category $tid deleted\n"

			$ref->delete()

		} else {
			warn "Category $tid not found\n"
		}
	}
}
?*/

//==============================================================================
//==============================================================================
//==== filter setup and processing
//==============================================================================

// meta.Filter is used by reports to sets the
//     default task filter, sort order, and display mode
func Filter(filter, sort, display_mode string) {
	mdebug("meta.Filter: %s, %s, %s\n", filter, sort, display_mode)

	task.Sort_mode(option.Get("Sort", sort))
	display.Mode(option.Get("Format", display_mode))

	option.Set("Filter", filter)
	Default_filter = filter
}

func Argv(args []string) []string {

	ret := make([]string, 0, len(args))

	for len(args) > 0 {
		// $_ = shift @_
		arg := args[0]
		args = args[1:]

		if arg == "!." {
			panic("Stopped.\n")
		}

		if arg[0] == '@' {
			task.Set_filter_context(arg[1:])
			continue
		}

		if task.MatchId(arg) {
			ret = append(ret, arg)
			continue
		}

		if arg[0] == '/' { // pattern match
			ret = append(ret, find_pattern(arg[1:])...)
			continue
		}

		if arg[0:1] == "=/" { // pattern match
			ret = append(ret, find_pattern(arg[2:])...)
			continue
		}

		//	if (s=^\*==) {
		//		my($type) = lc(substr($_, 0, 1))
		//		$type = type_name($_)
		//		print "Type ========($type)=:  $_\n"
		//		set_option(Type => $type)
		//		next
		//	}

		//	if (s/^([A-Z])://) {
		//		my($type) = lc($1)
		//			set_option(Type => $type)
		//
		//			print "Type: Title =====:  $type: $_\n"
		//			set_option(Title -> $_)
		//				push(@ret, find_hier($type, $_))
		//	next
		//		}

		// add include/exclude
		if arg[0] == '-' || arg[0] == '+' {
			//? task.Set_filter(arg)
			continue
		}

		//	if ($Title) {
		//		print "Desc:  ", join(' ', $_, @_), "\n"
		//		return join(' ', $_, @_)
		//	}

		ret = append(ret, arg)
	}

	task.Apply_filters()

	return ret
}

func Desc(args []string) string {
	return strings.Join(Argv(args), " ")
}

func Walk(args []string) *task.Walk {
	w := task.NewWalk()

	var top task.Tasks

	for _, criteria := range Argv(args) {
		if criteria == "all" {
			option.Set("Filter", "+all")
			continue
		}
		if task.MatchId(criteria) {
			t := Find(criteria)
			if t != nil {
				if t.Type == 'm' {
					w.Level = 1
				} else {
					w.Level = 2
				}
				top = append(top, t)
				w.Set_depth(map_depth(t.Type))
			}
		} else {
			want := task.Type_val(criteria)
			if want != 0 {
				w.Set_depth(map_depth(want))
			} else {
				panic("unknown type " + criteria)
			}
		}
	}

	if len(top) == 0 {
		top = Current()
		if len(top) > 0 {
			w.Set_depth(map_depth(top[0].Type))
		} else {
			top = Matching_type('m')
			w.Set_depth('o')
		}
	}
	w.Top = top
	return w
}

func map_depth(depth byte) byte {
	//	if depth != 0 {
	//		return depth
	//	}

	//	want := 'm'

	switch depth {
	case 'o': // role
		return 'g'
	case 'g': // goal
		return 'p'
	case 'p': // project
		return 'a'
	case 's': // sub project
		return 'a'
	default:
		return 'o'
	}
}

func Pick(args []string) task.Tasks {
	list := task.Tasks{}

	for _, arg := range Argv(args) {

		// task,task,task...
		if task.Is_comma_list(arg) {
			for _, arg := range strings.Split(arg, ",") {
				t := Find(arg)
				if t == nil {
					continue
				}
				list = append(list, t)
			}
			continue
		}

		// task all by itself
		//? if ($arg=~ s/^(\d+):$/$1/ or $arg =~ m/^\d+$/) {
		if task.MatchId(arg) {
			t := Find(arg)
			if t == nil {
				panic("Task " + arg + " doesn't exits\n")
			}
			list = append(list, t)
			continue
		}

		//		if check_option(arg, "priority") {
		//			continue
		//		}
		//		if check_option(arg, "pri") {
		//			continue
		//		}
		/*?
		  if ($arg =~ /pri\D+(\d+)/) {
			set_option("Priority", $1)
			  next
		  }
		  if ($arg =~ /limit\D+(\d+)/) {
			  set_option("Limit", $1)
			  next
		  }
		  if ($arg =~ /format\s(\S+)/) {
			  set_option("Format", $1)
			  next
		  }
		  if ($arg =~ /header\s(\S+)/) {
			  set_option("Header", $1)
			  next
		  }
		  ?*/

		want := task.Type_val(arg)
		if want != 0 {
			for _, t := range Matching_type(want) {
				if t.Filtered() {
					continue
				}
				list = append(list, t)
			}
			continue
		}
		panic("**** Can't understand argument: " + arg)
	}

	if len(list) == 0 {
		list = Current()
	}

	mdebug("meta.Pick: %v\n", list)
	return list
}

func find_pattern(pat string) []string {
	l := len(pat) - 1
	if pat[l] == '/' { // remove trailing /
		pat = pat[:l]
	}

	list := []string{}

	re, err := regexp.Compile("(?i)" + pat)
	if err != nil {
		fmt.Printf("Invalid pattern for search %s\n", pat)
		return list
	}

	for _, t := range task.All() {
		if re.MatchString(t.Title) {
			s := strconv.Itoa(t.Tid)
			list = append(list, s)

			//warn "Added($tid): /$pat/ =~ $title\n" if $Debug
		}
	}
	return list
}

/*?

sub find_hier {
	my($type, $pat) = @_

	$pat =~ s=/$==;	// remove trailing /

	my(@list)

	for my $ref (Hier::Tasks::all()) {
		next unless $ref->is_hier()
		next unless match_type($type, $ref)

		my($title) = $ref->get_title()
		if ($title =~ /$pat/i) {
			my($tid) = $ref->get_tid()
			push(@list, $tid)
			warn "Added($tid): /$pat/ =~ $title\n" if $Debug
		}
	}
	return @list
}
?*/

func match_type(want byte, ref *task.Task) bool {
	kind := ref.Type

	if kind == want {
		return true
	}

	if kind == 'm' && want == 'v' {
		return true
	}
	if kind == 'o' && want == 'r' {
		return true
	}

	return false
}

//---------------------------------------------------------------------------
//  Track current task
//---------------------------------------------------------------------------
var meta_Current task.Tasks

// meta.Current tracks the current task
func Current() task.Tasks {
	return meta_Current
}

// meta.Set_current set the current task to the list passed
func Set_current(list task.Tasks) {
	meta_Current = list
}

func mdebug(f string, v ...interface{}) {
	if !meta_Debug {
		return
	}
	log.Printf(f, v...)
}
