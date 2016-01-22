package GTD::CCT;

BEGIN {
        use Exporter   ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

        # set the version for version checking
        $VERSION     = 1.00;

        @ISA         = qw(Exporter);

        # your exported package globals go here,
        # as well as any optionally exported functions
        @EXPORT = qw( );
}

use strict;
use warnings;
use Carp;

#
#
#
my %Categories;		# mapping  Category Id   => Category Name
my %Contexts;		# mapping  Context Id    => Context Name
my %Timeframes;		# mapping  Timreframe Id => Timreframe Name
my %Tags;		# mapping  Tag Id        => Tag Name

my %Maps = (
	'Category'  => \%Categories,
	'Context'   => \%Contexts,
	'TimeFrame' => \%Timeframes,
	'Tag'       => \%Tags,
);

sub _table {
	my($mapname) = @_;

	$mapname = lc($mapname);

	return \%Categories if $mapname eq 'category';
	return \%Contexts   if $mapname eq 'context';
	return \%Timeframes if $mapname eq 'timeframe';
	return \%Tags       if $mapname eq 'tag';

	die "Unknown CCT table name $mapname\n";
}

sub use {
	my($class, $mapname) = @_;

	my $cct = _table($mapname);

	bless $cct;
	return $cct;
}

sub define {
	my($cct, $key, $val) = @_;

	confess("key undefined") unless defined $key;
	$cct->{$key} = $val;
}

sub set {
	my($cct, $key, $val) = @_;

	unless ($val) {
		$val = 1;
		foreach my $table_value (values(%$cct)) {
			$val = $table_value + 1 if $table_value <= $val;
		}
	}

	if (!defined $key) {
		warn "###BUG### Can't insert $key => $val\n";
		$cct->{$key} = $val;
	} else {
		warn "###BUG### Can't update $key => $val\n";
		$cct->{$key} = $val;
	}
}

sub get {
	my($hash, $val) = @_;

	return unless defined $val;
	return unless defined $hash->{$val};
	return $hash->{$val};
}

sub keys {
	my($type) = @_;

	if (ref $type) {
		return keys %$type;
	}
	my($cct) = _table($type);
	return keys %$cct;
}

sub name {
	my($cct, $val) = @_;

	###BUG### $CCT->name is horibly expensive
	my(%rev) = reverse(%$cct);

	return $rev{$val};
}

sub rename {
	my($cct, $key, $newname) = @_;

	die "###BUG### Can't rename $key => $newname\n";
}

1;
