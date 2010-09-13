# $Id: lock.pm,v 1.1 2003/12/31 14:40:41 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::lock;

 lock_dir($path);
 unlock_dir($path);

=head1 DESCRIPTION

Used to lock a directory for processing.

=cut

package Cos::lock;

use strict;
#use warnings;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&lock_dir &unlock_dir);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

my($Lock) = '';
END {
	unlock_dir();
}

sub lock_dir {
	my($dir) = @_;

	check_lock("$dir/LCK..cos");

	open(L, ">$dir/LCK..$$");
	print L "$$\n";
	close(L);

	unless (link("$dir/LCK..$$", "$dir/LCK..cos")) {
		check_lock("$dir/LCK..cos");
		unless (link("$dir/LCK..$$", "$dir/LCK..cos")) {
			die "Can't get lock.\n";
		}
	}
	unlink("$dir/LCK..$$");

	$Lock = "$dir/LCK..cos";		# we have the lock
}

sub unlock_dir {
	return if $Lock eq '';

        unlink($Lock);
	$Lock = '';
}

sub check_lock {
        my($lock) = @_;
        my($pid, $cnt);

        return unless -f $lock;

        open(L, "< $lock\0") or die "Can't open lock $lock ($!)\n";
        $pid = <L>;
        chomp $pid;
        close(L);

        $cnt = kill 0, $pid;

        if ($cnt) {
                warn "It's alive!  (process: $pid in $lock)\n" if $Debug;
                exit 0;
        }

        warn "It's dead jim. (process: $pid in $lock)\n" if $Debug;
        if (unlink($lock)) {
                warn "Removed broken lock $lock\n";
        } else {
                die "Can't remove broken lock $lock ($!)\n";
        }
}

1;
