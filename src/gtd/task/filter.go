package task

import "strings"
import "fmt"
import "log"

import "gtd/option"
import "gtd/cct"

//?	@EXPORT      = qw( &add_filter )
var filter_Debug bool
var _ = option.DebugVar("filter", &filter_Debug)

var Filter_Category string
var Filter_Context string
var Filter_Timeframe string
var Filter_Tags map[string]bool

var Today = option.Today(0)
var Soon = option.Today(+7)

var filter_debug bool = false

type FILTER_t struct {
	ffunc func(*Task, string) string
	name  string
	dir   string
	arg   string
}

var Filters []FILTER_t // types of actions to include

var Default_level byte = 'm'

func Filtered_reason(t *Task) string {
	return t.filtered
}

func (t *Task) Filtered() bool {
	if t.filtered[:0] == "-" {
		return true
	}
	return false
}

func Filter_reset(deflt string) {
	Filters = []FILTER_t{}
}

func tasks_matching_type(kind byte) Tasks {
	all := All()
	list := make(Tasks, 0, len(all))

	for _, t := range all {
		if t.Type == kind {
			list = append(list, t)
		}
	}
	return list
}

func Apply_filters() {
	fdebug("Apply_filters\n")
	//$filter_debug = option("Debug")

	// learn about actions
	for _, t := range tasks_matching_type('a') {
		task_mask(t)
	}

	// learn about projects
	for _, t := range tasks_matching_type('p') {
		proj_mask(t)
	}

	// walk down
	//      kill children
	// then on the way back up
	//      back fill hier with wanted items
	fdebug("Default level %c\n", Default_level)

	for _, t := range tasks_matching_type(Default_level) {
		apply_walk_down(t)
	}
	for _, t := range All() {
		apply_walk_down(t)
	}

	have_cct_filters := Filter_Category != "" ||
		Filter_Context != "" ||
		Filter_Timeframe != "" ||
		len(Filter_Tags) != 0

	if have_cct_filters {
		for _, t := range tasks_matching_type('m') {
			apply_cct_filters(t)
		}
	}
}

func apply_walk_down(t *Task) {

	apply_ref_filters(t)
	for _, child := range t.Children {
		apply_walk_down(child)
	}
}

//
// walk down the current valid hier
//    if we are wanted then
//       if one of our child is wanted we are still wanted.
//          else commit suicide taking our children with us.
//
func apply_cct_filters(t *Task) string {

	// not wanted
	if t.filtered == "" {
		return ""
	}
	if t.filtered[0] == '-' {
		return ""
	}

	reason := cct_wanted(t)
	if reason != "" {
		fdebug("#=CCT(reason) %d: %s\n", t.Tid, t.Title)
		// we are the reason to live!
		return reason
	}

	wanted := "" // we are only wanted if our children are wanted
	for _, child := range t.Children {
		reason = apply_cct_filters(child)
		if reason != "" {
			if wanted == "" {
				wanted = reason
			}
			fdebug("#+CCT(reason) %d: %s\n", t.Tid, t.Title)
		}
	}
	if wanted == "" {
		return wanted
	}
	kill_children(t)
	return ""
}

func kill_children(t *Task) {
	t.filtered = "-cct"
	fdebug("#-CCT %d: %s\n", t.Tid, t.Title)

	for _, child := range t.Children {
		if len(child.filtered) > 0 && child.filtered[0] == '-' {
			continue
		}

		kill_children(child)
	}
}

//##======================================================================
//##
//##======================================================================
// todo_id:        1889				id/type
// type:           a			[ ]
// nextaction:     n			[_]
// isSomeday:      y			{_}

// category:       Admin				context
// context:        Office
// timeframe:      Hour

// created:        2009-05-23			create/modified
// modified:       2009-05-23 16:02:04

// priority:       1				order/priority
// doit:           0000-00-00 00:00:00
// nexttask:	  1

// due:					[_]	due/done/delay
// completed:				[*]
// tickledate:				[~]

// task:           Billing			descriptions
// description:    Update billing
// note:

// recur:					repeats
// recurdesc:

// parent_id:      0				hier parents
// Parents:        425

