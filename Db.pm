package Hier::Db;  # assumes Some/Module.pm

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&DB_init &set &gtd_insert &gtd_update);
}

#==============================================================================
# Low level database abstraction
#==============================================================================

use DBI;
use YAML::Syck qw(LoadFile);
use Data::Dumper;

use Hier::CCT;
use Hier::Tasks;
use Hier::Hier;
use Hier::Option;

my $Current_ref;	# current gtd mapped item

my $Table;
our $Debug = 0;
my $MetaFix = 1;

my($Category, $Context, $Timeframe, $Tags);

# how to handle key
# x1 => normal
# x2 => use youngest
# x3 => used oldest
# 0x => virtual
# 1x => in gtd_todo
# 2x => in gtd
# 3x => in both
my(%Key_type) = (
	todo_id         => 0x31,
	category        => 0x11,
	task            => 0x31,
	children        => 0x01,
	priority        => 0x11,
	description     => 0x31,
	note            => 0x31,
	owner           => 0x11,
	private         => 0x11,

	created         => 0x32,	# youngest
	modified        => 0x33,	# oldest

	due             => 0x32,	# youngest
	completed       => 0x33,	# oldest

	recur		=> 0x21,
	recurdesc	=> 0x21,

	_gtd_category	=> 0x21,
	isSomeday	=> 0x21,
	nextaction	=> 0x21,
	tickledate	=> 0x21,
	timeframe	=> 0x01,
	_gtd_timeframe	=> 0x21,
	context		=> 0x01,
	_gtd_context	=> 0x21,

	palm_id         => 0x11,
	type            => 0x21,
	doit            => 0x11,
	effort		=> 0x11,
	'state'		=> 0x11,
	resource	=> 0x11,
	depends         => 0x11,
	percent         => 0x11,

	_hint		=> 0x01,	# resource hint
);

sub load_meta {
	my($row, $tid, $ref);

	my($sth) = T_select();
	while ($row = $sth->fetchrow_hashref) {
		$tid = $row->{todo_id};

		$ref = Hier::Tasks->New($tid);
		$ref->{_todo_only} = 0x01;

		delete $row->{todo_id};

		foreach my $key (keys %$row) {
			cset($ref, $key  => $row->{$key});
		}
	}
}

# post process after loading tables;
sub metafix {
	my($tid, $pid, $p, $name, $only);

	# Process Tasks (non-hier) items
	for my $ref (Hier::Tasks::all()) {
		$tid = $ref->get_tid();

		$only = $ref->{_todo_only};
		if ($only == 1) {	# only in gtd_todo (gtd deleted it)
			warn "Need delete: $tid\n" if $Debug;
			dump_task($ref);
			$ref->delete();
			next;

		} elsif ($only == 2) {	# only in gtd (we fucked up somewhere)
			warn "Need create: $tid\n" if $Debug;
			dump_task($ref);

		} elsif ($only == 3) {	# in both (happyness)

		} else {
			dump_task($ref);
			die "We buggered up: $tid\n";
		}
	}
}

sub dump_task {
	my ($ref) = @_;

	return unless $Debug;

	my($val);
	for my $key (sort keys %$ref) {
		$val = $ref->{$key} || '';
		$val =~ s/\n.*/.../m;
		warn "$key:\t$val\n";
	}
}

sub set {
	my($ref, $field, $value, $issafe) = @_;

	my $tid = $ref->{todo_id};
	unless ($tid) {
		die "set field=$field failed for [$value] todo_id undefined\n";
		return;
	}

	if (defined($ref->{$field}) and $ref->{$field} eq $value) {
		warn "Opps $tid: $field is already $value\n";
		return;
	}

	if ($field eq 'todo_id') {
		unless ($issafe) {
			warn "Won't change todo_id => $value\n";
			return;
		}
	}

	###ToDo check for parents, call set_parents.
	if ($field eq 'Parents') {
		$ref->set_parent_ids($value);
		return;
	}

	$ref->{$field} = $value;
	$ref->set_dirty($field);
}

# gtd_checklist      |	Not used
# gtd_checklistitems |  Not used
# gtd_list           |	Not used
# gtd_listitems      |	Not used

