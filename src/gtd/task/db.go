package task


//	@EXPORT      = qw(&DB_init &set &gtd_insert &gtd_update)


//==============================================================================
// Low level database abstraction
//==============================================================================

import (
	"fmt"
	"log"
	"os"
	"time"

	"encoding/json"

	"gtd/option"
	"gtd/cct"

//	"gopkg.in/yaml.v2"

	"database/sql"
	_ "github.com/go-sql-driver/mysql"
)

var db_debug bool = false
var MetaFix  bool = false

var Prefix string = "gtd_"

var db_Table string = ""

/*?
use DBI
use YAML::Syck qw(LoadFile)
use Data::Dumper

my $Current_ref;	// current gtd mapped item

my $Table

func (t *Task)Set(field string, value string) {
	tid := t.Tid

	if field == "todo_id {
		panic("set todo_id")
	}

	t.set_KEY(field, value)
}
?*/

// gtd_categories     |
// gtd_context        |

// gtd_items          |
// gtd_itemstatus     |
// gtd_lookup         |
// gtd_preferences    |
// gtd_tagmap         |
// gtd_timeitems      |
// gtd_version        |
// gtd_todo            <<< this one is mine

func db_load_gtd() {
	// get the cct values before task creation
	db_load_category()
	db_load_context()
	db_load_timeframe()

	// db_load_items to be called first
	//  since it creates the tasks
	db_load_items()
	db_load_itemstatus()

	db_load_todo()

	db_load_lookup()

	db_load_tags()
}

/*
+-------------+------------------+------+-----+---------+----------------+
| Field       | Type             | Null | Key | Default | Extra          |
+-------------+------------------+------+-----+---------+----------------+
| categoryId  | int(10) unsigned |      | PRI | NULL    | auto_increment |
| category    | text             |      | MUL |         |                |
| description | text             | YES  | MUL | NULL    |                |
+-------------+------------------+------+-----+---------+----------------+
*/
func db_load_category() {
	category := cct.Use("Category")

	var (
		id	int
		name	sql.NullString
		desc	sql.NullString
	)

	rows := G_select("categories", "categoryId,category,description")

	for rows.Next() {
		rows.Scan(&id, &name, &desc)
		category.Define(id, name.String, desc.String)
	}
	G_done(rows)
}

/*
+-------------+------------------+------+-----+---------+----------------+
| Field       | Type             | Null | Key | Default | Extra          |
+-------------+------------------+------+-----+---------+----------------+
| contextId   | int(10) unsigned |      | PRI | NULL    | auto_increment |
| name        | text             |      | MUL |         |                |
| description | text             | YES  | MUL | NULL    |                |
+-------------+------------------+------+-----+---------+----------------+
*/
func db_load_context() {
	context := cct.Use("Context")

	var (
		id	int
		name	sql.NullString
		desc	sql.NullString
	)

	rows := G_select("context", "contextId,name,description")
	for rows.Next() {
		rows.Scan(&id, &name, &desc)
		context.Define(id, name.String, desc.String)
	}
}

/*
+-------------+-------------------+------+-----+---------+----------------+
| Field       | Type              | Null | Key | Default | Extra          |
+-------------+-------------------+------+-----+---------+----------------+
| timeframeId | int(10) unsigned  | NO   | PRI | NULL    | auto_increment |
| timeframe   | text              | NO   | MUL | NULL    |                |
| description | text              | YES  | MUL | NULL    |                |
| type        | enum("vogpa")     | NO   | MUL | a       |                |
+-------------+-------------------+------+-----+---------+----------------+
*/
func db_load_timeframe() {
	timeframe := cct.Use("Timeframe")

	var (
		id	int
		name	sql.NullString
		desc	sql.NullString
	)

	rows := G_select("timeitems", "timeframeId,timeframe,description")
	for rows.Next() {
		rows.Scan(&id, &name, &desc)
		timeframe.Define(id, name.String, desc.String)
	}
}

/*
mysql> describe gtd_items
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
*/
func db_load_items() {
	var (
		todo_id	int
		title	string
		desc	sql.NullString
		note	sql.NullString
		rdesc	sql.NullString
		recur	sql.NullString
	)

	rows := G_select("items", "itemId,title,description,desiredOutcome,recurdesc,recur")
	for rows.Next() {
		rows.Scan(&todo_id, &title, &desc, &note, &rdesc, &recur)
		t := New(todo_id)
		
		t.Title       = title
		t.Description = desc.String
		t.Note        = note.String
		t.Rdesc       = rdesc.String
		t.Recur       = recur.String
	}
	G_done(rows)
}

