#!env perl6
use v6.c;

=begin pod
=head1 Basic test file of Log::Any.
=para
This test file tests if basic methods can be called, if the formatter is working correctly and if the generated date by Log::Any is correct.
=end pod

use Test;

plan 32;

use Log::Any;

# Can call some methods
my $l = Log::Any.new;
for keys %Log::Any::Definitions::SEVERITIES -> $severity {
	can-ok Log::Any, $severity;
	can-ok $l,       $severity;
}

dies-ok { $l.log( :msg('msg'), :severity('unknownSeverity') ) }, 'unknown severity dies';
dies-ok { $l.log( :msg('msg'), :severity('') ) }, 'empty severity dies';

ok $l.log( :msg(''), :severity('trace' ) ), 'Empty message allowed';

class AdapterDebug is Log::Any::Adapter {
	has @.logs;

	method handle( $msg ) {
		push @!logs, $msg;
	}
}

use-ok 'Log::Any::Adapter';
can-ok Log::Any::Adapter, 'handle';
use-ok 'Log::Any::Filter';
can-ok Log::Any::Filter, 'filter';
use-ok 'Log::Any::Formatter';
can-ok Log::Any::Formatter, 'format';

# Default pipeline
my $a = AdapterDebug.new;
Log::Any.add( $a );
Log::Any.log( :msg( 'test-1' ), :category( 'test-basic' ), :severity('debug') );
is $a.logs, [ 'test-1' ], 'Log "test-1" with default pipeline';

Log::Any.info( "msg\nwith \n newlines\n\n" );
is $a.logs[*-1], 'msg\nwith \n newlines\n\n', 'Newlines correctly removed';

# Continue-on-match: continue to the next adapter, even if the current adapter matches
$a.logs = [];
my $b = AdapterDebug.new;

Log::Any.add( :pipeline('continue-on-match'), $a, :continue-on-match );
Log::Any.add( :pipeline('continue-on-match'), $b );
Log::Any.info( :pipeline('continue-on-match'), 'info should log twice' );

ok $a.logs[*-1] === $b.logs[*-1] === 'info should log twice', 'continue on match';

ok Log::Any.gist, 'Log::Any.gist on undefined instance.';
ok Log::Any.new.gist, 'Log::Any.new.gist';