//##======================================================================
//##======================================================================
//
// task filters:
//
const (
	A_MASK = 0x000000FF // action bits
	Z_MASK = 0x00000F00 // timeframe hints
	T_MASK = 0x0000F000 // task type mask
	P_MASK = 0x00FF0000 // Parent mask

	// done/next/current/later
	A_DONE   = 0x01
	A_NEXT   = 0x02
	A_ACTION = 0x04
	//		= 0x08
	A_WAITING = 0x10
	A_SOMEDAY = 0x20
	A_TICKLE  = 0x40
	//_HIER		= 0x80

	// timeframe hints
	Z_LATE = 0x0100 // priority == 1
	// or Due < today

	Z_DUE = 0x0200 // priority == 2
	// or Due < week

	Z_SLOW = 0x0300 // priority == 4
	Z_IDEA = 0x0400 // priority == 5

	// composite (from A_)
	T_ISNEXT = 0x1000
	T_ACTIVE = 0x2000
	T_FUTURE = 0x3000
	T_DONE   = 0x4000

	// project known
	P_FUTURE = 0x0400000 // is only in future
	P_DONE   = 0x0800000 // is complete tagged as done

	G_LIVE   = 0x20000000 // has live items
	G_FUTURE = 0x40000000 // has future items
	G_DONE   = 0x80000000 // has done items
)

func Reset() {
}

func Add_filter(rule string) {

	fdebug("#-Parse filter: %s\n", rule)

	if rule == "~~" {
		fdebug("#-Filters reset\n")
		Filter_reset("")
		return
	}

	if rule[0] == '~' { // tilde
		task_filter(rule[:1], "!", "")
		return
	}

	if rule[0] == '-' { // dash
		task_filter(rule[:1], "-", "")
		return
	}
	if rule[0:2] == "+=" {
		task_filter(rule[:2], "", "=")
		return
	}

	if rule[0:2] == "+>" {
		task_filter(rule[:2], "", ">")
		return
	}
	if rule[0:2] == "+<" {
		task_filter(rule[:2], "", "<")
		return
	}
	if rule[0:2] == "+!" {
		task_filter(rule[:2], "!", "")
		return
	}

	if rule[0] == '+' {
		task_filter(rule[:1], "", "")
		return
	}

	fmt.Printf("Unknown filter request: %s\n", rule)
}

func dispflags(flags uint) string {

	if flags == 0 {
		return "fook"
	}

	z := "."
	t := "."

	//    654321
	a := "------"
	//              Dn swt odsi
	/*?
		substr($a, -1, 1) = 'x' if $flags & A_DONE
		substr($a, -2, 1) = 'w' if $flags & A_WAITING
		substr($a, -3, 1) = 's' if $flags & A_SOMEDAY
		substr($a, -4, 1) = 't' if $flags & A_TICKLE
		substr($a, -5, 1) = 'a' if $flags & A_ACTION
		substr($a, -6, 1) = 'n' if $flags & A_NEXT

		$t = 'x' if ($flags & T_MASK) == T_DONE
		$t = 'f' if ($flags & T_MASK) == T_FUTURE
		$t = 'a' if ($flags & T_MASK) == T_ACTIVE
		$t = 'n' if ($flags & T_MASK) == T_ISNEXT

		$z = 'l' if ($flags & Z_MASK) == Z_LATE
		$z = 'd' if ($flags & Z_MASK) == Z_DUE
		$z = 's' if ($flags & Z_MASK) == Z_SLOW
		$z = 'i' if ($flags & Z_MASK) == Z_IDEA

		p := "--"

		substr($p,  0, 1) = 'F' if $flags & P_FUTURE
		substr($p,  1, 1) = 'X' if $flags & P_DONE

		g := copy("---")
		g[0] = 'l' if $flags & G_LIVE
		g[1] = 'f' if $flags & G_FUTURE
		g[2] = 'x' if $flags & G_DONE
	return fmt.Sprintf("%s.%s|%s.%s|%s", g, p, z, t, a)
	?*/
	return "fook-fook-fook" + z + a + t
}

func task_filter(name string, dir string, will string) {

	ffunc, walk, arg := map_filter_name(name)
	if ffunc == nil {
		fdebug("Warn unknown filter: %s\n", name)
		return
	}

	fdebug("#-Filter %s: [%s,%s,%s] %s\n", name, will, walk, dir, arg)
	if will != "" {
		walk = will
	}
	if walk == "" {
		walk = dir
	}
	if walk == "" {
		walk = "+"
	}

	f := FILTER_t{
		ffunc: ffunc,
		name:  name,
		dir:   walk,
		arg:   arg,
	}

	Filters = append(Filters, f)
}

