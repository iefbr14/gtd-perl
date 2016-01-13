package task

import "regexp"

var re_is_word = regexp.MustCompile("^[a-zA-Z]+$")
var re_is_task = regexp.MustCompile("^[0-9]+$")
var re_is_comma = regexp.MustCompile("^[0-9]+,")

func IsWord(word string) bool {
	return re_is_word.MatchString(word)
}

func IsTask(word string) bool {
	return re_is_task.MatchString(word)
}

func Is_comma_list(word string) bool {
	return re_is_task.MatchString(word)
}

