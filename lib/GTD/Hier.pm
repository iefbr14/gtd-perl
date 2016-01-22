package GTD::Hier;

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
	$child->set_dirty('parents');
}

sub orphin_child {
        my($parent, $child) = @_;

	rel_del($child, parent => $parent);
	rel_del($parent, child => $child);
	$child->set_dirty('parents');
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
# helper routines they do useful things, but don't know interals

sub count_children {
	my(@children) = get_children(@_);

	### see GTD::Format::summray_children for counts
	### based on filters

	return scalar @children;
}

sub count_actions {
	my(@children) = get_children(@_);

	my($count) = 0;
	foreach my $child (get_children(@_)) {
		++$count if $child->get_type() eq 'a';
	}
	return $count;
}

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

	foreach my $parent ($self->parent_ids()) {
		return 1 if $check_parent_id == $parent;
	}
	return 0;
}

#------------------------------------------------------------------------------
## set_parent_ids is used by dset in Tasks.pm
#
sub set_parent_ids {
        my($self, $val) = @_;

	my(@pid) = split(',', $val);	# parent ids
	my(%pid);			# parent ids => parent ref

	# find my new parents
	for my $pid (@pid) {
		my $p_ref = GTD::Tasks::find($pid);
		unless ($p_ref) { # opps not a real parent
			warn "No parent id: $pid\n";
			next;
		}

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
		}
	}
	# for my new parents add self as thier child
	for my $pref (values %pid) {
		add_child($pref, $self);
	}
}

sub set_children_ids {
        my($self, $val) = @_;

	my(@cid) = split(',', $val);	# parent ids
	my(%cid);			# parent ids => parent ref

	# find my new parents
	for my $cid (@cid) {
		my $c_ref = GTD::Tasks::find($cid);
		unless ($c_ref) { # opps not a real child
			warn "No child id: $cid\n";
			next;
		}

		$cid{$cid} = $c_ref;
	}

	# keep child if already have that one, it otherwise disown it.
	for my $ref (rel_vals(child => $self)) {
		my $cid = $ref->get_tid();
		if (defined $cid{$cid}) {
			delete $cid{$cid};	# keeping this one.
		} else {
			# disown parent
			$self->orphin_child($ref);
		}
	}
	# for my new children add self as their parent
	for my $cref (values %cid) {
		add_child($self, $cref);
	}
}

1; #<===========================================================
