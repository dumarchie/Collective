use lib 'lib';
use Collective::Stack;

sub shares(Int $ops, Int $workers, Str $type) {
    return Empty unless $ops && $workers;
    die "Can't have more {$type}s than ops"
     if $workers > $ops;

    my @ranges;
    my $min = 0;
    my $share = $ops / $workers;
    for 1..$workers {
        my $max = truncate($_ * $share);
        @ranges.push: $min^..$max;
        $min = $max;
    }
    @ranges;
}

sub producers(Int() $ops, Int() $workers, :$batch) {
    my @workers;
    for shares($ops, $workers, 'producer') -> @values {
        my $id    = @workers + 1;
        my $share = @values.max - @values.min;

        if $batch > 1 {
            my @slips;
            @slips[@slips.elems] = .Slip for @values.batch($batch);
            @values := @slips;
        }

        @workers.push: -> $stack {
            say "Start producer $id";
            my int $count;
            for @values {
                $count++;
                $stack.push($_);
            }
            "Producer $id needed %0.3f seconds and $count calls"
              ~ " to push $share values";
        };
    }
    @workers;
}

sub consumers(Int() $ops, Int() $workers, :$pop-n) {
    my @workers;
    my &format = -> $id, $count, $consumed {
       "Consumer $id needed %0.3f seconds and $count calls"
         ~ " to pop $consumed values";
    }
    for shares($ops, $workers, 'consumer') -> @range {
        my $id    = @workers + 1;
        my $share = @range.max - @range.min;

        my int $consumed;
        @workers.push: $pop-n ?? -> $stack {
            say "Start consumer $id";
            my int $calls;
            while $consumed < $share {
                $calls++;
                $consumed++ for $stack.pop($share - $consumed);
            }
            format($id, $calls, $consumed);
        } !! -> $stack {
            say "Start consumer $id";
            my int $calls;
            while $consumed < $share {
                $calls++;
                $consumed++ if $stack.pop;
            }
            format($id, $calls, $consumed);
        };
    }
    @workers;
}

sub timer(&code, |args) {
    my \started = now;
    say sprintf code(|args), now - started;
}

sub MAIN(
    Int   $elems?    is copy, #= number of values to push and pop
    Int  :$producers is copy, #= number of workers that push values
    Int  :$batch = 1,         #= number of values to push at a time
    Int  :$consumers is copy, #= number of workers that pop values
    Bool :$pop-n,             #= pop sequences of values
    Bool :$reverse            #= start consumers before producers
) {
    my \cores = $*KERNEL.cpu-cores - 1;
    $elems //= cores * 100_000;

    with $consumers {
        $producers //= cores - $consumers;
    }
    else {
        $producers //= truncate(cores / 2);
        $consumers   = cores - $producers;
    }

    my @workers   = producers($elems, $producers, :$batch);
    my @consumers = consumers($elems, $consumers, :$pop-n);
    $reverse ?? @workers.prepend(@consumers)
             !! @workers.append(@consumers);

    my $stack;
    timer {
        if $producers > 0 {
            $stack := Collective::Stack.new;
        }
        else {
            timer {
                $stack := Collective::Stack.new: 1..$elems;
                "Constructor spent %.3f seconds stacking $elems values";
            };
        }

        if @workers > 1 {
            await @workers.map: -> &code { start timer &code, $stack };
        }
        elsif @workers {
            timer @workers[0], $stack
        }
        'Total time spent: %.3f seconds';
    }
    say 'Top value: ' ~ $stack.peek.raku;
}
