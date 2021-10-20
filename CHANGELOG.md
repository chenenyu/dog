## [1.4.0] - 2021/10/20

* Null safety.
* Upgrade to emoji 14.
* API opt.

## [1.3.2] - 2021/05/20

* Add constructor parameter `supportsAnsiColor` for `ConsoleEmitter`.

## [1.3.1] - 2020/11/26

* Upgrade `ansicolor` version to auto detect whether ANSI is supported.
* Remove `call` method.

## [1.3.0] - 2020/11/20

* Add script to download and parse unicode data.
* Use unicode codepoint to determine message line width.

## [1.2.0] - 2020/11/16

* Bug fix: handle `JsonUnsupportedObjectError` when convert message.

## [1.1.0] - 2020/11/16

* Colorful VERBOSE/DEBUG message in browser console.

## [1.0.0] - 2020/11/13

* Support web platform.

## [0.4.0] - 2020/11/12

* Support custom caller info getter in `formatter`. This is useful when you wrap `dog` in other log class.

## [0.3.0] - 2020/11/10

* Remove `final` modifier from the default `dog` instance.
* Support custom StackTrace level.
* Add `FileEmitter` to emit log to file.
* Add `SimpleFormatter` to format log without borders.

## [0.2.0] - 2020/11/06

* Handle runes in message.

## [0.1.0] - 2020/11/02

* Initial release.