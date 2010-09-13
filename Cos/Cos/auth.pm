# $Id: auth.pm,v 1.1 2003/12/31 14:40:41 cos Exp $
# $Source $
#
=head1 USAGE

 $ref = auth_user($user, $pass);
 $ref = auth_html($user, $pass);
        auth_prop($user, $pass);

=head1 OPTIONAL

        auth_cd($user, $ref);

=head1 DESCRIPTION

Used to validate a lab or retail user ($user) 
using a plain text password ($pass)

=item auth_user - returns the auth record

=item auth_html - displays an html error message is auth fails

=item auth_prop - prints a java properties error message on failure and exits

Otherwise it run auth_cd

= item auth_cd - changes to the xmit directory for the authenticated user

=cut


package Cos::auth;

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
	@EXPORT      = qw(&auth_user &auth_html &auth_prop);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw(&auth_cd);
}
use vars @EXPORT_OK;

use Cos::Dbh;

sub auth_user {
	my($user, $pass) = @_;

	return undef if $user eq '';
	return undef if $pass eq '';

	# Check the user account
	my($info) = sql("SELECT * FROM Users WHERE U_Username = ?", $user);

	
	return undef unless defined $info->{U_Password};
	return undef unless crypt($pass, $info->{U_Password}) eq $info->{U_Password};

	return $info;
}

sub auth_html {
	my($info) = auth_user(@_);

	return $info if $info;

	print <<"EOF";
<H1>Invalid user.</h1>
EOF
}

sub auth_prop {
	my($user, $pass) = @_;

	if (!defined($user) or $user eq '') {
		print "error:   missing user parm.\n";
		exit 0;
	}
	if (!defined($pass) or $pass eq '') {
		print "error:   missing pass parm.\n";
		exit 0;
	}

# Check the user account
	my($info) = sql("SELECT * FROM Users WHERE U_Username = ?", $user);

	
	unless (defined $info->{U_Password}) {
		# User ID not valid
		print "error:   auth failure.\n";
		exit 0;
	}

	unless (crypt($pass, $info->{U_Password}) eq $info->{U_Password}) {
		# Password not valid
		print "error:   auth failure!\n";
		exit 0;
	}

	auth_cd($user, $info);
}

sub auth_cd {
	my($user, $info) = @_;

	my($dir) = $user;

	if ($info->{U_Type} eq 'L') {
		$dir = $info->{U_InfoId};
	}

	if (!chdir("/home/cos/xmit/$dir")) {
		if ( -d "/home/cos/xmit/$dir") {
			print "error:   can't cd xmit/$dir ($!).\n";
			exit 0;
		}

		if (!mkdir("/home/cos/xmit/$dir", 02770)) {
			print "error:   can't create xmit/$dir ($!).\n";
			exit 0;
		}
		if (!chdir("/home/cos/xmit/$dir")) {
			print <<"EOF";
error:  Can't cd /home/cos/xmit/$dir $!
EOF
			exit 0;
		}       
	}
}

1;
