use v6;
use Test;

use lib 'lib';
use Collective::Stack;

plan 7;

my $stack;
subtest 'empty stack', {
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

subtest 'create a stack with values', {
    plan 5;

    my $a = a;
    my $b = b;
    $stack = Collective::Stack.new($a, $b);
    isa-ok $stack, Collective::Stack,
      '$stack = Collective::Stack.new($a, $b)';

    ok $stack, '$stack evaluates to True';

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

    throws-like { Collective::Stack.new(slip lazy a, b) },
      X::Cannot::Lazy, action => 'stack',
      'Collective::Stack.new(slip lazy a, b)';
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
