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

sub producers($stack, Int() $ops, Int() $workers, :$batch) {
    my @workers;
    for shares($ops, $workers, 'producer') -> @values {
        my $id    = @workers + 1;
        my $share = @values.max - @values.min;

        if $batch > 1 {
            my @slips;
            @slips[@slips.elems] = .Slip for @values.batch($batch);
            @values := @slips;
        }

        @workers.push: {
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

sub consumers($stack, Int() $ops, Int() $workers, :$no-retry) {
    my @workers;
    my &format = -> $id, $count, $consumed {
       "Consumer $id needed %0.3f seconds and $count calls"
         ~ " to pop $consumed values";
    }
    for shares($ops, $workers, 'consumer') -> @range {
        my $id    = @workers + 1;
        my $share = @range.max - @range.min;

        my int $consumed;
        @workers.push: $no-retry ?? {
            say "Start consumer $id";
            my $value;
            for @range {
                $consumed++ if $stack.pop;
            };
            format($id, $share, $consumed);
        } !! {
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

sub timer(&code) {
    my \started = now;
    say sprintf code, now - started;
}

sub MAIN(
    Int   $values?   is copy, #= number of values to push and pop
    Int  :$producers is copy, #= number of workers that push values
    Int  :$batch = 1,         #= number of values to push at a time
    Int  :$consumers is copy, #= number of workers that pop values
    Bool :$no-retry  is copy, #= don't retry if pop fails
    Bool :$reverse            #= start consumers before producers
) {
    my \cores = $*KERNEL.cpu-cores - 1;
    $values //= cores * 100_000;

    with $consumers {
        $producers //= cores - $consumers;
    }
    else {
        $producers //= truncate(cores / 2);
        $consumers   = cores - $producers;
    }

    if $consumers > 0 {
        note "WARNING: Consumers will retry until Ctrl+C"
         unless $producers > 0 || $no-retry
    }

    my \stack     = Collective::Stack.new;
    my @workers   = producers(stack, $values, $producers, :$batch);
    my @consumers = consumers(stack, $values, $consumers, :$no-retry);
    $reverse ?? @workers.prepend(@consumers)
             !! @workers.append(@consumers);

    timer {
        await @workers.map: -> &code { start timer &code };
        'Total time spent: %.3f seconds';
    }
    say 'Top value: ' ~ stack.peek.raku;
}
