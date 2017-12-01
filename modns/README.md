# minetest-mod-modns
A sane mod namespacing mechanism for minetest

This mod lets other mod register components with names which otherwise would have lua-reserved characters.
Dots are the member lookup operator in lua, which may fail if the second-to-last namespace element does not exist as a table already;
this mod lets you register it at such a name regardless of "parent" tables.
This allows e.g. the use of Java-style package names or http:// URIs like Golang uses.

Features / why bother using this at all:

* For mods that have historically used a rather generic modname for the purposes of depends.txt,
or can't change their modname because items/nodes already exist in player's worlds,
one can ensure that the e.g. "compressed_blocks" mod you're accessing is the one from the exact origin you're expecting.

* Relieves you of checking if the object exists already,
for example if two mods try to register themselves with the same component path -
just call modns.register(), and if such a conflict is detected,
you'll get a lua error() telling you so, so you don't have to worry about boilerplate.

* Faster detection of a mod component not existing -
modns.get() will throw an error() if the component does not exist instead of returning nil,
so you'll immediately know what's happened if you made a typo in the component name or forgot to update depends.txt.
optdepends can be safely probed with modns.check().

API doc Coming Soon.
