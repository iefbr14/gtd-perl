package Hier::CCT;

use strict;
use warnings;


BEGIN {
        use Exporter   ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

        # set the version for version checking
        $VERSION     = 1.00;

        @ISA         = qw(Exporter);

        # your exported package globals go here,
        # as well as any optionally exported functions
        @EXPORT = qw(
                %Categories  %Contexts   %Timeframes   %Tags
        );
}

#
#
#
our %Categories;	# mapping  Category Id   => Category Name
our %Contexts;		# mapping  Context Id    => Context Name
our %Timeframes;	# mapping  Timreframe Id => Timreframe Name
our %Tags;		# mapping  Tag Id        => Tag Name

my %Maps = (
	'Category'  => \%Categories,
	'Context'   => \%Contexts,
	'TimeFrame' => \%Timeframes,
	'Tag'       => \%Tags,
);

sub new {
	my($self) = @_;
}

sub define {
	my($ref, $key, $val) = @_;;

	$ref->{$key} = $val;
}

sub set {
}

sub get {
}

sub get_id {
	my($type, $val) = @_;

	return _check(\%Categories, $val) if $type eq 'category';
	return _check(\%Contexts, $val)   if $type eq 'context';
	return _check(\%Timeframes, $val) if $type eq 'timeframe';
	return _check(\%Tags, $val)       if $type eq 'tag';
	die "Unknown cct type $type\n";
}

sub _check {
	my($hash, $val) = @_;

	return undef unless defined $val;
	return undef unless defined $hash->{$val};
	return $hash->{$val};
}
1;
