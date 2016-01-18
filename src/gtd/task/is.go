package task

import "regexp"

var re_is_word = regexp.MustCompile(`^[a-zA-Z]+$`)
var re_is_keyv = regexp.MustCompile(`^[a-zA-Z]+:\s`)
var re_is_task = regexp.MustCompile(`^[0-9]+:?$`)
var re_is_comma = regexp.MustCompile(`^[0-9]+,`)

// task.IsWord checks to see if looks like a word such as role or goal
func IsWord(word string) bool {
	return re_is_word.MatchString(word)
}

// task.IsKeyValue checks to see if looks like key: value pair
func IsKeyValue(word string) (string, string) {
	if re_is_keyv.MatchString(word) {
		panic(".... code IsKeyValue")
	}
	return "", ""
}

// task.IsTask check to see if it is a valid task
func IsTask(word string) bool {
	return re_is_task.MatchString(word)
}

// task.Is_comma_list check to see if looks like a , seperated task list
func Is_comma_list(word string) bool {
	return re_is_task.MatchString(word)
}
