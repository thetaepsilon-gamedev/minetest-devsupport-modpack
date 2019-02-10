-- except where noted, all of the below are portable and can be loaded outside MT.
local components = {
	"varargs",
	"prettyprint",
	"iterators",
	"tableutils",
	"coords",
	"check",
	"facedir",
	"stats",
	"readonly",
	"typechecking",
	"datastructs",
	"continuations",
	"profiling",
	"errors",
	"testing",
	"strutil",
	"ioformats",
	"io",
}



return modns.mk_parent_ns(components)