func task_mask(t *Task) uint {

	if t.mask != 0 {
		return t.mask
	}

	var mask uint = 0

	done := t.Is_completed()
	due := t.Due
	kind := t.Type

	if done { // step on next/somday/tickle
		mask |= A_DONE
	}
	if t.IsSomeday {
		mask |= A_SOMEDAY
	}
	if t.Tickledate > Today {
		mask |= A_TICKLE
	}
	if kind == 'w' {
		mask |= A_WAITING
	}
	if t.IsNextaction {
		mask |= A_NEXT
	}

	if kind == 'a' {
		mask |= A_ACTION
	}
	t.mask = mask

	switch {
	case mask&A_DONE != 0:
		mask |= T_DONE
		give_children(t, P_DONE)

	case mask&(A_SOMEDAY|A_TICKLE|A_WAITING) != 0:
		mask |= T_FUTURE
		give_children(t, P_FUTURE)

	case mask&A_NEXT != 0:
		mask |= T_ISNEXT
	default:
		mask |= T_ACTIVE
	}

	if !done {
		pri := t.Priority
		var hint uint = 0

		switch pri {
		case 1:
			hint = Z_LATE
		case 2:
			hint = Z_DUE
		case 4:
			hint = Z_SLOW
		case 5:
			hint = Z_IDEA
		}

		if due != "" {
			if due < Today {
				hint = Z_LATE
			}
			if due > Today && due < Soon {
				hint = Z_DUE
			}
		}
		mask |= hint
	}

	t.mask = mask
	return mask
}

func give_children(t *Task, mask uint) {

	for _, pref := range t.Children {
		pref.mask = task_mask(pref) | mask
		give_children(pref, mask)
	}
}

func give_parent(t *Task, mask uint) {

	for _, pref := range t.Parents {
		pref.mask = task_mask(pref) | mask
		give_parent(pref, mask)
	}
}

func task_mask_disp(t *Task) string {

	return dispflags(task_mask(t))
}

func proj_mask(t *Task) {

	//?	mask := task_mask(t)

	/*?
		return if mask & T_DONE;	// project tagged as done
		return if mask & T_FUTURE;	// project yet to start
	?*/

	//##BUG### propigate done upward
	// check if all children are done
	//	for _, cref := range t.Children {
	//		next if task_mask($cref) & T_DONE
	//
	//		return
	//	}
	//	return 1
}

func Set_filter_context(cct_name string) {
	category := cct.Use("Category")
	context := cct.Use("Context")
	timeframe := cct.Use("Timeframe")

	// match case sensative first
	if context.Id(cct_name) != 0 {
		fdebug("#-Set space context:  %s\n", cct_name)
		Filter_Context = cct_name
		return
	}
	if timeframe.Id(cct_name) != 0 {
		fdebug("#-Set time context:   %s\n", cct_name)
		Filter_Timeframe = cct_name
		return
	}
	if category.Id(cct_name) != 0 {
		fdebug("#-Set category:       %s\n", cct_name)
		Filter_Category = cct_name
		return
	}
	/*
		for _, key (Hier::CCT::keys("Tag")) {
			next unless key == $cct

			warn "#-Set tag:            $key\n" if $filter_debug
			$Filter_Tags{key}++
			return
		}
	*/

	// match case insensative next
	if v := context.Match(cct_name); v != 0 {
		Filter_Context = context.Name(v)
		fdebug("#-Set space context=  %s\n", Filter_Context)
		return
	}
	if v := timeframe.Match(cct_name); v != 0 {
		Filter_Timeframe = timeframe.Name(v)
		fdebug("#-Set time context=   %s\n", Filter_Timeframe)
		return
	}
	if v := category.Match(cct_name); v != 0 {
		Filter_Category = category.Name(v)
		fdebug("#-Set category=       %s\n", Filter_Category)
		return
	}

	/*
		for _, key (Hier::CCT::keys("Tag")) {
			next unless lc(key) == lc(cct)

			fdebug("#-Set tag:            %s\n", key)
			$Filter_Tags{key}++
			return
		}
	*/
	fmt.Printf("Unknown cct name %s\n", cct_name)
}