# gtd_tickler        |	Not used 

# gtd_categories     |
# gtd_context        |
				# gtd_itemattributes | removed
# gtd_items          |
# gtd_itemstatus     |
# gtd_lookup         |
# gtd_preferences    |
# gtd_tagmap         |
# gtd_timeitems      |
# gtd_version        |
# gtd_todo           <<< this one is mine

sub load_gtd {
	my($ref, $row, $tid);
	
	my($XXX) = <<'EOF';
+-------------+------------------+------+-----+---------+----------------+
| Field       | Type             | Null | Key | Default | Extra          |
+-------------+------------------+------+-----+---------+----------------+
| categoryId  | int(10) unsigned |      | PRI | NULL    | auto_increment |
| category    | text             |      | MUL |         |                |
| description | text             | YES  | MUL | NULL    |                |
+-------------+------------------+------+-----+---------+----------------+
EOF
	$Category = Hier::CCT->use('Category');
	my($sth) = G_select('categories');
	while ($row = $sth->fetchrow_hashref()) {
		$Category->define($row->{category}, $row->{categoryId});
	}

	$XXX = <<'EOF';
+-------------+------------------+------+-----+---------+----------------+
| Field       | Type             | Null | Key | Default | Extra          |
+-------------+------------------+------+-----+---------+----------------+
| contextId   | int(10) unsigned |      | PRI | NULL    | auto_increment |
| name        | text             |      | MUL |         |                |
| description | text             | YES  | MUL | NULL    |                |
+-------------+------------------+------+-----+---------+----------------+
EOF
	$Context = Hier::CCT->use('Context');
	$sth = G_select('context');
	while ($row = $sth->fetchrow_hashref()) {
		$Context->define($row->{name}, $row->{contextId});
	}

	$XXX = <<'EOF';
+-------------+-------------------+------+-----+---------+----------------+
| Field       | Type              | Null | Key | Default | Extra          |
+-------------+-------------------+------+-----+---------+----------------+
| timeframeId | int(10) unsigned  | NO   | PRI | NULL    | auto_increment |
| timeframe   | text              | NO   | MUL | NULL    |                |
| description | text              | YES  | MUL | NULL    |                |
| type        | enum('vogpa')     | NO   | MUL | a       |                |
+-------------+-------------------+------+-----+---------+----------------+
EOF
	$Timeframe = Hier::CCT->use('Timeframe');
	$sth = G_select('timeitems');
	while ($row = $sth->fetchrow_hashref()) {
		$Timeframe->define($row->{timeframe}, $row->{timeframeId});
	}

	$XXX = <<'EOF';
+---------------+----------------------+------+-----+-------------------+
| Field         | Type                 | Null | Key | Default           |
+---------------+----------------------+------+-----+-------------------+
| itemId        | int(10) unsigned     | NO   | PRI | auto_increment    |
| dateCreated   | date                 | YES  |     | NULL              |
| lastModified  | timestamp            | NO   |     | CURRENT_TIMESTAMP |
| dateCompleted | date                 | YES  |     | NULL              |
| type          | enum('mvogparwiLCT') | NO   | MUL | i                 |
| categoryId    | int(11) unsigned     | NO   | MUL | 0                 |

| isSomeday   | enum('y','n')    | NO   | MUL | n       |                |
| contextId   | int(10) unsigned | NO   | MUL | 0       |                |
| timeframeId | int(10) unsigned | NO   | MUL | 0       |                |
| deadline    | date             | YES  |     | NULL    |                |
| tickledate  | date             | YES  |     | NULL    |                |
| nextaction  | enum('y','n')    | NO   |     | n       |                |
+---------------+----------------------+------+-----+-------------------+

EOF
	$sth = G_select('itemstatus');
	while ($row = $sth->fetchrow_hashref()) {
		gtdmap($row, todo_id        => 'itemId');
		gtdmap($row, modified       => 'lastModified');
		gtdmap($row, created        => 'dateCreated');
		gtdmap($row, completed      => 'dateCompleted');
		gtdmap($row, type           => 'type');
		gtdmap($row, _gtd_category  => 'categoryId');

		gtdmap($row, isSomeday      => 'isSomeday');
		gtdmap($row, _gtd_context   => 'contextId');
		gtdmap($row, _gtd_timeframe => 'timeframeId');
		gtdmap($row, due            => 'deadline');
		gtdmap($row, nextaction     => 'nextaction');
		gtdmap($row, tickledate     => 'tickledate');

		$ref = $Current_ref;
		cset($ref, category  => $Category->name($row->{categoryId}));
		cset($ref, context   => $Context->name($row->{contextId}));
		cset($ref, timeframe => $Timeframe->name($row->{timeframeId}));
	}
	G_default('isSomeday', 'n');

	$XXX = <<'EOF';
mysql> describe gtd_items;
+----------------+------------------+------+-----+---------+----------------+
| Field          | Type             | Null | Key | Default | Extra          |
+----------------+------------------+------+-----+---------+----------------+
| itemId         | int(10) unsigned |      | PRI | NULL    | auto_increment |
| title          | text             |      | MUL |         |                |
| description    | longtext         | YES  | MUL | NULL    |                |
| desiredOutcome | text             | YES  | MUL | NULL    |                |
| recurdesc      | text             | YES  |     | NULL    |                |
| recur          | text             | YES  |     | NULL    |                |
+----------------+------------------+------+-----+---------+----------------+
EOF

	$sth = G_select('items');
	while ($row = $sth->fetchrow_hashref) {
		gtdmap($row, todo_id     => 'itemId');
		gtdmap($row, task        => 'title');
		gtdmap($row, description => 'description');
		gtdmap($row, note        => 'desiredOutcome');

		gtdmap($row, recurdesc   => 'recurdesc');
		gtdmap($row, recur       => 'recur');

	}


	$XXX = <<'EOF';
+----------+------------------+------+-----+---------+-------+
| Field    | Type             | Null | Key | Default | Extra |
+----------+------------------+------+-----+---------+-------+
| parentId | int(11)          |      | PRI | 0       |       |
| itemId   | int(10) unsigned |      | PRI | 0       |       |
+----------+------------------+------+-----+---------+-------+
EOF
	$sth = G_select('lookup');
	while ($row = $sth->fetchrow_hashref()) {
		next if $row->{parentId} == 0;	# handle buggered up data
		next if $row->{itemId} == 0;	# to non-objects

		add_relationship($row->{parentId}, $row->{itemId});

	}
	$XXX = <<'EOF';
+---------+------------------+------+-----+---------+-------+
| Field   | Type             | Null | Key | Default | Extra |
+---------+------------------+------+-----+---------+-------+
| itemId  | int(10) unsigned | NO   | PRI | NULL    |       |
| tagname | text             | NO   | PRI | NULL    |       |
+---------+------------------+------+-----+---------+-------+
EOF
	my($tags_ref) = Hier::CCT->use('Tag');
	my($tag);
	$sth = G_select('tagmap');
	my($tag_id) = 0;
	while ($row = $sth->fetchrow_hashref) {
		$tid = $row->{itemId};
		$tag = $row->{tagname};
		$ref = Hier::Tasks::find($tid);
		next unless defined $ref;

		$ref->{_tags}{$tag}++;

		$tags_ref->define($tag, ++$tag_id);
	}

	foreach my $ref (Hier::Tasks::all()) {
		$ref->clean_dirty();		# everything cleanly loaded
	}

}

