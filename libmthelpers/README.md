# libmthelpers
Misc. helper routines for minetest mods

When experimenting with in-game code using the luacmd mod,
I noticed that there were fragments of code that kept popping up everywhere.
I therefore decided to write them in a persistent location instead...
and threw them in this mod.

This mod therefore contains a bunch of fairly small boilerplate functions for things I typed frequently.
Because of their size, I'm not really going to bother documenting them.
Their function is fairly obvious in most cases;
[use the source luke][1] for it cannot lie.
Access to the table of functions is performed via modns;
see the relevant mod in this mod's parent modpack repository.

## Why is init.lua empty!?
modns handles all loading of this mod.
See the lib/com/github/thetaepsilon/minetest directory;
The file "libmthelpers.lua" serves as the top-level package interface,
and the files within the libmthelpers/ directory and sub-directories are the sub-packages.
modns exports the mtrequire() function in global scope;
this library resolves to "com.github.thetaepsilon.minetest.libmthelpers",
and it's modules as "\*snip\*.libmthelpers.submodulename".
To access this library, it is sufficient to do something like

```
local libmthelpers = mtrequire(libpath)
```



[1]: https://blog.codinghorror.com/learn-to-read-the-source-luke/
