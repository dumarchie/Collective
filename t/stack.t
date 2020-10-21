use v6;
use Test;

use lib 'lib';
use Collective::Stack;

plan 5;

my $stack;
subtest 'empty stack', {
    plan 4;

    $stack = Collective::Stack.new;
    isa-ok $stack, Collective::Stack,
      '$stack = Collective::Stack.new';

    nok $stack, '$stack evaluates to False';

    cmp-ok $stack.peek, '===', Nil,
      '$stack.peek returns Nil';

    fails-like { $stack.pop }, X::Cannot::Empty,
      '$stack.pop', action => 'pop', what => $stack.^name;
};

# define unique test values
my \a = Mu;
my \b = Mu.new;

subtest 'push values onto a stack', {
    plan 4;

    my $a = a;
    my $b = b;
    cmp-ok $stack.push($a, $b), '===', $stack,
      '$stack.push($a, $b) returns the $stack';

    ok $stack, '$stack now evaluates to True';

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

subtest 'create a stack with values', {
    plan 4;

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
}

subtest 'pop the last value from a stack', {
    plan 3;

    my \got = $stack.pop;
    cmp-ok $stack.peek, '=:=', Nil,
      '$stack.pop removes the value of $a from the $stack';

    cmp-ok got, '=:=', a,
      '... and returns it';

    nok $stack, '$stack now evaluates to False';
}

subtest 'clone a stack', {
    plan 2;

    my $clone = $stack.clone;
    isa-ok $clone, Collective::Stack,
      'my $clone = $stack.clone';

    $clone.push(a);
    nok $stack, 'modifying the $clone does not modify the $stack';
}

done-testing;