/*
+---------------+----------------------+------+-----+-------------------+
| Field         | Type                 | Null | Key | Default           |
+---------------+----------------------+------+-----+-------------------+
| itemId        | int(10) unsigned     | NO   | PRI | auto_increment    |
| dateCreated   | date                 | YES  |     | NULL              |
| lastModified  | timestamp            | NO   |     | CURRENT_TIMESTAMP |
| dateCompleted | date                 | YES  |     | NULL              |
| type          | enum("mvogparwiLCT") | NO   | MUL | i                 |
| categoryId    | int(11) unsigned     | NO   | MUL | 0                 |

| isSomeday   | enum('y','n')    | NO   | MUL | n       |                |
| contextId   | int(10) unsigned | NO   | MUL | 0       |                |
| timeframeId | int(10) unsigned | NO   | MUL | 0       |                |
| deadline    | date             | YES  |     | NULL    |                |
| tickledate  | date             | YES  |     | NULL    |                |
| nextaction  | enum('y','n')    | NO   |     | n       |                |
+---------------+----------------------+------+-----+-------------------+
*/

func db_load_itemstatus() {
//	rows = G_select("itemstatus", "itemId,dateCreated,lastModified,dateCompleted,type,categoryId,isSomeday,contextId,timeframeId,deadline,tickledate,nextaction")
	rows := G_select("itemstatus", "itemId,type,nextaction")

	var(
		todo_id    int
		tasktype   byte
		nextaction byte
	)

	for rows.Next() {
		rows.Scan(&todo_id, &tasktype, &nextaction)

		t := Find(todo_id)
		if t == nil {
			continue
		}

		t.Type = tasktype
		t.IsNextaction = nextaction == 'y'
//?		gtdmap($row, "todo_id"       => "itemId")
//?		gtdmap($row, "modified"      => "lastModified")
//?		gtdmap($row, "created"       => "dateCreated")
//?		gtdmap($row, "completed"     => "dateCompleted")
//?		gtdmap($row, "type"          => "type")
//?		gtdmap($row, "_gtd_category" => "categoryId")
//?
//?		gtdmap($row, "isSomeday"     => "isSomeday")
//?		gtdmap($row, "_gtd_context"  => "contextId")
//?		gtdmap($row, "_gtd_timeframe"=> "timeframeId")
//?		gtdmap($row, "due"           => "deadline")
//?		gtdmap($row, "nextaction"    => "nextaction")
//?		gtdmap($row, "tickledate"    => "tickledate")
//?
//?		$ref = $Current_ref
//?		cset($ref, category  => $Category->name($row->{categoryId}))
//?		cset($ref, context   => $Context->name($row->{contextId}))
//?		cset($ref, timeframe => $Timeframe->name($row->{timeframeId}))
	}

	G_done(rows);
}


/*
+----------+------------------+------+-----+---------+-------+
| Field    | Type             | Null | Key | Default | Extra |
+----------+------------------+------+-----+---------+-------+
| parentId | int(11)          |      | PRI | 0       |       |
| itemId   | int(10) unsigned |      | PRI | 0       |       |
+----------+------------------+------+-----+---------+-------+
*/
func db_load_lookup() {
	var (
		pid	int
		tid	int
	)

	rows := G_select("lookup", "parentId,itemId")
	for rows.Next() {
		rows.Scan(&pid, &tid)
		if pid == 0 || tid == 0 {
			log.Printf("Invalid tid/pid lookup: (%d, %d)", tid, pid)
			continue
		}

		p := Find(pid)
		if p == nil {
			log.Printf("Invalid pid in tid/pid (%d, %d)", tid, pid)
			continue
		}

		t := Find(pid)
		if t == nil {
			log.Printf("Invalid tid in tid/pid (%d, %d)", tid, pid)
			continue
		}

		p.add_child(t)
	}
	G_done(rows)
}


/*
+---------+------------------+------+-----+---------+-------+
| Field   | Type             | Null | Key | Default | Extra |
+---------+------------------+------+-----+---------+-------+
| itemId  | int(10) unsigned | NO   | PRI | NULL    |       |
| tagname | text             | NO   | PRI | NULL    |       |
+---------+------------------+------+-----+---------+-------+
*/

