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


use Hier::globals;
use Hier::header;
use Hier::util;
use Hier::Tasks;

my @Lines;
my $Today = today();

my($List) = 0; ###BUG### should be an option
my($Done) = 0; ###BUG### should be an option

sub Report_doit {	#-- List top level next actions

	my($tid, $ref, $pri, $task, $cat, $created, $modified,
		$doit, $desc, $note, @desc);

	if ($Done) {
		for my $tid (@_) {
			$ref = $Task{$tid};

			unless ($ref) {
				warn "$tid doesn't exits\n";
				next;
			}
			set($ref, 'doit', $Today, 1);
		}
	}

	$= = lines();
	add_filters('+task', '+hier', '+next');
	my($title) = meta_desc(@ARGV);

print <<"EOF";
  Id   Pri Category  Doit        Task/Description $title
==== === = ========= =========== ==============================================
EOF

format DOIT =
@>>> [_] @ @<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$tid,  $pri, $cat,       $doit,    $desc
~~                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                   $desc
.
	$~ = "DOIT";	# set STDOUT format name to HIER

	my($count) = 0;
	for my $id (sort by_doitdate keys %Task) {
		$tid = $id;
		$ref = $Task{$tid};
		
		next if filtered($ref);

		$pri       = $ref->{priority};

		$task      = $ref->{task} || $ref->{context} || '';
		$cat       = $ref->{category} || '';
		$created   = $ref->{created};
		$modified  = $ref->{modified} || $created;
		$doit      = $ref->{doit} || '';
		$desc      = $ref->{description} || '';
		$note      = $ref->{note} || '';

		my($pid, $pref, $pname, $pdesc);
		$pid      = parent($ref);
		next unless defined $Hier{$pid};

		$pref     = $Hier{$pid};
		$pname    = $pref->{task} || '';
		$pdesc    = $pref->{description} || '';

		next if filtered($pref);

		my($gid, $gref, $gname);
		$gid      = parent($pref);
		next unless defined $Hier{$gid};

		$gref     = $Hier{$gid};
		$gname    = $gref->{task} || '';

#		next if hier_filtered($gref);

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
			$desc = join("\r", "G[$gid]: $gname",
				  "P[$pid]: $pname", 
					split("\n", $pdesc),
				  "*[$tid] $task",
					split("\n", $desc),
					split("\n", "Outcome: $note")
			);

			write;
		}
		last if $- < 10;
		last if ++$count >= $Limit;
	}
}

sub next_line {
	my($v) =  shift(@Lines);
	$v ||= '';
	return $v;
}

sub by_doitdate {
#	my($a, $b) = @_;

	my($ad) = $Task{$a}->{doit} || sprintf("-%06d", $a);
	my($bd) = $Task{$b}->{doit} || sprintf("-%06d", $b);

	return $ad cmp $bd;
}


1;  # don't forget to return a true value from the file