sub add_relationship {
	my($pid, $tid) = @_;

	my $pref = Hier::Tasks::find($pid);
	my $tref = Hier::Tasks::find($tid);

	return unless $pref and $tref;	# both must be defined

	$pref->add_child($tref);
}

sub gtdmap {
	my($db, $t_key, $g_key) = @_;
	# add mapping for $Table/g_key => t_key;
#	$GTd{$t_key} = ...

	G_learn($t_key, $g_key);

	my($val) = html_clean( $db->{$g_key} );

	# New master key
	if ($t_key eq 'todo_id') {
		my $ref = Hier::Tasks::find($val);
		if (defined $ref) {
			$Current_ref = $ref;
			$Current_ref->{_todo_only} |= 0x02;
			return;
		}
		unless ($val) {
			die "Can't create gtd_todo with todo_id=$val for table $Table\n";
		}
		warn "Hard Need Create $val\n" if $Debug;
		$Current_ref = Hier::Tasks->New($val);
		$Current_ref->{_todo_only} = 0x03;
		sac_create($val, {});
		return;
	}

	cset($Current_ref, $t_key, $val);
}

sub html_clean {
	my($val) = @_;

	return undef unless defined $val;

	return $val unless $val =~ m/&[a-z]+;/;
	my %map = (
		lt	=> '<',
		gt	=> '>',
		amp	=> '&',
		quote	=> "'",
		dquote	=> '"',
	);

	my($to) = '';
	while ($val =~ s/^(.*)&([A-Za-z]+);//) {
		if (defined $map{lc($2)}) {
			$to .= $1 . $map{lc($2)};
		} else {
			$to .= $1 . '&' . $2 . ';'; # put it back
			warn "No & XXX ; mapping for $2\n";
		}
	}

	return $to . $val;
}

