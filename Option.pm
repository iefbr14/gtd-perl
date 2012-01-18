package Hier::Option;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw( option set_option get_today );
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

	'Limit'       => 1,
	'Reverse'     => 1,	# reverse sort

	'Format'      => 1,	# Formating routine
	'Sort'        => 1,	# Sortting routine

	'List'        => 1,	# tab seperated list format
	'Wiki'        => 1,	# media wiki format
	'Html'        => 1,	# html text format
);

my $Debug = 0;

sub option_key {
	my($key) = @_;

	my($newkey) = $Option_keys{$key};
	unless ($newkey) {
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
