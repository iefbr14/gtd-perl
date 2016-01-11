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
type Reports struct {
	name string
	f    func(...string) int
	desc string
}

var report_list = []Reports{
	{
		"actions",
		Report_actions,
		"Detailed list of projects with (next) actions",
	},
	{
		"addplans",
		Report_addplans,
		"add plan action items to unplaned projects",
	},
	{
		"board",
		Report_board,
		"report board of projects/actions",
	},
	{
		"bulk",
		Report_bulk,
		"Create Bulk create Projects/Actions items from a file",
	},
	{
		"bulkload",
		Report_bulkload,
		"Create Projects/Actions items from a file",
	},
	{
		"cct",
		Report_cct,
		"List Categories/Contexts/Time Frames",
	},
	{
		"checklist",
		Report_checklist,
		"display a check list",
	},
	{
		"clean",
		Report_clean,
		"clean unused categories",
	},
	{
		"color",
		Report_color,
		"Detailed list of projects with (next) actions",
	},
	{
		"delete",
		Report_delete,
		"Delete listed actions/projects (will orphine items)",
	},
	{
		"did",
		Report_did,
		"update listed projects/actions doit date to today",
	},
	{
		"doit",
		Report_doit,
		"doit tracks which projects/actions have had movement",
	},
	{
		"done",
		Report_done,
		"Tag listed projects/actions as done",
	},
	{
		"dump",
		Report_dump,
		"dump records in edit format",
	},
	{
		"edit",
		Report_edit,
		"Edit listed actions/projects",
	},
	{
		"fixcct",
		Report_fixcct,
		"Fix Categories/Contexts/Time Frames",
	},
	{
		"focus",
		Report_focus,
		"List focus -- live, plan or someday",
	},
	{
		"ged",
		Report_ged,
		"generate a gedcom file from gtd db",
	},
	{
		"gui",
		Report_gui,
		"Tk gui front end",
	},
	{
		"help",
		Report_help,
		"Help on commands",
	},
	{
		"hier",
		Report_hier,
		"Hiericial List of Values/Visions/Roles...",
	},
	{
		"hierlist",
		Report_hierlist,
		"List all top level item (Project and above)",
	},
	{
		"init",
		Report_init,
		"Init ~/.todo structure",
	},
	{
		"items",
		Report_items,
		"list titles for any filtered class (actions/projects etc)",
	},
	{
		"kanban",
		Report_kanban,
		"report kanban of projects/actions",
	},
	{
		"list",
		Report_list,
		"list titles for any filtered class (actions/projects etc)",
	},
	{
		"merge",
		Report_merge,
		"Merge Projects (first list is receiver)",
	},
	{
		"new",
		Report_new,
		"create a new action or project",
	},
	{
		"nextactions",
		Report_nextactions,
		"List next actions",
	},
	{
		"oocalc",
		Report_oocalc,
		"Project Summary for a role",
	},
	{
		"orphans",
		Report_orphans,
		"list all items without a parent ",
	},
	{
		"planner",
		Report_planner,
		"Create a planner file from gtd db",
	},
	{
		"print",
		Report_print,
		"dump records in edit format",
	},
	{
		"projects",
		Report_projects,
		"List projects -- live, plan or someday",
	},
	{
		"purge",
		Report_purge,
		"interactive purge completed work",
	},
	{
		"rc",
		Report_rc,
		"rc - Run Commands",
	},
	{
		"records",
		Report_records,
		"detailed list all records for a type",
	},
	{
		"renumber",
		Report_renumber,
		"Renumber task Ids ",
	},
	{
		"review",
		Report_review,
		"Review all projects with actions",
	},
	{
		"search",
		Report_search,
		"Search for items",
	},
	{
		"spreadsheet",
		Report_spreadsheet,
		"Project Summary for a role",
	},
	{
		"status",
		Report_status,
		"report status of projects/actions",
	},
	{
		"take",
		Report_take,
		"take listed actions/projects",
	},
	{
		"task",
		Report_task,
		"quick List by various methods",
	},
	{
		"taskjuggler",
		Report_taskjuggler,
		"generate taskjuggler file from gtd db",
	},
	{
		"todo",
		Report_todo,
		"List high priority next actions",
	},
	{
		"toplevel",
		Report_toplevel,
		"List Values/Visions/Roles",
	},
	{
		"tsort",
		Report_tsort,
		"write out hier as as set of nodes",
	},
	{
		"update",
		Report_update,
		"Command line update of an action/project",
	},
	{
		"url",
		Report_url,
		"open browser window for wiki and gtd",
	},
	{
		"walk",
		Report_walk,
		"Command line walk of a hier",
	},
}

//-- List Reports
func Report_reports(args ...string) { 
	task.Header("Reports")

	for v := range report_list {
		display(fmt.Sprintf("%-12s -- %s", v.name, v.desc))
	}
}
?*/
