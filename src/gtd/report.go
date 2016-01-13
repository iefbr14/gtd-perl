package gtd

import "fmt"
import "gtd/report"

var reports = map[string]func([]string) int{
	"edit":   report.Report_edit,
	"list":   report.Report_list,
	"hier":   report.Report_hier,
	"noop":   report.Report_noop,
	"search": report.Report_search,
}

// load_report -- return 1 if it compile correctly
func Load_report(report_name string) func([]string) int {
	rfunc, ok := reports[report_name]
	if ok {
		return rfunc
	}

	fmt.Printf("#!? Bad command: %s\n", report_name)
	return nil

}

// run report but protect caller from report failure
func Run_report(report_name string, arg []string) int {
	defer func() {
//?		if r := recover(); r != nil {
//?			fmt.Printf("Recovered in %s: %v\n", report_name, r)
//?		}
	}()

	rfunc := Load_report(report_name)
	if rfunc == nil {
		return 2
	}

	return rfunc(arg)
}
