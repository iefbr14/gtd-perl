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


use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_help);

	our $OurPath = __FILE__;
}

use Hier::Meta;
use Hier::Format;

our $OurPath;

my(%Helps) = (
//------------------------------------------------------------------------------
// Obsolete Sac view of projects vs gts view of projects
	"Sac" => <<"EOF",
(gtd) Value => Vision => Role => Goal => Project => Action
(sac)                  Client => Project => Task => Item
EOF

//------------------------------------------------------------------------------
	"Selection" => <<"EOF",
  tid       -- task id
  /title    -- match any with title
  T:/title  -- match only type T,  with title
               (T == A,P,G,R,V)
EOF

//------------------------------------------------------------------------------
	"Filters" => <<"EOF",
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

//------------------------------------------------------------------------------
	"Sort" => <<"EOF",
id/tid	      - by task id
task/title    - by task name (title)

hier          - by hier position, sub-sorted by title

pri/priority  - by priority
panic         - by panic (highest priority propigated up the hierarchy)
focus         - by panic within {nextaction;action;someday}

date/age      - by created date
change        - by modified date
doit/doitdate - by doit date
status        - by completed if done otherwise by modified.

rgpa/goaltask - by task withing goal
EOF

//------------------------------------------------------------------------------
	"Types" => <<"EOF",
m - value
v - vision
o - role
g - goal
p - project
a - action

i - inbox
w - waiting

R - reference
L - list
C - checklist
T - item
EOF

//------------------------------------------------------------------------------
	"Project-Verbs" => <<"EOF",
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

//------------------------------------------------------------------------------
	"Action-Verbs" => <<"EOF",
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

//------------------------------------------------------------------------------
	"Planning" => <<"EOF",
1. Define purpose & principles (why)
2. Outcome visioning
3. Brainstorming
4. Organizing material
5. Identify next actions
EOF

//------------------------------------------------------------------------------
	"Agile" => <<"EOF",
Using "kanban" and "board" commands to refine project state.
Then by iterating over those items to create momentum.
EOF

);

sub Report_help {	//-- Help on commands
	my($f, $path);
	my($dir) = $OurPath;

	my($help) = @_;

	if (scalar(@_) == 0 or $help eq "help") {
		print "Help is available for:\n";
		for my $key (sort keys %Helps) {
			print "\t$key\n";
		}
		print "\nAlso try: help reports\n";
		return;
	}

	if (defined $Helps{$help}) {
		print $Helps{$help};
		return;
	}

	$dir =~ s=/help.pm==;
	my($report) = "$dir/$help.pm";
	if (-f $report) {
		//##BUG### should look at other args for perldoc args
		system("perldoc", $report);
		return;
	}

	print "? Don't understand help $help, try: help help\n";
	
}

1;  # don't forget to return a true value from the file
