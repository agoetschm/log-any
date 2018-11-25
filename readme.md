[![Build Status](https://travis-ci.org/jsimonet/log-any.svg?branch=master)](https://travis-ci.org/jsimonet/log-any)
[![Build status](https://ci.appveyor.com/api/projects/status/rjhdnidc2hwnmd0p/branch/master?svg=true)](https://ci.appveyor.com/project/jsimonet/log-any/branch/master)
# NAME

Log::Any

# SYNOPSIS

```perl6
use Log::Any;
use Log::Any::Adapter::Stdout;
use Log::Any::Adapter::Stderr;


# Basic usage
Log::Any.add( Log::Any::Adapter::Stdout.new, formatter => '\d \m' );
Log::Any.info( 'yolo' );
# OUTPUT: 2017-06-06T11:43:43.067909Z yolo


# Advanced usage
Log::Any.add( Log::Any::Adapter::Stderr.new,
              formatter => '\d \m',
              filters( [severity => '>=error'] ) );
Log::Any.add( Log::Any::Adapter::Stdout.new, formatter => '\d \m' );

# Will be logged on stderr
Log::Any.error( :category('security'), 'oups' );
# Will be logged on stdout
Log::Any.log( :msg('msg from app'), :category( 'network' ), :severity( 'info' ) );
```

# DESCRIPTION

Log::Any is a library to generate and handle application logs.
A log is a message indicating an application status at a given time. It has attributes, like a _severity_ (error, warning, debug, …), a _category_, a _date_ and a _message_.

These attributes are used by the _Formatter_ to format the log and can also be used to filter logs and to choose where the log will be handled (via Adapters).

Like the Perl5 implementation (https://metacpan.org/pod/Log::Any), the idea is to split log generation and log management.

## SEVERITY

The severity is the level of urgence of a log.
It can take the following values (based on Syslog):
- trace
- debug
- info
- notice
- warning
- error
- critical
- alert
- emergency

## CATEGORY

The category can be seen as a group identifier.

Ex:
- security ;
- database ;
- ...

_Default value_ : the package name where the log is generated.

## DATE

The date is generated by Log::Any, and its values is the current date and time (ISO 8601).

## MESSAGE

A message is a string passed to Log::Any defined by the user. Newlines in message are escaped to prevent logging multi-line.

# ADAPTERS

An adapter handles a log by storing it, or sending it elsewhere.
If no adapters are defined, or no one meets the filtering, the message will not be logged.

A few examples:

- Log::Any::Adapter::File
- Log::Any::Adapter::Database::SQL
- Log::Any::Adapter::Stdout

## Provided adapters

### File

```perl6
use Log::Any::Adapter::File;
Log::Any.add( Log::Any::Adapter::File.new( path => '/path/to/file.log' ) );
```

Starting with 0.9.5 version,, it's now possible to choose the buffering size to use, with _out-buffer_. This option can takes the same values as described in the perl6 documentation (https://docs.perl6.org/routine/out-buffer).

### Stdout

```perl6
use Log::Any::Adapter::Stdout;
Log::Any.add( Log::Any::Adapter::Stdout.new );
```

### Stderr

```perl6
use Log::Any::Adapter::Stderr;
Log::Any.add( Log::Any::Adapter::Stderr.new );
```

# FORMATTERS

Often, logs need to be formatted to simplify the storage (time-series databases), or the analysis (grep, log parser).

Formatters will use the attributes of a Log.

|Symbol   |Signification|Description                                  |Default value             |
|---------|-------------|---------------------------------------------|--------------------------|
|\\d      |Date (UTC)   |The date on which the log was generated      |Current date time         |
|\\c      |Category     |Can be any anything specified by the user    |The current package/module|
|\\s      |Severity     |Indicates if it's an information, or an error| none                     |
|\\e{key} |Extra Field  |Additional fields, used for formatting       | none                     |
|\\m      |Message      |Payload, explains what is going on           | none                     |

_Note: Depending on the context or the configuration, some values can be empty._

_Note: Extra fields uses a key in {} caracters to print associated value._

```perl6
use Log::Any::Adapter::Stdout;
Log::Any.add( Some::Adapter.new, :formatter( '\d \c \m \e{key1} \e{key2}' ) );
```

You can of course use variables in the formatter, but since _\\_ is already used in Perl6 strings interpolation, you have to escape them.

```perl6
use Log::Any::Adapter::Stdout;
my $prefix = 'myapp ';
Log::Any.add( Log::Any::Adapter::Stdout.new, :formatter( "$prefix \\d \\c \\s \\m \\e\{key}" ) );
```

A formatter can be more complex than the default one by extending the class _Formatter_.

```perl6
use Log::Any::Formatter;

class MyOwnFormatter is Log::Any::Formatter {
	method format( :$date-time!, :$msg!, :$category!, :$severity!, :%extra-fields ) {
		# Returns an Str
	}
}
```

# FILTERS

Filters can be used to allow a log to be handled by an adapter, to select which adapter to use or to use a different formatting string.
Many fields can be filtered, like the _category_, the _severity_ or the _message_.

The easiest way to define a filter is by using the built-in _filter_ giving an array to _filter_ parameter:

```perl6
Log::Any.add( Some::Adapter.new, :filter( [ <filters fields goes here>] ) );
```

## Filtering on category or message

```perl6
# Matching by String
Log::Any.add( Some::Adapter.new, :filter( ['category' => 'My::Wonderfull::Lib' ] ) );
# Matching by Regex
Log::Any.add( Some::Adapter.new, :filter( ['category' => /My::*::Lib/ ] ) );

# Matching msg by Regex
Log::Any.add( Some::Adapter.new, :filter( [ 'msg' => /a regex/ ] );
```

## Filtering on severity

The severity can be considered as levels, so can be traited as numbers.

1. trace
2. debug
3. info
4. notice
5. warning
6. error
7. critical
8. alert
9. emergency

Filtering on severity can be done by specifying an operator in front of the severity:

```perl6
filter => [ 'severity' => '<notice'   ] # Less
filter => [ 'severity' => '<=notice'  ] # Less or equal
filter => [ 'severity' => '==debug'   ] # Equality
filter => [ 'severity' => '!=notice'  ] # Inequality
filter => [ 'severity' => '>warning'  ] # Greater
filter => [ 'severity' => '>=warning' ] # Greater or equal
```

Matching only several severities is also possible:

```perl6
filter => [ 'severity' => [ 'notice', 'warning' ] ]
```

## Several filters

If many filters are specified, all must be valid:

```perl6
# Use this adapter only if the category is My::Wonderfull::Lib and if the severity is warning or error
[ 'severity' => '>=warning', 'category' => /My::Wonderfull::Lib/ ]
```

## Write your own filter

If a more complex filtering is necessary, a class inheriting Log::Any::Filter can be created:
```perl6
# Use home-made filters
class MyOwnFilter is Log::Any::Filter {
	method filter( :$msg, :$severity, :$category, :%extra-fields ) returns Bool {
		# Write some complicated tests
		return True;
	}
}

Log::Any.add( Some::Adapter.new, :filter( MyOwnFilter.new ) );
```

## Filters acting like barrier

A filter generally authorize a log to be sent to an Adapter. If there is no defined Adapter, the log will end up in a black hole.
```perl6
Log::Any.add( :filter( [ severity => '>warning' ] );
# Logs with severity above "warning" does not continue through the pipeline
```

# PIPELINES

A _pipeline_ is a set of adapters, filters, formatters and options (asynchronicity) and can be used to define alternatives paths. This allows to handle differently some logs (for example, for security or realtime).
If a log is produced with a specific pipeline which is not defined in the log consumers, the default pipeline is used.

Pipelines can be specified when an Adapter is added.
```perl6
Log::Any.add( :pipeline('security'), Log::Any::Adapter::Example.new );

Log::Any.error( :pipeline('security'), :msg('security error!' ) );
```

## ASYNCHRONICITY

By default, a pipeline is synchronous, but it can be asynchronous:
```perl6
Log::Any.add( :pipeline( 'async pipeline'  ), Log::Any::Pipeline.new( :asynchronous ) );
```

If a pipeline of the specified name already exists, an exception will be throwed.
The _overwrite_ parameter can be specified to force adding a new pipeline:
```perl6
# Overwrite the default pipeline
Log::Any.add( Log::Any::Pipeline.new( :asynchronous ), :overwrite );
# Overwrite the "other" pipeline
Log::Any.add( Log::Any::Pipeline.new( :asynchronous ), :pipeline('other'), :overwrite );
```

**Asynchronous pipelines can contains messages to handle when a program reaches its end, so these messages will not be logged.**

## Continue on match

When adding an Adapter to the pipeline, `:continue-on-match` option can be specified.
This option tells the pipeline to continue to the next adapter if the Adapter is matched.

The log `info log twice` will be dispatched to both adapters.

```perl6
Log::Any.add( :pipeline('continue-on-match'), SomeAdapterAs.new, :continue-on-match );
Log::Any.add( :pipeline('continue-on-match'), SomeAdapterB.new );
Log::Any.info( :pipeline('continue-on-match'), 'info log twice' );
```

# INTROSPECTION

Check if a log will be handled (to prevent computation of log).
It is usefull if you want to log a dump of a complex object which can take time.

## will-log method

This method can takes in parameters the *category*, the *severity* and the *pipeline* to use.
Theses parameters are then used to check if the message could pass through the pipelines and will be handled.

** _msg_ parameter cannot be tested, so if a filter acts on it, the results will differ between `will-log()` and `log()`. **

```perl6
if Log::Any.will-log( :severity('debug') ) {
	Log::Any.debug( serialize( $some-complex-object ) );
}
```

## will-log aliases methods

Some aliases are defined and provide the severity.

- will-emergency()
- …
- will-trace()

```perl6
Log::Any.will-debug(); # Alias to will-log( :severity('debug') )
```

# DEBUGGING

## gist method

_gist_ method prints a string represention of the internal Log::Any state (defined pipelines with their adapters, filters and formatters). Since many attributes are not public, you cannot recreate a Log::Any stack based on this representation.

# TODO

[TODO page](doc/todo.md)
