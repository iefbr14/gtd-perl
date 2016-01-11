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
import "gtd/task";
import "gtd/meta";
import "gtd/option";
import "gtd/task";
import "gtd/task";

my $Mode = 'p';	// project, doit, next-actions, actions, someday

my($List) = 0; ###BUG### should be an option

//-- Review all projects with actions
func Report_review(args []string) {
	gtd.Meta_filter("+active", '^doitdate', "simple");
	my $desc = meta.Desc(args)(@_);

	$Mode = 'p';
	if (lc($desc) eq "doit") {
		$Mode = 'd';
	} elsif (lc($desc) eq "next") {
		$Mode = 'a';
	} elsif (lc($desc) eq "action") {
		$Mode = 'a';
	} elsif (lc($desc) eq "project") {
		$Mode = 'p';
	} elsif (lc($desc) eq "waiting") {
		$Mode = 'w';
		warn "Fooked, gtd.Meta_filter reset report/sort";
		gtd.Meta_filter("+wait", '^doitdate', "simple");
	} else {
		$desc = "= $desc =";
	}
		
	reload($Mode);
}

sub reload {
	my($Mode) = @_;

	if ($Mode eq 'p') {
		mode_projects(1, "Projects", meta.Desc(args)(@_));
	} elsif ($Mode eq 'd') {
		mode_doit();
	} elsif ($Mode eq 's') {
		mode_type('s');
	} elsif ($Mode eq 'a') {
		mode_type('a');
	} elsif ($Mode eq 'w') {
		mode_type('a');
	} else {
		panic("Unknown mode: $Mode (Projects, Someday, Next, Actions, Doit, Waiting\n");
	}
}

sub mode_doit {
	my(@list);

	for my $ref (gtd.Meta_sorted("^doitdate")) {
		lookat($ref);
	}
}

sub lookat {
	my($ref) = @_;

	return unless $ref->is_task();
	next if $ref->filtered();
	next if $ref->is_later();

	my $pref = $ref->get_parent();
	next unless defined $pref;
	next if $pref->filtered();

	display_task($ref);
	get_status($ref);
}

sub mode_type {
	my($type) = @_;

	for my $ref (sort_tasks gtd.Meta_matching_type($type)) {
		lookat($ref);
	}
}

sub mode_projects {
	my($all, $head, $desc) = @_;

	task.Header($head, $desc);

	my($work_load) = 0;
	my($proj_cnt) = 0;
	my($ref, $proj, %wanted, %counted, %actions);

	// find all next and remember there projects
	for my $ref (sort_tasks gtd.Meta_matching_type('p')) {
		next if $ref->filtered();
		next if $ref->is_later();

		my($work, $counts) = summary_children($ref);
		$work_load += $work;
		display_rgpa($ref, $counts);
		++$proj_cnt;

		get_status($ref);

	}
	print "***** Work Load: $proj_cnt Projects, $work_load action items\n";
}

sub get_status {
	my($ref) = @_;

	local($|) = 1;
	local($_) = 1;

	$_ = prompt('?", "#');
	return unless defined $_;

	//##BUG### '!' command should be part of prompt Term mode
	//##BUG### ':' command should be part of prompt to call rc
	//##BUG### ^C need to be handled in Prompt
	//##BUG### ^D eof need to propigate up nicely

    foreach $_ (split(';', $_)) {
	if (/^h/ or /^\?/) {
		doit_help();
		return;
	}

	if (/^q/) {
		//##BUG### quit need to propigate up nicely
		//##BUG### :quit need to propigate up nicely from rc
		panic("Quit\n");
	}
	if (/^m/) {
		s/^\S+\s+//;
		print "Switching to mode $_\n";
		$Mode = $_;
		reload();
		return;
	}
	if (/^l/) {
		print "Latered: ...\n";
		doit_later($ref, +7);
		return;
	}
	if (/^n/) {
		print "Nowed: ...\n";
		doit_now($ref);
		return;
	}
	if (/^d/) {
		print "Done: ...\n";
		doit_done($ref);
		return;
	}
	if (/^k/) {
		print "Deleted: ...\n";
		doit_delete($ref);
		return;
	}
	if (/^s/) {
		print "Somedayed: ...\n";
		doit_someday($ref);
		return;
	}
	if (/^p (\d)/) {
		print "Priority: ...\n";
		doit_priority($ref, $1);
		return;
	}
	if (/^f\s*(\-?\d+)/) {
		print "Forward $1: ...\n";
		doit_later($ref, $1);
		return;
	}

	print "huh? $_\n";
   }
}


