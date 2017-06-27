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
import "sort"

//-- Help on commands
func Report_help(args []string) int {
	helps := map[string]string{

		//------------------------------------------------------------
		// Obsolete Sac view of projects vs gts view of projects
		"Sac": `
(gtd) Value => Vision => Role => Goal => Project => Action
(sac)                  Client => Project => Task => Item
`,

		//------------------------------------------------------------
		"Selection": `
  tid       -- task id
  /title    -- match any with title
  T:/title  -- match only type T,  with title
               (T == A,P,G,R,V)
`,

		//------------------------------------------------------------
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

		//------------------------------------------------------------
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

		//------------------------------------------------------------
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

		//------------------------------------------------------------
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

		//------------------------------------------------------------
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

		//------------------------------------------------------------
		"Planning": `
1. Define purpose & principles (why)
2. Outcome visioning
3. Brainstorming
4. Organizing material
5. Identify next actions
`,

		//------------------------------------------------------------
		"Agile": `
Using "kanban" and "board" commands to refine project state.
Then by iterating over those items to create momentum.
`,

		//------------------------------------------------------------
		// generated from gtd-perl: gtd reports
		"reports": `
#=============================================================================
#== Reports
#=============================================================================
actions      -- Detailed list of projects with (next) actions
addplans     -- add plan action items to unplaned projects
board        -- report board of projects/actions
bulk         -- Create Bulk create Projects/Actions items from a file
bulklist     -- Bulk List project for use in bulk load
bulkload     -- Create Projects/Actions items from a file
cct          -- List Categories/Contexts/Time Frames
checklist    -- display a check list
clean        -- clean unused categories
color        -- Detailed list of projects with (next) actions
delete       -- Delete listed actions/projects (will orphine items)
did          -- update listed projects/actions doit date to today
doit         -- doit tracks which projects/actions have had movement
done         -- Tag listed projects/actions as done
dump         -- dump records in edit format
edit         -- Edit listed actions/projects
fixcct       -- Fix Categories/Contexts/Time Frames
focus        -- List focus -- live, plan or someday
ged          -- generate a gedcom file from gtd db
gui          -- Tk gui front end
help         -- Help on commands
hier         -- Hiericial List of Values/Visions/Roles...
hierlist     -- List all top level item (Project and above)
init         -- Init ~/.todo structure
items        -- list titles for any filtered class (actions/projects etc)
kanban       -- report kanban of projects/actions
list         -- list titles for any filtered class (actions/projects etc)
merge        -- Merge Projects (first list is receiver)
new          -- create a new action or project
nextactions  -- List next actions
noop         -- No Operation
oocalc       -- Project Summary for a role
orphans      -- list all items without a parent 
planner      -- Create a planner file from gtd db
print        -- display records in dump format based on format type
projects     -- List projects -- live, plan or someday
purge        -- interactive purge completed work
rc           -- rc - Run Commands
records      -- detailed list all records for a type
renumber     -- Renumber task Ids 
reports      -- List Reports (use 'reports file' for file names)
review       -- Review all projects with actions
search       -- Search for items
spreadsheet  -- Project Summary for a role
status       -- report status of projects/actions
take         -- take listed actions/projects
task         -- quick List by various methods
taskjuggler  -- generate taskjuggler file from gtd db
todo         -- List high priority next actions
toplevel     -- List Values/Visions/Roles
tsort        -- write out hier as as set of nodes
update       -- Command line update of an action/project
url          -- open browser window for wiki and gtd
walk         -- Command line walk of a hier

`,
	}

	if len(args) == 0 {
		args = []string{"help"}
	}

	done := false
	for _, help := range args {
		if help == "help" {
			done = true
			fmt.Println("Help is available for:")
			for _, name := range sort_keys(helps) {
				fmt.Printf("\t%s\n", name)
			}
			fmt.Println("\nAlso try: help reports")
			continue
		}

		val, ok := helps[help]
		if ok {
			done = true
			fmt.Println(val)
			continue
		}

		fmt.Printf("Unknown help for %s\n", val)
	}

	if done {
		return 0
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
	fmt.Printf("? Don't understand help %v, try: help help\n", args)
	return 1
}

func sort_keys(m map[string]string) []string {
	keys := make([]string, 0, len(m))
	for key := range m {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}
