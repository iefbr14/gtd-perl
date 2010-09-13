package Cos::Object;  

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

	@ISA         = qw(Exporter);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
}

use Cos::Dbh;

sub new {
	my($self) = {};

	bless($self);
	return $self;
}

sub dump {
	my($self) = @_;

	my($meta) = $self->{meta};
	my($data) = $self->{data};

	foreach my $field (sort keys %$meta) {
		print "$field:\t$data->{$field}\n";
	}
}

sub select {
	my($self, $table, $key, $val) = @_;

	my($ref) = sql("select * from $table where $key = ?", $val);

	$self->{data} = $ref;
	return $self;
}

END { }       # module clean-up code here (global destructor)


1;  # don't forget to return a true value from the file


