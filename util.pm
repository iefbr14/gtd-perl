package Hier::util;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		&type_name &type_val &type_depth
		&report_header &summary_line
		&dump_task 
		&meta_desc &type_disp &action_disp
		&add_filters &cct_filtered
		&lines &columns &today
		&option &set_option
	);
}

use Hier::Tasks;
use Hier::Filter;
use Hier::CCT;

use POSIX qw(strftime);

my $Debug = 0;

my %Types = (
	'Value'		=> 'm',
	'Vision'	=> 'v',

	'Role'		=> 'o',
	'Goal'		=> 'g',

	'Project'	=> 'p',

	'Action'	=> 'a',
	'Inbox'		=> 'i',
	'Wait'		=> 'w',
	'Waiting'	=> 'w',

	'Reference'	=> 'r',

	'List'		=> 'L',
	'Checklist'	=> 'C',
	'Item'		=> 'T',
);
my %Type_name = ( reverse %Types );

sub type_val {
	my($type) = ucfirst($_[0]);

	if (defined $Types{$type}) {
		return $Types{$type};
	}
	if ($type =~ s/s$//) {
		if (defined $Types{$type}) {
			return $Types{$type};
		}
	}
	return '';
}

sub type_name {
	my($type) = @_;

	return $Type_name{$type};
}

sub type_depth {
	my($type) = @_;

	my %depth = (
		'm' => 1,		# hier
		'v' => 2,
		'o' => 3,
		'g' => 4,
		'p' => 5,

		'n' => 6,		# next actions
		'a' => 6,		# actions (tasks)
		'i' => 7,
		'w' => 7,
	);
	return $depth{$type};
}

sub type_disp {
	my($ref) = @_;
	my($type) = uc($ref->get_type());

	return '<X>'     if $ref->is_ref_task() && $ref->get_completed();
	$type = '_'      if $ref->is_ref_task();

	return "<$type\>" if $ref->get_completed();
	
	return "}$type\{" if $ref->get_later();
	return "{$type\}" if $ref->get_isSomeday() eq 'y';
	return "[$type\]" if $ref->get_nextaction() eq 'y';
	return "($type\)";
}

sub action_disp {
	my($ref) = @_;

	my($key) = '[ ]';

	$key = '[_]' if $ref->get_nextaction() eq 'y';
	$key = '[*]' if $ref->get_completed();

	$key =~ s/.(.)./($1)/ 	if $ref->get_isSomeday() eq 'y';
	$key =~ s/.{.}./($1)/ 	if $ref->get_tickledate();
	$key =~ s/(.)./$1w/ 	if $ref->get_type() eq 'w';

	return $key;
}

#==============================================================================
sub dump_task {
	my ($ref) = @_;

	my($val);
	for my $key (sort keys %$ref) {
		$val = $ref->{$key} || '';
		$val =~ s/\n.*/.../m;
		print "$key:\t$val\n";
	}
}


sub delete_hier {
	die "###ToDo Broked, should be deleting by categories?\n";
	foreach my $tid (@_) {
		my $ref = Hier::Tasks::find{$tid};
		if (defined $ref) {
			print "Category $tid deleted\n";

			$ref->delete();

		} else {
			print "Category $tid not found\n";
		}
	}
}

sub is_hier {
	my($id) = @_;

	my $ref = Hier::Tasks::find{$id};
	return unless defined $ref;

	return unless $ref->is_ref_hier();
	return $ref;
		
}

# post process after loading tables;
sub metafix {
	my($tid, $pid, $p, $name, $only);

	$Debug = option('Debug');

	# Process Tasks (non-hier) items
	for my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid();

		$only = $ref->{_todo_only};
		if ($only == 1) {	# only in todo (gtd deleted it)
			print "Need delete: $tid\n";
			dump_task($ref);
			$ref->delete();
			next;

		} elsif ($only == 2) {	# only in gtd (we fuck up somewhere)
			print "Need create: $tid\n";
			dump_task($ref);

		} elsif ($only == 3) {	# in both (happyness)

		} else {
			dump_task($ref) if option('Debug');
			die "We buggered up: $tid\n";
		}

#		$ref->set_priority(5) ||= 5  unless $ref->{isSomeday} eq 'y';

		$ref->{_actions} = 0;		# todo items
		$ref->{_child} = 0;		# hier items
	}
}

