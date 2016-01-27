package task

//	@EXPORT      = qw(&DB_init &set &gtd_insert &gtd_update)

//==============================================================================
// Low level database abstraction
//==============================================================================

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	//? use YAML::Syck qw(LoadFile)
	//	"gopkg.in/yaml.v2"
	"encoding/json"

	"gtd/cct"
	"gtd/option"

	"database/sql"
	_ "github.com/go-sql-driver/mysql"
)

var db_debug bool = false
var MetaFix bool = false

var Prefix string = "gtd_"

var db_Table string = ""

var Last_Modified string = ""

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
		id   int
		name sql.NullString
		desc sql.NullString
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
		id   int
		name sql.NullString
		desc sql.NullString
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
		id   int
		name sql.NullString
		desc sql.NullString
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
		todo_id int
		title   string
		desc    sql.NullString
		note    sql.NullString
		rdesc   sql.NullString
		recur   sql.NullString
	)

	rows := G_select("items", "itemId,title,description,desiredOutcome,recurdesc,recur")
	for rows.Next() {
		rows.Scan(&todo_id, &title, &desc, &note, &rdesc, &recur)
		t := New(todo_id)

		t.Title = title
		t.Description = desc.String
		t.Note = note.String
		t.Rdesc = rdesc.String
		t.Recur = recur.String
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
	rows := G_select("itemstatus", "itemId,dateCreated,lastModified,dateCompleted,type,categoryId,isSomeday,contextId,timeframeId,deadline,tickledate,nextaction")
	//rows := G_select("itemstatus", "itemId,type,lastModified,dateCompleted,nextaction")

	category := cct.Use("Category")
	context := cct.Use("Context")
	timeframe := cct.Use("Timeframe")

	var (
		todo_id int

		dateCreated  sql.NullString // time.Time
		lastModified sql.NullString // time.Time

		dateCompleted sql.NullString // time.Time
		tasktype      sql.NullString // enum: m,v,o,g,p,a,r,w,i,L,C,T

		categoryId  int
		isSomeday   sql.NullString // enum: y,n
		contextId   int
		timeframeId int
		deadline    sql.NullString // time.Time
		tickledate  sql.NullString // time.Time
		nextaction  sql.NullString // enum: y,n
	)

	for rows.Next() {
		err := rows.Scan(&todo_id,

			&dateCreated,
			&lastModified,

			&dateCompleted,
			&tasktype,

			&categoryId,
			&isSomeday,
			&contextId,
			&timeframeId,
			&deadline,
			&tickledate,
			&nextaction)
		if err != nil {
			panic(err)
		}
		t := Find(todo_id)
		if t == nil {
			continue
		}

		//		t.Kind = T_kind(tasktype.String[0])
		t.Type = tasktype.String[0]
		t.IsNextaction = nextaction.String == "y"
		t.IsSomeday = isSomeday.String == "y"

		t.Created = dateCreated.String
		t.Modified = lastModified.String

		t.Due = deadline.String
		t.Tickledate = tickledate.String
		t.Completed = dateCompleted.String

		t.Category = category.Name(categoryId)
		t.Context = context.Name(contextId)
		t.Timeframe = timeframe.Name(timeframeId)

		if lastModified.String > Last_Modified {
			Last_Modified = lastModified.String
		}
	}

	G_done(rows)
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
		pid int
		tid int
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

		t := Find(tid)
		if t == nil {
			log.Printf("Invalid tid in tid/pid (%d, %d)", tid, pid)
			continue
		}

		p.Children = append(p.Children, t)
		t.Parents = append(t.Parents, p)
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

	var (
		id  int
		tag string
	)

	tag_id := 0
	for rows.Next() {
		rows.Scan(&id, &tag)

		t := Find(id)
		if t == nil {
			continue
		}

		t.Tags = append(t.Tags, tag)

		tag_id++
		tags.Define(tag_id, tag, "")
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
		todo_id  int
		priority int
		state    string
		doit     sql.NullString //time.Time
		effort   int
		resource sql.NullString
		depends  sql.NullString
		percent  int
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
		t.State = state[0]
		t.Doit = doit.String
		t.Effort = effort
		t.Resource = resource.String
		t.Depends = depends.String
		t.Percent = percent
	}
	G_done(rows)

}

func gtd_insert(t *Task) {
	gtd_fix_maps(t)
	gset_insert(t, "itemstatus")
	gset_insert(t, "items")
	gset_insert(t, "todo")

	gset_insert_parents(t, false)
}

