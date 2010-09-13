package Cos::process;

use strict;
#use warnings;

use Cos::Dbh;

use Cos::JobRequest;
use Cos::JobSave;
use Cos::Dbh;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&process_jobs);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

# 
# dest is either the string:    'lab:XXX' where XXX is the lab number
# or is the name of a user.

sub process_jobs {
	my($user) = shift @_;

	chdir('/home/cos/recv');

	while (-d "$user.tmp") {
		sleep(0);
	}

#process the rdt directory
#if ( -d "/home/cos/recv/$user/rdt") {
#        process( "/home/cos/recv/$user/rdt" );
#}

	rename($user, "$user.tmp");
}


# ----------------------------------------------------------------------------------------------------
sub process {
# ----------------------------------------------------------------------------------------------------
	my($dir) = @_;
	my($job, $jobreq);

	foreach $job (Cos::JobRequest::list($dir)){
		my($jobreq);
		my( $fileprefix ) = $job;
		$fileprefix =~ s=.*/(.*)$=$1=;
		#print "$fileprefix\n";
		eval {
			$jobreq = Cos::JobRequest::load($job);
		};
		if ($@) {
			#job is not saved. file is moved to /home/cos/work/Fail/
			warn $@;
			rename( $job . "r", "/home/cos/work/Fail/$fileprefix" . " r" );
			rename( $job . "d", "/home/cos/work/Fail/$fileprefix" . " d" );
			rename( $job . "t", "/home/cos/work/Fail/$fileprefix" . " t" );
			rename( $job . "R", "/home/cos/work/Fail/$fileprefix" . " R" );
			rename( $job . "D", "/home/cos/work/Fail/$fileprefix" . " D" );
			rename( $job . "T", "/home/cos/work/Fail/$fileprefix" . " T" );
			next;
		}
		$jobreq->{job_date} = '';
		my($order_id) = Cos::JobSave::save($jobreq);
		my($dbh) = Cos::Dbh::new;
		my( $rowsUpdated ) = $dbh->do( "UPDATE orders_pending SET status='N' WHERE orders_pending_id=?", undef, $order_id );

		#once the file is processed do somethig with it
		my( $archive ) = mksavepath() . $fileprefix;
		rename( $job . 'r', $archive . 'r'  ) or die "Can't rename $job" . "r" ." ($!)\n";
		rename( $job . 'd', $archive . 'd'  );
		rename( $job . 't', $archive . 't'  );
		rename( $job . 'R', $archive . 'R'  );
		rename( $job . 'D', $archive . 'D'  );
		rename( $job . 'T', $archive . 'T'  );
	}
}


# ----------------------------------------------------------------------------------------------------
sub mksavepath{
# ----------------------------------------------------------------------------------------------------
	my( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( time );
	my( $path ) = sprintf( "/home/cos/work/Done/%4d/%02d/%02d", $year+1900, $mon+1, $mday);
	mkpath( $path );
	return $path . '/';
}


# ----------------------------------------------------------------------------------------------------
sub mkpath{
# ----------------------------------------------------------------------------------------------------
	my( $path ) = @_;
	return if -d $path;
	my( $parent ) = $path;
	return unless $parent =~ s=^(.*)/.*=$1=;
	return if $parent eq '';
	mkpath( $parent );
	unless( mkdir $path, 0777 ){
		print "error: could not create directory $path $1";
	}
}

1;