sub _report_doit {	

	$= = lines();
	gtd.Meta_filter("+a:live", '^doitdate', "doit");
	my($target) = 0;
	my($action) = \&doit_list;

	foreach my $arg (Hier::util::gtd.Meta_argv(@_)) {
		if ($arg =~ /^\d+$/) {
			my($ref) = meta.Find($arg);

			unless (defined $ref) {
				warn "$arg doesn't exits\n";
				next;
			}
			&$action($ref);
			++$target;
			next;
		}

		print "Unknown option: $arg (ignored) (try option help)\n";
	}
	if ($target == 0) {
		list_all();
	}
}

sub doit_later {
	my($ref, $delay) = @_;

	$ref->set_doit(get_today($delay));
	$ref->update();
}
sub doit_next {
	my($ref) = @_;

	$ref->set_doit(get_today(0));
	$ref->update();
}
sub doit_done {
	my($ref) = @_;

	$ref->set_completed(get_today(0));
	$ref->update();
}

sub doit_someday {
	my($ref) = @_;

	$ref->set_isSomeday('y');
	$ref->set_doit(get_today(+7));
	$ref->update();
}

sub doit_now {
	my($ref) = @_;

	$ref->set_isSomeday('n');
	$ref->set_doit(get_today(0));
	$ref->update();
}

sub doit_delete {
	my($ref) = @_;

	$ref->delete();
}

sub doit_priority {
	my($ref, $priority) = @_;

	if ($ref->get_priority() == $priority) {
		print $ref->get_tid() . ": " . $ref->get_description() . 
			" already at priority $priority\n";
		return;
	}

	$ref->set_priority($priority);
	$ref->update();
}

sub doit_header {
print <<"EOF" unless $List;
  Id   Pri Category  Doit        Task/Description
==== === = ========= =========== ==============================================
EOF
}

sub doit_list {
	my($tid, $ref, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

format DOIT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,       $doit,    $desc
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                   $desc
.
	$~ = "DOIT";	// set STDOUT format name to HIER

	foreach my $ref (@_) {
		$tid = $ref->get_tid();

		$pri       = $ref->get_priority();

		$task      = $ref->get_title() || $ref->get_context() || '';
		$cat       = $ref->get_category() || '';
		$created   = $ref->get_created();
		$modified  = $ref->get_modified() || $created;
		$doit      = $ref->get_doit() || '';
		$desc      = $ref->get_description();
		$note      = $ref->get_note();

		my($pid, $pref, $pname, $pdesc);

		$pref     = $ref->get_parent();
		next unless defined $pref;

		$pid      = $pref->get_tid();
		$pname    = $pref->get_title();
		$pdesc    = $pref->get_description();

		my($gid, $gref, $gname);
		$gref      = $pref->get_parent();
		next unless defined $gref;

		$gid      = $gref->get_tid();
		$gname    = $gref->get_title();

//		next if $gref->hier_filtered();

		if ($List) {
			$desc =~ s=\n.*==s;
			print join("\t", $tid, $pri, $cat, $doit, $pname, $task, $desc), "\n";
		} else {
			chomp $gname;
			chomp $pname;
			chomp $pdesc;
			chomp $task;
			chomp $desc;
			chomp $note;
			$note = "Outcome: $note" if $note;

			$desc = join("\r", "G[$gid]: $gname",
				  "P[$pid]: $pname", 
					split("\n", $pdesc),
				  "*[$tid] $task",
					split("\n", $desc),
					split("\n", $note)
			);

			write;
		}
	}
}

sub doit_help {
	print <<"EOF";
help    -- this help text
list    -- list next
later   -- skip this for a week
next    -- skip this for now
done    -- set them to done
someday -- set them to someday
now     -- set them to from someday

f :    -- forward later : days
p :    -- priorty : 

EOF
//limit:  -- Set the doit limit to this number of items
}
?*/
