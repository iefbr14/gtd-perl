package Hier::Report::doit;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_doit);
}


use Hier::util;
use Hier::Tasks;

my @Lines;
my $Today = today();
my $Later = today(+7);
my $Priority = 0;
my $Limit = 2;

my($List) = 0; ###BUG### should be an option

sub Report_doit {	#-- List top level next actions

	$List = option('List', 0);
	$Limit = option('Limit', 2);

	$= = lines();
	add_filters('+active', '+next');
	my($target) = 0;
	my($action) = \&doit_list;

	foreach my $arg (Hier::util::meta_argv(@ARGV)) {
		if ($arg =~ /^\d+$/) {
			my($ref) = Hier::Tasks::find($arg);

			unless (defined $ref) {
				warn "$arg doesn't exits\n";
				next;
			}
			&$action($ref);
			++$target;
			next;
		}
		if ($arg eq 'help') {
			doit_help();
			next;
		}
		if ($arg eq 'list') {
			list_all();
			$target = 1;
			next;
		}
		if ($arg eq 'later') {
			$action = \&doit_later;
			next;
		}
		if ($arg eq 'next') {
			$action = \&doit_next;
			next;
		}
		if ($arg eq 'done') {
			$action = \&doit_done;
			next;
		}
		
		if ($arg eq 'someday') {
			$action = \&doit_someday;
			next;
		}
		if ($arg eq 'now') {
			$action = \&doit_now;
			next;
		}
		if ($arg =~ /pri\D+(\d+)/) {
			$Priority = $1;
			$action = \&doit_priority;
			next;
		}
		if ($arg =~ /limit\D+(\d+)/) {
			$Limit = $1;
			set_option('Limit', $Limit);
			next;
		}
		print "Unknown option: $arg (ignored) (try option help)\n";
	}
	if ($target == 0) {
		list_all();
	}
}

sub doit_later {
	my($ref) = @_;

	$ref->set_doit($Later);
	$ref->update();
}
sub doit_next {
	my($ref) = @_;

	$ref->set_doit($Today);
	$ref->update();
}
sub doit_done {
	my($ref) = @_;

	$ref->set_completed($Today);
	$ref->update();
}

sub doit_someday {
	my($ref) = @_;

	$ref->set_isSomeday('y');
	$ref->set_doit($Later);
	$ref->update();
}

sub doit_now {
	my($ref) = @_;

	$ref->set_isSomeday('n');
	$ref->set_doit($Today);
	$ref->update();
}

sub doit_priority {
	my($ref) = @_;

	if ($ref->get_priority() == $Priority) {
		print $ref->get_tid() . ': ' . $ref->get_description() . 
			" already at priority $Priority\n";
		return;
	}

	$ref->set_priority($Priority);
	$ref->update();
}

sub list_all {
	my(@list);

	for my $ref (Hier::Tasks::sorted('^doitdate')) {
		next unless $ref->is_ref_task();
		next if $ref->filtered();

		my $pref = $ref->get_parent();
		next unless defined $pref;
		next if $pref->filtered();
		push(@list, $ref);
	}
	doit_list(@list);
}

		
sub doit_list {
	my($tid, $ref, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

print <<"EOF" unless $List;
  Id   Pri Category  Doit        Task/Description
==== === = ========= =========== ==============================================
EOF

format DOIT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,       $doit,    $desc
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                   $desc
.
	$~ = "DOIT";	# set STDOUT format name to HIER

	foreach my $ref (@_) {
		last if $Limit-- <= 0;


		$tid = $ref->get_tid();

		$pri       = $ref->get_priority();

		$task      = $ref->get_task() || $ref->get_context() || '';
		$cat       = $ref->get_category() || '';
		$created   = $ref->get_created();
		$modified  = $ref->get_modified() || $created;
		$doit      = $ref->get_doit() || '';
		$desc      = $ref->get_description();
		$note      = $ref->get_note();

		my($pid, $pref, $pname, $pdesc);

		$pref     = $ref->get_parent();
		next unless defined $pref;

		$pid      = $pref->get_tid();
		$pname    = $pref->get_title();
		$pdesc    = $pref->get_description();

		my($gid, $gref, $gname);
		$gref      = $pref->get_parent();
		next unless defined $gref;

		$gid      = $gref->get_tid();
		$gname    = $gref->get_title();

#		next if $gref->hier_filtered();

		if ($List) {
			$desc =~ s/\n.*//s;
			print join("\t", $tid, $pri, $cat, $doit, $pname, $task, $desc), "\n";
		} else {
			chomp $gname;
			chomp $pname;
			chomp $pdesc;
			chomp $task;
			chomp $desc;
			chomp $note;
			$note = "Outcome: $note" if $note;

			$desc = join("\r", "G[$gid]: $gname",
				  "P[$pid]: $pname", 
					split("\n", $pdesc),
				  "*[$tid] $task",
					split("\n", $desc),
					split("\n", $note)
			);

			write;
		}
#		last if $- < 10;
	}
}

sub next_line {
	my($v) =  shift(@Lines);
	$v ||= '';
	return $v;
}

sub doit_help {
	print <<'EOF';
help    -- this help text
list    -- list next
later   -- skip this for a week
next    -- skip this for now
done    -- set them to done
someday -- set them to someday
now     -- set them to from someday

Options: 

pri :    -- Set priority
limit :  -- Set the doit limit to this number of items

EOF
}

1;  # don't forget to return a true value from the file
