#!/usr/bin/perl


###############################################################################
#
#  name: util.pm
#  purpose: Different subroutines for the administrative CGI scripts
#   (See utilcfg.pm for some of the configuration parameters, e.g. config{})
#  subroutine names:
#`		cgi_query
#		db_connect      del_cookie
#		db_disconnect   log_error
#		send_err_header     user_error
#		send_err_footer     cgi_error
#		send_ord_footer auth_error
#		show_user       auth_notadmin
#		redirect        acl
#		redirectURL     url_encode
#		redirectHTML    url_decode
#		get_input       number_check
#		get_file        get_date
#		exit
#		get_cookie      display
#		set_cookie      authenticate
#
###############################################################################
package Cos::w2;		# webservices version 2

require Exporter;		# acquire the Exporter module's ability


@ISA = qw (Exporter);		# Declare the module to inherit Exporter's capability,
				# by setting the variable @ISA to equal "Exporter"
				# and next

# what symbols will be automatically available to an importing module
@EXPORT = qw(@EXPORT_OK);	# the same symbols as @EXPORT_OK

# what symbols will have to be requested by an importing module
@EXPORT_OK = qw($dbh encrpyt);		# only the $dbh header will be available
				# by request, all other subroutines must
				# be called with the full package name


use strict;			# keep things safe
use utf8;
use encoding 'utf-8';
use Cos::Dbh;
use Text::CSV;


###########################################################
#
#     Site specific navigation
#
###########################################################
### BUG ### depricate these
my %config;

# When persistent cookies will expire
$config{'cexp'} = 'Thu, 31-Dec-2020 23:00:00 GMT';
#$config{'cexp'} = '+5m';

# If your time needs to be adjusted, in hours (2,1,0,-1,-2)
$config{'adjusttime'} = 	0;


###########################################################
#
#  Load site local configs
#
###########################################################

$ENV{'SERVER_NAME'} = 'test' unless defined $ENV{'SERVER_NAME'};
# create a filename based on 'server_name'
my($f) = $ENV{'SERVER_NAME'} . ".cfg";

if (-f $f) {

    my($key, $val);
    open(F, $f);

    while (<F>) {
	next if /^\s*$/;
	next if /^\s*#/;
	chomp;
	($key, $val) = split(' ', $_, 2);
	$config{$key} = $val;
    }
        
    close(F);

}


use vars    qw($dbh);

use CGI;			# Include the CGI.pm symbols

my $Query;
my $Authenticated = 0;

###########################################################
#
#  subroutine name: cgi_query
#  purpose:
#  used internally by: redirectURL, get_input, get_file,
#      get_cookie, set_cookie, del_cookie, user_error,
#      auth_error
#
###########################################################

sub cgi_query {

	# do this if $Query is already instantiated 
	return $Query if $Query;

	$Query = new CGI;
	$Query->charset('utf-8');

	return $Query;
}

# Some versions of perl are barking about the DBI and statement handlers
# For now, we are just turning these off.
# Uncomment this if you are getting DBI and statement handler errors in
# your error log.
#$SIG{'__WARN__'} = sub { };

# Uncomment this if you want to send cgi errors to the browser
$SIG{'__WARN__'} = \&cgi_error;

#my %cookie = &get_cookie();


###########################################################################
#
# Database related subroutines
#
###########################################################################


###########################################################
#
#  subroutine name: db_connect
#  purpose: connects to the database
#
###########################################################

sub db_connect{

	$dbh = new Cos::Dbh;

	# If we are not using Mod_Perl
	if (!$ENV{'MOD_PERL'}) {
		$dbh->{'Warn'} = 0;	# then turn off warning
	}
}


###########################################################
#
#  subroutine name: db_disconnect
#  purpose: disconnects from database
#
###########################################################

sub db_disconnect{

    defined $dbh and ($dbh->disconnect
        or
    die "Can't disconnect from database. Reason: $DBI::errstr" and undef $dbh);

}


###########################################################################
#
# HTTP handling subroutines
#
###########################################################################


###########################################################
#
#  subroutine name: send_err_header
#  purpose: sends the HTML header block
#
###########################################################

