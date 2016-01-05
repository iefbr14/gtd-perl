package report

/*
NAME:

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

*/

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

	my($ini) = "$todo/Access.yaml";
	unless (-f $ini) {
		open(my $fh, '>', $ini) or die "Can't create $ini ($!)\n";
		print {$fh} <<'EOF';
gtd:
    host:      localhost
    dbname:    gtd
    user:      gtd
    pass:      gtd-time
    prefix:    gtd_

resource:
    category:
	Where: personal
    context:
	Context: personal
    goal:
        Golename: personal
    role:
        Rolename: personal
EOF

		close($fh);
		print "created $ini\n";
		print "Please set/verify the values in [gtd] section\n";
	}
}

1;  # don't forget to return a true value from the file
