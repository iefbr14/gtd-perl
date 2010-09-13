# $Id: debug.pm,v 1.1 2003/12/31 14:40:41 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::debug;

 $Debug
 trace($msg)
 trace_log($path)

=head1 OPTIONAL

 trace_warn($msg)
 trace_die($msg)

=head1 DESCRIPTION

Used to manage the $Cos::debug::Debug variable

=item trace_warn - generates a trace back function call list

=item trace_die - used to kill program with a trace back 

=cut


package Cos::debug;

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
	@EXPORT      = qw($Debug);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK = qw(&trace &trace_log &trace_back &trace_die);
}
use vars @EXPORT_OK;

my($Debug) = 0;
my($Log) = '';

sub debug {
	if (@_) {
		$Debug = $_[0];
	}

	return $Debug;
}

sub trace {
	return unless $Debug;

	print "@_\n";

	print TRACELOG "@_\n" if $Log;
}

sub trace_log {
	if (@_ == 0) {
		close(TRACELOG) if $Log;
		$Log = '';
		return;
	}

	$Log = $_[0];
	unless (open(TRACELOG, ">> $Log\0")) {
		warn "Can't open trace_log($Log): $!\n";
		$Log = '';
		return;
	}
}

END {
	close(TRACELOG) if $Log;
	$Log = '';
}


# ===========================================================================
# trace back management
# ***BUG*** add traceback to TRACELOG
# ===========================================================================
sub trace_back {
        my($i, @list);

        for ($i=0;;++$i) {
                @list = caller($i);
                last unless @list;

                warn "Traceback($i): ", join(' ', @list), "\n";
        }
        warn "Traceback(msg):", @_, "\n";
}

sub trace_die {
        my($i, @list);

        for ($i=0;;++$i) {
                @list = map { defined $_ ? $_ : '' } caller($i);
                last unless @list;

                warn "Traceback($i): ", join(' ', @list), "\n";
        }
        die "Traceback(msg):", @_, "\n";
}
