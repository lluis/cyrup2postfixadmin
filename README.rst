Cyrup to Postfix Admin migration
================================

scripts to migrate cyrup database to postfixadmin

it expects:

* cyrup database to be called 'mail'

* postfixadmin database to be called 'postfix'

* a default domain configured on cyrup2postfixadmin.sql

SHA1 conversion (from text to base64 encoded binary)
----------------------------------------------------

* copy shaswitch script to somewhere in your path

* install lib_mysqludf_sys from UDF: https://github.com/mysqludf/lib_mysqludf_sys

TODO
----

* migrate cyrup_maillists (now should be done manually)
