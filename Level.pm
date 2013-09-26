package Hier::Level;

use strict;
use warnings;

my $VERSION     = 1.00;

my $Top_Level = 0;

sub level {
	my($self) = @_;

	my($level) = $self->{_level};

	# we have alread defined it, return it.
	return $level if defined $level;

	# get our parent
	my($parent) = $self->get_parent();

	# have a parent, return 1 down from parent
	if (defined $parent) {
		$level =  $parent->level() + 1;
		$self->{_level} = $level;
		return $level;
	}

	# don't have a parent, return 1 down from Top_level
	$level = $Top_Level + 1;
	$self->{_level} = $level;
	return $level;
}

sub set_level {
	my($self, $level) = @_;

	$level = 1 unless defined $level;

	# get our parent
	my($parent) = $self->get_parent();

	# have a parent, set his level to 1 up.
	if (defined $parent) {
		$parent->set_level($level - 1);
	} else {
		# not our top level;
		$Top_Level = $level - 1;
	}

	# now remember our level;
	$self->{_level} = $level;
}

sub top_level {
	return $Top_Level;
}

1; #<============================================================
