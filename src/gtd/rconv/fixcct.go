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

//-- Fix Categories/Contexts/Time Frames
func Report_fixcct(args []string) {
	/*?
		my($new_id, $id)

		task.Header("Categories")
		my($Category) = Hier::CCT->use("Category")
		for my $key (sort $Category->keys()) {
			$id = $Category->get($key)

			next unless $key =~ s/^(\d+)://
			$new_id =  $1

			sql_fix_cct("category", $id, $new_id, $key)
		}
		task.Header("Contexts")
		my($Context) = Hier::CCT->use("Context")
		for my $key (sort $Context->keys()) {
			$id = $Context->get($key)

			next unless $key =~ s/^(\d+)://
			$new_id =  $1

			sql_fix_cct("context", $id, $new_id, $key)
		}
		print "\n"
		task.Header("Time Frames")
		my($Timeframe) = Hier::CCT->use("Timeframe")
		for my $key (sort $Timeframe->keys()) {
			$id = $Timeframe->get($key) || ''

			next unless $key =~ s/^(\d+)://
			$new_id =  $1

			sql_fix_cct("timeframe", $id, $new_id, $key)
		}
		print "\n"
	?*/
}

func sql_fix_cct() { /*?
		my($hint, $old_id, $new_id, $val) = @_

		my($table, $keycol, $valcol)
		if ($hint == "category") {
			$table = G_table("categories")
			$keycol = "categoryId"
			$valcol = "category"
		} elsif ($hint == "context") {
			$table = G_table("context")
			$keycol = "contextId"
			$valcol = "name"
		} elsif ($hint == "timeframe") {
			$table = G_table("timeitems")
			$keycol = "timeframeId"
			$valcol = "timeframe"
		} else {
			panic("sql_fix_cct")
		}
		my($itemstatus) = G_table("itemstatus")

		G_sql("update $table set $keycol=$new_id, $valcol=? where $keycol = $old_id", $val)
		G_sql("update $itemstatus set $keycol=$new_id where $keycol = $old_id")

	?*/
}
