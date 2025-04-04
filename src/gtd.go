package main

import "flag"
import "fmt"
import "os"
import "path"

//import "strings"

import "gtd/rc"
import "gtd/option"
import "gtd/task"

func usage() {
	cmd := path.Base(os.Args[0])

	fmt.Fprintf(os.Stderr, `
usage: %s [options] report-cmd [sub-options]
   used to set/query tasks in the gtd database.
global options:
    -x      -- turn Debug on.
    -X :    -- turn feature ':' debug on 
    -u      -- Don't update database (for testing)

    -Z :    -- gtd database group (default: test)

    -S :    -- Sort order :
    -f :    -- set page format to :
    -F :    -- set item Format to :
    -H :    -- Header format :

    -a      -- all tasks but done
    -A      -- All includes done

    -p :    -- set the priority (default 3; range 1..5)
    -s :    -- set the title (subject) text 
    -d :    -- set the description text
    -N :    -- set the note (result) text

    -c :    -- set the category
    -C :    -- set the context
    -t :    -- set the timeframe
    -T :    -- set the tag

    -D :    -- set the date to :

    -o :    -- set option eg(Mask)
X   -L      -- list format (use -oList instead)

    -l :    -- limit to first : (default 10)
    -r      -- reverse sort

Page format
   Html,Wiki 
   Man,Ms

Meta Info:
	\@Category or \@Context (Space or Time) or \@Tag
	/title/ ==> maps to list of tids for actions
	P:Project G:Goal R:Roal (Sets parents)
	=Project -- Sets parents
	NNNN (Project id) -- Sets parents
	*Type (Sets type)
	^sort^criteria	
	+ or ~ attributes for filters

Option
	color	=> none,pri,context,category,hier
`, cmd)
}

var (
	Zname      string
	main_debug bool
	MetaFix    int
	Title      string
	Task       string
)

func main() {
	flag.Usage = usage

	flag.BoolVar(&main_debug, "x", false, "Turn debugging on")

	Zname := "gtd"
	flag.StringVar(&Zname, "Z", "test", "gtd database group")

	// db_load_defaults($Zname);

	option.Flag("MetaFix", "u")

	option.Flag("Title", "s")
	option.Flag("Task", "d")
	option.Flag("Note", "N")

	option.Flag("Context", "C")
	option.Flag("Category", "c")
	option.Flag("Timeframe", "t")

	option.Flag("Limit", "l") // reports set own defaults

	option.Flag("Priority", "p")
	option.Flag("Tag", "T")

	option.Flag("Header", "H")
	option.Flag("Format", "F")
	option.Flag("Sort", "S")
	option.Flag("Reverse", "r")

	option.Flag("Layout", "f")

	option.Flag("Date", "D")

	//?	var myopts []string
	//?	flag.Var(&myopts, "o", "List of options")

	option.Filter("all", "a", "+future")
	option.Filter("Any", "A", "+done")

	flag.Parse()

	if main_debug {
		option.Debug("main")
	}

	task.DB_init(Zname)

	args := flag.Args()
	cmd := path.Base(os.Args[0])

	// the test here should be a "valid" command
	if cmd[0] == 'g' {
		// cmd is gtd or g, so run it's args
		if len(args) == 0 {
			report("rc", args)
		} else {
			report(args[0], args[1:])
		}
	} else {
		// cmd was symlinked so run by name
		report(cmd, args)
	}

	return
}

func report(report string, args []string) {
	rc := rc.Run_report(report, args)
	os.Exit(rc)
}
