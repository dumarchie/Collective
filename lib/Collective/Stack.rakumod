class Collective::Stack {
    # Private node definition, not to be exposed
    my class Node {
        has Mu $.value;
        has Node $.next;
        method !SET-SELF(Mu \value, \next) {
            $!value := value;
            $!next  := next;
            self;
        }

        proto method insert(|) {*}
        multi method insert(Node: Mu \value is readonly --> Node:D) {
            self.CREATE!SET-SELF(value, self);
        }
        multi method insert(Node: Mu $value is rw --> Node:D) {
            self.CREATE!SET-SELF($value<>, self);
        }
    }

    # The actual stack definition
    has Node $!top;
    method !SET-SELF($!top) { self }

    method new(**@values is raw --> ::?CLASS:D) {
        my $node := Node;
        $node := $node.insert($_<>) for @values;
        self.CREATE!SET-SELF($node);
    }

    my constant Absent = Mu.new;
    method pop(::?CLASS:D:) is nodal {
        my $value;
        cas $!top, {
            if $_ {
                $value := .value;
                .next;
            }
            else {
                $value := Absent;
                $_;
            }
        };
        $value =:= Absent ?? Failure.new(
          X::Cannot::Empty.new(:action<pop>,:what(self.^name))
        ) !! $value;
    }

    multi method push(::?CLASS:D: Mu \value --> ::?CLASS:D) {
        cas $!top, { .insert(value) };
        self;
    }
    multi method push(::?CLASS:D: Slip:D \value --> ::?CLASS:D) {
        self!push-list(value);
    }
    multi method push(::?CLASS:D: **@values is raw --> ::?CLASS:D) {
        self!push-list(@values);
    }
    method !push-list(::?CLASS:D: @values --> ::?CLASS:D) {
        X::Cannot::Lazy.new(:action<push>,:what(self.^name)).throw
          if @values.is-lazy;

        self.push($_) for @values;
        self;
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

    method new(**@values --> Collective::Stack:D)

Creates and returns a new stack with the provided values. Figuratively,
each value is placed on top of the preceding values.

=head2 method pop

Defined as:

    method pop(Collective::Stack:D:)

Removes a value from the top of the stack and returns it. Fails if the
stack is empty.

This method may be called via the homonymous array operator. For
example:

    my $stack = Collective::Stack.new('a', 'b');
    $stack.pop; # b
    pop $stack; # a
    pop $stack;
    CATCH { default { put .^name, ': ', .message } }; # OUTPUT:
    # «X::Cannot::Empty: Cannot pop from an empty Collective::Stack␤»

=head2 method push

Defined as:

    method push(Collective::Stack:D: **@values --> Collective::Stack:D)

Puts the values on the stack and returns the modified stack.

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
