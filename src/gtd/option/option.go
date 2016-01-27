package option

import "flag"
import "fmt"
import "log"
import "time"
import "strconv"

//=============================================================================
var option_Debug bool
var options map[string]string

//=============================================================================

//??? @EXPORT = qw( option set_option debug load_report run_report get_today);

//=============================================================================

func option_key(key string) string {
	option_alias := map[string]string{
		"Subject":     "Title",
		"Desc":        "Task",
		"Description": "Task",
		"Result":      "Result",
		"Tags":        "Tag",
		"Colour":      "Color",
	}

	option_keys := map[string]int{
		"Debug":   1,
		"MetaFix": 1,
		"Mask":    1,

		"Changed": 1, // time of last db changed.
		"Current": 1, // current task (used as parent in new)

		// used as default in edit
		"Title": 1,
		"Task":  1,
		"Note":  1,

		"Category":  1,
		"Context":   1,
		"Timeframe": 1,
		"Priority":  1,
		"Complete":  1,
		"Tag":       1,

		"Color": 1,

		"List": 0,

		"Limit":   1,
		"Reverse": 1, // reverse sort

		"Header": 1, // Header routine
		"Format": 1, // Formating routine
		"Sort":   1, // Sortting routine
		"Filter": 1, // Default filter mode

		"Layout": 1,

		"Date": 1,

		"Mode": 1,
	}

	// check to see if the option has an alias
	alias, ok := option_alias[key]
	if ok {
		key = alias
	}

	_, ok = option_keys[key]
	if !ok {
		fmt.Printf("Unknown option: %s\n", key)
		option_keys[key] = 1
	}
	return key
}

// set_option

func Set(key string, val string) {
	key = option_key(key)

	options[key] = val
}

func Get(key string, deflt string) string {
	key = option_key(key) // map alias
	val, ok := options[key]
	if ok {
		return val
	}

	if option_Debug {
		fmt.Printf("Fetch Option %s == nil\n", key)
	}
	if options == nil {
		options = make(map[string]string)
	}
	if deflt != "" {
		options[key] = deflt
	}
	return deflt
}

func Bool(key string, deflt bool) bool {
	val := Get(key, "")

	if val == "" {
		return deflt
	}
	rval, err := strconv.ParseBool(val)
	if err != nil {
		fmt.Printf("Conversion failure %s -> %s", key, val)
		Set(key, "")
		return false
	}
	return rval
}

func Int(key string, deflt int) int {
	val := Get(key, "")

	if val == "" {
		return deflt
	}
	rval, err := strconv.Atoi(val)
	if err != nil {
		fmt.Printf("Conversion failure %s -> %s", key, val)
		Set(key, "0")
		return 0
	}
	return rval
}

//***BUG*** option.Date needs to take,vet,use internal date format!
func Date(key string, deflt string) string {
	val := Get(key, "")

	if val == "" {
		return deflt
	}

	/*?
	rval, err := strconv.Atoi(val)
	if err != nil {
		fmt.Printf("Conversion failure %s -> %s", key, val)
		Set(key, "0")
		return 0
	}
	return rval
	?*/
	return val
}

//==============================================================================
// Magic opion.Flag parsing to load options from command line
//------------------------------------------------------------------------------
type option string

func (i *option) String() string {
	s := string(*i)

	return fmt.Sprintf("%s: %s", s, options[s])
}

func (i *option) Set(value string) error {
	s := string(*i)
	log.Printf("Setting: %s => %s\n", s, value)
	if options == nil {
		options = make(map[string]string)
	}
	options[s] = value
	return nil
}

func Flag(key string, f string) {
	var key_val option

	key_val = option(key)

	if option_Debug {
		log.Printf("### Coding option.Flag -%s %s\n", f, key)
	}

	flag.Var(&key_val, f, key)
}

//------------------------------------------------------------------------------
type filter string

func (i *filter) String() string {
	s := string(*i)

	return fmt.Sprintf("%s: %s", s, options[s])
}

func (i *filter) Set(value string) error {
	s := string(*i)
	log.Printf("Setting: %s => %s\n", s, value)
	if options == nil {
		options = make(map[string]string)
	}
	options[s] = value

	return nil
}

func Filter(key, f, desc string) {
	log.Printf("... ***BUG*** option.Filter: %s %s %s", key, f, desc)

	var key_val filter

	key_val = filter(key)

	if option_Debug {
		log.Printf("### Coding option.Filter -%s %s\n", f, key)
	}

	flag.Var(&key_val, f, key)
}

//==============================================================================
// Debug
//------------------------------------------------------------------------------
var option_Debug_name = map[string]*bool{}

func Debug(what string) {
	if option_Debug {
		log.Printf("### Debug: %s\n", what)
	}

	// magic push debug into library routines (perl code)
	//	if regexp.Match("^[A-Z]", what) {
	//		no strict "refs";
	//		my($var) = "Hier::${what}::Debug";
	//		$$var = 1;

	//		if ($@) {
	//			warn "Debug $var failed\n";
	//			return;
	//		}
	//		print "Debug of $what on\n";
	//		return;
	//	}
	if v, ok := option_Debug_name[what]; ok {
		*v = true

		fmt.Printf("Debug of %s on\n", what)
		return
	}

	if what == "option" {
		option_Debug = true
		return
	}

	if what == "on" {
		option_Debug = true
		Set("Debug", "1")
		return
	}

	if what == "main" {
		//		$main::Debug = 1;
		return
	}

	// magic push debug into report routines (perl code)
	//	if ($what =~ /^[a-z]/) {
	//		load_report($what);

	//		no strict "refs";
	//		my($var) = "Hier::Report::${what}::Debug";
	//		$$var = 1;
	//		eval "Hier::Report::$what::Debug = 1";
	//		if ($@) {
	//			warn "Debug Hier::Report::$what failed\n";
	//			return;
	//		}
	//	}
}

func DebugVar(name string, notify *bool) *bool {
	option_Debug_name[name] = notify

	return notify
}

//==============================================================================
func Today(days int) string {
	t := time.Now()
	if days > 0 {
		t.AddDate(0, 0, days) // years,months,days
	}
	return t.Format("2006-01-02")
}
