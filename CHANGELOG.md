Pry Doc changelog
=================

### v0.4.6 (May 19, 2013)

* Added new docs for Ruby 1.9 and Ruby 2.0. For example, now you can execute
  `pry-doc BigDecimal` and feel a little bit more happy.
* Fixed error message when trying to `show-doc` non-module singleton methods (like
  top-level methods `include`, `private`, `public`, etc.)

### v0.4.5 (March 21, 2013)

* **Important:** updated YARD gem dependency to loose `0.8` version. It is a
  known fact that YARD `v0.8.4` [does not work with Pry Doc][yard648].

* Removed a bunch of old and unused metafiles
* Added docs for Ruby 2.0 (based on patchlevel 0)
* Rescanned docs for Ruby 1.9 (based on patchlevel 392)
* Rescanned docs for Ruby 1.8 (based on patchlevel 370)
* Implicitly fixed `show-doc require_relative` to the new rescan of 1.9 docs
* Signed the gem with a cryptographic signature

[yard648]: https://github.com/lsegal/yard/issues/648
