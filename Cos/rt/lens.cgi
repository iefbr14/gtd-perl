#!/usr/bin/perl
#######################################
#
#	name: lens.cgi
#	purpose:  OpticalOnline retrieves
#			  lens data from specified
#			  table
#
#######################################
use DBI;
use CGI qw/:standard/;
use Cos::Dbh;
use utf8;
use encoding "utf-8";

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

# Check the user account
my($retailer) = sql("SELECT user_id,lab_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

# User ID is valid - continue
my($type) = param('type');
my($lab) = param('lab');
my($lab_id) = $retailer->{lab_id};

$lab = $lab_id if $lab eq '';

my($dbh) = new Cos::Dbh;

if ($type eq 'selection') {
	$query = <<"EOF";
SELECT style_code,material_code,color_code,rx_code,price 
FROM   lense_data 
WHERE  status='L' and lab_id=?
ORDER BY material_code,style_code,color_code
EOF
}

if ($type eq 'style') {
	$query = <<"EOF";
SELECT code,description,process_code 
FROM style_data 
WHERE status='L' and lab_id=?
ORDER BY description
EOF
}

if ($type eq 'material') {
	$query = <<"EOF";
SELECT code,description,type,thickness 
FROM material_data 
WHERE status='L' and lab_id=?
ORDER BY description
EOF
}

if ($type eq 'color') {
	$query = <<"EOF";
SELECT code,description2 
FROM color_data 
WHERE status='L' and lab_id=?
EOF
}


print <<"EOF";
# Version 1.0 lens.cgi information
# User:   $user
# Lab:    $lab
# Lab_id: $lab_id
# Type:   $type
#
EOF


sql_item($query, $lab);

sub sql_item {
	my($query) = shift @_;

	$sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute(@_)             or die "Can't execute: $query. Reason: $!";

	my($i) = 0;
	while (@row = $sth->fetchrow_array()) {
		++$i;
		print "item$i: ", join("\t", @row), "\n";
	}
	print "max: $i\n";
}

