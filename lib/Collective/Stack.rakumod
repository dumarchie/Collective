class Collective::Stack {
    # Private node definition, not to be exposed
    my class Node {
        has Mu $.value;
        has Node $.next;
        method !SET-SELF(Mu \value, Node \next --> Node:D) {
            $!value := value;
            $!next  := next;
            self;
        }

        proto method insert(Mu $ --> Node:D) {*}
        multi method insert(Mu \value is readonly) {
            self.CREATE!SET-SELF(value, self);
        }
        multi method insert(Mu $value is rw) {
            self.CREATE!SET-SELF($value<>, self);
        }
    }

    # The actual stack definition
    has Node $!top;
    method !SET-SELF($!top) { self }

    proto method new(+values --> ::?CLASS:D) {*}
    multi method new() {
        self.CREATE!SET-SELF(Node);
    }
    multi method new(Iterable \values is readonly) {
        X::Cannot::Lazy.new(:action<stack>).throw
          if values.is-lazy;

        my $node := Node;
        $node := $node.insert($_) for values;
        self.CREATE!SET-SELF($node);
    }
    multi method new(**@values is raw) {
        self.new(@values);
    }

    proto method push(**@values is raw --> ::?CLASS:D) is nodal {*}
    multi method push(::?CLASS:U $target is rw: **@values is raw) {
        # even autovivification requires concurrency control
        cas $target, { $_ // .new };
        $target.push(|@values);
    }
    multi method push(::?CLASS:D: Mu \value) {
        cas $!top, { .insert(value) };
        self;
    }
    multi method push(::?CLASS:D: Slip:D \values) {
        self!push-list(values);
    }
    multi method push(::?CLASS:D: **@values is raw) {
        self!push-list(@values);
    }
    method !push-list(::?CLASS:D: @values --> ::?CLASS:D) {
        X::Cannot::Lazy.new(:action<push>,:what(self.^name)).throw
          if @values.is-lazy;

        self.push($_) for @values;
        self;
    }

    my class ValueConsumer does Iterator {
        has &.extract;
        method pull-one() { &!extract() }
    }

    proto method pop(::?CLASS:D: $n?) is nodal {*}
    multi method pop() {
        my \value = self!extract;
        value =:= IterationEnd ?? Failure.new(
          X::Cannot::Empty.new(:action<pop>,:what(self.^name))
        ) !! value;
    }
    multi method pop($n) {
        my &extract = { self!extract };
        Seq.new(ValueConsumer.new(:&extract)).head($n);
    }
    method !extract(::?CLASS:D:) {
        my $value := IterationEnd;
        while $value =:= IterationEnd && my $node := ⚛$!top {
            if cas($!top, $node, $node.next) =:= $node {
                $value := $node.value;
            }
        }
        $value;
    }

    method clone(::?CLASS:D: --> ::?CLASS:D) {
        self.CREATE!SET-SELF(⚛$!top);
    }

    method peek(::?CLASS:D:) {
        with ⚛$!top { .value }
        else { Nil }
    }

    multi method Bool(::?CLASS:D: --> Bool:D) {
        (⚛$!top).defined;
    }
}


=begin pod

=TITLE class Collective::Stack

=SUBTITLE Lock-free concurrent LIFO data structure

    class Collective::Stack {}

A C<Collective::Stack> is a mutable B<LIFO (last in, first out)> data
structure that can be shared safely between threads. It supports some
of the same routines as Raku's C<Array> which probably is a more
efficient stack implementation for a single-threaded use case.

=head1 Methods

=head2 method new

Defined as:

    proto method new(+values --> Collective::Stack:D)

Creates and returns a new C<Collective::Stack> with the provided values.
Figuratively, each value is placed on top of the preceding values.

=head2 method push

Defined as:

    proto method push(**@values is raw --> Collective::Stack:D) is nodal

Puts the values on the stack and returns the modified stack.
Autovivifies the stack if called on an undefined C<Scalar> of type
C<Collective::Stack>. For example:

    my Collective::Stack $var;
    $var.push('a', 'b');
    say $stack.pop(*).join(' on top of '); # OUTPUT: «b on top of a␤»

Pushing more than one value at a time may not be particularly efficient.

=head2 method pop

Defined as:

    proto method pop(Collective::Stack:D: $n?) is nodal

Without argument, this method behaves like the corresponding C<Array>
method: it removes and returns a value from the top of the stack, or
fails if the stack is empty.

If called with an argument, it returns a C<Seq> that pops values I<on
demand> until C<$n> values have been popped or the stack is empty. For
example:

    my $stack = Collective::Stack.new('a');
    my $seq = $stack.pop(*);
    $stack.push('b');
    say $seq.join(' on top of ');          # OUTPUT: «b on top of a␤»

=head2 method clone

Defined as:

    method clone(Collective::Stack:D: --> Collective::Stack:D)

Returns a clone of the original stack. This is a very efficient
operation because the underlying implementation is persistent.

=head2 method peek

Defined as:

    method peek(Collective::Stack:D:)

Returns the value at the top of the stack, or C<Nil> if the stack is
empty.

=head2 Bool

Defined as:

    multi method Bool(Collective::Stack:D: --> Bool:D)

Returns C<True> if the stack contains at least one value, C<False> if
the stack is empty.

=end pod
