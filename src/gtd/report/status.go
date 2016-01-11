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

/*?
my @Class = qw(Done Someday Action Next Future Total);

import "gtd/meta";
import "gtd/option";
import "gtd/task";
import "gtd/task";		// %Types and typemap

my $Hours_proj = 0;
my $Hours_task = 0;
my $Hours_next = 0;

//-- report status of projects/actions
func Report_status(args []string) {
	// counts use it and it give a context
	gtd.Meta_filter("+active", '^tid', "none");	

	my $desc = meta.Desc(args)(@_);

	if (lc($desc) eq "all") {
		report_detail();
		return;
	}
	
	$Hours_proj = $Hours_task = $Hours_next = 0;

	my $hier = count_hier();
	my $proj = count_proj();
	my $task = count_task();
	my $next = count_next();

//	print "Options:\n";
//	for my $option (qw(pri debug db title report)) {
//		printf "%10s %s\n", $option, get_info($option);
//	}
//	print "\n";

	if ($desc) {
		print "For: $desc \n";
//		my ($ref) = gtd.Meta_task($desc);
//		print $ref->get_title(), "\n";
	}
	my($total) = $task + $next;

	printf "hier: %6s  projects: %6s  next,actions: %6s %6s  = %s\n",
		$hier, $proj, $next, $task, $total;

	my($t_p) = f_h($Hours_proj);
	my($t_a) = f_h($Hours_task);
	my($t_n) = f_h($Hours_next);

	my($time) = f_h($Hours_proj+$Hours_task+$Hours_next);

	printf "time:  %6s projects:  %6s next,actions:  %6s %6s = %s\n",
		$time, $t_p, $t_n, $t_a, f_h($Hours_next+$Hours_task);

	print "Next";
	for my $type (qw(m v o g p s a)) {
		my($n_tid) = next_avail_task($type);
		$n_tid ||= '-';

		print "\t$type => $n_tid\n";
	}
}

sub f_h {
	my($hours) = @_;

	return $hours.' '                     if $hours < 8;
	return sprintf("%.1fd", $hours/8)     if $hours < 8*20;
	return sprintf("%.2fm", $hours/8/20)  if $hours < 8*20*15;
	return sprintf("%.3fy", $hours/8/20/12);
}

sub count_hier {
	my($count) = 0;

	// find all hier records
	foreach my $ref (gtd.Meta_all()) {
		next unless $ref->is_hier();
		next if $ref->filtered();

		++$count;
	}
	return $count;
}

sub count_proj {
	my($count) = 0;

	// find all projects
	foreach my $ref (gtd.Meta_matching_type('p')) {
//##FILTER	next if $ref->filtered();

		++$count;

		my($resource) = new Hier::Resource($ref);
		my($hours) = $resource->hours($ref);
		if ($hours == 0) {
			if ($ref->get_children()) {
				$hours = 1;
				// to manage done.
			} else {
				$hours = 4;
				// to start planning.
			}
		}
		$Hours_proj += $hours;
	}
	return $count;
}

sub count_liveproj {
	my($count) = 0;

	// find all projects
	foreach my $ref (gtd.Meta_matching_type('p')) {
//##FILTER	next if $ref->filtered();

		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub count_task {
	my($count) = 0;
	my($time) = 0;

	// find all records.
	foreach my $ref (gtd.Meta_selected()) {
		next unless $ref->is_task();

		next if $ref->filtered();

		next unless project_live($ref);

		++$count;

		my($resource) = new Hier::Resource($ref);
		$Hours_task += $resource->hours($ref);
	}
	return $count;
}

sub count_next {
	my($count) = 0;
	my($time) = 0;

	// find all records.
	foreach my $ref (gtd.Meta_selected()) {
		next unless $ref->is_task();

		next if $ref->filtered();

		next unless project_live($ref);

		next unless $ref->is_nextaction();

		++$count;

		my($resource) = new Hier::Resource($ref);
		$Hours_next += $resource->hours($ref);
	}
	return $count;
}

sub count_tasklive {
	my($count) = 0;
	my($time) = 0;

	// find all records.
	foreach my $ref (gtd.Meta_selected()) {

		next unless $ref->is_task();

		next if $ref->filtered();
		next unless project_live($ref);

		++$count;
	}
	return $count;
}

sub project_live {
	my($ref) = @_;

	return $ref->get_live() if defined $ref;

	my($type) = $ref->get_type();

	if ($ref->is_task()) {
		$ref->get_live() = ! task_filtered($ref);
		return $ref->get_live();
	}

	if ($ref->is_hier()) {
		foreach my $pref ($ref->get_parents()) {
			$ref->get_live() |= project_live($pref);
		}
		foreach my $cref ($ref->get_children()) {
			$ref->get_live() |= project_live($cref);
		}
	
		$ref->get_live() = ! task_filtered($ref);
		return $ref->get_live();
	}

	return 0;
}

sub calc_type {
	my($ref) = @_;

	return 'h' if $ref->is_hier();
	return 'a' if $ref->is_task();
	return 'l';
}

sub calc_class {
	my($ref) = @_;

	return 'd' if $ref->get_completed();
	return 's' if $ref->is_someday();
	return 'f' if $ref->is_later();

	return 'n' if $ref->is_nextaction();
	return 'a';
}

sub report_detail {
	gtd.Meta_filter("+all", '^title', "simple");

	my @Types = qw(Hier Action List Total);
	my @Class = qw(Done Someday Action Next Future Total);

	my(%data);
	my($type, $class);
	for my $ref (gtd.Meta_all()) {
		$type = calc_type($ref);
		$class = calc_class($ref);

		++$data{$type}{$class};

		// totals;
		++$data{'t'}{$class};
		++$data{$type}{'t'};
		++$data{'t"}{"t'};
	}

	for my $title ("Type", @Class) {
		printf "   %7s", $title;
	}
	print "\n".('-'x75)."\n";

	for my $type (@Types) {
		my $tk = lc(substr($type,0, 1));
		my $classes = $data{$tk};

		printf "%7s | ", $type;

		for my $class (@Class) {
			my $ck = lc(substr($class,0, 1));
			my $val = $classes->{$ck};
			$val ||= '';
	
			printf "   %7s", $val;
		}
		print "\n";
	}
}
?*/