#
# create-initial set value. (nothing dirty at this point)
#
sub cset {
	my($ref, $key, $val) = @_;

	# no value defined, skip update/creation of field
	return unless defined $val;

	my($key_type) = $Key_type{$key} & 0x0F;
	unless ($key_type) {
		warn "Unknown key: $key\n";
		$Key_type{$key} = 1;

		$ref->{$key} = $val;
		return;
	}
	# never seen value, just set it
	unless (defined $ref->{$key}) {
		$ref->{$key} = $val;
		return;
	}

	# keep youngest (smaller value)
	if ($key_type == 2) {
		return if $val eq ''; # no new value

		my($current_value) = $ref->{$key};

		# handle we don't have enough detail
                if (length($current_value) eq 8 or length($val) == 8) {
			return if (substr($current_value,0,8) eq substr($val,0,8));
		}

		if ($current_value eq '' || $val lt $current_value) {
			$ref->{$key} = $val;
		}
		return;
	}

	# keep oldest (bigger value)
	if ($key_type == 3) {
		return if $val eq ''; # no new value

		my($current_value) = $ref->{$key};

		if ($current_value eq '' || $val gt $current_value) {
			$ref->{$key} = $val;
		}
		return;
	}

	# keep value last seen value
	$ref->{$key} = $val;
}

sub gtd_insert {
	my($ref, $mode) = @_;

	my($tid) = $ref->get_tid();
	sac_create($tid, $ref);

	gtd_fix_maps($ref);
	gset_insert($ref, 'itemstatus');
	gset_insert($ref, 'items');
	gset_insert_parents($ref, 0);
}

sub gset_insert_parents {
	my($ref, $del) = @_;

	return unless $ref->get_dirty('parents');

	my $tid = $ref->{todo_id};
	my $table = "gtd_lookup";

	G_sql("delete from $table where itemId=?", $tid) if $del;
	foreach my $pid ($ref->parent_ids()) {
		G_sql("insert into $table(parentId,itemId)values(?,?)",
			$pid, $tid);
	}
}

sub gset_insert {
	my $ref = shift @_;
	my $table = G_table(shift @_);

	my $qmark = '';
	my $sql;
	my @keys = ();
	my @vals = ();

	my ($key, $fld, $val);

	my $map = G_list($table);
	for my $key (keys %$map) {
		$fld = $map->{$key};

		next unless defined $ref->{$key};
		next unless $ref->{$key};

		push(@keys, $fld);
		push(@vals, $ref->{$key});

		$qmark .= ',?';
	}

	$qmark =~ s/^,//;
	$sql = "insert into $table(" . join(',', @keys) . ") values($qmark)";

	G_sql($sql, @vals);
}

sub gtd_update {
	my($ref) = @_;

	gtd_fix_maps($ref);

	sac_update($ref);

	gset_update($ref, 'itemstatus');
	gset_update($ref, 'items');

	gset_insert_parents($ref, 1);
	$ref->clean_dirty();
}

