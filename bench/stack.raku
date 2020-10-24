use lib 'lib';
use Collective::Stack;

my \values = 150000;
my $stack = Collective::Stack.new;

my &producer = {
    say 'Starting producer';
    for 1..values -> \a, \b, \c {
        $stack.push(a, b, c);
    }
};

my &consumer = {
    say 'Starting consumer';
    my int $consumed;
    while $consumed < values {
        $consumed++ if my \value = $stack.pop;
    }
};

my \time = now;
await Promise.allof(
    Promise.start(&producer),
    Promise.start(&producer),
    Promise.start(&consumer),
    Promise.start(&consumer),
);

say $stack.peek;
say now - time;
