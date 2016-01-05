package main

import "flag"

import "Hier/Util"
import "Hier/Db"
import "Hier/Option"
import "Hier/Filter"

func usage() {
	panic(`
usage: $0 [options] report-cmd [sub-options]
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
`)
}

var (
	Zname   string
	Debug   int
	MetaFix int
	Title   string
	Task    string
)

func main() {
	flag.IntVar(&Debug, "x", 0, "Turn debugging on")

	err := getopts("X:uS:F:H:f:LaAZ:o:T:c:C:D:p:N:s:t:l:r")
	if err {
		usage()
	}

	flag.StringVar(&Zname, 'Z', "gtd", "gtd database group (default: test)")

	// db_load_defaults($Zname);

	if Debug {
		debug("main")
	}

	var new string
	option.StringVar(&new, "n", "", "New item")

	option.Flag("MetaFix", 'u')

	option.Flag("Title", 's')
	option.Flag("Task", 'd')
	option.Flag("Note", 'N')

	option.Flag("Context", 'C')
	option.Flag("Category", 'c')
	option.Flag("Timeframe", 'T')

	option.Flag("Limit", 'l') // reports set own defaults

	option.Flag("Priority", 'p')
	option.Flag("Tag", 'T')

	option.Flag("Header", 'H')
	option.Flag("Format", 'F')
	option.Flag("Sort", 'S')
	option.Flag("Reverse", 'r')

	option.Flag("Layout", 'f')

	option.Flag("Date", 'D')

	var myopts []string
	flag.Var(&myopts, 'o', "List of options")

	option.Filter("a", "+future", "all")
	option.Filter("A", "+done", "Any")

	flag.Parse()

	DB_init(Zname)

	args := flag.Args()
	cmd := os.Args[0]

	if new {
		if cmd == "hier" {
			report("new", append("project", args...))
		} else {
			report("new", append("action", args...))
		}
	}

	if cmd == "doit" {
		report("doit", args)
		return
	}

	if cmd == "hier" {
		report("hier", args)
		return
	}

	if len(args) > 0 && IsLetter(args[0][0]) {
		report(args)
		return
	}

	if len(args) > 0 {
		report("gtd", Args)
		return
	}

	report("rc")
	return
}

func report(report string, args ...string) {
	rfunc = load_report(report)
	if rfunc != nil {
		rfunc(args)
	}
}
