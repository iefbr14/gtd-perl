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

import "gtd/display"

var Report_cmd_map = map[string]func([]string) int{
	// place holders
	"rc":      Report_noop,
	"gui":     Report_noop,
	"web":     Report_noop,
	"reports": Report_noop,

	"addplans":    Report_addplans,
	"board":       Report_board,
	"cct":         Report_cct,
	"color":       Report_color,
	"delete":      Report_delete,
	"did":         Report_did,
	"doit":        Report_doit,
	"done":        Report_done,
	"edit":        Report_edit,
	"focus":       Report_focus,
	"help":        Report_help,
	"hier":        Report_hier,
	"kanban":      Report_kanban,
	"list":        Report_list,
	"new":         Report_new,
	"noop":        Report_noop,
	"orphans":     Report_orphans,
	"print":       Report_print,
	"projects":    Report_projects,
	"renumber":    Report_renumber,
	"search":      Report_search,
	"status":      Report_status,
	"taskjuggler": Report_taskjuggler,
	"task":        Report_task,
	"todo":        Report_todo,
	"walk":        Report_walk,
}

type Reports struct {
	name string
	desc string
}

var report_list = []Reports{
	{
		"actions",
		"Detailed list of projects with (next) actions",
	},
	{
		"addplans",
		"add plan action items to unplaned projects",
	},
	{
		"board",
		"report board of projects/actions",
	},
	{
		"bulk",
		"Create Bulk create Projects/Actions items from a file",
	},
	{
		"bulkload",
		"Create Projects/Actions items from a file",
	},
	{
		"cct",
		"List Categories/Contexts/Time Frames",
	},
	{
		"checklist",
		"display a check list",
	},
	{
		"clean",
		"clean unused categories",
	},
	{
		"color",
		"Test CLI color palette",
	},
	{
		"delete",
		"Delete listed actions/projects (will orphan items)",
	},
	{
		"did",
		"update listed projects/actions doit date to today",
	},
	{
		"doit",
		"doit tracks which projects/actions have had movement",
	},
	{
		"done",
		"Tag listed projects/actions as done",
	},
	{
		"dump",
		"dump records in edit format",
	},
	{
		"edit",
		"Edit listed actions/projects",
	},
	{
		"fixcct",
		"Fix Categories/Contexts/Time Frames",
	},
	{
		"focus",
		"List focus -- live, plan or someday",
	},
	{
		"ged",
		"generate a gedcom file from gtd db",
	},
	{
		"gui",
		"Tk gui front end",
	},
	{
		"help",
		"Help on commands",
	},
	{
		"hier",
		"Hiericial List of Values/Visions/Roles...",
	},
	{
		"hierlist",
		"List all top level item (Project and above)",
	},
	{
		"init",
		"Init ~/.todo structure",
	},
	{
		"items",
		"list titles for any filtered class (actions/projects etc)",
	},
	{
		"kanban",
		"report kanban of projects/actions",
	},
	{
		"list",
		"list titles for any filtered class (actions/projects etc)",
	},
	{
		"merge",
		"Merge Projects (first list is receiver)",
	},
	{
		"new",
		"create a new action or project",
	},
	{
		"nextactions",
		"List next actions",
	},
	{
		"oocalc",
		"Project Summary for a role",
	},
	{
		"orphans",
		"list all items without a parent ",
	},
	{
		"planner",
		"Create a planner file from gtd db",
	},
	{
		"print",
		"dump records in edit format",
	},
	{
		"projects",
		"List projects -- live, plan or someday",
	},
	{
		"purge",
		"interactive purge completed work",
	},
	{
		"rc",
		"rc - Run Commands",
	},
	{
		"records",
		"detailed list all records for a type",
	},
	{
		"renumber",
		"Renumber task Ids ",
	},
	{
		"review",
		"Review all projects with actions",
	},
	{
		"search",
		"Search for items",
	},
	{
		"spreadsheet",
		"Project Summary for a role",
	},
	{
		"status",
		"report status of projects/actions",
	},
	{
		"take",
		"take listed actions/projects",
	},
	{
		"task",
		"quick List by various methods",
	},
	{
		"taskjuggler",
		"generate taskjuggler file from gtd db",
	},
	{
		"todo",
		"List high priority next actions",
	},
	{
		"toplevel",
		"List Values/Visions/Roles",
	},
	{
		"tsort",
		"write out hier as as set of nodes",
	},
	{
		"update",
		"Command line update of an action/project",
	},
	{
		"url",
		"open browser window for wiki and gtd",
	},
	{
		"walk",
		"Command line walk of a hier",
	},
}

//-- List Reports
func Report_reports(args []string) int {
	display.Header("Reports")

	for _, v := range report_list {
		if _, ok := Report_cmd_map[v.name]; ok {
			display.Text(fmt.Sprintf("%-12s -- %s\n", v.name, v.desc))
		} else {
			display.Text(fmt.Sprintf("%-12s !! %s (:-)\n", v.name, v.desc))
		}
	}
	return 0
}
