Pry Doc changelog
=================

### v0.4.5 (March 21, 2013)

* **Important:** updated YARD gem dependency to loose `0.8` version. It is a
  known fact that YARD `v0.8.4` [does not work with Pry Doc][yard648].

* Removed a bunch of old and unused metafiles
* Added docs for Ruby 2.0 (based on patchlevel 0)
* Rescanned docs for Ruby 1.9 (based on patchlevel 392)
* Rescanned docs for Ruby 1.8 (based on patchlevel 370)
* Implicitly fixed `show-doc require_relative` to the new rescan of 1.9 docs

[yard648]: https://github.com/lsegal/yard/issues/648
