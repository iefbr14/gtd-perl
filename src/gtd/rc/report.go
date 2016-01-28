package rc

import "fmt"
import "gtd/report"

//import "gtd/web"
//import "gtd/gui"

func Load_report(report_name string) func([]string) int {
	if report_name == "rc" {
		return Report_rc
	}

	if report_name == "web" {
		fmt.Printf("web not built yet :-(\n")
		return Report_rc
	}

	if report_name == "gui" {
		fmt.Printf("gui not built yet :-(\n")
		return Report_rc
	}

	if report_name == "reports" {
		return report.Report_reports
	}

	// load_report -- return 1 if it compile correctly
	rfunc, ok := report.Report_cmd_map[report_name]
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
