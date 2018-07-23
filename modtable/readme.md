# modtable: lightweight namespacing mechanism for minetest mods

Some mods don't need the full heavyweight capabilities of modns.
For these mods, modtable can be used to register their API functions table.
Namespaced API paths can be used to avoid confusion among mods with the same short name
(in particular because dots can't appear in a mod folder name or MT will complain).
