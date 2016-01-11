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

=head1 Bulk Load Syntax

  num:	Id of Roal/Goal/Proj/Action (Tab/Empty for New)
  type:	Type of Id (R/G/P) (if no num, will lookup this entry)
 or
  [_]	Next Action
  [ ]	Action
  [*]	Done
  [X]	Delete
  [-]	Hidden
  { }	Somday/maybe
 or
  ?attr	Attribute
  +	Description
  =	Result
  @cct	Category/Context/Timeframe
  *tag	Tag(s)
  #	comment
 or	
	Blank line end of group

*/

/*?
import "gtd/meta";
import "gtd/option";
import "gtd/prompt";

my $Parent;
my $Child;
my $Type;
my $Info = {};

our report_debug = 0;

//-- Create Projects/Actions items from a file
func Report_bulkload(args []string) {
	my($pid);

	my($action) = \&add_nothing;
	my($desc) = '';

	my($parents) = {};

	for (;;) {
		prompt("+>", '#');
		last unless defined $_;

		if (/^debug/) {
			report_debug = 1;
			print "Debug on\n";
			next;
		}
		//---------------------------------------------------
		// default values
                if (/^pri\D+(\d+)/) {
			set_option("Priority", $1);
                        next;
                }
                if (/^limit\D+(\d+)/) {
                        set_option("Limit", $1);
                        next;
                }
                if (/^format\s(\S+)/) {
                        set_option("Format", $1);
                        next;
                }
                if (/^header\s(\S+)/) {
                        set_option("Header", $1);
                        next;
                }

                if (/^sort\s(\S+)/) {
                        set_option("Sort", $1);
                        next;
                }
		if (/^edit$/) {
			eval {
				Report_edit($pid, $Child);
			}; if ($@) {
				print "Trapped error: $@\n";
			}
			next;
		}

		//---------------------------------------------------

		if (/^(\d+):$/) {
			my($tid) = $1;
			// get context
			my($pref) = meta.Find($tid);
			unless ($pref) {
				print "Can't find pid: $tid\n";
				next;
			}

			$pid = $pref->get_tid();
			my($type) = $pref->get_type();
			$parents->{$type} = $pid;
			
			print "Parent($type): $tid - ", $pref->get_title(), "\n";
			next;
		}

		if (s=^([a-z]+):\s*==) {
			chomp;
			$Info->{$1} = $_;
			next;
		}

		if (s=^(\d+)\t[A-Z]:\s*==) {
			&$action($parents, $desc);
			$action = \&add_update;
			$pid = $1;
			$parents->{me} = $pid;
			next;
		}
		if (s=^R:\s*==) {
			&$action($parents, $desc);

			$pid = find_hier('r', $_);
			panic("No parent $_") unless $pid;
			$parents->{r} = $pid;
			next;
		}
		if (s=^G:\s*==) {
			&$action($parents, $desc);

			$pid = find_hier('g', $_);
			if ($pid) {
				$action = \&add_nothing;
				$parents->{g} = $pid;
			} else {
				$action = \&add_goal;
			}
			next;
		}
		if (s=^[P]:\s*==) {
			&$action($parents, $desc);

			$action = \&add_project;
			set_option(Title => $_);
			$desc = '';
			next;
		}
		// lines that start with bullets or checkboxs:
		// ie:
		if (s=^\**\s*\[_*\]\s*==	//    * [_]  title
		|| s=^\**\s*==			//or  *      title
		|| s=^\[_*\]\s*==) {		//or  [_]    title
			&$action($parents, $desc);

			$action = \&add_action;
			set_option(Title => $_);
			$desc = '';
			next;
		}
		$desc .= "\n" . $_;
	}
	&$action($parents, $desc);
}

sub find_hier {
	my($type, $goal) = @_;

	for my $ref (gtd.Meta_hier()) {
		next unless $ref->get_type() eq $type;
		next unless $ref->get_title() eq $goal;

		return $ref->get_tid();
	}
	for my $ref (gtd.Meta_hier()) {
		next unless $ref->get_type() eq $type;
		next unless lc($ref->get_title()) eq lc($goal);

		return $ref->get_tid();
	}

	for my $ref (gtd.Meta_hier()) {
		next unless $ref->get_title() eq $goal;
	
		my($type) = $ref->get_type();
		my($tid) = $ref->get_tid();
		warn "Found: something close($type) $tid: $goal\n";
		return $tid;
	}
	panic("Can"t find a hier item for "$goal' let alone a $type.\n");
}

sub add_nothing {
	my($parents, $desc) = @_;

	// do nothing
	print "# nothing pending\n" if report_debug;

	if ($desc) {
		print "Lost description\n" if $desc;
	}
}

sub add_goal {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s=^\n*==s;

	$Parent = $parents->{'r'};

	$tid = add_task('g', $desc);

	$parents->{'g'} = $tid;
}

sub add_project {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s=^\n*==s;

	$Parent = $parents->{'g'};

	$tid = add_task('p', $desc);

	$parents->{'p'} = $tid;
}

sub add_action {
	my($parents, $desc) = @_;
	my($tid);

	$desc =~ s=^\n*==s;
	$Parent = $parents->{'p'};

	$tid = add_task('a', $desc);
}

sub add_task {
	my($type, $desc) = @_;

	my($pri, $title, $category, $note, $line);

	$title    = option("Title");
	$pri      = option("Priority") || 4;
	$desc     = option("Desc") || $desc;

	$category = option("Category") || '';
	$note     = option("Note"); 

	my $ref = Hier::Tasks->new(undef);

	$ref->set_category($category);
	$ref->set_title($title);
	$ref->set_description($desc);
	$ref->set_note($note);

	$ref->set_type($type);

	if ($pri > 5) {
		$pri -= 5;
		$ref->set_isSomeday('y');
	}
	$ref->set_nextaction('y') if $pri < 3;
	$ref->set_priority($pri);

	print "Parent: $Parent\n";

	$Child = $ref->get_tid();

	$ref->set_parent_ids($Parent);

	print "Created ($type): ", $ref->get_tid(), "\n";

	for my $key (keys %$Info) {
		$ref->set_KEY($key, $Info->{$key});
	}
	$Info = {};

	$ref->insert();
	return $ref->get_tid();
}
?*/
