#!/usr/bin/perl
###########################################################
#
#    Configuration for Session tracking utilities
#
###########################################################
package Cos::utilcfg;       # define this as a package namespace

require Exporter;           # acquire the Exporter module's ability

@ISA = qw (Exporter);

# what symbols will be automatically available to another importing module
@EXPORT = qw(@EXPORT_OK);   # the same symbols as @EXPORT_OK

# what symbols will have to be requested by an importing module
@EXPORT_OK = qw(%config);   # only the %config hash will be available
                            # by request, all other subroutines must
                            # be calledwith the full package name

use vars qw(%config);

use strict;                 # keep things safe

###########################################################
#
#  User defined variables -  Production Site
#
###########################################################

# Relative Url containing images 
$config{'images'}   = 	'/OO_images';

# Name of the server running sql - (yourhost.com or localhost)
$config{'dbserver'} = 	'cosdb.optical-online.com';

# Name of the database you created for the sql tables
$config{'dbname'}   = 	'webrx';

# Name of the DBI driver you are using
$config{'dbdriver'} = 	'mysql';

# Name of the database user to connect as.
$config{'dbuser'}   = 	'WEB';

# Password of the database user.
$config{'dbpass'}   = 	'';

# Use sendmail or a SMTP server.  If you are on a server that has
# the sendmail program then set $config{'sendmail'} to the location
# of the server.  If you do not have sendmail then set 
# config{'SMTP'} to the name of the SMTP server you wish to use.
# Make sure you uncomment the one you want to use.
# DO NOT LEAVE BOTH UNCOMMENTED
$config{'sendmail'} = 	'/usr/sbin/sendmail';
# $config{'SMTP'} = 		'name.smtp.server.';

# URL of the server the program is running from. 
# For multiple referers seperate them with a |
$config{'referer'}  = 	'http://www.optical-online.com';

###########################################################
#
#     Site specific navigation
#
###########################################################

# Title of site
$config{'title'} = 		'Optical Online';

# Your home page
$config{'homeurl'} = 	'http://www.optical-online.com/';

# Text for your homepage link
$config{'urltitle'} = 	'www.optical-online.com';

# Text for your homepage link
$config{'bgcolor'} = 	'FFFFFF';

# Your email address
$config{'emailaddy'} = 	'webmaster@optical-online.com';

# Text for your email address
$config{'emailtitle'} = 	'Email Us';
  
# When persistent cookies will expire
$config{'cexp'} = 'Thu, 31-Dec-2020 23:00:00 GMT';
#$config{'cexp'} = '+5m';

# If your time needs to be adjusted, in hours (2,1,0,-1,-2)
$config{'adjusttime'} = 	0;

# We also need the url to the files directory.
$config{'fileurl'} = 	'/oo_files';

# If you are allowing file attachments then you need to set a maximum
# filesize.  If a user tries to upload a file larger than what is set
# they will get an error message.  This is measured in bytes.
$config{'filesize'} = 	3000000;

# Your Time Zone - PST, EST, etc.
$config{'timezone'} =	'EST';

# Allow users to specify their password at the time of creating their userid
$config{'userpass'}	=	'off';

# Allow multiple usernames from the same email address
# On - 'Allow multiple' : Off - 'Do not allow multiple'
$config{'multiuser'} = 	'on';

# Path to templates
$config{'tmplpath'} = '/home/httpd/templates';


###########################################################
#
#  Load site local configs
#
###########################################################

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


###########################################################
#
#           end of package / end of file
#
###########################################################
1;
