package GTD::App;

use strict;
use warnings;

use Getopt::Std;

use GTD::Util;
use GTD::Db;
use GTD::Option;
use GTD::Filter;

sub usage {
	die <<"EOF";
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
EOF
}

sub run {
	my %Opt;

	getopts('xX:uS:F:H:f:LaAZ:o:T:c:C:D:p:N:s:t:l:r', \%Opt) or usage();

	my $Zname = $Opt{Z} || 'gtd';

	debug('main') if $Opt{x};

	set_option(MetaFix   => !($Opt{u} || 0));

	set_option(Title     => $Opt{s} || '');
	set_option(Task      => $Opt{d} || '');
	set_option(Note      => $Opt{N} || '');

	set_option(Context   => $Opt{C} || '');
	set_option(Category  => $Opt{c} || '');
	set_option(Timeframe => $Opt{T} || '');

	set_option(Limit     => $Opt{l}); 	# reports set own defaults

	set_option(Priority  => $Opt{p} || 0);
	set_option(Tag       => $Opt{T} || '');

	set_option(Header    => $Opt{H}) if $Opt{H};
	set_option(Format    => $Opt{F}) if $Opt{F};
	set_option(Sort      => $Opt{S}) if $Opt{S};
	set_option(Reverse   => $Opt{r} || 0);

	set_option(Layout    => $Opt{f}) if $Opt{f};	# layout format

	set_option(Date      => $Opt{D}) if $Opt{D};

	if ($Opt{o}) {
		set_option($Opt{o}, 1);
	}

	add_filter('+future') if $Opt{a};
	add_filter('+done')   if $Opt{A};

	DB_init($Zname);

	my($cmd) = $0;
	$cmd =~ s=.*/==;	# strip any path

	# the test here should be a "valid" command
	if ($cmd =~ /^g/) {
		# cmd is gtd or g, so run it's args
		if (@ARGV == 0) {
			report('rc');
		} else {
			report(@ARGV);
		}
	} else {
		# cmd was symlinked so run by name
		report($cmd, @ARGV);
	}

	exit 0;
}

sub report {
	my($report) = shift @_;

	exit 1 unless load_report($report);

	run_report($report, @_);
	exit 0;
}

1;
