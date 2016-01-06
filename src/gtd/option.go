package gtd

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		option set_option 
		debug
		load_report run_report
		get_today
	);
}

use strict;
use warnings;

use POSIX qw(strftime);

//=============================================================================
var options map[string]int;
var option_keys map[string]int = {
	'Debug'       , 1,
	'MetaFix'     , 1,
	'Mask'        , 1,

	'Changed'      , 1,		// time of last db changed.
	'Current'      , 1,		// current task (used as parent in new)
					// used as default in edit

	'Title'       , 1, // 'Subject'     => 'Title',
	'Task'        , 1, // 'Desc'        => 'Task', 'Description' => 'Task',
	'Note'        , 1, // 'Result'      => 'Result',

	'Category'    , 1,
	'Context'     , 1,
	'Timeframe'   , 1,
	'Priority'    , 1,
	'Complete'    , 1,
	'Tag'         , 1, // 'Tags'        => 'Tag',

	'Color'       , 1, // 'Colour'      => 'Color',

	'List'        , 0,

	'Limit'       , 1,
	'Reverse'     , 1,	// reverse sort

	'Header'      , 1,	// Header routine
	'Format'      , 1,	// Formating routine
	'Sort'        , 1,	// Sortting routine
	'Filter'      , 1,     # Default filter mode

	'Layout'      , 1,// 'Text', # Layout format

	'Date'        , 1,// '',	// Date (completed etc)

	'Mode'        , 1,// '',    # no mode set yet
);

our $Debug = 0;

sub option_key {
	my($key) = @_;

	my($newkey) = $Option_keys{$key};
	unless (defined $newkey) {
		warn "Unknown option: $key\n";
		$Option_keys{$key} = 1;
		$newkey = 1;
	}
	if ($newkey =~ /^[A-Z]/) {
		$key = $newkey;
	}
	return $key;
}
	
// set_option
func Flag(name string, opt rune) {
	
}

func Set(key string, val string) {

	// an alias is a valid option, but not the main key for it
	// often comes from command line or provide backward compatibility
	if alias, err := option_alias(key); err == nil {
		key = alias
	} 

	// option
	Options[key] = val;
}

sub option {
	my($key, $default) = @_;

	$key = option_key($key);

	unless (defined $Options{$key}) {
		warn "Fetch Option $key == undef\n" if $Debug;
		if (defined $default) {
			$Options{$key} = $default;
		}
	} else {
		warn "Fetch Option $key => $Options{$key}\n" if $Debug;
	}

	return $Options{$key};
}


//==============================================================================
// Debug
//------------------------------------------------------------------------------
func Debug(what string) {
	if Debug {
		warn "### Debug: $what\n";
	}

	if ($what =~ /^[A-Z]/) {
		no strict 'refs';
		my($var) = "Hier::${what}::Debug";
		$$var = 1;

//		if ($@) {
//			warn "Debug $var failed\n";
//			return;
//		}
		print "Debug of $what on\n";
		return;
	}

	if (what == "on") {
		Debug = 1;
		Set("Debug", "1");
		return;
	}

	if (what == "main") {
		$main::Debug = 1;
		return;
	}

	if ($what =~ /^[a-z]/) {
		load_report($what);

		no strict 'refs';
		my($var) = "Hier::Report::${what}::Debug";
		$$var = 1;
//		eval "Hier::Report::$what::Debug = 1";
//		if ($@) {
//			warn "Debug Hier::Report::$what failed\n";
//			return;
//		}
	}	
}

type Report func([]string)

var report map[string]Report = {
	"noop",		report.Noop,
}

func Filter(opt, filter, desc string) {
	// add to options handler for opt to set filter with desc
	panic("Not yet")
}
	

// load_report -- return 1 if it compile correctly
func load_report(arg []string) rfunc Report {
	my(report_name) = @_;

	rfunc, err := report[report]
	if err == nil {
		fmt.println("#:? Bad command: $report")
		return nil;
	}

	return rfunc;
}

// run report but protect caller from report failure 
sub run_report {
	my($report) = shift @_;

	if ($report !~ /^[a-z]+$/) {
		print "#:? Bad command: $report\n";
		return;
	}

	my($func) = \&{"Report_$report"};

	//##BUG### run_report has too unneeded eval
	//######## is this eval needed now that load_report does
	//######## basic report name syntax checking.
	//######## if it load then failure to run is still just a failure
	eval {
		return $func->(@_);
	}; if ($@) {
//		return if $@ =~ /Undefined subroutine.*Report_\Q$report\E/;
		panic("#:? Report $report failed: $@");
	}
	return;
}

//==============================================================================
my $Today = _today();

sub _today {
        my($later) = @_;
        $later = 0 unless $later;

        my($now) = time();
        my($when) = $now + 60*60*24 * $later; # 7 days

	return strftime("%04Y-%02m-%02d \%T", gmtime($when));
}

sub get_today {
	if (@_) {
		return _today(@_);
	}
	return $Today;
}


1; # <=============================================================