sub metacount {
	my($tid, $pid, $p, $name);

	# Process Tasks (non-hier) items
	foreach my $ref (Hier::Tasks::all()) {
		for my $pref ($ref->get_parents()) {
			if ($ref->is_ref_hier()) {
				$pref->{_child}++;
			} else {
				$pref->{_actions}++;
			}
		}
	}
}

sub min_key {
	my($hash) = @_;

	my(@list) = sort { $a <=> $b } keys %$hash;
	return undef unless @list;

	return $list[0];
}

sub today {
	return Hier::Filter::get_today(@_);
}

sub report_header {
	my($title) = option('Title') || '';
	if (@_) {
		my($desc) = join(' ', @_) || '';

		if ($title and $desc) {
			$title .= ' -- ' . $desc;
		} elsif ($title eq '') {
			$title = $desc;
		}
	}

	my($cols) = columns() - 2;

	print '#',"=" x $cols, "\n";
	print "#== $title\n";
	print '#',"=" x $cols, "\n";
}

sub lines {
	my($lines) = $ENV{LINES} || 24;

	return $lines;
}

sub columns {
	my($rows) = $ENV{COLUMNS} || 80;

	return $rows;
}

sub summary_line {
	my($val, $sep, $ishtml) = @_;

	return '' unless $val;
	return '' if $val =~ /^\s*[.\-\*]/;

	$val =~ s/\n.*//s;
	$val =~ s/\r.*//s;

	if ($ishtml) {
		$val =~ s/&/\&amp;/g;
		$val =~ s/</&lt;/g;
		$val =~ s/>/&gt;/g;
		$val =~ s/"/&quote;/g;
	}

	return $sep . $val;
}
#==============================================================================
#==== filter setup and processing

my $Filter_Category;
my $Filter_Context;
my $Filter_Timeframe;
my %Filter_Tags;
my @Filter_Parents;

