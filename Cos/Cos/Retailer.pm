package Cos::Retailer;  

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

	die unless $attr eq 'retail_id';
	$self->select('retailer', user_id => $val);

	$self->{data}{retail_id} = $self->{data}{user_id};
	delete $self->{data}{user_id};

	return $self->{data};
}

sub hashref {
	my($self) = @_;
	return $self->{data};
}

END { }       # module clean-up code here (global destructor)


1;  # don't forget to return a true value from the file
