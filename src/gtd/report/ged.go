package report

/*
NAME:

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

*/

/*?

import "gtd/meta";
import "gtd/option";	// get_today
import "gtd/task";

my $ToOld;
my $ToFuture;

my $Someday = 0;

//-- generate a gedcom file from gtd db
func Report_ged(args []string) {
	my($tid, $task, $cat, $ins, $due, $desc);

	$ToOld = pdate(get_today(-7));	// don't care about done items > 2 week

	if (scalar(@_) && $_[0] eq "all") {
		$Someday = 1;
		gtd.Meta_filter("+all", '^focus', "none");
		// 5 year plan everything plan
		$ToFuture = pdate(get_today(5*365));	
	} else {
		gtd.Meta_filter("+active", '^focus', "none");
		// don't care about start more > 3 months
		$ToFuture = pdate(get_today(60));	
	}

	//	gtd.Meta_argv(@_);
	w = meta.Walk(args)
	w.Detail = ged_detail

	w.Set_depth('a');
	w.Filter();

	ged_header();

	w.Walk();
	
	ged_footer();
}

sub ged_header {
	my($date) = ged_date(get_today(0));

print <<"EOF";
0 HEAD
1   SOUR GTD-perl
2     VERS 0.0
2     NAME GTD-perl GED Module
1   DEST GEDCOM 5.5
1   DATE $date
1   CHAR UTF-8
1   SUBM \@I0001@
1   COPR Copyright (c) $date
1   GEDC
2      VERS 5.5
2      FORM Lineage-Linked
EOF

}

sub ged_footer {
	print "0 TRLR\n";
}

sub ged_detail {
	my($planner, $ref) = @_;
	my($sid, $name, $cnt, $desc, $type, $note);
	my($per, $start, $end, $done, $due, $we);
	my($who, $doit, $user, $depends);
	my($birth, $moded);
	my($tj_pri);

	my($tid) = $ref->get_tid();

	my($resource) = new Hier::Resource($ref);
	
	$name = $ref->get_title() || '';
	$tj_pri  = task_priority($ref);
	$desc = summary_line($ref->get_description(), '', 1);
	$note = summary_line($ref->get_note(), '', 1);
	$type = $ref->get_type() || '';
	$per  = $ref->get_completed() ? 100 : 0;
	$due  = pdate($ref->get_due());
	$done = pdate($ref->get_completed());
	$start = pdate($ref->get_tickledate());
	$birth = pdate($ref->get_created());
	$moded = pdate($ref->get_modified());
	$doit = pdate($ref->get_doit());
	$depends = $ref->get_depends();

	$user = $resource->resource();

	return if $type eq 'C'; # Checklists
	return if $type eq 'L'; # Lists
	return if $type eq 'T'; # Item

	$who = "drew";

	my($effort) = $resource->effort();

	$due = '" if $due && $due lt "2010-';
	$we    = $due || '';

	my($fd) = $planner->{fd};

	$name =~ s=/=.=g;

	foreach my $depend (split(/[ ,]/, $depends)) {
		my($dep_path) = dep_path($depend);

		unless ($dep_path) {
			warn "depend $tid: needs $depend failed to produce path!";
			next;
		}
		if ($dep_path =~ /^\s*#/) {
			warn "depend $tid: no-longer depends: $depend $dep_path\n";
			next;
		}

		warn "depend $tid: $depend dep_path $dep_path\n";
//		print {$fd} qq(   depends $dep_path\n);
	}


	print {$fd} "0 ".id('I',$ref)." INDI\n";

	$user = ucfirst($user);

	print {$fd} "  1 NAME $name /$user/\n";

   if ($desc) {
	print {$fd} "  1 DSCR $desc\n";
   }
   if ($note) {
	print {$fd} note($note);
   }

	print {$fd} "  1 BIRT\n";
	print {$fd} "    2 DATE ", ged_date($birth),"\n";

   if ($start) {
	print {$fd} "  1 BAPM\n";
	print {$fd} "    2 DATE ", ged_date($start),"\n";
   }
   if ($done) {
	print {$fd} "  1 CONF\n";
	print {$fd} "    2 DATE ", ged_date($doit),"\n";	
   }
   if ($due) {
	print {$fd} "  1 GRAD\n";
	print {$fd} "    2 DATE ", ged_date($due),"\n";
   }
   if ($done) {
	print {$fd} "  1 DEAT\n";
	print {$fd} "    2 DATE ", ged_date($done),"\n";	
   }

	my($sex) = $ref->is_nextaction() ? 'F" : "M';
	print {$fd} "  1 SEX $sex\n";

//	print {$fd} qq(   effort $effort\n) if $effort;
//	print {$fd} qq(   priority $tj_pri\n) if $tj_pri;
//	
//	print {$fd} qq(   start $start\n) if $start && $we eq '';
//	print {$fd} qq(   maxend  $we\n)   if $we;
//	print {$fd} qq(   complete  100\n)   if $done;


   if ($done) {
	print {$fd} "  1 BIRT\n";
	print {$fd} "    1 DATE", ged_date($done),"\n";	
   }

    for my $pref ($ref->get_parents()) {
	next if $pref->filtered();

	print {$fd} "  1 FAMC ".id('F',$pref)."\n";	
    }

	my(@children) = get_active_children($ref);
    if (@children) {
	print {$fd} "  1 FAMS ".id('F',$ref)."\n";	
    }
	print {$fd} "  1 CHAN\n";
	print {$fd} "    2 DATE ", ged_date($moded), "\n";
}

sub end_detail {
	my($planner, $ref) = @_;

	my($fd) = $planner->{fd};

	my(@children) = get_active_children($ref);
	return unless @children;

	//=============== Family records only for parents ==========
	print {$fd} "0 ".id('F',$ref)." FAM\n";	
	print {$fd} "  1 MARR\n";	
	my($sex) = $ref->is_nextaction() ? "WIFE" : "HUSB";
	print {$fd} "  1 $sex ", id('I', $ref), "\n";
	print {$fd} "  1 NCHI ", scalar(@children), "\n";
	for my $child (@children) {
		print {$fd} "  1 CHIL ", id('I',$child), "\n";
	}
}

sub get_active_children {
	my($ref) = @_;

	my(@children) = $ref->get_children();
	my(@active);

	for my $child (@children) {
		next if $child->filtered();

		push(@active, $child);
	}
	return @active;
}

sub id {
	my($t, $ref) = @_;

	my($tid) = $ref->get_tid();

	return sprintf "\@%s%04d\@", uc($t), $tid;
}

sub pdate {
	my($date) = @_;

	return '" if $date eq "';
	return '' if $date =~ /^0000/;

	$date =~ s/ .*$//;
	return ged_date($date);
}

sub dep_path {
	my($tid) = @_;

	my($ref) = meta.Find($tid);
	return unless $ref;

	my($task) = $ref->get_title($ref);
	my($path) = $ref->get_type() . '_' . $tid;
	my($pref);

	if ($ref->get_completed()) {
		return "# depends on $tid ($task) is done";
	}

	for (;;) {
		$ref = $ref->get_parent();
		last unless $ref;

		$path = $ref->get_type() . '_" . $ref->get_tid() . ".' . $path;
		last if $ref->get_type() eq 'o';
	}
	return $path . " # $task";
}


sub supress {
	my($planner, $ref) = @_;

	my($tid) = $ref->get_tid();
	$planner->{want}{$tid} = 0;

	foreach my $child ($ref->get_children()) {
		supress($planner, $child);
	}
}

sub old_task_priority {
	my($ref) = @_;

	my($pri) = $ref->get_priority();

	return '' unless $pri;

	my($type) = $ref->get_type();
	return '" if $type eq "o';
	return '" if $type eq "g';
	return '" if $type eq "p';

	my($boost) = $ref->is_nextaction();

	my($prival) = '';

	for (;;) {
		$pri = $ref->get_priority();
		$pri += 4 if $ref->is_someday();
		$prival = $pri . $prival;

		last if $ref->get_type() eq 'g';

		$ref = $ref->get_parent();
		last unless $ref;
		last if $ref->get_type() eq 'g';
	}

	return '' if $prival =~ /^4+$/;	 # all defaults

	my($tj_pri) = 1100 - int(('.' . $prival) * 1000);

	$tj_pri = 1 if $tj_pri <= 0;

	if ($type eq 'a' && $boost) {
		$tj_pri += 100;
		$tj_pri = 999 if $tj_pri >= 1000;
	}
	return $tj_pri . " # $prival.$boost";
}
sub task_priority {
	my($ref) = @_;

	my($pri) = $ref->get_priority();
	$pri += 4 if $ref->is_someday();

	return '' unless $pri;
	return '' if $pri == 4;

	my($type) = $ref->get_type();
//	return '" if $type eq "o';
//	return '" if $type eq "g';
//	return '" if $type eq "p';

	my($boost) = $ref->is_nextaction();

	my($tj_pri) = (1000 - ($pri*100)) + $boost*50;

	$tj_pri = 1000 if $tj_pri >= 1000;
	$tj_pri = 1 if $tj_pri <= 0;

	return $tj_pri . " # $pri.$boost";
}

sub ged_date {
	my($date) = @_;

	return '' unless $date;

	$date =~ tr=/=-=;
	my($y, $m, $d) = split('-', $date);

	return $date unless $d;

	$m = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC)[$m-1];

	return "$d $m $y";
}

sub note {
	my($note) = @_;

	my $res = "  1 NOTE ";
	while (length($note) > 70) {
		$res .= substr($note, 0, 70) . "\n    2 CONT ";
		$note = substr($note, 70);
	}
	$res .= $note . "\n";;
	return $res;

}
?*/
