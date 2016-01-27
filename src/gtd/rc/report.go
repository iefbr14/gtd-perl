package rc

import "fmt"
import "gtd/report"

func Load_report(report_name string) func([]string) int {
	var report_cmd_map = map[string]func([]string) int{
		"rc": Report_rc,

		"addplans": report.Report_addplans,
		// next to work on goes here.
		"board":       report.Report_board,
		"cct":         report.Report_cct,
		"color":       report.Report_color,
		"delete":      report.Report_delete,
		"did":         report.Report_did,
		"doit":        report.Report_doit,
		"done":        report.Report_done,
		"edit":        report.Report_edit,
		"help":        report.Report_help,
		"focus":       report.Report_focus,
		"list":        report.Report_list,
		"hier":        report.Report_hier,
		"noop":        report.Report_noop,
		"print":       report.Report_print,
		"renumber":    report.Report_renumber,
		"status":      report.Report_status,
		"task":        report.Report_task,
		"taskjuggler": report.Report_taskjuggler,
		"todo":        report.Report_todo,
		"search":      report.Report_search,
	}

	// load_report -- return 1 if it compile correctly
	rfunc, ok := report_cmd_map[report_name]
	if ok {
		return rfunc
	}

	fmt.Printf("#!? Bad command: %s\n", report_name)
	return nil

}

// run report but protect caller from report failure
func Run_report(report_name string, arg []string) int {

	rfunc := Load_report(report_name)
	if rfunc == nil {
		return 2
	}

	return rfunc(arg)
}