func db_load_tags() {
	tags := cct.Use("Tags")

	rows := G_select("tagmap", "itemId,tagname")

	var(
		id	int
		tag	string
	)

	tag_id := 0
	for rows.Next() {
		rows.Scan(&id, &tag);

		t := Find(id)
		if t == nil {
			continue
		}

		t.Tags = append(t.Tags, tag);

		tag_id++; tags.Define(tag_id, tag, "")
	}
	G_done(rows)
}

/*
mysql> describe gtd_todo
+----------+-------------+------+-----+---------+----------------+
| Field    | Type        | Null | Key | Default | Extra          |
+----------+-------------+------+-----+---------+----------------+
| todo_id  | int(11)     | NO   | MUL | NULL    | auto_increment |
| category | varchar(16) | YES  |     | NULL    |                |
| priority | int(11)     | NO   |     | 4       |                |
| state    | char(1)     | YES  |     | NULL    |                |
| doit     | datetime    | YES  |     | NULL    |                |
| effort   | int(11)     | YES  |     | NULL    |                |
| resource | varchar(60) | YES  |     | NULL    |                |
| depends  | varchar(60) | YES  |     | NULL    |                |
| percent  | int(11)     | YES  |     | NULL    |                |
+----------+-------------+------+-----+---------+----------------+
*/
func db_load_todo() {
	var (
		todo_id		int
		priority	int
		state		byte
		doit		time.Time
		effort		int
		resource	sql.NullString
		depends		sql.NullString
		percent		int
	)
	
	rows := G_select("todo", "todo_id,priority,state,doit,effort,resource,depends,percent")
	for rows.Next() {
		rows.Scan(
			&todo_id,
			&priority,
			&state,
			&doit,
			&effort,
			&resource,
			&depends,
			&percent)
		t := Find(todo_id)
		if t == nil {
			continue
		}

		t.Tid = todo_id
		t.Priority = priority
		t.State = state
		t.Doit = doit
		t.Effort = effort
//?		t.Resource = resource.String
//?		t.Depends = depends.String
		t.Percent = percent
	}
	G_done(rows)

}

//
// create-initial set value. (nothing dirty at this point)
//
/*?
sub cset {
	my($ref, $key, $val) = @_

	// no value defined, skip update/creation of field
	return unless defined $val

	my($key_type) = $Key_type{$key} & 0x0F
	unless ($key_type) {
		warn "Unknown key: $key\n"
		$Key_type{$key} = 1

		$ref->{$key} = $val
		return
	}
	// never seen value, just set it
	unless (defined $ref->{$key}) {
		$ref->{$key} = $val
		return
	}

	// keep youngest (smaller value)
	if ($key_type == 2) {
		return if $val eq ''; # no new value

		my($current_value) = $ref->{$key}

		// handle we don't have enough detail
                if (length($current_value) eq 8 or length($val) == 8) {
			return if (substr($current_value,0,8) eq substr($val,0,8))
		}

		if ($current_value eq '' || $val lt $current_value) {
			$ref->{$key} = $val
		}
		return
	}

	// keep oldest (bigger value)
	if ($key_type == 3) {
		return if $val eq ''; # no new value

		my($current_value) = $ref->{$key}

		if ($current_value eq '' || $val gt $current_value) {
			$ref->{$key} = $val
		}
		return
	}

	// keep value last seen value
	$ref->{$key} = $val
}
*/

func gtd_insert(t *Task)  {
	gtd_fix_maps(t)
	gset_insert(t, "itemstatus")
	gset_insert(t, "items")
	gset_insert(t, "todo")

	gset_insert_parents(t, false)
}

func gset_insert_parents(t *Task, del bool) {
	if ! t.dirty["parents"] {
		return
	}
	
	tid := t.Tid
	
	table := G_table("lookup")

	if (del) {
		G_sql("delete from "+table+" where itemId=?", tid)
	}
	for _, p := range t.Parents {
		pid := p.Tid

		G_sql("insert into "+table+"(parentId,itemId)values(?,?)", pid, tid)
	}
}

func gset_insert(ref *Task, table string) {
	table = G_table(table)

	panic("... code gset_insert")
/*?
	my $qmark = ''
	my $sql
	my @keys = ()
	my @vals = ()

	my ($key, $fld, $val)

	my $map = G_list($table)
	for my $key (keys %$map) {
		$fld = $map->{$key}

		next unless defined $ref->{$key}
		next unless $ref->{$key}

		push(@keys, $fld)
		push(@vals, $ref->{$key})

		$qmark .= ",?"
	}

	$qmark =~ s/^,//
	$sql = "insert into $table(" . join(',', @keys) . ") values($qmark)"

	G_sql($sql, @vals)
?*/
}

