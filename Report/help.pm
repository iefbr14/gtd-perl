package Hier::Report::help;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_report &get_reports);

	our $OurPath = __FILE__;
}

use Hier::Meta;

our $OurPath;

sub Report_help {	#-- List Reports
	report_header('Reports');

	my @files  = get_reports();

	print join("\n", @files), "\n\n";
}

sub get_reports {
	my(@list, $name);
	
	my($f, $path);
	my($dir) = $OurPath;

	$dir =~ s=/report.pm==;
	opendir(DIR, $dir) or die;
	while ($f = readdir(DIR)) {
		next unless $f =~ /\.pm$/;

		$path = "$dir/$f";

		open(R, "< $path") or die "Can't open $path ($!)\n";
		while (<R>) {
			next unless /^sub Report_(\w+)/;
			$name = $1;
			if (m/#--\s*(.*)/) {
				push(@list, sprintf("%-12s -- %s", $name, $1));
			} else {
				push(@list, $name);
			}
		}
		close(R);
	}
	return sort @list;
}

my(%Helps) = (
	'Hier' => <<'EOF',
(gtd) Value => Vision => Role => Goal => Project => Action
(sac)                  Client => Project => Task => Item
EOF
	'Selection' => <<'EOF',
  tid       -- task id
  /title    -- match any with title
  T:/title  -- match only type T,  with title
               (T == A,P,G,R,V)
EOF

	'Filters' => <<'EOF',
~NAME -- exclude those of the type (check first)
+NAME -- include those of the type (check last)

done
next
cur[ent]
some[day] maybe
wait[ing]
tickle

late
due
slow
idea

task
list
hier

live +cur +next
all +live
dead|future|later => someday|waiting|tickle

dink => nokids noacts
kids - hier has sub-hier items
acts - hier has sub-actions

EOF

	'Sort' => <<'EOF',
EOF

	'Types' => <<'EOF',
[_] m value
[_] v vision
[_] r role
[_] g goal
[_] p project
[_] a action
[_] i inbox
[_] w waiting
[_] R reference
[_] L list
[_] C checklist
[_] T item
EOF
	'Project Verbs' => <<'EOF',
* Finalize
* Resolve
* Handle
* Look into
* Submit
* Maximize
* Organize
* Design
* Complete
* Ensure
* Roll out
* Update
* Install
* Implement
* Set-up 
EOF
	'Action Verbs' => <<'EOF',
* Call
* Review
* Buy
* Fill.Out
* Find
* Purge
* Look.Into 
* Gather
* Print
* Take
* Waiting for
* Load
* Draft
* Email 
* Sort
EOF
	'Planning' => <<'EOF',
1. Define purpose & principles (why)
2. Outcome visioning
3. Brainstorming
4. Organizing
5. Identify next actions
EOF

);

sub help_subhelp {
}

1;  # don't forget to return a true value from the file
