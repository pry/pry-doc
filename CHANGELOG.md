Pry Doc changelog
=================

### master

* Added Ruby 2.7 support ([#94](https://github.com/pry/pry-doc/pull/94))
* Improved Ruby 2.7 suport for certain methods
  ([#100](https://github.com/pry/pry-doc/pull/100))
* Fixed ``NoMethodError: undefined method `namespace_name'``
  ([#97](https://github.com/pry/pry-doc/pull/97))

### [v1.0.0][v1.0.0] (December 27, 2018)

* Added suport for Ruby 2.6 docs ([#90](https://github.com/pry/pry-doc/pull/90))

### [v0.13.5][v0.13.5] (November 8, 2018)

* Fixed deprecation warnings emitted by Pry v0.12.0
  ([#87](https://github.com/pry/pry-doc/pull/87))
* Fixed MRI 2.0 regression ([#88](https://github.com/pry/pry-doc/pull/88))

### [v0.12.0][v0.12.0] (January 21, 2018)

* Added suport for Ruby 2.5 docs ([#75](https://github.com/pry/pry-doc/pull/75))

### [v0.11.1][v0.11.1] (August 8, 2017)

* Specified minimum required Ruby version in the gemspec
  ([#70](https://github.com/pry/pry-doc/pull/70))

### [v0.11.0][v0.11.0] (August 8, 2017)

* **IMPORTANT:** Drop support for Ruby 1.9.3
  ([#68](https://github.com/pry/pry-doc/pull/68))
* Stopped raising exception when Pry Doc doesn't support current Ruby version
  (we print a warning instead) ([#65](https://github.com/pry/pry-doc/pull/65))

### [v0.10.0][v0.10.0] (December 31, 2016)

* Added support for Ruby 2.4 docs
  ([#46](https://github.com/pry/pry-doc/pull/46))

### [v0.9.0][v0.9.0] (June 30, 2016)

* **Important:** Added support for Ruby 2.3 docs
  ([#35](https://github.com/pry/pry-doc/pull/35))
* Warn when Pry Doc doesn't support current Ruby version
  ([#31](https://github.com/pry/pry-doc/pull/31))

### v0.8.0 (June 14, 2015)

* Reverted to 0.6.0 approach for packaging Ruby core docs.
* Generated docs for Ruby 2.2

### v0.7.0 (April 1, 2014)

* 0.7.0 tried a new approach to packaging Ruby core docs, which turned out to
  have issues with cross-version compatibility. It's since been yanked.

### v0.6.0 (March 8, 2014)

* **Important:** dropped Ruby 1.8.7 support.
* Fixed (sort of [#19](https://github.com/pry/pry-doc/pull/19)) "Scanning and caching *.c files..." for show-doc Kernel.is_a?
* Rescanned docs for Ruby 2.0 (based on patchlevel 484)
* Rescanned docs for Ruby 2.1
* Removed the gem certificate

### v0.5.1 (December 26, 2013)

* **Important:** previous version `v0.5.0` does _not_ support Ruby 2.1.0. This
  version does!
* Pry Doc has a logo now (embedded in the README)

### v0.5.0 (December 25, 2013)

* **Important:** added support for Ruby 2.1.0. The docs are super fresh!

* Rescanned docs for Ruby 1.9.3 (based on patchlevel 484)
* Rescanned docs for Ruby 2.0.0 (based on patchlevel 353)

### v0.4.6 (May 19, 2013)

* Added new docs for Ruby 1.9 and Ruby 2.0. For example, now you can execute
  `show-doc BigDecimal` and feel a little bit more happy.
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
[v0.9.0]: https://github.com/pry/pry-doc/releases/tag/v0.9.0
[v0.10.0]: https://github.com/pry/pry-doc/releases/tag/v0.10.0
[v0.11.0]: https://github.com/pry/pry-doc/releases/tag/v0.11.0
[v0.11.1]: https://github.com/pry/pry-doc/releases/tag/v0.11.1
[v0.12.0]: https://github.com/pry/pry-doc/releases/tag/v0.12.0
[v0.13.5]: https://github.com/pry/pry-doc/releases/tag/v0.13.5
[v1.0.0]: https://github.com/pry/pry-doc/releases/tag/v1.0.0
[v1.1.0]: https://github.com/pry/pry-doc/releases/tag/v1.1.0