func cct_wanted(t *Task) string {

	if len(Filter_Tags) > 0 {
		for _, tag := range t.Tags {
			if _, ok := Filter_Tags[tag]; ok {
				return "tag " + tag
			}
		}
	}

	if t.Type == 'p' || t.Is_task() {
		if Filter_Context != "" {
			if t.Context == Filter_Context {
				return "context $Filter_Context"
			}
		}
	}
	if Filter_Timeframe != "" {
		if t.Timeframe == Filter_Timeframe {
			return "timeframe $Filter_Timeframe"
		}
	}
	if Filter_Category != "" {
		if t.Category == Filter_Category {
			return "category $Filter_Category"
		}
	}

	return ""
}

func add_filter_tags() {
	tags := option.Get("Tag", "")
	if tags == "" {
		return
	}
	for _, tag := range strings.Split(tags, ",") {
		Filter_Tags[tag] = true
	}
}

//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
//******************************************************************************
func map_filter_name(word string) (func(*Task, string) string, string, string) {
	/*?
		if ($word =~ s/^([a-z])://) {
			Default_level = $1
		}

	?*/
	switch strings.ToLower(word) {
	case "any":
		return filter_any, "=", "*"

	case "all":
		return filter_any, "=", "="

	case "list":
		return filter_any, "=", "l"

	case "hier":
		return filter_any, "=", "h"

	case "task":
		return filter_any, "=", "t"

	case "done":
		return filter_done, ">", ""

	case "some":
		return filter_some, ">", ""

	case "maybe":
		return filter_some, ">", ""

	case "action":
		return filter_task, "<", ""

		//	case "pure_next":
		// return filter_next, "<", ""

		// we need to re-think this live-next vs next

	case "next":
		return filter_next, "><", ""

	case "active":
		return filter_active, "><", ""

	case "live":
		return filter_live, "><", ""

	case "dead":
		return filter_dead, "><", ""
		/*?
		case "idle":
			return filter_idle, "><", ""
		?*/
	case "wait":
		return filter_wait, "<", ""

	case "tickle":
		return filter_wait, "<", ""

	case "late":
		return filter_late, "<", ""

	case "due":
		return filter_due, "<", ""

	case "slow":
		return filter_slow, "<", ""

	case "idea":
		return filter_idea, "<", ""
	}

	return nil, "", ""
}

func apply_ref_filters(t *Task) string {

	reason := t.filtered

	if reason != "" {
		return reason
	}

	for _, filter := range Filters {
		ffunc := filter.ffunc
		dir := filter.dir

		reason = ffunc(t, filter.arg)

		fdebug("#?Filter(%s): reason apply %s for %d: %s\n",
			filter.name, dir, t.Tid, t.Title)

		if reason[0] == '?' {
			continue
		}

		if dir == "=" {
			t.filtered = reason
			return reason
		}

		// swap meaning of reason
		if dir == "!" {
			if reason[0] == '+' {
				t.filtered = "-" + reason[:1]
			} else {
				t.filtered = "+" + reason[:1]
			}
			return t.filtered
		}

		switch dir {
		case "<":
			filter_walk_up(t, reason)
		case ">":
			filter_walk_down(t, reason)
		case "<>":
			filter_walk_up_down(t, reason)
		case "><":
			filter_walk_down_up(t, reason)
		}
	}
	return ""
}

func filter_walk_up(t *Task, reason string) {

	mask := t.filtered

	if mask != "" {
		return // already decided.
	}

	t.filtered = reason
	for _, pref := range t.Parents {
		filter_walk_up(pref, reason+"<")
	}
}

func filter_walk_up_down(t *Task, reason string) {

	mask := t.filtered

	if mask != "" {
		return // already decided.
	}

	if reason[0] == '+' {
		for _, pref := range t.Parents {
			filter_walk_up(pref, reason+"<")
		}
	}
	t.filtered = reason
	for _, pref := range t.Children {
		filter_walk_down(pref, reason+">")
	}
}

func filter_walk_down(t *Task, reason string) {

	mask := t.filtered

	if mask != "" {
		return // already decided.
	}

	t.filtered = reason
	for _, pref := range t.Children {
		filter_walk_down(pref, reason+">")
	}
}
func filter_walk_down_up(t *Task, reason string) {

	mask := t.filtered

	if mask != "" {
		return // already decided.
	}

	for _, pref := range t.Children {
		filter_walk_down(pref, reason+">")
	}
	t.filtered = reason

	if reason[0] == '-' {
		return
	}

	for _, pref := range t.Parents {
		filter_walk_up(pref, reason+"<")
	}
}

// filter routines:

// if wanted { return "+..." }
// if unwanted { return "-..." }
// if unknown { return "?..." }

