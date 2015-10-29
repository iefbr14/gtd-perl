package Hier::Prompt;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		prompt
	);
}

use strict;
use warnings;

our $Debug;

my $Prompt = '> ';
my $Term;

my $Mode = 0;	# 0 - unknown
		# 1 - file input
		# 2 - term input

sub prompt {
	my($prompt);

	init_mode();

	for (;;) {
		if ($Mode == 1) {
			$_ = <STDIN>;

			return unless defined $_;

			chomp $_;
		} else {
			$_ = $Term->readline($Prompt.' ');

			print "# eof\n";
			return unless defined $_;
		}

		next if /^\s*#/;
		next if /^\s*$/;

		if ($Mode == 1) {
			print "$Prompt\t$_\n";
		} else {
	#		$term->addhistory($_);
		}
		return $_;
	}
}

sub init_mode {
	return if $Mode;

	if (-t STDIN) {
		$Mode = 2;
		$Term = Term::ReadLine->new('gtd');
	} else {
		$Mode = 1;
	}
}


1; # <=============================================================