sub gtd_fix_maps {
	my($ref) = @_;

	my($today) = get_today(0);	# uncached version
	unless (defined $ref->{created}) {
		set($ref, 'created', $today);
	}
	set($ref, 'modified', $today);
	set($ref, '_gtd_modified', $today);

	_fix_map($ref, 'category',  '_gtd_category',  $Category);
	_fix_map($ref, 'context',   '_gtd_context',   $Context);
	_fix_map($ref, 'timeframe', '_gtd_timeframe', $Timeframe);

#	_fix_map($ref, 'tags', 'timeframeId', \%Timeframes);
}

sub _fix_map {
	my($ref, $type, $index, $master) = @_;

	return unless $ref->is_dirty($type);

	my($val_id) = 0;
	my($val) = $ref->{$type};
	if (!defined $val) {
			## timeframe never set
			return;
	}

	if ($val ne '') {
		$val_id = $master->get($val);
		if (!defined $val_id) {
			warn "unmapped $type: $val";
			###BUG### we need to create it?
			return;
		}
	}

	if (defined $ref->{$index}) {
		return if $ref->{$index} == $val_id;
	}
	$ref->{$index} = $val_id;

	$ref->set_dirty($index);
}

sub gset_update {
	my $ref = shift @_;
	my $table = G_table(shift @_);

	my $qmark = '';
	my $sql;
	my @keys = ();
	my @vals = ();

	my ($fld, $val);

	my $map = G_list($table);
	for my $key (keys %$map) {
		next unless $ref->get_dirty($key);	# don't update clean fields

		warn "Mapping: $key => $map->{$key}\n" if $Debug;
		$fld = $map->{$key};

		next unless defined $ref->{$key};
#		next unless $ref->{$key};

		push(@keys, $fld);
		push(@vals, $ref->{$key});

		$qmark .= ',?';
	}

	return unless @keys;	# nothing changed


	$qmark =~ s/^,//;
	$sql = "update $table set " . join('=?, ', @keys) .
	                          "=? where itemId=?";
	push(@vals, $ref->{todo_id});

	G_sql($sql, @vals);
}

sub gtd_delete {
	my($tid) = @_;

	gset_delete($tid, 'itemstatus');
	gset_delete($tid, 'items');
	gset_delete($tid, 'lookup');

	sac_delete($tid);
}

sub gset_delete {
	my($tid, $table) = @_;

	$table = G_table($table);
	my($sql) = "delete from $table where itemId = ?";
	G_sql($sql, $tid);
}

sub sac_update {
	my $ref = shift @_;

	my($tid) = $ref->{todo_id};
	for my $fld (keys %Key_type) {
		next unless $Key_type{$fld} & 0x10;		# in gtd_todo db
		next unless defined $ref->{$fld};
		next unless $ref->get_dirty($fld);

		my($sql) = "update gtd_todo set $fld = ? where todo_id = ?";
		G_sql($sql, $ref->{$fld}, $tid);
	}
}

sub sac_create {
	my($tid, $ref) = @_;

	G_sql("insert into gtd_todo(todo_id) values(?)", $tid);
	
	for my $fld (keys %Key_type) {
		next if $fld eq 'todo_id';
		next unless $Key_type{$fld} & 0x10;	# in gtd_todo db
		next unless defined $ref->{$fld};

		next unless $ref->get_dirty($fld);

		my($sql) = "update gtd_todo set $fld = ? where todo_id = ?";
		G_sql($sql, $ref->{$fld}, $tid);
	}
}

sub sac_delete {
	my($tid) = @_;

	G_sql("delete from gtd_todo where todo_id = ?", $tid);
}


##############################################################################
##############################################################################
################### Database #################################################
##############################################################################
##############################################################################

my($GTD);
my($GTD_map, $GTD_default);
my($Prefix) = 'gtd_';

our $Resource;	# used by Hier::Resource

