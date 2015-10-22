package Hier::Meta;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		&tasks_by_type
		&meta_matching_type
		&meta_selected &meta_sorted
		&meta_find &meta_all
		&meta_filter &meta_desc &meta_argv
		&meta_reset_filters
		&meta_pick
	);
}

use Hier::Tasks;
use Hier::Filter;
use Hier::CCT;
use Hier::Option;
use Hier::Format;
use Hier::Sort;
use Hier::Util;

our $Debug = 0;

use base qw(Hier::Hier Hier::Fields Hier::Filter);

#==============================================================================
#==== Top level filter/sort/selection
#==============================================================================
my @Selected;
my $Default_filter = '';

sub hier {
	return grep { $_->is_hier() } selected();
}

sub meta_reset_filters {
	@Selected = ();		# nothing is selected/sorted.
}

sub meta_selected {
	if (@Selected == 0) {
		@Selected = meta_filtered();
	}
	return @Selected;
}

sub meta_filtered {
	if (@Selected == 0) {
		foreach my $ref (Hier::Tasks::all()) {
			next if $ref->filtered(0);
			push(@Selected, $ref);
		}
	}

	return @Selected;
}

sub meta_sorted {
	my($mode) = @_;

	sort_mode(option('Sort', $mode));
	if (@Selected == 0) {
		@Selected = sort_tasks(meta_filtered());
	}
	return @Selected;
}

sub meta_matching_type {
	my($type) = @_;

	return grep { $_->get_type() eq $type } meta_sorted();
}

sub meta_all {
	return Hier::Tasks::all();
}

sub meta_all_matching_type {
	my($type) = @_;

	return grep { $_->get_type() eq $type } Hier::Tasks::all();
}

sub meta_find {
	return Hier::Tasks::find(@_);
}

#==============================================================================

sub delete_hier {
	die "###ToDo Broked, should be deleting by categories?\n";
	foreach my $tid (@_) {
		my $ref = Hier::Tasks::find{$tid};
		if (defined $ref) {
			warn "Category $tid deleted\n";

			$ref->delete();

		} else {
			warn "Category $tid not found\n";
		}
	}
}


#==============================================================================
#==============================================================================
#==== filter setup and processing
#==============================================================================

sub meta_filter {
	my($filter, $sort, $display) = @_;

	sort_mode(option('Sort', $sort)) if $sort;
	display_mode(option('Format', $display)) if $display;

	option('Filter', $filter);
	$Default_filter = $filter;
}

sub meta_argv {
	local($_);

	my(@ret);

	my($has_filters) = 0;

	Hier::Filter::add_filter_tags();
	while (scalar(@_)) {
		$_ = shift @_;
		if ($_ eq '!.') {
			die "Stopped.\n";
		}

		if (s/^\@//) {
			Hier::Filter::meta_find_context($_);
			next;
		}

		if (s/^(\d+:)$/$1/ or m/^\d+$/) {
			push(@ret, $_);		# tid
			next;
		}

		if (s=^\/==) {				# pattern match
			push(@ret, find_pattern($_));
			next;
		}

		if (s|^=\/||) {				# pattern match
			push(@ret, find_pattern($_));
			next;
		}


		if (s/^\*//) {
			my($type) = lc(substr($_, 0, 1));
			$type = type_name($_);
			print "Type ========($type)=:  $_\n";
			set_option(Type => $type);
			next;
		}
		if (s/^([A-Z])://) {
			my($type) = lc($1);
#			set_option(Type => $type);
#
#			print "Type: Title =====:  $type: $_\n";
#			set_option(Title -> $_);
			push(@ret, find_hier($type, $_));
			next;
		}

		if (m/^[-~+]/) {		# add include/exclude
			Hier::Filter::add_filter($_);
			$has_filters = 1;
			next;
		}
#		if ($Title) {
#			print "Desc:  ", join(' ', $_, @_), "\n";
#			return join(' ', $_, @_);
#		}
		push(@ret, $_);
	}

	unless ($has_filters) {
		Hier::Filter::add_filter($Default_filter);
	}
	Hier::Filter::apply_filters($Default_filter);
	return @ret;
}

sub meta_desc {
	return join(' ', meta_argv(@_));
}

sub meta_pick {
	my(@list) = ();

	foreach my $arg (meta_argv(@_)) {
		# comma sperated list of tasks
                while ($arg =~ s/^(\d+),(\d[\d,]*)$/$2/) {
                        my($ref) = meta_find($1);

                        unless (defined $ref) {
                                die "Task $arg doesn't exits\n";
                        }
			push(@list, $ref);
                        next;
                }

		# task all by itself
		if ($arg=~ s/^(\d+):$/$1/ or $arg =~ m/^\d+$/) {
                        my($ref) = meta_find($arg);

                        unless (defined $ref) {
                                die "Task $arg doesn't exits\n";
                        }
			push(@list, $ref);
                        next;
                }

                if ($arg =~ /pri\D+(\d+)/) {
			set_option('Priority', $1);
                        next;
                }
                if ($arg =~ /limit\D+(\d+)/) {
                        set_option('Limit', $1);
                        next;
                }
                if ($arg =~ /format\s(\S+)/) {
                        set_option('Format', $1);
                        next;
                }
                if ($arg =~ /header\s(\S+)/) {
                        set_option('Header', $1);
                        next;
                }

		my($want) = type_val($arg);
		if ($want) {
			for my $ref (meta_matching_type($want)) {
				next if $ref->filtered();
				push(@list, $ref);
			}
			next;
		}
		die "**** Can't understand argument $arg\n";
	}
	return @list;
}

sub find_pattern {
	my($pat) = @_;

	$pat =~ s=/$==;	# remove trailing /

	my(@list);

	for my $ref (Hier::Tasks::all()) {
		my($title) = $ref->get_title();
		if ($title =~ /$pat/i) {
			my($tid) = $ref->get_tid();
			push(@list, $tid);
			warn "Added($tid): /$pat/ =~ $title\n" if $Debug;
		}
	}
	return @list;
}

sub find_hier {
	my($type, $pat) = @_;

	$pat =~ s=/$==;	# remove trailing /

	my(@list);

	for my $ref (Hier::Tasks::all()) {
		next unless $ref->is_hier();
		next unless match_type($type, $ref);

		my($title) = $ref->get_title();
		if ($title =~ /$pat/i) {
			my($tid) = $ref->get_tid();
			push(@list, $tid);
			warn "Added($tid): /$pat/ =~ $title\n" if $Debug;
		}
	}
	return @list;
}

sub match_type {
	my($want, $ref) = @_;

	my($type) = $ref->get_type();

	return 1 if $type eq $want;

	return 1 if $type eq 'm' and $want eq 'v';
	return 1 if $type eq 'o' and $want eq 'r';

	return 0;
}

1; # <=============================================================
