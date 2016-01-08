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

import "fmt"

//-- Help on commands
func Report_help(args []string) {
	helps := map[string]string{

		//------------------------------------------------------------------------------
		// Obsolete Sac view of projects vs gts view of projects
		"Sac": `
(gtd) Value => Vision => Role => Goal => Project => Action
(sac)                  Client => Project => Task => Item
`,

		//------------------------------------------------------------------------------
		"Selection": `
  tid       -- task id
  /title    -- match any with title
  T:/title  -- match only type T,  with title
               (T == A,P,G,R,V)
`,

		//------------------------------------------------------------------------------
		"Filters": `
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

`,

		//------------------------------------------------------------------------------
		"Sort": `
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
`,

		//------------------------------------------------------------------------------
		"Types": `
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
`,

		//------------------------------------------------------------------------------
		"Project-Verbs": `
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
`,

		//------------------------------------------------------------------------------
		"Action-Verbs": `
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
`,

		//------------------------------------------------------------------------------
		"Planning": `
1. Define purpose & principles (why)
2. Outcome visioning
3. Brainstorming
4. Organizing material
5. Identify next actions
`,

		//------------------------------------------------------------------------------
		"Agile": `
Using "kanban" and "board" commands to refine project state.
Then by iterating over those items to create momentum.
`,
	}

	done := false
	for _, help := range args {
		if help == "help" {
			done := true
			fmt.Println("Help is available for:")
			for key := range sort_keys(helps) {
				fmt.Printf("\t%s\n", key.name)
			}
			fmt.Println("\nAlso try: help reports")
			continue
		}

		if val, ok := helps[help]; ok {
			done := true
			fmt.Println(val)
			continue
		}

		fmt.Printf("Unknown help for %s\n", val)
	}
	if done {
		return
	}
	fmt.Println("No help specified: Try gtd help")

	/*
		my($f, $path);
		my($dir) = $OurPath;

		my($help) = @_;

		$dir =~ s=/help.pm==;
		my($report) = "$dir/$help.pm";
		if (-f $report) {
			//##BUG### should look at other args for perldoc args
			system("perldoc", $report);
			return;
		}
	*/
	fmt.Println("? Don't understand help $help, try: help help")

}

func sort_keys(m map[string]string) []string {
	keys := make([]string, 0, len(m))
	for key := range m {
		keys = append(keys, key)
	}
	return sort.Strings(keys)
}
