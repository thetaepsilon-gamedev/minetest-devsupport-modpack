# minetest-mod-modns
A sane mod namespacing and loading mechanism for minetest

This mod allows mod writers to package code for other mods that can be loaded via mtrequire(),
an approximate equivalent to standalone lua's require() function.
Supported path types are Java-style package names (e.g. "com.foo.bar")
or http:// URIs like Golang uses (e.g. using "https://github.com/user/repo" directly as the identifier).

Features / why bother using this at all:

* For mods that have historically used a rather generic modname for the purposes of depends.txt,
or can't change their modname because items/nodes already exist in player's worlds,
one can ensure that the e.g. "compressed_blocks" mod you're accessing is the one from the exact origin you're expecting.

* Optional manual registration of components.
This also relieves you of checking if the object exists already,
for example if two mods try to register themselves with the same component path -
just call modns.register(), and if such a conflict is detected,
you'll get a lua error() telling you so, so you don't have to worry about boilerplate.
This exists as an alternative to the dynamic loading mechanism.

* Faster detection of a mod component not existing -
modns.get() will throw an error() if the component does not exist instead of returning nil,
so you'll immediately know what's happened if you made a typo in the component name,
or do not have the relevant mod installed.

* Load dependencies without having to pass them around inside your mod.
You can just mtrequire("com.example.somecomponent")
(modns.get is aliased to mtrequire internally)
in the same way you would use require() in a regular lua script.
Mods declare which component namespaces they export,
and components can even be loaded on-demand instead of when that mod loads.
Loaded components are kept (protectively!) cached between invocations for faster access of common code.

How-to guide on writing loadable components/mods Coming Soon.
