package Hier::Hier;

use strict;
use warnings;

use Carp;
use Data::Dumper;

sub rel_add {
	my($obj, $rel, $target) = @_;

	my($id) = $target->get_tid();

	$obj->{"_${rel}_"}->{$id} = $target;

	my($rel_ref) = $obj->{"_${rel}_"};

	my @keys  = sort { $a <=> $b } keys %$rel_ref;
	my @vals  = map { $rel_ref->{$_} } @keys;

	$obj->{"_${rel}_keys"} = [ @keys ];
	$obj->{"_${rel}_vals"} = [ map { $rel_ref->{$_} } @keys ];

}

sub rel_del {
	my($obj, $rel, $target) = @_;

	my($id) = $target->get_tid();

	my($rel_ref) = $obj->{"_${rel}_"};

	delete $rel_ref->{$id};

	my @keys  = sort { $a <=> $b } keys %$rel_ref;
	my @vals  = map { $rel_ref->{$_} } @keys;

	$obj->{"_${rel}_keys"} = [ @keys ];
	$obj->{"_${rel}_vals"} = [ map { $rel_ref->{$_} } @keys ];
}

sub rel_keys {
	my($rel, $obj) = @_;

	return unless defined $obj->{"_${rel}_keys"};

	return @{$obj->{"_${rel}_keys"}};
}
	
sub rel_vals {
	my($rel, $obj) = @_;

	confess unless ref $obj;

	return unless defined $obj->{"_${rel}_vals"};

	return @{$obj->{"_${rel}_vals"}};
}

#------------------------------------------------------------------------------
# core routines.  Only these add/remove relationships
#
sub add_child {
        my($parent, $child) = @_;

	rel_add($child, parent => $parent);
	rel_add($parent, child => $child);
}

sub orphin_child {
        my($parent, $child) = @_;

	rel_del($child, parent => $parent);
	rel_del($parent, child => $child);
}

#------------------------------------------------------------------------------
# access routines but they don't change anything.

sub get_parents {
	return rel_vals(parent => $_[0]);
}

sub get_children {
	return rel_vals(child => $_[0]);
}

sub parent_ids {
	return rel_keys(parent => $_[0]);
}

sub children_ids {
	return rel_keys(child => $_[0]);
}

#------------------------------------------------------------------------------
# these are counted in metacount in db.pm
# (ugly hack, we should keep this info ourselfs or create it as needed)

# count the number of hier children (not actions)
sub count_children {
	my ($self) = @_;

	return $self->{_child};
}

# count the number of actions (not hier children)
sub count_actions {
	my ($self) = @_;

	return $self->{_actions};
}

#------------------------------------------------------------------------------
# helper routines they do useful things, but don't know interals
sub get_parent {
	my($self) = @_;

	confess unless ref $self;

	my(@parents) = $self->get_parents();

	return $parents[0];
}

sub safe_parent {
        my ($ref) = @_;

        return 'fook' unless defined $ref;

	my $type = $ref->get_type();
        return 'vision' if defined $type && $type eq 'm';

	my(@parent_ids) = $ref->parent_ids();

        return 'orphin' unless @parent_ids;

        return $parent_ids[0];
}

sub disp_parents {
        my ($ref) = @_;

        return join(',', $ref->parent_ids());
}

sub disp_children {
        my ($ref) = @_;

        return join(',', children_ids($ref));
}

sub parent_id {
	my($self) = @_;

	return ${$self->parent_ids()}[0];
}

sub has_parent_id {
	my($self, $check_parent_id) = @_;

	foreach my $parent ($self->parent_refs()) {
		return 1 if $check_parent_id == $parent->get_tid();
	}
}

#------------------------------------------------------------------------------
## set_parent_ids is used by edit.
#
sub set_parents_ids {
        my($self, $val) = @_;

	my(@pid) = split(',', $val);	# parent ids
	my(%pid);			# parent ids => parent ref

	# find my new parents
	for my $pid (@pid) {
		my $p_ref = Hier::Tasks::find($pid);
		next unless $p_ref;	# opps not a real parent

		$pid{$pid} = $p_ref;
	}

	# keep parent if already have that one, it otherwise disown it.
	for my $ref (rel_vals(parent => $self)) {
		my $pid = $ref->get_tid();
		if (defined $pid{$pid}) {
			delete $pid{$pid};	# keeping this one.
		} else {
			# disown parent
			$ref->orphin_child($self);
			$ref->set_dirty('parents');
		}
	}
	# for my new parents add self as thier child
	for my $pref (values %pid) {
		add_child($pref, $self);
		$pref->set_dirty('parents');
	}
}

1; #<===========================================================