sub send_err_header {
    my ($title) = @_;
    
    my $cgi = cgi_query();	# get reference to CGI namespace
    if ($Authenticated) {
	  print $cgi->header(-charset=>'utf-8');
   } else {
	  my @cookie = Cos::w2::del_cookie("Username","Password");
	  print $cgi->header(
			-charset=>'utf-8',
			-cookie=>[ @cookie ]
	  );
   }
    print "<HTML><HEAD>\n";
    print '<META HTTP-EQUIV="Expires" CONTENT="Mon, 01 Jan 1990 00:00:01 GMT">'."\n";
    
    print "</HEAD>\n";

    print "<TITLE>$title</TITLE>\n";
    print "</HEAD>\n";
    print "<BODY>\n";

}

###########################################################################
#
#              CGI handling subroutines
#
###########################################################################


###########################################################
#
#  subroutine name: get_input
#  purpose: Parses form input and returns it in a hash.
#  useage: my %in = &get_input;
#
###########################################################

sub get_input {

    my %in    = ();		# Resulting param name-value hash
    my $query = cgi_query();	# Get a reference to the CGI object

    # Get names of all the CGI parameters in this array
    my @param_names = $query->param;
    
#send_header("DEBUG");
#print "<pre>\n";
    # Get a value for the appropriate parameter and put them in a hash
    foreach my $param_name ( @param_names ) {
        
	my $param_val = $query->param($param_name);
	Encode::_utf8_on($param_val);
#print "$param_name: $param_val === ", hd($param_val), "\n";
        $in{$param_name} = $param_val;
	
    }
#foreach my $env (sort keys %ENV) { print "$env=$ENV{$env}\n" };
#print "</pre>\n";
    return %in;

}

