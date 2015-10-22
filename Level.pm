package Hier::Level;

use strict;
use warnings;

my $VERSION     = 1.00;

sub level {
	my($self) = @_;

	my($level) = $self->{_level};

	# we have alread defined it, return it.
	return $level if defined $level;
	die "level not set correctly?";
}

sub set_level {
	my($self, $level) = @_;

	die "set_level missing level value" unless defined $level;

	# now remember our level;
	$self->{_level} = $level;
}

1; #<============================================================
