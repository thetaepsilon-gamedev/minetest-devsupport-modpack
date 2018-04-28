## External testing utilities

These GNU/Linux shell scripts allow you to run unit tests on "pure" mod code
(that is, parts which don't rely on MT-specific things being present)
outside of the game.

(NB BSD users: needs GNU grep. Sorry.
Discussion/patches welcome if you need it to be so.)

To write a unit test, create a directory in your mod folder,
and create a lua script which performs the tests -
make it throw an assertion or otherwise exit with a failure status,
and the entire test procedure will halt.
These special directories are marked by the presence of the file
modns-portable-tests.txt which can contain anything,
just make sure it's there.
You can call mtrequire() within these scripts
to load the component you need to test.

run-all-mt-tests will then run each script one by one,
until either they all pass or some failure occurs.

NB: These scripts assume the external loader script
as provided in the directory above this one
has already been loaded.

