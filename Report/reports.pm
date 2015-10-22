package Hier::Report::reports;

=head1 NAME

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

=cut

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_reports &get_reports);

	our $OurPath = __FILE__;
}

use Hier::Util;
use Hier::Meta;
use Hier::Format;

our $OurPath;

my($Fname) = 0;

sub Report_reports {	#-- List Reports
	if (@_ && $_[0] =~ /^f/) {
		$Fname = 1;
	}
	report_header('Reports');

	my @files  = get_reports();

	print join("\n", @files), "\n\n";
}

sub get_reports {
	my(@list, $name);
	
	my($f, $path);
	my($dir) = $OurPath;

	$dir =~ s=/reports.pm==;
	opendir(DIR, $dir) or die "Can't open $dir ($!)\n";
	while ($f = readdir(DIR)) {
		next unless $f =~ /\.pm$/;

		$path = "$dir/$f";

		open(my $fd, "< $path") or die "Can't open $path ($!)\n";
		while (<$fd>) {
			next unless /^sub Report_(\w+)/;
			$name = $1;
			if ($Fname) {
				if ($f =~ /^(.*)\.pm$/) {
					$name = "$1\t$name";
				} else {
					$name = "$f\t$name";
				}
			}

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