sub DB_init {
	my($confname) = @_;

	$Debug = option('Debug');
	$MetaFix = option('MetaFix');


	if ($confname) {
		warn "#-Using $confname in Access.yaml\n" if $Debug;
	} else {
		$confname = 'gtd';
#		$confname = 'gtdtest';
	}

	my $HOME = $ENV{'HOME'};
	my $conf = LoadFile("$HOME/.todo/Access.yaml");

	$Hier::Resource::Resource = $conf->{resource};

	my($dbconf) = $conf->{$confname};

	unless ($dbconf) {
		die "Can't fine section $confname in ~/.todo/Access.yaml\n";
	}

	warn Dumper($dbconf) if $Debug;

	my($dbname) = $dbconf->{'dbname'};
	my($host)   = $dbconf->{'host'};
	my($user)   = $dbconf->{'user'};
	my($pass)   = $dbconf->{'pass'};
	my($port)   = $dbconf->{'port'} || 3306;

	if ($confname ne 'gtd') {
		warn "confname=$confname;dbname=$dbname;host=$host;port=$port\n";
	}

	$Prefix = $dbconf->{'prefix'};
	$Prefix = 'gtd_' unless defined $Prefix; # empty, but defined ok

	$GTD = DBI->connect("dbi:mysql:dbname=$dbname;host=$host", $user, $pass);
	die "confname=$confname;dbname=$dbname;host=$host;user=$user;pass=$pass\n" unless $GTD;

	option('Changed', G_val('gtd_todo', 'max(modified)'));

#warn "Start ".localtime()."\n";
	load_meta();
#warn "Mid   ".localtime()."\n";
	load_gtd();
#warn "End   ".localtime()."\n";

	metafix();
#warn "Done  ".localtime()."\n";
}

sub G_table {
	return $Prefix . $_[0];
}

sub T_select {
	my($sql) = "select * from gtd_todo";

	my($sth) = $GTD->prepare($sql);
	my($rv) = $sth->execute();
	if ($rv < 0) {
		die "sql=$sql";
	}
	return $sth;
}

sub G_sql {
	my($sql) = shift @_;

	warn "gtd-sql: $sql: @_\n" if $Debug;

	unless ($MetaFix) {
		warn "Skipped: $sql\n";
		return;
	}

	my($rv);
	eval {
		$rv = $GTD->do($sql, undef, @_);
		warn "-> $rv\n" if $Debug;
	}; if ($@ or !defined $rv) {
		print "Failed sql: $sql ($rv)\n";
		print "..........: $@";
	}
	
	return $rv;
}

sub G_select {
	my($table) = @_;

	$Table = $Prefix . $table;

	my($sql) = "select * from $Table";

	$GTD_map->{$Table} = {};

	my($sth) = $GTD->prepare($sql);
	my($rv) = $sth->execute;
	if ($rv < 0) {
		die "$table: sql=$sql";
	}
	return $sth;
}

sub G_learn {
	my($from, $to) = @_;

	$GTD_map->{$Table}->{$from} = $to;
}

sub G_list {
	my($table) = @_;

	return $GTD_map->{$table};
}

sub G_default {
	my($key, $val) = @_;

	$GTD_default->{$key} = $val;
}

sub G_default_val {
	my($key) = @_;

	return $GTD_default->{$key};
}

sub G_renumber {
	my($ref, $tid, $new) = @_;

        my(@list) = qw(items itemstatus tagmap);
        warn "Setting TID $tid => $new\n";

        G_sql("update gtd_lookup set itemId=$new where itemId=$tid");
        G_sql("update gtd_lookup set parentId=$new where parentId=$tid");
        G_sql("update gtd_tagmap set itemId=$new where itemId=$tid");

	G_sql("update gtd_todo set todo_id = ? where todo_id = ?", $new, $tid);

        for my $table (@list) {
                G_sql("update gtd_$table set itemId=$new where itemId=$tid");
        }
}

sub G_val {
	my($table, $query) = @_;

	my($sql) = "select $query from $table";
	my($sth) = $GTD->prepare($sql);
	my($rv) = $sth->execute();
	if ($rv < 0) {
		die "sql=$sql";
	}

	my($row, $changed);
	while (($row) = $sth->fetchrow_array()) {
		$changed = $row;
	}
	return $changed;
}

1;  # don't forget to return a true value from the file