func gtd_update(t *Task) {
	gtd_fix_maps(t)

	panic("... Code gtd_update")

//?	gset_update(t, "itemstatus")
//?	gset_update(t, "items")

//?	gset_update(t, "todo")

//?	gset_insert_parents(t, true)
}

func gtd_fix_maps(ref *Task) {

	today := time.Now()
	if ref.Created.IsZero() {
		ref.Created = today
	}
	ref.Modified = today

	panic("... Code gtd_fix_maps")
//***BUG***	ref.fix_map("category",  '_gtd_category',  $Category)
//***BUG***	ref.fix_map("context",   '_gtd_context',   $Context)
//***BUG***	ref.fix_map("timeframe", '_gtd_timeframe', $Timeframe)

//	_fix_map($ref, "tags", 'timeframeId', \%Timeframes)
}

/*?
sub _fix_map {
	my($ref, $type, $index, $master) = @_

	return unless $ref->is_dirty($type)

	my($val_id) = 0
	my($val) = $ref->{$type}
	if (!defined $val) {
			//# timeframe never set
			return
	}

	if ($val ne '') {
		$val_id = $master->get($val)
		if (!defined $val_id) {
			warn "unmapped $type: $val"
			//##BUG### we need to create it?
			return
		}
	}

	if (defined $ref->{$index}) {
		return if $ref->{$index} == $val_id
	}
	$ref->{$index} = $val_id

	$ref->set_dirty($index)
}
?*/

func gset_update(ref *Task, table string) {
	panic("... code gset_update");
/*?
	my $qmark = ''
	my $sql
	my @keys = ()
	my @vals = ()

	my ($fld, $val)

	my $map = G_list($table)
	for my $key (keys %$map) {
		next unless $ref->get_dirty($key);	// don't update clean fields

		if db_debug {
			warn "Mapping: $key => $map->{$key}\n"
		}
		$fld = $map->{$key}

		next unless defined $ref->{$key}
//		next unless $ref->{$key}

		push(@keys, $fld)
		push(@vals, $ref->{$key})

		$qmark .= ",?"
	}

	return unless @keys;	// nothing changed


	$qmark =~ s/^,//
	$sql = "update $table set " . join("=?, ", @keys) .
	                          "=? where itemId=?"
	push(@vals, $ref->{todo_id})

	G_sql($sql, @vals)
?*/
}

func gtd_delete(tid int) {
	panic("... code sac_delete")

//?	gset_delete(tid, "itemId", "itemstatus")
//?	gset_delete(tid, "itemId", "items")
//?	gset_delete(tid, "itemId", "lookup")
//?	gset_delete(tid, "todo_id", "todo")
}


func gset_delete(tid int, table string) {
	table = G_table(table)

	sql := fmt.Sprintf("delete from %s where itemId = ?", table)
	G_sql(sql, tid)
}

func join([]string) {
}

//#############################################################################
//#############################################################################
//################## Database #################################################
//#############################################################################
//#############################################################################

var db_GTD	*sql.DB


/*
my($GTD_map, $GTD_default)
var GTD_map = map[string]map[string]string
var Prefix := "gtd_"

our $Resource;	// used by Hier::Resource

*/
func DB_init(confname string) {
	db_debug = option.Bool("Debug", false)

	MetaFix = option.Bool("MetaFix", false)

	if confname != "" {
		if db_debug {
			log.Printf("#-Using %s in Access.yaml\n", confname)
		}
	} else {
//		confname = "gtd"
		confname = "gtdtest"
	}


	home := os.Getenv("HOME")
	conf := load_config(home+"/.todo/Access.json")

	if db_debug {
		dump_config("Access", conf)
	}

//?	resource := load_config(home+"/.todo/Resource.json")
//?	$Hier::Resource::Resource = $conf->{resource}

	dbconf, ok := conf[confname]
	if !ok {
		panic("Can't fine section "+confname+" in ~/.todo/Access.json")
	}

	dbname := dbconf["dbname"]
	host   := dbconf["host"]
	user   := dbconf["user"]
	pass   := dbconf["pass"]
	port   := dbconf["port"]
	if port == "" {
		port = "3306"
	}

	if confname != "gtd" {
		log.Printf("confname=%s;dbname=%s;host=%s;port=%s\n", 
			confname, dbname, host, port)

	}

	if prefix, ok := dbconf["prefix"]; ok {
		Prefix = prefix
	} else {
		Prefix = "gtd_"
	}
		
        url := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s?%s",
                user, pass, host, dbname,
                "allowOldPasswords=1")

	db, err := sql.Open("mysql", url)
	if err != nil {
		log.Fatal(err)
        }

	err = db.Ping()
        if err != nil {
                log.Fatal("Can't connect to %s: %s", url, err)
        }
	db_GTD = db

	fmt.Printf("... code DB_init lastModified\n")
