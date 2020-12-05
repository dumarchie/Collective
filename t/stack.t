use v6;
use Test;

use lib 'lib';
use Collective::Stack;

plan 10;

my $stack;
subtest 'create empty stack', {
    plan 4;

    $stack = Collective::Stack.new;
    isa-ok $stack, Collective::Stack,
      '$stack = Collective::Stack.new';

    nok $stack, '$stack evaluates to False';

    cmp-ok $stack.peek, '===', Nil,
      '$stack.peek returns Nil';

    fails-like { $stack.pop },
      X::Cannot::Empty, :action<pop>, :what($stack.^name),
      '$stack.pop';
};

subtest 'push nothing onto a stack', {
    plan 4;

    cmp-ok $stack.push(), '===', $stack,
      '$stack.push() returns the $stack';

    nok $stack, '$stack still evaluates to False';

    cmp-ok $stack.peek, '===', Nil,
      '$stack.peek still returns Nil';

    fails-like { $stack.pop },
      X::Cannot::Empty, :action<pop>, :what($stack.^name),
      '$stack.pop';
}

# define unique test values
my \a = Mu;
my \b = Mu.new;

subtest 'push a single value onto a stack', {
    plan 4;

    my $a = a;
    cmp-ok $stack.push($a), '===', $stack,
      '$stack.push($a) returns the $stack';

    ok $stack, '$stack now evaluates to True';

    $a = Any.new;
    cmp-ok $stack.peek, '=:=', a,
      '$stack.peek returns the value of $a';

    subtest '$stack.pop', {
        my \got = $stack.pop;
        nok $stack, '$stack.pop removes the value from the $stack';
        cmp-ok got, '=:=', a, '... and returns it';
    }
}

subtest 'push multiple values onto a stack', {
    plan 3;

    my $a = a;
    my $b = b;
    cmp-ok $stack.push($a, $b), '===', $stack,
      '$stack.push($a, $b) returns the $stack';

    $b = Any.new;
    cmp-ok $stack.peek, '=:=', b,
      '$stack.peek returns the value of $b';

    subtest '$stack.pop', {
        my \got = $stack.pop;
        cmp-ok $stack.peek, '=:=', a,
          '$stack.pop removes the value of $b from the $stack';

        cmp-ok got, '=:=', b,
          '... and returns it';
    }
}

subtest 'push a slip onto a stack', {
    plan 4;

    cmp-ok $stack.push(slip a, b), '===', $stack,
      '$stack.push(slip a, b) returns the $stack';

    cmp-ok $stack.peek, '=:=', b,
      '$stack.peek returns the last value of the slip';

    subtest '$stack.pop', {
        my \got = $stack.pop;
        cmp-ok $stack.peek, '=:=', a,
          '$stack.pop removes the value from the $stack';

        cmp-ok got, '=:=', b,
          '... and returns it';
    }

    throws-like { $stack.push(slip lazy a, b) },
      X::Cannot::Lazy, action => 'push', what => $stack.^name,
      '$stack.push(slip lazy a, b)';
}

subtest 'create a stack from a single Iterable', {
    plan 5;

    my @values = a, b;
    $stack = Collective::Stack.new(@values);
    isa-ok $stack, Collective::Stack,
      '$stack = Collective::Stack.new(@values)';

    ok $stack, '$stack evaluates to True';

    @values[1] = Any.new;
    cmp-ok $stack.peek, '=:=', b,
      '$stack.peek returns the original value of @values.tail';

    subtest '$stack.pop', {
        my \got = $stack.pop;
        cmp-ok $stack.peek, '=:=', a,
          '$stack.pop removes the last value from the $stack';

        cmp-ok got, '=:=', b,
          '... and returns it';
    }

    throws-like { Collective::Stack.new(lazy @values) },
      X::Cannot::Lazy, action => 'stack',
      'Collective::Stack.new(lazy @values)';
}

subtest 'create a stack from multiple arguments', {
    plan 4;

    my @values = a, b;
    $stack = Collective::Stack.new(@values, lazy @values);
    isa-ok $stack, Collective::Stack,
      '$stack = Collective::Stack.new(@values, lazy @values)';

    ok $stack, '$stack evaluates to True';

    @values[1] = Any.new;
    is $stack.peek, lazy @values,
      '$stack.peek returns lazy @values';

    subtest '$stack.pop', {
        my \got = $stack.pop;
        cmp-ok $stack.peek, '=:=', @values,
          '$stack.pop removes the lazy @values from the $stack';

        is got, lazy @values,
          '... and returns it';
    }
}

subtest '.pop(Whatever)', {
    plan 3;

    my $stack = Collective::Stack.new('a');
    my $seq = $stack.pop(*);
    isa-ok $seq, Seq, 'my $seq = $stack.pop(*)';

    $stack.push('b');
    is $seq.join(' on top of '), 'b on top of a',
      '$seq produces values on demand';

    ok !$stack, 'values are removed from the $stack';
}

subtest '.pop(Int)', {
    plan 3;

    my $stack = Collective::Stack.new('a', 'b');
    my $seq = $stack.pop(2);
    isa-ok $seq, Seq, 'my $seq = $stack.pop(2)';

    $stack.push('c');
    is $seq.join(' on top of '), 'c on top of b',
      '$seq produces values on demand';

    is $stack.peek, 'a', 'values are removed from the $stack';
}

subtest 'clone a stack', {
    plan 2;

    my $clone = $stack.clone;
    isa-ok $clone, Collective::Stack,
      'my $clone = $stack.clone';

    $clone.pop;
    ok $stack, 'modifying the $clone does not modify the $stack';
}

done-testing;