func gset_insert_parents(t *Task, del bool) {
	if !t.dirty["parents"] {
		return
	}

	tid := t.Tid

	table := G_table("lookup")

	if del {
		G_sql("delete from "+table+" where itemId=?", tid)
	}
	for _, p := range t.Parents {
		pid := p.Tid

		G_sql("insert into "+table+"(parentId,itemId)values(?,?)", pid, tid)
	}
}

func gset_insert(t *Task, table string) {
	key_map := G_list(table) // no prefix table name
	table = G_table(table)

	qmark := ""
	sql := ""

	var keys []string
	var vals []string

	for _, key := range key_map {
		fld := key_map[key]

		// next unless defined $t->{$key}
		// next unless $t->{$key}

		keys = append(keys, fld)
		vals = append(vals, t.Get_KEY(key))

		qmark += ",?"
	}

	qmark = qmark[1:] // s=^,==

	sql = "insert into " + table + "(" + strings.Join(keys, ",") +
		") values(" + qmark + ")"

	G_sql(sql, vals)
}

func gtd_update(t *Task) {
	log.Printf("Update: %v\n", t)
	gtd_fix_maps(t)

	gset_update(t, "itemstatus")
	gset_update(t, "items")

	gset_update(t, "todo")

	gset_insert_parents(t, true)
}

func gtd_fix_maps(t *Task) {
	today := time.Now()
	if t.Created == "" {
		t.Created = today.Format("2006-02-03")
		t.dirty["created"] = true
	}
	t.Modified = today.Format("2006-02-03 15:04:05")
	t.dirty["modified"] = true

	fix_map(t, t.Category, "Category")
	fix_map(t, t.Context, "Context")
	fix_map(t, t.Timeframe, "Timeframe")

	//	_fix_map($t, "tags", 'timeframeId', \%Timeframes)
}

func fix_map(t *Task, val string, cct_name string) {

	if !t.dirty[cct_name] {
		return
	}

	val_id := 0

	if val != "" {
		c := cct.Use(cct_name)
		val_id = c.Id(val)

		if val_id == 0 {
			log.Printf("unmapped %s: %s\n", cct_name, val)
			//##BUG### we need to create it?
			return
		}
	}
	/*
		if (defined $t->{$index}) {
			return if $t->{$index} == $val_id
		}
		$t->{$index} = $val_id

		$t->set_dirty($index)
	*/
}

func gset_update(t *Task, table string) {
	key_map := G_list(table) // no prefix table name
	table = G_table(table)

	qmark := ""
	sql := ""

	var keys []string
	var vals []string

	for _, key := range key_map {
		fld := key_map[key]
		if !t.dirty[key] {
			continue
		}

		if db_debug {
			log.Printf("Mapping: %s => %s\n", key, fld)
		}
		// next unless defined $t->{$key}
		// next unless $t->{$key}

		keys = append(keys, fld)
		vals = append(vals, t.Get_KEY(key))

		qmark += ",?"
	}

	if len(keys) == 0 {
		return // nothing changed
	}

	qmark = qmark[1:] // s=^,==

	sql = "update " + table + " set " + strings.Join(keys, "=?, ") +
		"=? where itemId=?"

	vals = append(vals, strconv.Itoa(t.Tid))

	G_sql(sql, vals)
}

func gtd_delete(tid int) {
	gset_delete(tid, "itemId", "itemstatus")
	gset_delete(tid, "itemId", "items")
	gset_delete(tid, "itemId", "lookup")
	gset_delete(tid, "todo_id", "todo")
}

func gset_delete(tid int, table string, column string) {
	table = G_table(table)

	sql := fmt.Sprintf("delete from %s where %s = ?", table, column)
	G_sql(sql, tid)
}

//#############################################################################
//#############################################################################
//################## Database #################################################
//#############################################################################
//#############################################################################

var db_GTD *sql.DB

/*
my($GTD_map, $GTD_default)
var GTD_map = map[string]map[string]string
var Prefix := "gtd_"

*/
func DB_init(confname string) {
	db_debug = option.Bool("Debug", false)

	MetaFix = option.Bool("MetaFix", true)

	if confname != "" {
		if db_debug {
			log.Printf("#-Using %s in Access.yaml\n", confname)
		}
	} else {
		//		confname = "gtd"
		confname = "gtdtest"
	}

	home := os.Getenv("HOME")
	conf := load_config(home + "/.todo/Access.json")
	Resources = load_config(home + "/.todo/Resource.json")

	if db_debug {
		dump_config("Access", conf)
	}

	dbconf, ok := conf[confname]
	if !ok {
		panic("Can't fine section " + confname + " in ~/.todo/Access.json")
	}

	dbname := dbconf["dbname"]
	host := dbconf["host"]
	user := dbconf["user"]
	pass := dbconf["pass"]
	port := dbconf["port"]
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
		log.Printf("!!! Can't connect to %s: %s\n", url, err)
		log.Fatal("!!! no database connect\n")
	}
	db_GTD = db

	//?warn "Start ".localtime()."\n"
	db_load_gtd()
	//warn "Done  ".localtime()."\n"
}

