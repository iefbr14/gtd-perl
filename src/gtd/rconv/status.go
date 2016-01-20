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
import "gtd/task" // %Types and typemap

/*?
my @Class = qw(Done Someday Action Next Future Total)


my $Hours_proj = 0
my $Hours_task = 0
my $Hours_next = 0
?*/

//-- report status of projects/actions
func Report_status(args []string) int {
	// counts use it and it give a context
	meta.Filter("+active", '^tid', "none")

	desc := meta.Desc(args)

	if (strings.Lower(desc) == "all") {
		report_detail()
		return
	}

	Hours_proj = 0
	Hours_task = 0
	Hours_next = 0

	  	hier := count_hier()
	  	proj := count_proj()
	  	task := count_task()
	  	next := count_next()

	  //	print "Options:\n"
	  //	for my $option (qw(pri debug db title report)) {
	  //		printf "%10s %s\n", $option, get_info($option)
	  //	}
	  //	print "\n"

	  	if (desc) {
	  		fmtp.Print("For: $desc \n")
	  //		ref := meta.ask($desc)
	  //		print ref.get_title(), "\n"
	  	}
	  	total := task + next

	  	fmt.Printf("hier: %6s  projects: %6s  next,actions: %6s %6s  = %s\n",
	  		hier, proj, next, task, total)

	  	t_p := f_h(Hours_proj)
	  	t_a := f_h(Hours_task)
	  	t_n := f_h(Hours_next)

	  	t_time := f_h(Hours_proj+Hours_task+Hours_next)

	  	fmt.Printf("time:  %6s projects:  %6s next,actions:  %6s %6s = %s\n",
	  		t_time, t_p, t_n, t_a, f_h(Hours_next+Hours_task))

	  	fmt.Print("Next")
		for _,kind := range "mvogpsa" {
	  		n_tid := next_avail_task(kind)
			if n_tid == 0 {
				n_tid = '-'
				}

	  		fmt.Printf("\t%s => %s\n",  kind , n_tid)
	  	}
}

func f_h(hours int) {
	switch {                     
	case hours < 8:
		return fmt.Sprintf("%.1f ", hours)
		case hours < 8*20:
		return fmt.Sprintf("%.1fd", hours/8)     
		case hours < 8*20*15:
		return fmt.Sprintf("%.2fm", hours/8/20)  
		default:
		return fmt.Sprintf("%.3fy", hours/8/20/12)
		}
}

func count_hier() { /*?
		my($count) = 0

		// find all hier records
		foreach my ref (meta.ll()) {
			next unless ref.is_hier()
			next if ref.filtered()

			++$count
		}
		return $count
	?*/
}

func count_proj() {
	count := 0

		// find all projects
		for _, t := range meta.Matching_type('p') {
	//##FILTER	next if t.Filtered()

			count++

			resource := resource.New(t)
			hours := resource.hours(t)
			if (hours == 0) {
				if len(t.Children) > 0{
					hours = 1
					// to manage done.
				} else {
					hours = 4
					// to start planning.
				}
			}
			$Hours_proj += hours
		}
		return $count
}

func count_liveproj() int {
		count := 0

		// find all projects
		for _, ref := range meta.Matching_type('p') {
	//##FILTER	next if ref.filtered()

			if !  project_live(ref) {
				continue
				}

			count++
		}
		return$count
}

func count_task() int { 
		count := 0
		time := 0

		// find all records.
		for _,ref := range meta.Selected() {
			next unless ref.is_task()

			next if ref.filtered()

			next unless project_live(ref)

			++$count

			my($resource) = new Hier::Resource(ref)
			$Hours_task += $resource->hours(ref)
		}
		return $count
}

func count_next() {
		my($count) = 0
		my($time) = 0

		// find all records.
		foreach my ref (meta.elected()) {
			next unless ref.is_task()

			next if ref.filtered()

			next unless project_live(ref)

			next unless ref.is_nextaction()

			++$count

			my($resource) = new Hier::Resource(ref)
			$Hours_next += $resource->hours(ref)
		}
		return $count
}

func count_tasklive() {
		my($count) = 0
		my($time) = 0

		// find all records.
		foreach my ref (meta.elected()) {

			next unless ref.is_task()

			next if ref.filtered()
			next unless project_live(ref)

			++$count
		}
		return $count
}

func project_live() { 
		my(ref) = @_

		return ref.get_live() if defined ref

		my($type) = ref.get_type()

		if (ref.is_task()) {
			ref.get_live() = ! task_filtered(ref)
			return ref.get_live()
		}

		if (ref.is_hier()) {
			foreach my $pref (ref.get_parents()) {
				ref.get_live() |= project_live($pref)
			}
			foreach my $cref (ref.get_children()) {
				ref.get_live() |= project_live($cref)
			}

			ref.get_live() = ! task_filtered(ref)
			return ref.get_live()
		}

		return 0
}

func calc_type(t *task.Task) {

	switch {
		case t.Is_hier():
		return 'h' 
		case: t.is_task()
		return 'a'
		default:
		return 'l'
		}
}

func calc_class() { 
		my(ref) = @_

	switch {
		case ref.Completed != "":
		return 'd' 
		case ref.Is_someday():
		return 's' 
		case ref.Is_later():
		return 'f' 

		case ref.Is_nextaction():
		return 'n' 
		default:
		return 'a'
		}
}

func report_detail() {
	meta.Filter("+all", "^title", "simple")

		my @Types = qw(Hier Action List Total)
		my @Class = qw(Done Someday Action Next Future Total)

		my(%data)
		my($type, $class)
		for my ref (meta.ll()) {
			$type = calc_type(ref)
			$class = calc_class(ref)

			++$data{$type}{$class}

			// totals
			++$data{'t'}{$class}
			++$data{$type}{'t'}
			++$data{'t"}{"t'}
		}

		for my $title ("Type", @Class) {
			printf "   %7s", $title
		}
		print "\n".('-'x75)."\n"

		for my $type (@Types) {
			my $tk = lc(substr($type,0, 1))
			my $classes = $data{$tk}

			printf "%7s | ", $type

			for my $class (@Class) {
				my $ck = lc(substr($class,0, 1))
				my $val = $classes->{$ck}
				$val ||= ''

				printf "   %7s", $val
			}
			print "\n"
		}
}
