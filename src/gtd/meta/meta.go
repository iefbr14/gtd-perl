package meta

import	"log"
import	"fmt"
import	"sort"
import	"strconv"
import	"strings"

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
var meta_Filter = "+live"

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
	if len(meta_Selected) > 0{
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

	list := make(task.Tasks, 0, len(meta_Selected))

	for _, t := range meta_Selected {
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

/*?
sub meta_all_matching_type {
	my($type) = @_

	return grep { $_->get_type() eq $type } Hier::Tasks::all()
}

?*/

func Find(task_id string) * task.Task {
	if tid, err := strconv.Atoi(task_id); err == nil {
		return task.Find(tid)
	}

	fmt.Printf("Invalid task id %s\n", task_id)
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
	meta_Filter = filter
}

func Argv(args []string) []string {
	return args

	ret := make([]string, 0, len(args))

/*?
	has_filters := false

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
			$has_filters = 1
			next
		}
//		if ($Title) {
//			print "Desc:  ", join(' ', $_, @_), "\n"
//			return join(' ', $_, @_)
//		}
		push(@ret, $_)
	}

	unless ($has_filters) {
		Hier::Filter::add_filter($Default_filter)
	}
	Hier::Filter::apply_filters($Default_filter)
?*/

	return ret
}

func Desc(args []string) string {
	return strings.Join(Argv(args), " ")
}

func Pick(args []string) []*task.Task {
	panic("... code meta.Pick")
}/*?
	my(@list) = ()

	foreach my $arg (meta_argv(@_)) {
		// comma sperated list of tasks
                while ($arg =~ s/^(\d+),(\d[\d,]*)$/$2/) {
                        my($ref) = meta_find($1)

                        unless (defined $ref) {
                                panic("Task $arg doesn't exits\n")
                        }
			push(@list, $ref)
                        next
                }

		// task all by itself
		if ($arg=~ s/^(\d+):$/$1/ or $arg =~ m/^\d+$/) {
                        my($ref) = meta_find($arg)

                        unless (defined $ref) {
                                panic("Task $arg doesn't exits\n")
                        }
			push(@list, $ref)
                        next
                }

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

		my($want) = type_val($arg)
		if ($want) {
			for my $ref (meta_matching_type($want)) {
				next if $ref->filtered()
				push(@list, $ref)
			}
			next
		}
		panic("**** Can't understand argument $arg\n")
	}
	return @list
}

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
	log.Printf(".... code meta.Current")

	list := task.Tasks{}
	return list
}

func Set_current(list task.Tasks) {
}

