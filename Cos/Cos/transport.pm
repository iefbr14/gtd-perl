# $Id: transport.pm,v 1.3 2003/12/31 14:39:19 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::transport;

 $id = transport_files($dest, @files);

=head1 OPTIONAL

 $id = transport_via($method, $dest, @files);

=head1 DESCRIPTION

Used to transport files to the specified destination.
transport_via can override the transport method

=head1 METHODS

=item mail-XXX

Use multi-part mail to transport files

=item cosx-XXX

Use the web based cosx transport system.

=item perl-XXX

Obsolete, inbound transport is out of scope, outbound is via mail.

=item uucp-XXX

Not impletement.  This might be useful some day.

=cut

package Cos::transport;

use strict;
#use warnings;

use MIME::Lite;
use Cos::Dbh;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&transport_files);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw(&transport_via);
}
use vars @EXPORT_OK;

#
# transport_via allows the transport to be overridden
#
my $Transport = '';
sub transport_via {
	$Transport = (shift @_) . '-';	# allow just the transport
	transport_files(@_);		# prefix 
	$Transport = '';
}

# 
# dest is either the string:    'lab:XXX' where XXX is the lab number
# or is the name of a user.

sub transport_files {
	my($dest) = shift @_;

	if ($dest =~ /^lab:(\d+)$/) {
		my($lab) = $1;

		return transport_lab($lab, @_);
	}

	my($user) = sql('select * from Users where U_Username = ?', $dest);

	if ($user->{U_Type} eq 'R') {
		return transport_user($dest, @_);
	}
	if ($user->{U_Type} eq 'L') {
		# U_InfoId for labs is the lab id.
		return transport_lab($user->{U_InfoId}, @_);
	}
}

sub transport_user {
	my($user) = shift @_;

	my($info) = sql('select * from retailer where user_id = ?', $user);

	my($transport) = $info->{transport};
	my($mbox)      = $info->{mbox};

	return transport_dest($transport, $user, $mbox, @_);
}

sub transport_lab {
	my($lab) = shift @_;

	my($info) = sql('select * from lab_info where lab_id = ?', $lab);

	my($transport) = $info->{transport};
	my($mbox)      = $info->{mbox};

	return transport_dest($transport, $lab, $mbox, @_);
}

sub transport_dest {
	my($transport) = shift @_;
	my($user)      = shift @_;
	my($mbox)      = shift @_;

	if ($Transport) {
		# magic from transport_via
		$transport = $Transport;
	}

	if ($transport =~ /^perl-/i) {
		return transport_via_perl($mbox, @_);

	} elsif ($transport =~ /^mail-/i) {
		return transport_via_mail($mbox, @_);

	} elsif ($transport =~ /^cosx-/i) {
		return transport_via_cosx($user, @_);

	} else {
		die "Unknown transport system: $transport\n";
	}
	return 0;
}

#===============================================================================
# cosx
#===============================================================================
sub transport_via_cosx {
	my($user) = shift @_;

	my($cnt) = scalar(@_);
	my($id) = time . '.' . $$;
	my($i) = 0;
	my($to, $target);
	my($type) = 'hou'; 	# default

	for my $file (@_) {
		$type = 'rx',  last if $file =~ /\.rx$/;
		$type = 'rdt', last if $file =~ /\.\d\d[rdt]$/;
	}

	for my $file (@_) {
		++$i;
		($to = $file) =~ s=.*/==;
		$to =~ s/-/_/g;

		$target = "/home/cos/xmit/$user";
		if ( ! -d $target) {
			mkdir($target, 02770)
			   or die "Can't create directory: $target ($!)\n";;
		}
		$target = "/home/cos/xmit/$user/$id-$i-$type-$to";
print "link $file -> $target\n";
		unless (link($file, $target)) {
			die "Can't link $file $target ($!)\n";
		}
	}
	return $cnt;
}

#===============================================================================
# mail
#===============================================================================

sub transport_via_mail {
	my($mbox) = shift @_;
	my($cnt) = 0;

	if ($mbox eq '') {
		die "Failed to map mailbox";
	}
	if ($mbox eq 'problems') {
		die "Attempt to send mail to problems";
	}

	my($msg) = MIME::Lite->new(
                        From    => 'problems@rfg.optical-online.com',
                        To      => $mbox . 'ot@rfg.optical-online.com',
                        Subject => "Optical Transport -> $mbox",
                        Type    => 'multipart/mixed'
                        );

	foreach my $file (@_) {
		next unless -s $file;

		$msg->attach(
			Type => 'application/octet-stream',
			Path => $file,
			Filename => "orders/${file}",
			Disposition => 'attachment'
		);
		++$cnt;
	}

	$msg->send;
	print "Mail sent to ${mbox}ot\@rfg.optical-online.com\n";
	return $cnt;
}

#===============================================================================
# perl-rdt
#===============================================================================

sub transport_via_perl {
	my($mbox) = shift @_;
	my($cnt) = 0;

	if ($mbox eq '') {
		die "Failed to map mailbox";
	}
	if ($mbox eq 'problems') {
		die "Attempt to send mail to problems";
	}

	my($msg) = MIME::Lite->new(
                        From    => 'problems@rfg.optical-online.com',
                        To      => $mbox . 'ot@rfg.optical-online.com',
                        Subject => "Optical Transport -> $mbox",
                        Type    => 'multipart/mixed'
                        );

	foreach my $file (@_) {
		next unless -s $file;

		# strip our funky 'lab-user:' prefix from file names
		$file =~ s=/.*:=/=;

		$msg->attach(
			Type => 'application/octet-stream',
			Path => $file,
			Filename => "orders/${file}",
			Disposition => 'attachment'
		);
		++$cnt;
	}

	$msg->send;
	print "Mail sent to ${mbox}ot\@rfg.optical-online.com\n";
	return $cnt;
}

1;
