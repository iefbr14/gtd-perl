#!/usr/bin/perl
#######################################
#
#	name: table.cgi
#	purpose:  OpticalOnline, provide
#			  the table data requested
#			  based on lab
#
#######################################
use strict;
use DBI;
use CGI qw/:standard/;
use Cos::Dbh;

my($dbh) = new Cos::Dbh;

print "Content-type: text/html;charset=utf-8\n\n";

my($user)  = param('user');
my($pass)  = param('pass');
my($vers)  = param('vers');
my($table) = param('table');
my($lab)   = param('lab');
my($price) = param('price');

# Check the user account
my($retailer) = sql("SELECT user_id,lab_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}
my($lab_id) = $retailer->{lab_id};

print <<"EOF";
# Version 1.0 table.cgi information
# Table: $table
# Lab:   $lab
# Lab_id: $lab_id
# User:  $user
# Vers:  $vers
#
EOF

# User ID is valid - continue
if ($lab ne '' and $lab ne $lab_id) {
	print "# lab override: $lab_id\n";
	$lab_id = $lab;
}
my($query);
if($table eq 'FrameMounting'){
	($query) = "SELECT code,description, price FROM frame_mounting where lab_id=? and status='L'";
}else{
	($query) = "SELECT stock_num,description, price FROM treatments_data where lab_id=? and status='L'";
	my %select = (
         "Hardening"		=> "type='H' and (mtype='G' or mtype='B')",
         "Tinting"		=> "type='T'",
         "PlasticCoatings"	=> "type='C' and (mtype='P' or mtype='B')",
         "GlassCoating"		=> "type='C' and (mtype='G' or mtype='B')",
         "AntiReflective"	=> "type='A' Order By description ASC",
         "Treatments"		=> "type='O'",
		);

	$query .= " and " . $select{$table};
}
print "# $query\n";

sql_item($query, $lab_id);

sub sql_item {
	my($query, $lab) = @_;

	my(%treatment);
	my($sth, @row);

	$sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute(1)             or die "Can't execute: $query. Reason: $!";

	# Build base table from lab 1
	while (@row = $sth->fetchrow_array()) {
		$treatment{$row[0]} = $row[1];
	}


	# Override table from specified lab
	$sth->execute($lab)             or die "Can't execute: $query. Reason: $!";

	while (@row = $sth->fetchrow_array()) {
		$treatment{$row[0]} = $row[1];
		#compatibility issue, only send price if requested
		if($price==1){
			my $code_price = "price_".$row[0];
			$treatment{$code_price} = $row[2];
		}
	}

	foreach my $key (sort keys %treatment) {
		next if $treatment{$key} =~ /^-/;

		print "$key = $treatment{$key}\n";
	}
}
