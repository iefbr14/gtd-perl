package cct

import "log"

var cct_debug bool = false

type CCT struct {
	name map[int]string
	desc map[int]string
	id   map[string]int
}

var (

	// mapping  Category Id   => Category Name
	Categories CCT

	// mapping  Context Id    => Context Name
	Contexts CCT

	// mapping  Timreframe Id => Timreframe Name
	Timeframes CCT

	// mapping  Tag Id        => Tag Name
	Tags CCT
)

var maps = map[string]CCT{
	"Category":  Categories,
	"Context":   Contexts,
	"Timeframe": Timeframes,
	"Tags":      Tags,
}

func table(mapname string) *CCT {
	if cct, ok:= maps[mapname]; ok {
		return &cct
	}

	panic("Unknown CCT table type: "+mapname);
}


func Use(mapname string) *CCT {
	if cct_debug {
		log.Printf("cct.Use(%s): %v", mapname, table(mapname));
	}
	cct := table(mapname);

	if cct.name == nil {
		cct.name = make(map[int]string);
		cct.desc = make(map[int]string);
		cct.id = make(map[string]int);
	}
	return cct;
}

func (cct *CCT) Define(id int, name,desc string) {
	//***BUG*** we should check to see if already defined!
	cct.name[id] = name
	cct.desc[id] = desc
	cct.id[name] = id
}

/*?
func (cct *CCT) Set(key int, val string) {
	unless ($val) {
		$val = 1;
		foreach my $table_value (values(%$ref)) {
			$val = $table_value + 1 if $table_value <= $val;
		}
	}

	if (!defined $key) {
		warn "###BUG### Can't insert $key => $val\n";
		$ref->{$key} = $val;
	} else {
		warn "###BUG### Can't update $key => $val\n";
		$ref->{$key} = $val;
	}
}

func (cct *CCT) Get(int) {
	my($hash, $val) = @_;

	return unless defined $val;
	return unless defined $hash->{$val};
	return $hash->{$val};
}

func keys(mapname string) []string {
	cct := table(mapname);
	if (ref $type) {
		return keys %$type;
	}
	my($ref) = _table($type);
	return keys %$ref;
}

func Name(val int) {
	my($ref, $val) = @_;

	//##BUG### $CCT->name is horibly expensive
	my(%rev) = reverse(%$ref);

	return $rev{$val};
}

func (cct *CCT)Rename(key, newname string) {
	panic("###BUG### Can't rename $key => $newname");
}
*/
