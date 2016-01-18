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

import "gtd/task"
import "gtd/meta"
import "gtd/option"
import "gtd/task"

/*?
our report_debug = 0
my %Depth

?*/
//-- write out hier as as set of nodes
func Report_tsort(args []string) {
	/*?
	  	for my $ref (meta.atching_type('a')) {
	  		up($ref)
	  	}

	  	if (@_ == 0) {
	  		for my $ref (meta.atching_type('m')) {
	  			dpos($ref, 1)
	  		}
	  		return
	  	}


	  	for my $task (@_) {
	  		my $ref = meta.Find($task)
	  //		down($ref, 1)
	  		dpos($ref, 1)
	  	}

	  ?*/
}

func down() { /*?
		my($ref, $level) = @_

		my $id = $ref->get_tid()

		if ($Depth{$id} && $level != $Depth{$id}) {
			warn "Recurson: $id at $level (was $Depth{$id})\n"
			return
		}
		$Depth{$id} = $level

		foreach my $pref ($ref->get_parents()) {
			my $pid = $pref->get_tid()

			if ($Depth{$pid} > $level) {
				warn "Depth: $id at $level (pid $pid > $Depth{$pid})\n"
			}

			print $pid, ' ', $ref->get_tid(), "\n"
		}

		foreach my $cref ($ref->get_children()) {
			down($cref, $level+1)
		}
	?*/
}

func dpos() { /*?
		my($ref, $level) = @_

		my $id = $ref->get_tid()
		my $type = $ref->get_type()

		print "$id\t$type $level:\t"

		if ($Depth{$id} && $level != $Depth{$id}) {
			warn "Recurson: $id at $level (was $Depth{$id})\n"
			return
		}
		$Depth{$id} = $level

		my($join) = ' '
		foreach my $pref ($ref->get_parents()) {
			my $pid = $pref->get_tid()

			$Depth{$pid} = '0' unless defined $Depth{$pid}
			if ($Depth{$pid} > $level) {
				warn "Depth: $id at $level (pid $pid > $Depth{$pid})\n"
			}

			print "$join$pid"
			$join = ','
		}
		print " <$id>"

		foreach my $cref ($ref->get_children()) {
			my $cid = $cref->get_tid()
			print " $cid"
		}
		print "\n"

		foreach my $cref ($ref->get_children()) {
			dpos($cref, $level+1)
		}
	?*/
}

func up() { /*?
		my($ref) = shift @_

		my $id = $ref->get_tid()

		print "up: $id @_\n" if report_debug

		for my $cid (@_) {
			next if $id != $cid

			panic("Stack fault: $id in @_\n")
		}


		foreach my $pref ($ref->get_parents()) {
			up($pref, $id, @_)

		}
	?*/
}
