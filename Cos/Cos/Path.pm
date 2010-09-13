
# $Id: Path.pm,v 1.1 2005/03/29 21:47:04 drew Exp $
# $Source $
#
=head1 USAGE

 use Cos::Path;

=head1 DESCRIPTION

 addes the /home/cos/bin paths to the environment

=head1 BUGS

=cut


package Cos::Path;

use strict;


BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

load_env();

sub load_env {
	add_env('/home/cos/bin') if -d '/home/cos/bin';
	add_env('/opt/cos/bin') if -d '/opt/cos/bin';
}

sub add_env {
	my($newpath) = @_;

	my(%path);
	%path = map { $path{$_} = 1 } split(':', $ENV{PATH});

	return if defined $path{$newpath};


	$ENV{PATH} = $newpath . ':' . $ENV{PATH};
}

1;