func G_table(table string) string {
	db_Table = table

	return Prefix + table
}

func G_sql(sql string, args ...interface{}) error {

	if !MetaFix {
		log.Printf("skipped G_sql: %s %v\n", sql, args)
		return nil
	}

	log.Printf("gtd-sql: %s\n\t\t%v\n", sql, args)

	//X count := len(args)
	result, err := db_GTD.Exec(sql, args...)

	if err == nil {
		log.Printf("gtd-sql got: %v\n", result)
	} else {
		log.Printf("gtd-sql failed: %v -- %v\n", result, err)
	}

	return err
}

func G_select(table string, fields string) *sql.Rows {
	q := "select " + fields + " from " + G_table(table)

	rows, err := db_GTD.Query(q)
	if err != nil {
		log.Printf("%s: %s", table, q)
		panic(err)
	}
	return rows
}

func G_list(table string) map[string]string {

	switch table {
	case "itemstatus":
		return map[string]string{
			"created":   "dateCreated",
			"modified":  "lastModified",
			"completed": "dateCompleted",
			"type":      "type",
			//"category": "categoryId",
			"issomeday": "isSomeday",
			//".": "contextId",
			//".": "timeframeId",
			"due":        "deadline",
			"tickle":     "tickledate",
			"nextaction": "nextaction",
		}
	case "items":
		return map[string]string{
			"title":       "title",
			"description": "description",
			"note":        "desiredOutcome",
			//"title":   "title",
		}
	case "todo":
		return map[string]string{
			"category": "category",
			"priority": "priority",
			"state":    "state",
			"doit":     "doit",
			"effort":   "effort",
			"resource": "resource",
			"depends":  "depends",
			"percent":  "percent",
		}
	}
	log.Printf("!!!! bad G_list(%s) map", table)
	panic("!!!!bad G_list")

	/*?
	return $GTD_map->{$table}
	rows, _ := db.Query("SELECT * FROM _user;")

	columns, _ := rows.Columns()
	count := len(columns)
	values := make([]interface{}, count)
	valuePtrs := make([]interface{}, count)

	for rows.Next() {

		for i, _ := range columns {
			valuePtrs[i] = &values[i]
		}

		rows.Scan(valuePtrs...)

		for i, col := range columns {

			var v interface{}

			val := values[i]

			b, ok := val.([]byte)

			if ok {
				v = string(b)
			} else {
				v = val
			}

			fmt.Println(col, v)
		}
	}
	?*/
}

func G_renumber(t *Task, tid, new int) {
	log.Printf("Setting TID %d => %d\n", tid, new)

	G_transaction()
	G_sql("update gtd_lookup set itemId=? where itemId=?", new, tid)
	G_sql("update gtd_lookup set parentId=? where parentId=?", new, tid)

	G_sql("update gtd_todo set todo_id = ? where todo_id = ?", new, tid)

	G_sql("update gtd_items set itemId=? where itemId=?", new, tid)
	G_sql("update gtd_itemstatus set itemId=? where itemId=?", new, tid)
	G_sql("update gtd_tagmap set itemId=? where itemId=?", new, tid)
	G_commit()
}

func G_transaction() {
	panic("G_transaction")
}

func G_commit() {
	panic("G_commit")
}

func G_val(table, query string) int {
	table = G_table(table)
	sql := fmt.Sprintf("select %s from %s", query, table)
	log.Printf("G_val sql: %s", sql)

	panic(".... Migrate max(itemId) and max(lastModified)")
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
}

func G_done(rows *sql.Rows) {
	rows.Close()

	err := rows.Err()
	if err != nil {
		log.Printf("I/O error %s on table %s", err, db_Table)
	}
}

//#############################################################################
// Load up config file
//#############################################################################
type Dict map[string]map[string]string

func load_config(file string) Dict {
	fd, err := os.Open(file)
	if err != nil {
		log.Printf("Can't open %s: %s", file, err)
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
