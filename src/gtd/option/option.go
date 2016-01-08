package option

import "fmt"
import "time"
import "strconv"


//=============================================================================
var option_debug bool
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
	key = option_key(key)		// map alias
	val, ok := options[key]
	if ok {
		return val
	}

	if option_debug {
		fmt.Printf("Fetch Option %s == nil\n", key)
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

func Flag(key string, flag string) {
	fmt.Printf("... Code option.Flag -%s %s\n", flag, key);
}


//==============================================================================
// Debug
//------------------------------------------------------------------------------
func Debug(what string) {
	if option_debug {
		fmt.Printf("### Debug: %s\n", what)
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

	if what == "on" {
		option_debug = true
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

func Filter(opt, filter, desc string) {
	// add to options handler for opt to set filter with desc
	fmt.Printf("... code options.Filter\n")
}

//==============================================================================
var Today = time.Now()

func get_today(days int) time.Time {
	if days == 0 {
		return Today
	}

	panic("write get_today")
	//	Today = time.Now()
	//       my($when) = $now + 60*60*24 * $later; # 7 days
	//
	//	return fmt.Sprintf("%04Y-%02m-%02d \%T", gmtime($when));
}
