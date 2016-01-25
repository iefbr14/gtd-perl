package meta

import "fmt"
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

// meta.Selected returns the set of selected tasks
func Selected() task.Tasks {
	if len(meta_Selected) > 0 {
		return meta_Selected
	}

	meta_Selected = Filtered()
	return meta_Selected
}

// meta.Filtered returns the set of filtered tasks
func Filtered() task.Tasks {
	all := task.All()
	selected := make(task.Tasks, 0, len(all))

	for _, t := range all {
		if t.Filtered() {
			continue
		}
		selected = append(selected, t)
	}

	return selected
}

// meta.Sorted returns the set of selected tasks sorted
func Sorted() task.Tasks {
	list := Selected()
	sort.Sort(list)
	return list
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
	if task.IsTask(task_id) {
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
	fmt.Printf("... meta.Filter: %s, %s, %s\n", filter, sort, display_mode)

	task.Sort_mode(option.Get("Sort", sort))
	display.Mode(option.Get("Format", display_mode))

	option.Set("Filter", filter)
	Default_filter = filter
}

func Argv(args []string) []string {
	return args

	ret := make([]string, 0, len(args))

	has_filters := false
	/*?

	  	local($_)

	  	Hier::Filter::add_filter_tags()
	  	while (scalar(@_)) {
	  		$_ = shift @_

	  		next unless defined $_;	 # option("Current") may be undef

	  		if ($_ eq "!.") {
	  			painc("Stopped.\n")
	  		}

	  		if (s/^\@//) {
	  			Hier::Filter::meta_find_context($_)
	  			next
	  		}

	  		if (s/^(\d+:)$/$1/ or m/^\d+$/) {
	  			push(@ret, $_);		// tid
	  			next
	  		}

	  		if (s=^\/==) {				// pattern match
	  			push(@ret, find_pattern($_))
	  			next
	  		}

	  		if (s|^=\/||) {				// pattern match
	  			push(@ret, find_pattern($_))
	  			next
	  		}


	  		if (s=^\*==) {
	  			my($type) = lc(substr($_, 0, 1))
	  			$type = type_name($_)
	  			print "Type ========($type)=:  $_\n"
	  			set_option(Type => $type)
	  			next
	  		}
	  		if (s/^([A-Z])://) {
	  			my($type) = lc($1)
	  //			set_option(Type => $type)
	  //
	  //			print "Type: Title =====:  $type: $_\n"
	  //			set_option(Title -> $_)
	  			push(@ret, find_hier($type, $_))
	  			next
	  		}

	  		if (m/^[-~+]/) {		// add include/exclude
	  			Hier::Filter::add_filter($_)
	  			has_filters = true
	  			next
	  		}
	  //		if ($Title) {
	  //			print "Desc:  ", join(' ', $_, @_), "\n"
	  //			return join(' ', $_, @_)
	  //		}
	  		push(@ret, $_)
	  	}

	  ?*/

	if !has_filters {
		task.Add_filter(Default_filter)
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
		if task.IsTask(criteria) {
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
		if task.IsTask(arg) {
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

	//***debug*** log.Printf("meta.Pick: %v\n", list)
	return list
}

/*?
sub find_pattern {
	my($pat) = @_

	$pat =~ s=/$==;	// remove trailing /

	my(@list)

	for my $ref (Hier::Tasks::all()) {
		my($title) = $ref->get_title()
		if ($title =~ /$pat/i) {
			my($tid) = $ref->get_tid()
			push(@list, $tid)
			warn "Added($tid): /$pat/ =~ $title\n" if $Debug
		}
	}
	return @list
}

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