sub meta_argv {
	local($_);

	my(@ret);

	if (option('Tag')) {
		foreach my $tag (split(',', option('Tag'))) {
			$Filter_Tags{$tag}++;
		}
	}

	while (scalar(@_)) {
		$_ = shift @_;
		if ($_ eq '!.') {
			print "Stopped.\n";
			exit 0;
		}

		if (s/^\@//) {
			meta_find_context($_);
			next;
		}
		if (s=^\/==) {				# pattern match
			my $pat = $_; $pat =~ s=/$==;	# remove trailing /

			for my $ref (Hier::Tasks::hier()) {
				my($title) = $ref->get_title();
				if ($title =~ /$pat/i) {
					my($tid) = $ref->get_tid();
					push(@Filter_Parents, $tid);
					print "Parent($tid): $title\n";
				}
			}
			next;
		}
		if (s/^\=//) {				# search for.
			my($title);
			if (m/^\d+$/) {
				my $tid = $_;
				my $pref = Hier::Tasks::find($tid);
				if (defined $pref) {
					$title = $pref->get_title();
					push(@Filter_Parents, $tid);

					print "Parent($tid): $title\n";
					next;
				}
				print "Unknown project: $tid\n";
				next;
			}

			my($found) = 0;
			my $pat = $_;	# first by case match

			for my $ref (Hier::Tasks::hier()) {
				$title = $ref->get_title();

				if ($title eq $pat) {
					my($tid) = $ref->get_tid();
					push(@Filter_Parents, $tid);
					print "Parent($tid): $title\n";
					$found = 1;
				}
			}
			next if $found;		# got at least one

			$pat = lc($_);		# ok try case insensative.

			for my $ref (Hier::Tasks::hier()) {
				$title = lc($ref->get_title());

				if ($title eq $pat) {
					my($tid) = $ref->get_tid();
					push(@Filter_Parents, $tid);
					print "Parent($tid): $title\n";
					last;
				}
			}
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

		if (m/^[+~]/) {		# add include/exclude
			add_filters($_);
			next;
		}
#		if ($Title) {
#			print "Desc:  ", join(' ', $_, @_), "\n";
#			return join(' ', $_, @_);
#		}
		push(@ret, $_);
	}

	return @ret;
}

sub meta_desc {
	return join(' ', meta_argv(@_));
}

sub match_desc {
	my($ref, $pattern) = @_;

	return 0 unless defined $ref;
	return 0 unless defined $ref->get_title();

	return 1 if $ref->get_title() =~ /$pattern/i;
	return 1 if $ref->get_description() =~ /$pattern/i;

	if ($Filter_Category) {
		return 1 if $ref->get_category() =~ /$Filter_Category/i;
	}
	return 0;
}

sub meta_find_context {
	my($cct) = @_;

	# match case sensative first
	if (defined $Contexts{$cct}) {
		print "#-Set space context:  $cct\n" if $Debug;
		$Filter_Context = $cct;
		return;
	}
	if (defined $Timeframes{$cct}) {
		print "#-Set time context:   $cct\n" if $Debug;
		$Filter_Timeframe = $cct;
		return;
	}
	if (defined $Categories{$cct}) {
		print "#-Set category:       $cct\n" if $Debug;
		$Filter_Category = $cct;
		return;
	}
	for my $key (keys %Tags) {
		next unless $key eq $cct;

		print "#-Set tag:            $key\n" if $Debug;
		$Filter_Tags{$key}++;
		return;
	}

	# match case insensative next
	for my $key (keys %Contexts) {
		next unless lc($key) eq lc($cct);

		print "#-Set space context:  $key\n" if $Debug;
		$Filter_Context = $key;
		return;
	}
	for my $key (keys %Timeframes) {
		next unless lc($key) eq lc($cct);

		print "#-Set time context:   $key\n" if $Debug;
		$Filter_Timeframe = $key;
		return;
	}
	for my $key (keys %Categories) {
		next unless lc($key) eq lc($cct);

		print "#-Set category:       $key\n" if $Debug;
		$Filter_Category = $key;
		return;
	}
	for my $key (keys %Tags) {
		next unless lc($key) eq lc($cct);

		print "#-Set tag:            $key\n" if $Debug;
		$Filter_Tags{$key}++;
		return;
	}

	print "Defaulted category: $cct\n";
	$Filter_Category = $cct;
}

sub cct_filtered {
	my ($ref) = @_;

	if (@Filter_Parents) {
		foreach my $tid (@Filter_Parents) {
			return 0 if ($ref->has_parent_id($tid));
		}
		return 1;
	}

	if (%Filter_Tags) {
		for my $tag ($ref->get_tags()) {
			return 0 if exists $Filter_Tags{$tag}
			         &&        $Filter_Tags{$tag};
		}
		return 1;
	}

	if ($ref->get_type() eq 'p' or $ref->is_ref_task()) {
		if ($Filter_Context) {
			return 1 unless $ref->get_context() eq $Filter_Context;
		}
	}
	if ($Filter_Timeframe) {
		return 1 unless $ref->get_timeframe() eq $Filter_Timeframe;
	}
	if ($Filter_Category) {
		return 1 unless $ref->get_category() eq $Filter_Category;
	}


	return 0;
}

sub add_filters {
	Hier::Filter::add_filter(@_);
}

#==============================================================================
my %Options;
my %Option_keys = (
	'Debug'       => 1,
	'MetaFix'     => 1,
	'Mask'        => 1,

	'Title'       => 1,
	'Subject'     => 'Title',
	'Task'        => 1,
	'Desc'        => 'Task',
	'Description' => 'Task',
	'Note'        => 1,
	'Result'      => 'Result',

	'Category'    => 1,
	'Priority'    => 1,
	'Tag'         => 1,
	'Tags'        => 'Tag',


	'Limit'       => 1,
	'Reverse'     => 1,

	'List'        => 1,	# tab seperated list format
	'Wiki'        => 1,	# media wiki format
	'Html'        => 1,	# html text format
);

sub option_key {
	my($key) = @_;

	my($newkey) = $Option_keys{$key};
	unless ($newkey) {
		warn "Unknown option: $key\n";
		$Option_keys{$key} = 1;
		$newkey = 1;
	}
	if ($newkey =~ /^[A-Z]/) {
		$key = $newkey;
	}
	return $key;
}
	
sub set_option {
	my($key, $val) = @_;

	$Options{option_key($key)} = $val;
}

sub option {
	my($key, $default) = @_;

	$key = option_key($key);

	unless (defined $Options{$key}) {
		print "Fetch Option $key == undef\n" if $Debug;
		if (defined $default) {
			$Options{$key} = $default;
		}
	} else {
		print "Fetch Option $key => $Options{$key}\n" if $Debug;
	}

	return $Options{$key};
}
#==============================================================================

1; # <=============================================================
