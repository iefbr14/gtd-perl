package gtd

import "fmt"
import "gtd/report"

var reports = map[string]func([]string){
	"noop": report.Report_noop,
}

// load_report -- return 1 if it compile correctly
func Load_report(report_name string) func([]string) {
	rfunc, ok := reports[report_name]
	if ok {
		return rfunc
	}

	fmt.Printf("#:? Bad command: %s\n", report_name)
	return nil

}

// run report but protect caller from report failure
func Run_report(report_name string, arg []string) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("Recovered in %s: %v\n", report_name, r)
		}
	}()
	rfunc := Load_report(report_name)
	rfunc(arg)

}
