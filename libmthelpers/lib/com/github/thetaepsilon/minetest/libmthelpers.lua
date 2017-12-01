-- except where noted, all of the below are portable and can be loaded outside MT.
local components = {
	"varargs",
	"prettyprint",
	"iterators",
	"tableutils",
	"coords",
	"playerpos",	-- portable, though stoodnode expects the interface of an objectref.
	"check",
	"facedir",
	"stats",
	"readonly",
	"datastructs",
	"continuations",
	"profiling",
}



return modns.mk_parent_ns(components)
