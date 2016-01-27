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

import "gtd/meta"
import "gtd/task"

//-- Project Summary for a role
func Report_oocalc(args []string) {
	meta.Filter("+live", "^tid", "none")

	/*?
		my @want = meta.Argv(args))

		new_calc()

		my($roles) = load_roles()
		for my $role (sort keys %$roles) {
			display_role($role, $roles->{$role})
		}
		save_calc()
	?*/
}

func load_roles() { /*?
		my($role) = @_

		my(%roles)

		// find all next and remember there projects
		for my $ref (meta.Matching_type('o')) {
	//#FILTER	next if $ref->filtered()

			my $pid = t.Tid()
			my $role = t.Title()
			$role =~ s= .*==
			$role = ucfirst($role)
			$roles{$role} = $ref
		}
		return \%roles
	?*/
}
func display_role() { /*?
		my($role, $ref) = @_

		my(@head) = qw(Goal P-id Project T-id Next-Action Hours .)

		my(@list)
		for my $gref (t.Children()) {
			next if $gref->filtered()

			push(@list, get_projects($gref))
		}

		new_sheet($role, scalar @list, 7)
		save_row(1, @head)
		my($row) = 2
		for my $line (sort {
			lc($a->[0]) cmp lc($b->[0])
		   ||	lc($a->[2]) cmp lc($b->[2])
		   ||	lc($a->[4]) cmp lc($b->[4])
		} @list) {
			save_row($row++, @$line)
		}
	?*/
}

func get_projects() { /*?
		my($gref) = @_

		my(@list)

		for my $pref ($gref->get_children()) {
			next if $pref->filtered()

			push(@list, get_actions($gref, $pref))
		}
		return @list
	?*/
}

func get_actions() { /*?
		my($gref, $pref) = @_

		my($gtitle) = $gref->get_title()

		my($pid)    = $pref->get_tid()
		my($ptitle) = $pref->get_title()

		my(@next) = ()
		my(@doit) = ()
		my(@some) = ()
		my(@done) = ()

		// figure out which order.
		for my $ref ($pref->get_children()) {
			next if $ref->filtered()

			if (t.Completed()) {
				push(@done, $ref)
				next
			}

			if ($ref->is_someday()) {
				push(@some, $ref)
				next
			}
			if ($ref->is_nextaction()) {
				push(@next, $ref)
				next
			}

			push(@doit, $ref)
		}

		if (@next == 0) {	// no next actions
			if (@doit == 0 && @some == 0 && @done == 0) {
				// needs planning
				return ([ $gtitle, $pid, $ptitle,
					'", "", "',
					join(':", pnum($gref), pnum($pref), "0')
					])
				   if $pref->get_completed() or
					$pref->is_someday()

				return ([ $gtitle, $pid, $ptitle,
					'-", "##   gtd plan $pid   ##", ".1',
					join(':", pnum($gref), pnum($pref), "6')
					])

			} elsif (@doit == 0 && @some == 0) {
				// is complete

				return ([ $gtitle, $pid, $ptitle,
					'", "", "',
					join(':", pnum($gref), pnum($pref), "0')
					])
				   if $pref->get_completed()

				return ([ $gtitle, $pid, $ptitle,
					'-", "##   gtd done $pid   ##", "2',
					join(':", pnum($gref), pnum($pref), "6')
				])
			}
			// pick best
			@next = ( @doit, @some, @done ) [0]
		}

		my($tid, $title, $hours, $pri)

		if ($pref->get_completed() or $pref->is_someday()) {
			// slice it down to first item only
			@next = ( $next[0] )
		}

		my(@list)
		for my $ref (@next) {
			my($resource) = $ref->Project()
			my($effort) = $resource->hours()
			$effort = .5 unless $effort

			$tid = t.Tid()
			$title = t.Title()
			$hours = $effort
			$pri = join(':', pnum($gref), pnum($pref), pnum($ref))

			push(@list,  [ $gtitle, $pid, $ptitle, $tid, $title, $hours, $pri])
		}

		return @list
	?*/
}

func pnum() { /*?
		my($ref) = @_

		return 9 if t.Completed()

		return 7 if $ref->is_someday()

		return t.Priority()
	?*/
}

/*?
use OpenOffice::OOCBuilder

my $Calc
my $Sheet
my @Widths = ('')
?*/

