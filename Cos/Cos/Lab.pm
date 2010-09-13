package Cos::Lab;  

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 2.21 $ =~ /\d+/g); sprintf "
	%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter Cos::Object);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
}

use Cos::Object;

my($DBATTR) = <<'EOF';
| lab_id       | int(10) unsigned | NO   | PRI | NULL     | auto_increment | 
| name         | varchar(60)      | YES  |     | NULL     |                | 
| password     | varchar(64)      | YES  |     | NULL     |                | 
| phone        | varchar(16)      | YES  |     | NULL     |                | 
| fax          | varchar(14)      | YES  |     | NULL     |                | 
| email        | varchar(60)      | YES  |     | NULL     |                | 
| contact_name | varchar(40)      | YES  |     | NULL     |                | 
| create_time  | int(11)          | YES  |     | NULL     |                | 
| update_time  | int(11)          | YES  |     | NULL     |                | 
| status       | char(1)          | YES  |     | NULL     |                | 
| transport    | varchar(64)      | NO   |     | perl-rdt |                | 
| inbox        | varchar(16)      | NO   |     | problems |                | 
| outbox       | varchar(16)      | NO   |     | problems |                | 
| inpass       | varchar(16)      | NO   |     | letmein  |                | 
| outpass      | varchar(16)      | NO   |     | letmein  |                | 
| mbox         | varchar(16)      | NO   |     | problems |                | 
| capability   | mediumtext       | YES  |     | NULL     |                | 
| username     | varchar(24)      | YES  |     | NULL     |                | 
| bizname      | varchar(60)      | YES  |     | NULL     |                | 
| nameupdated  | enum('N','Y')    | NO   |     | N        |                | 
| NPI          | varchar(15)      | YES  |     | NULL     |                | 
| MID          | varchar(15)      | YES  |     | NULL     |                | 
EOF

sub new {
	my($self) = new Cos::Object($DBATTR);

	bless($self);

#	$self->attr_alias(create_time => 'created)';
#	$self->attr_alias(update_time => 'modified');
	return $self;
}

sub find {
	my($self, $attr, $val) = @_;

	die unless $attr eq 'lab_id';
	$self->select('lab_info', lab_id => $val);

	return $self->{data};
}

sub hashref {
	my($self) = @_;
	return $self->{data};
}

END { }       # module clean-up code here (global destructor)


1;  # don't forget to return a true value from the file
