package Hier::Report::report;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_report &get_reports);

	our $OurPath = __FILE__;
}

use Hier::header;
use Hier::globals;
use Hier::Tasks;

our $OurPath;

sub Report_report {	#-- List Reports
	report_header('Reports');

	my @files  = get_reports();

	print join("\n", @files), "\n\n";
}

sub get_reports {
	my(@list, $name);
	
	my($f, $path);
	my($dir) = $OurPath;

	$dir =~ s=/report.pm==;
	opendir(DIR, $dir) or die;
	while ($f = readdir(DIR)) {
		next unless $f =~ /\.pm$/;

		$path = "$dir/$f";

		open(my $fd, "< $path") or die "Can't open $path ($!)\n";
		while (<$fd>) {
			next unless /^sub Report_(\w+)/;
			$name = $1;
			if (m/#--\s*(.*)/) {
				push(@list, sprintf("%-12s -- %s", $name, $1));
			} else {
				push(@list, $name);
			}
		}
		close($fd);
	}
	return sort @list;
}

1;  # don't forget to return a true value from the file
