package gtd

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	// set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		prompt
	);
}

use strict;
use warnings;

our $Debug = 0;

my $Term;

my $Mode = 0;	// 0 - unknown
		// 1 - file input
		// 2 - term input

sub prompt {
	my($prompt, $ignore_comments) = @_;

	init_mode();

	for (;;) {
		if ($Mode == 1) {
			$_ = <STDIN>;

			return unless defined $_;

			chomp $_;
		} else {
			$_ = $Term->readline($prompt.' ');

			unless (defined $_) {
				print ":quit # eof\n";
				return;
			}
		}

		print "Prompt($prompt) read: $_\n" if $Debug;

		if ($ignore_comments) {
			next if /^\s*#/;
			next if /^\s*$/;
		}

		if ($Mode == 1) {
			print "$prompt\t$_\n";
		} else {
	//		$term->addhistory($_);
		}
		return $_;
	}
}

sub init_mode {
	return if $Mode;

	if (-t STDIN) {
		$Mode = 2;
		$Term = Term::ReadLine->new("gtd");
	} else {
		$Mode = 1;
	}
}


1; # <=============================================================
