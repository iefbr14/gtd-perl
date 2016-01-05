package gtd

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

sub new {
	my($self) = @_;
}

sub use {
	my($self, $type) = @_;

	my $ref = _table($type);

	bless $ref;
	return $ref;
}

sub define {
	my($ref, $key, $val) = @_;;

	confess("key undefined") unless defined $key;
	$ref->{$key} = $val;
}

sub set {
	my($ref, $key, $val) = @_;;

	unless ($val) {
		$val = 1;
		foreach my $table_value (values(%$ref)) {
			$val = $table_value + 1 if $table_value <= $val;
		}
	}

	if (!defined $key) {
		warn "###BUG### Can't insert $key => $val\n";
		$ref->{$key} = $val;
	} else {
		warn "###BUG### Can't update $key => $val\n";
		$ref->{$key} = $val;
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
	my($ref) = _table($type);
	return keys %$ref;
}

sub name {
	my($ref, $val) = @_;

	###BUG### $CCT->name is horibly expensive
	my(%rev) = reverse(%$ref);

	return $rev{$val};
}

sub rename {
	my($ref, $key, $newname) = @_;

	die "###BUG### Can't rename $key => $newname\n";
}

sub _table {
	my($type) = @_;

	$type = lc($type);

	return \%Categories if $type eq 'category';
	return \%Contexts   if $type eq 'context';
	return \%Timeframes if $type eq 'timeframe';
	return \%Tags       if $type eq 'tag';

	die "Unknown CCT table type: $type\n";
}

1;