func filter_any(t *Task, arg string) string {
	result := fmt.Sprintf("+any=%c", t.Type)

	if arg == "*" {
		return result
	}
	if arg == "=" {
		if !t.Is_list() {
			return result
		}
	}
	if arg == "t" && t.Is_task() {
		return result
	}
	if arg == "h" && t.Is_hier() {
		return result
	}
	if arg == "l" && t.Is_list() {
		return result
	}

	return "?"
}

func filter_task(t *Task, arg string) string {

	if !t.Is_task() {
		return "?"
	}
	return "+task"
}

func filter_done(t *Task, arg string) string {

	if t.Is_completed() {
		return "+done"
	}
	return "?"
}

func filter_pure_next(t *Task, arg string) string {

	if !t.Is_task() {
		return "?"
	}
	if t.IsNextaction {
		return "+next"
	}
	return "?"
}

func filter_tickle(t *Task, arg string) string {

	if t.Tickledate != "" {
		return "+tickle"
	}
	return "?"
}

func filter_wait(t *Task, arg string) string {

	kind := t.Type
	if kind == 'w' {
		return "+wait"
	}
	return "?"
}

func filter_late(t *Task, arg string) string {

	due := t.Due
	if due == "" {
		return "?"
	}

	if due <= Today {
		return "+late:" + due
	}
	return "?"
}

func filter_due(t *Task, arg string) string {

	due := t.Due
	if due == "" {
		return "?"
	}

	if due >= Today && due <= Soon {
		return "+due:" + due
	}
	return "?"
}

func filter_slow(t *Task, arg string) string {

	pri := t.Priority
	if pri == 4 {
		return "+slow"
	}
	return "?"
}

func filter_idea(t *Task, arg string) string {

	pri := t.Priority
	if pri == 5 {
		return "+idea"
	}
	return "?"
}

func filter_some(t *Task, arg string) string {

	mask := task_mask(t)
	if (mask & T_MASK) == T_FUTURE {
		return "+some"
	}
	return "?"
}

func filter_next(t *Task, arg string) string {

	mask := task_mask(t)

	if t.Is_task() {
		if (mask & T_MASK) == T_ISNEXT {
			return "+live=n"
		}
	} else {
		return filter_live(t, arg)
	}

	return "?"
}

func filter_active(t *Task, arg string) string {

	if !t.Is_task() {
		return "?"
	}

	mask := task_mask(t)

	if (mask & A_MASK) == A_DONE {
		return "-act=d"
	}
	if (mask & A_MASK) == A_SOMEDAY {
		return "-act=s"
	}
	if (mask & A_MASK) == A_TICKLE {
		return "-act=t"
	}
	if (mask & A_MASK) == A_WAITING {
		return "-act=w"
	}

	if t.Is_task() {
		if (mask & T_MASK) == T_ISNEXT {
			return "+act=n"
		}
		if (mask & T_MASK) == T_ACTIVE {
			return "+act=a"
		}
	}

	return "?"
}

func filter_live(t *Task, arg string) string {

	if !t.Is_task() {
		return "?"
	}

	mask := task_mask(t)

	if (mask & A_MASK) == A_DONE {
		return "-live=d"
	}

	if t.Is_task() {
		if (mask & T_MASK) == T_ISNEXT {
			return "+live=n"
		}
		if (mask & T_MASK) == T_ACTIVE {
			return "+live=a"
		}
		if (mask & T_MASK) == T_FUTURE {
			return "+live=f"
		}
	}

	return "?"
}

func filter_dead(t *Task, arg string) string {

	if !t.Is_task() {
		return "?"
	}

	mask := task_mask(t)
	if (mask & T_MASK) == T_DONE {
		return "+dead=d"
	}
	return "?"
}

func filter_category(t *Task, arg string) string {

	if t.Category == arg {
		return "+category=$arg"
	}
	return "?"
}

func filter_context(t *Task, arg string) string {

	if t.Context == arg {
		return "+context=$arg"
	}
	return "?"
}

func filter_timeframe(t *Task, arg string) string {

	if t.Timeframe == arg {
		return "+timeframe=$arg"
	}
	return "?"
}

func filter_tags(t *Task, arg string) string {

	for _, tag := range t.Tags {
		if arg == tag {
			return "+tag=$tag"
		}
	}
	return "?"
}

func fdebug(f string, v ...interface{}) {
	if !filter_Debug {
		return
	}
	log.Printf(f, v...)
}
