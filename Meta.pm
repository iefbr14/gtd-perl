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
		&meta_pick
	);
}

use Hier::Tasks;
use Hier::Selection;
use Hier::Filter;
use Hier::CCT;
use Hier::Option;
use Hier::Format;
use Hier::Sort;
use Hier::util;


use base qw(Hier::Hier Hier::Fields Hier::Filter Hier::Selection);

#==============================================================================
#==== Top level filter/sort/selection
#==============================================================================
my @Selected;
my $Default_filter = '';

sub hier {
	return grep { $_->is_hier() } selected();
}

sub meta_selected {
	if (@Selected == 0) {
		@Selected = Hier::Tasks::all();
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

#	filter_mode(option('Filter', $filter)) if $sort;
	sort_mode(option('Sort', $sort)) if $sort;
	display_mode(option('Format', $display)) if $display;

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
			print "Stopped.\n";
			exit 0;
		}

		if (s/^\@//) {
			Hier::Filter::meta_find_context($_);
			next;
		}
		if (s=^\/==) {				# pattern match
			add_pattern($_);
			next;
		}

		if (s/^\=//) {				# search for.
			add_selection($_);
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
			set_option(Type => $type);

			print "Type: Title =====:  $type: $_\n";
			set_option(Title -> $_);
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

	my($fail) = 0;

	foreach my $arg (meta_argv(@_)) {
                if ($arg =~ /^\d+$/) {
                        my($ref) = meta_find($arg);

                        unless (defined $ref) {
                                warn "Task $arg doesn't exits\n";
				$fail++;
                                next;
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
		print "**** Can't understand argument $arg\n";
		exit 1;
	}
	exit(1) if $fail;
	return @list;
}

1; # <=============================================================
