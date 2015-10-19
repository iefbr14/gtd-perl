package Hier::Option;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
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

#==============================================================================
my %Options;
my %Option_keys = (
	'Debug'       => 1,
	'MetaFix'     => 1,
	'Mask'        => 1,

	'Title'       => 1, 'Subject'     => 'Title',
	'Task'        => 1, 'Desc'        => 'Task', 'Description' => 'Task',
	'Note'        => 1, 'Result'      => 'Result',

	'Category'    => 1,
	'Context'     => 1,
	'Timeframe'   => 1,
	'Priority'    => 1,
	'Complete'    => 1,
	'Tag'         => 1, 'Tags'        => 'Tag',

	'Color'       => 1, 'Colour'      => 'Color',

	'List'        => 0,

	'Limit'       => 1,
	'Reverse'     => 1,	# reverse sort

	'Header'      => 1,	# Header routine
	'Format'      => 1,	# Formating routine
	'Sort'        => 1,	# Sortting routine
	'Filter'      => 1,     # Default filter mode

	'Layout'      => 'Text', # Layout format

	'Date'        => '',	# Date (completed etc)

	'Mode'        => '',    # no mode set yet
);

my $Debug = 0;

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
	
sub set_option {
	my($key, $val) = @_;

	$Options{option_key($key)} = $val;
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


#==============================================================================
# Debug
#------------------------------------------------------------------------------
sub debug {
	my($what) = @_;

	if ($main::Debug) {
		warn "### Debug: $what\n";
	}

	if ($what =~ /^[A-Z]/) {
		eval "Hier::$what::Debug = 1";
		if ($@) {
			warn "Debug Hier::$what failed\n";
			return;
		}
		print "Debug of $what on\n";
		return;
	}

	if ($what eq 'on') {
		$Debug = 1;
		set_option('Debug', 1);
		return;
	}

	if ($what eq 'main') {
		$main::Debug = 1;
		return;
	}

	if ($what =~ /^[a-z]/) {
		load_report($what);

		eval "Hier::Report::$what::Debug = 1";
		if ($@) {
			warn "Debug Hier::Report::$what failed\n";
			return;
		}
	}	
}

sub load_report {
	my($report) = @_;

	eval "use Hier::Report::$report";
	if ($@) {
		my($error) = "Report compile: $@\n";
		if ($error =~ /Can't locate Hier.Report.$report/) {
			print "Unknown command $report\n";
			print "try:  reports # for a list of reports\n";
			return 0;
		}
		die "Report compile failed: $@\n";
	}
	return 1;
}

sub run_report {
	my($report) = shift @_;

	my($func) = \&{"Report_$report"};

	eval {
		return $func->(@_);
	};
#	eval "Report_$report(\@_);";	# call report with argv
	if ($@) {
		die "Report $report failed: $@";
	}
	return;
}

#==============================================================================
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
