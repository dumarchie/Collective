use Collective::LinkedList;

class Collective::Stack {
    has $!linkedlist;
    method !SET-SELF($!linkedlist) { self }

    sub stack(|init --> ::?CLASS:D) is export {
        ::?CLASS.new(|init);
    }

    proto method new(+values --> ::?CLASS:D) {*}
    multi method new() {
        self.CREATE!SET-SELF(linkedlist);
    }
    multi method new(Iterable \values is readonly) {
        self.CREATE!SET-SELF(linkedlist values, :reversed);
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
        cas $!linkedlist, { .insert(value) };
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
        my $node;
        cas $!linkedlist, {
            $node := $_;
            .rest;
        };
        $node.value;
    }

    method clone(::?CLASS:D: --> ::?CLASS:D) {
        self.CREATE!SET-SELF(⚛$!linkedlist);
    }

    method peek(::?CLASS:D:) {
        my \list = ⚛$!linkedlist;
        list ?? list.value !! Nil;
    }

    multi method Bool(::?CLASS:D: --> Bool:D) {
        (⚛$!linkedlist).Bool;
    }
}


=begin pod

=TITLE class Collective::Stack

=SUBTITLE Lock-free concurrent LIFO data structure

    class Collective::Stack {}

A C<Collective::Stack> is a mutable B<LIFO (last in, first out)> data
structure that supports lock-free concurrent access. It supports some of
the same routines as Raku's C<Array> which is probably more efficient in
nonconcurrent use cases.

=head1 Exports

=head2 sub stack

Defined as:

    sub stack(|init --> Collective::Stack:D)

Calls L<C<Collective::Stack.new>|#method_new> with the provided arguments.

=head1 Methods

=head2 method new

Defined as:

    proto method new(+values --> Collective::Stack:D)

Creates and returns a new C<Collective::Stack> with the provided values.
Figuratively, each value is placed on top of the preceding values.

=head2 method peek

Defined as:

    method peek(Collective::Stack:D:)

Returns the value at the top of the stack, or C<Nil> if the stack is empty.

=head2 method push

Defined as:

    proto method push(**@values is raw --> Collective::Stack:D) is nodal

Puts the values on the stack and returns the modified stack. Autovivifies
the stack if called on an undefined C<Scalar> of type C<Collective::Stack>.
For example:

    my Collective::Stack $stack;
    $stack.push('a', 'b');
    say $stack.peek; # OUTPUT: «b␤»

Pushing more than one value at a time may not be particularly efficient.

=head2 method pop

Defined as:

    proto method pop(Collective::Stack:D: $n?) is nodal

Without argument, this method behaves like the corresponding C<Array>
method: it removes and returns a value from the top of the stack, or fails
if the stack is empty.

If called with an argument, it returns a C<Seq> that pops values I<on
demand> until C<$n> values have been popped or the stack is empty. For
example:

    my $stack = Collective::Stack.new('a');
    my $seq = $stack.pop(*);
    $stack.push('b');
    say $seq.join(' on top of '); # OUTPUT: «b on top of a␤»

=head2 method clone

Defined as:

    method clone(Collective::Stack:D: --> Collective::Stack:D)

Returns a clone of the original stack. This is an efficient operation
because the underlying implementation is persistent.

=head2 Bool

Defined as:

    multi method Bool(Collective::Stack:D: --> Bool:D)

Returns C<True> if the stack contains at least one value, C<False> if the
stack is empty.

=end pod
