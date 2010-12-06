package Hier::Report::review;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_review);
}

use Hier::util;
use Hier::Tasks;

my $Mode = 'p';	# project, doit, next-actions, actions, someday

my($List) = 0; ###BUG### should be an option
my($Done) = 0; ###BUG### should be an option

sub Report_review {	#-- Review all projects with actions
	add_filters('+live');
	my $desc = meta_desc(@ARGV);

	$Mode = 'p';
	if (lc($desc) eq 'doit') {
		$Mode = 'd';
	} elsif (lc($desc) eq 'next') {
		$Mode = 'a';
	} elsif (lc($desc) eq 'action') {
		$Mode = 'a';
	} elsif (lc($desc) eq 'project') {
		$Mode = 'p';
	} elsif (lc($desc) eq 'plan') {
		add_filters('=plan');
	} elsif (lc($desc) eq 'someday') {
		add_filters('=later');
	} elsif (lc($desc) eq 'waiting') {
		$Mode = 'w';
		add_filters('=wait');
	} else {
		$desc = "= $desc =";
	}
		
	reload();
}

sub reload {
	if ($Mode eq 'p') {
		mode_projects(1, 'Projects', meta_desc(@ARGV));
	} elsif ($Mode eq 's') {
		mode_someday();
	} elsif ($Mode eq 'a') {
		mode_action();
	} elsif ($Mode eq 'd') {
		mode_doit();
	} elsif ($Mode eq 'w') {
		mode_waiting();
	} else {
		die "Unknown mode: $Mode (Projects, Someday, Next, Actions, Doit, Waiting\n";
	}
}

sub mode_doit {
	my(@list);

	for my $ref (Hier::Tasks::sorted('^doitdate')) {
		next unless $ref->is_ref_task();
		next if $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;
		next if $pref->filtered();

		doit_list($ref);
		get_status($ref);
	}
}

sub mode_actions {
	for my $ref (Hier::Tasks::matching_type('a')) {
		next unless $ref->is_ref_task();
		next if $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;
		next if $pref->filtered();

		doit_list($ref);
		get_status($ref);
	}
}

sub mode_next {
	for my $ref (Hier::Tasks::matching_type('n')) {
		next unless $ref->is_ref_task();
		next if $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;
		next if $pref->filtered();

		doit_list($ref);
		get_status($ref);
	}
}

sub mode_waiting {
	for my $ref (Hier::Tasks::matching_type('w')) {
		next unless $ref->is_ref_task();
		next if $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;
		next if $pref->filtered();

		doit_list($ref);
		get_status($ref);
	}
}

sub mode_projects {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($work_load) = 0;
	my($proj_cnt) = 0;
	my($ref, $proj, %wanted, %counted, %actions);

	# find all next and remember there projects
	for my $ref (Hier::Tasks::matching_type('p')) {
		next if $ref->filtered();

		my $pid = $ref->get_tid();
		$wanted{$pid} = $ref;
		$counted{$pid} = 0;
		$actions{$pid} = 0;

		for my $child ($ref->get_children()) {
			$counted{$pid}++ unless $child->filtered();
			$actions{$pid}++;

			$work_load++ unless $child->filtered();
		}
	}

### format:
### ==========================
### Value Vision Role
### -------------------------
### 99	Goal 999 Project
	my($cols) = columns() - 2;

	my($g_id) = 0;
	my($prev_goal) = 0;
	my($prev_role) = 0;
	my($pid, $g_ref);
	for my $ref (sort by_goal_task values %wanted) {
		$pid = $ref->get_tid();

		$g_ref = $ref->get_parent();
		$g_id  = $g_ref->get_tid();

		if ($g_id != $prev_goal) {
			print '#', "=" x $cols, "\n" if $prev_goal != 0;
			print "$g_id:\tG:", $g_ref->get_title();

			my $r_ref = $g_ref->get_parent();
			my $r_id = $r_ref->get_tid();
			print " [** R:$r_id: ", $r_ref->get_title(), " **]\n";
			$prev_goal = $g_id;
		} else {
#			print '#', "-" x $cols, "\n";
		}

		$counted{$pid} = 0 unless defined $counted{$pid};
		print "$pid:\tP:", $ref->get_title(), 
			' (', $counted{$pid}, '/', $actions{$pid}, ')',
			"\n";
		++$proj_cnt;

		get_status($ref);

	}
	print "***** Work Load: $proj_cnt Projects, $work_load action items\n";
}

sub by_goal_task {
	return $a->get_parent->get_title() cmp $b->get_parent->get_title()
	    or $a->get_title() cmp $b->get_title()
	    or $a->get_tid() <=> $b->get_tid();
}

sub get_status {
	my($ref) = @_;

	local($|) = 1;
	local($_) = 1;

	print "? ";

	$_ = <STDIN>;
	return unless defined $_;

	chomp;
	return if /^\s*$/;

	# add '!' command

    foreach $_ (split(';', $_)) {
	if (/^h/ or /^\?/) {
		doit_help();
		return;
	}

	if (/^q/) {
		exit 0;
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

use Hier::util;
use Hier::Tasks;

sub _report_doit {	

	$List = option('List', 0);
	$Done = option('Done', 0);

	if ($Done) {
	}

	$= = lines();
	add_filters('+active', '+next');
	my($target) = 0;
	my($action) = \&doit_list;

	foreach my $arg (Hier::util::meta_argv(@ARGV)) {
		if ($arg =~ /^\d+$/) {
			my($ref) = Hier::Tasks::find($arg);

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

	$ref->set_doit(today($delay));
	$ref->update();
}
sub doit_next {
	my($ref) = @_;

	$ref->set_doit(today());
	$ref->update();
}
sub doit_done {
	my($ref) = @_;

	$ref->set_completed(today());
	$ref->update();
}

sub doit_someday {
	my($ref) = @_;

	$ref->set_isSomeday('y');
	$ref->set_doit(today(+7));
	$ref->update();
}

sub doit_now {
	my($ref) = @_;

	$ref->set_isSomeday('n');
	$ref->set_doit(today());
	$ref->update();
}

sub doit_delete {
	my($ref) = @_;

	$ref->delete();
}

sub doit_priority {
	my($ref, $priority) = @_;

	if ($ref->get_priority() == $priority) {
		print $ref->get_tid() . ': ' . $ref->get_description() . 
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
	$~ = "DOIT";	# set STDOUT format name to HIER

	foreach my $ref (@_) {
		$tid = $ref->get_tid();

		$pri       = $ref->get_priority();

		$task      = $ref->get_task() || $ref->get_context() || '';
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

#		next if $gref->hier_filtered();

		if ($List) {
			$desc =~ s/\n.*//s;
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
	print <<'EOF';
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
#limit:  -- Set the doit limit to this number of items
}

1;  # don't forget to return a true value from the file
1;  # don't forget to return a true value from the file
