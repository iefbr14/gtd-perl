package Hier::Report::init;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_goals);
}

sub Report_init {	#-- Init ~/.todo structure
	my($home) = $ENV{HOME};

	my($todo) = "$home/.todo";
	unless (-d $todo) {
		mkdir $todo, 0700 or die "Can't mkdir $todo ($!)\n";
		print "mkdir $todo\n";
	}

	my($ini) = "$todo/Access.ini";
	unless (-f $ini) {
		open(my $fh, '>', $ini) or die "Can't create $ini ($!)\n";
		print {$fh} <<'EOF';
[gtd]
        host   = localhost
        dbname = gtd
        user   = gtd-user
        pass   = gtd-pass
        prefix = gtd_
EOF
		close($fh);
		print "created $ini\n";
		print "Please set/verify the values in [gtd] section\n";
	}

		
}


1;  # don't forget to return a true value from the file
