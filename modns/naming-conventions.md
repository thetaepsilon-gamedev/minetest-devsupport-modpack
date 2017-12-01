# Allowed path types

* Java style: com.foo.bar..., where "." delimits sub-packages of the package before it.
* URI style: scheme:... or scheme://.../sub/components/...

For the Java-style paths, apart from the "." separator only alphanumerics (0-9, a-z and A-Z)
and underscore "_" are allowed.
"$" is not allowed as Java only uses that for nested classes, which doesn't apply here.

For URI-style paths, "//" after scheme: indicates that the URI is hierachical and the code will treat it as such.
Otherwise, everything after the scheme: is expected to be one whole path component,
and any other "/" characters are forbidden.

# Conventions for full paths

Regardless of the path scheme used,
some common sense should be used when picking a "unique enough" path.
It should be frowned upon to try to imply that a mod came from a location that the author is not related to.

In general, the path should not be overly vague and should where possible refer to who wrote it.
Java-style paths such as "com.somename.foo. ..."
(if using the convention of referring to a website "somename.com")
have the issue that replacements for "somename" may clash.
If usernames or domain names are overly similar, append numerical prefixes.

URI paths, such as golang-style "https://github.com/someuser/modrepository",
should in general NOT register sub-namespaces but have everything accessed via tables within the top-level component.
This is because the resulting names in error messages may not produce actually valid URLs
(e.g. files within a github repository generally have to be accessed via github.com/user/repo/blob/master/... or similar).
Also note that trailing slashes will be treated as null path tokens and will trigger an error.



# Conventions for path components

Internally, paths for packages and sub-packages are split up into tokens called "path components".
e.g. com.foo.bar for java-style names is split up at "." characters.
A package "com.foo.bar.baz" would be considered a sub-package of the above,
as it shares a common prefix.
In this sense they are much like hierachial filesystem paths.

Where possible, within path components use only the characters 0-9, a-z,
hyphen "-", and underscore "_".
(Note that Java-style paths use the dot as the component *separator*,
and that stronger restrictions from the path type on allowed characters still apply.)
Capitalisation is generally discouraged;
the Java-style path doesn't allow them at all,
and things like upper-case CONSTANTS (depending on coding convention)
should generally not be exposed directly as a component but under a sub-namespace.

Other characters allowed by the path type
(including capital letters and the plus symbol "+" used for escaping)
*may* be used, but the corresponding file name will be escaped using hyphens
(see the function encode\_safe\_filename() in strutil.lua).
In particular, for internationality's sake non-ASCII characters are strongly discouraged,
unless e.g. an unaccented form of a word is confusingly different.
Unicode characters that are visually very similar or identical to an ASCII equivalent are also strongly discouraged.

The reason for this is that the characters [0-9a-z_-+] (where "+" is used as the escape character)
represents a safe set that is pretty much guaranteed to work on all relevant operating systems.
This includes taking into account case-insensitive systems such as is typical with MS Windows;
"com" and "Com" will be respectively unchanged and converted to "+43om"
(where 0x43 is the hex ASCII code for "C") which those operating systems will never alias.

On that note, it should be noted that this mod *itself* does not assume any kind of encoding,
beyond the assumption that the values 0-127 are mapped to ASCII.
Non-ASCII codepage bytes are all encoded,
however by convention all mods should assume UTF-8 for the purposes of the string escape mechanism
(bearing in mind the above discouragement of non-ASCII characters for that reason.
Seeing as Minetest also internally handles strings in UTF-8,
please please *please* write your source files in UTF-8.