//?	option("Changed", G_val('itemstatus', 'max(lastModified)'))

//?warn "Start ".localtime()."\n"
	db_load_gtd()
//warn "Done  ".localtime()."\n"
}

func G_table(table string) string {
	db_Table = table

	return Prefix+table
}

func G_sql(sql string, args ...interface{}) {
	panic("... code G_sql")
/*?
	my($sql) = shift @_

	warn "gtd-sql: $sql: @_\n" if $Debug

	unless ($MetaFix) {
		warn "Skipped: $sql\n"
		return
	}

	my($rv)
	eval {
		$rv = $db_GTD->do($sql, undef, @_)
		warn "-> $rv\n" if $Debug
	}; if ($@ or !defined $rv) {
		print "Failed sql: $sql ($rv)\n"
		print "..........: $@"
	}
	
	return $rv
?*/
}

func G_select(table string, fields string) * sql.Rows {
	q := "select "+fields+" from "+G_table(table)

	rows, err := db_GTD.Query(q)
        if err != nil {
		log.Printf("%s: %s", table, q)
		panic(err);
        }
	return rows
}

/*?
sub G_list {
	my($table) = @_

	return $GTD_map->{$table}
}

sub G_renumber {
	my($ref, $tid, $new) = @_

        my(@list) = qw(items itemstatus tagmap)
        warn "Setting TID $tid => $new\n"

        G_sql("update gtd_lookup set itemId=$new where itemId=$tid")
        G_sql("update gtd_lookup set parentId=$new where parentId=$tid")
        G_sql("update gtd_tagmap set itemId=$new where itemId=$tid")

	G_sql("update todo set todo_id = ? where todo_id = ?", $new, $tid)

        for my $table (@list) {
                G_sql("update gtd_$table set itemId=$new where itemId=$tid")
        }
}
?*/

func G_val(table, query string) int {

	table = G_table(table)
	sql := fmt.Sprintf("select %s from %s", query, table)
	return len(sql)
/*?

	my($sth) = $db_GTD->prepare($sql)
	my($rv) = $sth->execute()
	if ($rv < 0) {
		panic("sql=$sql")
	}

	my($row, $changed)
	while (($row) = $sth->fetchrow_array()) {
		$changed = $row
	}
	return $changed
?*/
	return 0
}

func G_done(rows *sql.Rows) {
	rows.Close()

	err := rows.Err()
	if err != nil {
		log.Fatal("I/O error %s on table %s", err, db_Table)
	}
}

//#############################################################################
// Load up config file
//#############################################################################
type Dict map[string]map[string]string

func load_config(file string) Dict {
        fd, err := os.Open(file)
        if err != nil {
                log.Printf("Can't open %s: %s", fd, err)
                return nil
        }

        decoder := json.NewDecoder(fd)

        configuration := Dict{}
        err = decoder.Decode(&configuration)
        if err != nil {
                fmt.Println("error:", err)
        }

//      os.Close(fd)
        return configuration

}

func dump_config(file string, configuration Dict) {
        fmt.Printf("==== %s ==== \n", file)
        for group, group_map := range configuration {
                fmt.Printf("%s:\n", group)

                for key, val := range group_map {
                        fmt.Printf("\t%s:%s\n", key, val)
                }
        }
}

//#############################################################################
// Load up config file
//#############################################################################
/*
type NullTime struct {
    time.Time
    Valid bool // Valid is true if Time is not NULL
}

// Scan implements the Scanner interface.
func (nt *NullTime) Scan(value interface{}) error {
    nt.Time, nt.Valid = value.(time.Time)
    return nil
}

// Value implements the driver Valuer interface.
func (nt NullTime) Value() (sql.driver.Value, error) {
    if !nt.Valid {
        return nil, nil
    }
    return nt.Time, nil
}
*/
