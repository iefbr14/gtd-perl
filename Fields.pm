package Hier::Fields;

use strict;
use warnings;

our $VERSION     = 1.00;

use constant {
	VALUE		=> 'm',		# hier
	VISION		=> 'v',
	ROLE		=> 'o',
	GOAL		=> 'g',
	PROJECT		=> 'p',

	ACTION		=> 'a',		# task(s)
	INBOX		=> 'i',
	WAIT		=> 'w',

	REFERENCE	=> 'r',		# list(s)/references
	LIST		=> 'L',
	CHECKLIST	=> 'C',
	ITEM		=> 'T',
};

sub is_ref_task {
	my ($ref) = @_;

	return 0 unless $ref;
	return 0 unless defined $ref->{type};

	my $type = $ref->{type};

	return 1 if $type eq ACTION;	# action item
	return 1 if $type eq WAIT;	# waiting item
	return 1 if $type eq INBOX;	# inbox item

	return 0;
}

sub is_ref_hier {
	my ($ref) = @_;

	return 0 unless $ref;

	my $type = $ref->get_type();
	return 0 unless defined $type;

	return 1 if $type eq VALUE;
	return 1 if $type eq VISION;
	return 1 if $type eq ROLE;
	return 1 if $type eq GOAL;
	return 1 if $type eq PROJECT;

	return 0;
}

sub is_ref_list {
	my ($ref) = @_;

	return 0 unless $ref;
	return 0 unless defined $ref->{type};

	my $type = $ref->{type};

	return 1 if $type eq REFERENCE;	# reference
	return 1 if $type eq LIST;	# list
	return 1 if $type eq CHECKLIST;	# checklist
	return 1 if $type eq ITEM;	# list or checklist item

	return 0;
}

1; #<============================================================
