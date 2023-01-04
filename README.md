![Pry Doc][logo]

[![pry-doc](https://github.com/pry/pry-doc/actions/workflows/test.yml/badge.svg)](https://github.com/pry/pry-doc/actions/workflows/test.yml)

* Repository: [https://github.com/pry/pry-doc][repo]
* Wiki: [https://github.com/pry/pry-doc/wiki][wiki]

Description
-----------

Pry Doc is a plugin for [Pry][pry]. It provides extended documentation support
for Pry.

Installation
------------

Install the gem using the below command.

    gem install pry-doc

To automatically load `pry-doc` upon starting `pry`, add the command `require 'pry-doc'` to your `pryrc`.
You can read more about it in Pry's [README file][pry-overview].

Synopsis
--------

Pry Doc extends two core Pry commands: `show-doc` and `show-source` (aliased as
`?` and `$` respectively).

For example, in vanilla Pry it’s impossible to get the documentation for the
`loop` method (it’s a method, by the way). However, Pry Doc solves that problem.

![show-source][show-doc]

Let's check the source code of the `loop` method.

![show-doc][show-source]

Generally speaking, you can retrieve most of the MRI documentation and
accompanying source code. Pry Doc is also smart enough to get any documentation
for methods and classes implemented in C.

Limitations
-----------

Pry Doc supports Ruby 2.0 and above.

Getting Help
------------

Simply file an issue or visit `#pry` at `irc.freenode.net`.

License
-------

The project uses the MIT License. See LICENSE file for more information.

[logo]: http://img-fotki.yandex.ru/get/6724/98991937.13/0_9faaa_26ec83af_orig "Pry Doc"
[pry]: https://github.com/pry/pry
[pry-overview]: https://github.com/pry/pry#overview
[show-source]: http://img-fotki.yandex.ru/get/9303/98991937.13/0_9faac_aa86e189_orig "show-source extended by Pry Doc"
[show-doc]: http://img-fotki.yandex.ru/get/9058/98991937.13/0_9faab_68d7a43a_orig "show-doc extended by Pry Doc"
[repo]: https://github.com/pry/pry-doc
[wiki]: https://github.com/pry/pry-doc/wiki