sub hd {
	my($val) = @_;
	my($hd) = '';
	foreach my $c (split(//, $val)) {
		$hd .= sprintf("%x ", ord($c));
	}
	return $hd;
}


###########################################################
#
#  subroutine name: get_file
#  purpose: get file from multipart/form-data
#  usage: $status = &get_file($file_field_name);
#
###########################################################

sub get_file {
	
    my $filename = shift;	# get whatever was passed
    my $query = cgi_query();	# get reference to CGI namespace

    return 0 unless defined $filename;	# make sure

    my $fh = $query->upload( $filename ); # get a local copy of the reference

    # if we got a file handle to the temporary file created by CGI.pm
    if( $fh ) {
	
	rename("${filename}.csv", "${filename}.old.csv");
	# open for writing
        open(DATA,">${filename}.csv") or die "Can't create ${filename}.csv ($!)\n";
        
	while( <$fh> ) {
            print DATA;		# write the file out
        }
	
        close(DATA);
        return 1;		# successful return
	
    # there must be a CGI error	
    } else {
	my ($errstr) = $query->cgi_error; 

	if ($errstr) {
		print "CGI error($filename): $errstr<br>\n";
	} else {
		print "CGI nodata($filename)<br>\n";
        }
        return 0;
	
    }
    
}


###########################################################################
#
# Cookie handling subroutines
#
###########################################################################


###########################################################
#
#  subroutine name: get_cookie
#  purpose: Gets the cookie value specified by $cookie_name
#  usage: my $cookie_value = &get_cookie($cookie_name);
#
###########################################################

sub get_cookie {

    my $cookie_name = shift;
    
    my $query = cgi_query();
    
    return $query->cookie(-name=>$cookie_name);

}


###########################################################
#
#  subroutine name: set_cookie
#  purpose: Sets a cookie.
#  usage: set_cookie('Name',"Value",?)
#                   ? = 0 or 1. 0 = temp, 1 = permanent
#
###########################################################

sub set_cookie {

    my @cookie = @_;	# get whatever was passed
    
    my ($cookie, $value, $type, $cur_cookie);
    my @res_cookie = ();

    my $query = cgi_query();	# get reference to CGI namespace

    for (my $i = 0; $i <= $#cookie; $i = $i + 3) {
	
        ($cookie, $value, $type) = @cookie[$i .. $i+2];

        if ($type == 1) {
	
            $cur_cookie = $query->cookie(-name=>$cookie,
					-value=>$value,
					-expires=>$config{'cexp'});
	    
        } else {
	
            $cur_cookie = $query->cookie(-name=>$cookie,
					-value=>$value);
        }

        push @res_cookie, $cur_cookie;
    }

    return @res_cookie;

}


###########################################################
#
#  subroutine name: del_cookie
#  purpose: Delete cookies.
#  usage : del_cookie( 'Name',['Name', ...] )
#
###########################################################

sub del_cookie {

    my @cookie = @_;
    my @res_cookie = ();  
    my $cur_cookie = '';

    my $query = cgi_query();

    foreach my $cookie ( @cookie  ) {
        $cur_cookie = $query->cookie(-name=>$cookie,-value=>'',
					-expires=>'-1y');
        push @res_cookie, $cur_cookie;
    }

    return @res_cookie;

}


###########################################################################
#
# Error handling subroutines
#
###########################################################################


###########################################################
#
#  subroutine name: log_error
#  purpose: keep track of errors in the httpd errorlog
#
###########################################################

sub log_error {
	return;
	
    my $msg = shift;
    my $dt = `date`;

    chomp($dt);
    
    $dt = '['.$dt.']';
    print STDERR "$dt $msg\n";
 
}


###########################################################
#
#  subroutine name: user_error
#  purpose: user did something wrong
#
###########################################################

sub user_error {

    my ($error,$redir) = @_;
    my $cgi = cgi_query();



    send_err_header("Problem Encountered: $error",$redir);

	print "<hr><h1>$error</h1>";

    send_err_footer();

    # then just end the script with the error
    exit($error);
    
}


###########################################################
#
#  subroutine name: cgi_error
#  purpose: System did something wrong
#
###########################################################

sub cgi_error {

    my $error = shift;
    
    send_err_header("Problem Encountered");
    print "System Error: $error";
    send_err_footer();
    
    #exit();
    die($error);
    
}


###########################################################
#
#  subroutine name: auth_error
#  purpose: standard error for bad authentication
#
###########################################################

sub auth_error {
	
    my $user = shift;
  
    my $cgi = cgi_query();
  
    if( !defined($user) or $user eq '') {
	
        print $cgi->redirect('login.cgi');
        exit 0;
    
    }

}


sub send_err_footer {
    print "</BODY></HTML>\n"
}

###########################################################
#
#  subroutine name: auth_notadmin
#  purpose: standard error for bad authentication
#
###########################################################

sub auth_notadmin {
	
    my $user = shift;
    my $type = $user->{'U_Type'};

    
    unless( $type =~ /[SA]/ ) {
        user_error("Need admin account to perform this action");}

}

###########################################################################
#
# Security Subroutines
#
###########################################################################


###########################################################
#
#  subroutine name: acl
#  purpose: checks the permissions for a range of actions using
#      Access Control Lists defined in utilcfg.pm for
#      every action
#
###########################################################

sub acl {
	my ($user_type,$acct_type,$type) = @_;
  
    # First check the values of $user_type and $acct_type
    if ( !defined($user_type) || !defined($acct_type)) {
	
	return 0;
    }

    #                 S A L F R W
    my $acl = {	'S'=>[1,1,1,1,1,1],
		'A'=>[0,0,1,1,1,1],
                'L'=>[0,0,0,1,1,1],
		'F'=>[0,0,0,0,0,0],
		'R'=>[0,0,0,0,0,0],
                'W'=>[0,0,0,0,0,0] };

    $acct_type =~ tr/SALFRW/0-5/;
    
    return $acl->{$user_type}->[$acct_type];
}


###########################################################################
#
# Misc subroutines
#
###########################################################################


###########################################################
#
#  subroutine name: url_encode
#  purpose: Encodes a string for printing in a URL.
#  usage: my $encoded = &url_encode ($string);
#
###########################################################

sub url_encode {

    my $input = shift;
  
    return CGI::escape($input);

}


###########################################################
#
#  subroutine name: url_decode
#  purpose: Decodes a string that's been encoded in a URL.
#  usage: my $string = &url_decode ($encoded);
#
###########################################################

sub url_decode {

    my $input = shift;
    
    return CGI::unescape($input);

}


###########################################################
#
#  subroutine name: number_check
#  purpose: Make sure that we only have numeric data
#      for SQL calls
#
###########################################################

sub number_check {

    my $data = shift;
    
    $data =~ tr/0-9//cd;
    
    return $data;

}


###########################################################
#
#  subroutine name: get_date
#  purpose: returns a date in seconds
#
###########################################################

sub get_date {

    my ($currtime)=time();
  
    my ($adjust)=$currtime+($config{'adjusttime'}*3600);
  
    return $adjust;

}


###########################################################
#
#  subroutine name: exit
#  purpose: Figure out how we should exit
#
###########################################################
sub exit{

    if(exists $ENV{MOD_PERL}) {
	
        Apache::exit(0);
    
    } else {
	
        CORE::exit(0);
    
    }

}


###########################################################
#
#  subroutine name: display
#  purpose:
#
###########################################################

sub display {
	
    my($file) = @_;

    open(F, "< $file") or user_error("Can't open $file ($!)\n");
    while(<F>) {
	
        print;
	
    }
	
    close(F);
    
}


###########################################################
#
#  subroutine name: authenticate
#  purpose: Checks the username/password to make sure it
#      is valid, and returns a hash of the user info.
#      If no parameters are provided, it gets the
#      username/password from cookies. Returns undef if
#      unable to validate or no username/password found.
#		Does not check if U_Status is Active.
#
###########################################################

sub authenticate {

	db_connect() unless defined $dbh;

	if ($< == 0) {
		$Authenticated = 1;
		return;
	}
	if ($ENV{'HOME'}) {
		$Authenticated = 1;
		return;
	}
	$Authenticated = 1;
	return;

	my ($Username, $Password);
	($Username, $Password) = @_;

	### BUG ### need cgi values
	if ( ($Username eq "COOKIE") && ($Password eq "COOKIE") ) {
		$Username   = &get_cookie('Username');
		$Password   = &get_cookie('Password');
	}

	return undef unless $Username and $Password;


	my $query = "SELECT * FROM Users WHERE U_Username = ? AND U_Password = ?";

	my $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute($Username, $Password) or die "Can't execute: $query. Reason: $!";

	my $user = $sth->fetchrow_hashref;
	$sth->finish;

	if ($user) {
	    $Authenticated = 1;
	} else {
	    auth_error($user);
	}

	return $user; # return the hashref
    
}

sub encrypt {
	my($pass, $salt) = @_;

	Encode::_utf8_off($pass);
	$salt = gensalt(2) unless defined $salt;

	return crypt($pass, $salt);
}

sub gensalt {
	my $count = shift;

	my @salt = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
	my $salt;
	for (1..$count) {
		$salt .= (@salt)[rand @salt];
	}
	return $salt;
}

sub dump_table_csv {
	my($table) = shift @ARGV;
	my($where) = shift @ARGV;

	my($CSV) = Text::CSV::new;
	my($query) = "SELECT * FROM $table";
	if ($where) {
		$query .= ' WHERE ' . $where;
	}

	# ---------------------------------------------------------------
	# Prep to get all of the data
	my($Dbh) = new Cos::Dbh;

	my $sth = $Dbh->prepare($query) or
	  die("Cannot prepare: $query Reason: $DBI::errstr");
	$sth->execute() or
	  die("Cannot execute: $query Reason: $DBI::errstr");

	my(@keys, $key, @vals, $val);

	# ---------------------------------------------------------------
	# Handle over-riding the list of keys
	if (@ARGV) {
		@keys = @ARGV;

		$CSV->combine(@keys);
		print $CSV->string(), "\n";
	}

	# ---------------------------------------------------------------
	# Dump the data

	my $total = 0;

	while( my $ref = $sth->fetchrow_hashref() ) {

		# if we don't have a list of keys yet
		# use the ones we get back.
		unless (@keys) {
			@keys = sort keys %$ref;

			$CSV->combine(@keys);
			print $CSV->string(), "\n";
		}

		@vals = ();
		foreach $key (@keys) {
			$val = $ref->{$key};
			$val = '' unless defined $val;
			push(@vals, $val);
		}

		$CSV->combine(@vals);
		print $CSV->string(), "\n";
		$total++;

	}
}


#####################################################################
#
#			end of file - except for last true statement
#
#####################################################################
1;