func new_calc() {
	/*?
	  	$Sheet = 0

	  	$Calc = OpenOffice::OOCBuilder->new()
	  	// - Set Meta.xml data
	  	$Calc->set_title ("GTD")
	  	$Calc->set_author ("Drew Sullivan")
	  	$Calc->set_subject ("gtd oocalc")

	  //	$sheet->set_comments ("Fill in your comments here")
	  //	$sheet->set_keywords ("openoffice autogeneration", 'OpenOffice::OOBuilder')
	  //	$sheet->push_keywords ("OpenOffice::OOCBuilder")
	  //	$sheet->set_meta (1, "name 1", 'value 1')
	  ?*/
}

func new_sheet() { /*?
		my($title, $rows, $cols) = @_

		++$Sheet
		$Calc->add_sheet() unless $Sheet == 1
		$Calc->goto_sheet($Sheet)
		$Calc->set_sheet_name($title, $Sheet)
	?*/
}

func save_row() { /*?
		my($line, @row) = @_

		//my($pri) = pop @row
		my($pri) = $row[-1]
		my($g,$p,$t)
		if ($line > 1) {
			($g,$p,$t) = split(':', $pri)
		}

		$Calc->set_bold($line == 1)
		my($col) = 1
		for my $value (@row) {
			my($type) = "string"
			$type = "float" if $value =~ /^[\d.]+$/

			$Widths[$col] ||= 7
			my $old_width = $Widths[$col]
			my $new_width = length($value)

			if ($old_width < $new_width) {
				$Widths[$col] = $new_width
			}
			color_ref($g) if $col == 1
			color_ref($p) if $col == 3
			color_ref($t) if $col == 5

			$Calc->set_data_xy($col++, $line, $value, $type)
			set_color()
		}
	?*/
}

func set_color() { /*?
		my ($pri) = @_

		my(%c) = (
			"white"	=> "FFFFFF",
			"grey"	=> "D0D0D0",
			"pink"	=> "FFC0CB",
			"red"	=> "FF6060",
			"cyan"	=> "80FFFF",
			"blue"	=> "99CCFF",
			"ivory" => "FFFFD0",
		)

		$Calc->set_bgcolor("white")

		return unless defined $pri

		$Calc->set_bgcolor($c{"pink"})	if $pri == 1
		$Calc->set_bgcolor($c{"cyan"})	if $pri == 2

	//	$Calc->set_bgcolor($c{"red"})	if $pri == 1
	//	$Calc->set_bgcolor($c{"pink"})	if $pri == 2
	//	$Calc->set_bgcolor($c{"cyan"})	if $pri == 3


	//	$Calc->set_bgcolor("blue")	if $pri == 3

	//	$Calc->set_bgcolor("FFCC99") if $pri == 4; # yellow
	//	$Calc->set_bgcolor("FFDD99") if $pri == 5; # orange

		$Calc->set_bgcolor($c{"blue"}) if $pri == 6; # Plan
		$Calc->set_bgcolor($c{"ivory"}) if $pri == 7; # Someday
		$Calc->set_bgcolor($c{"grey"})	if $pri == 9; # Done
	?*/
}

func save_calc() { /*?
		print "Widths: @Widths\n"
		for my $sheet (1..$Sheet) {
			$Calc->goto_sheet($sheet)
			for my $col (1..7) {
				$Calc->set_colwidth($col, $Widths[$col]*170)
			}
		}
		$Calc->generate("gtd")
	?*/
}

//? package Calc::CSV

func new() { /*?
	?*/
}

//? package Calc::OOC

//? use OpenOffice::OODoc
//? use OpenOffice::OOSheets

func new() { /*?
		my $calc
		$Calc = odfContainer("gtd.ods", create => "spreadsheet")
		$Sheet = 0
	?*/
}

func new_sheet() { /*?
		my($title, $rows, $cols) = @_
		++$Sheet

		$Calc->expandTable($Sheet, $rows, $cols)
	?*/
}

func save_row() { /*?
		my($line, @row) = @_

		my($col) = 1
		for my $value (@row) {
			$Calc->updateCell($Sheet, $line, ++$col, $value)
	//	        $Calc->updateCell($Sheet, $line, $col, $value, $string)
		}
	?*/
}
