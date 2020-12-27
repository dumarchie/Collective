class Collective::LinkedList {
    has Mu $.value;
    has ::?CLASS $.next;
    method !SET-SELF(Mu \value, ::?CLASS:D \next --> ::?CLASS:D) {
        $!value := value;
        $!next  := next;
        self;
    }

    sub linkedlist(|init --> ::?CLASS:D) is export {
        ::?CLASS.new(|init);
    }

    proto method new(+values --> ::?CLASS:D) {*}
    multi method new() {
        my $self := self.CREATE;
        $self!SET-SELF(IterationEnd, $self);
    }
    multi method new(Iterable \values is readonly) {
        X::Cannot::Lazy.new(:action<link>).throw
          if values.is-lazy;

        my $node := self.new;
        $node := $node.insert($_) for values.reverse;
        $node;
    }
    multi method new(**@values is raw) {
        self.new(@values);
    }

    proto method insert(::?CLASS:D: Mu $value --> ::?CLASS:D) {*}
    multi method insert(Mu \value is readonly) {
        self.CREATE!SET-SELF(value, self);
    }
    multi method insert(Mu $value is rw) {
        self.CREATE!SET-SELF($value<>, self);
    }

    multi method Bool(::?CLASS:D: --> Bool:D) {
        $!next !=:= self;
    }
}

=begin pod

=TITLE class Collective::LinkedList

=SUBTITLE Purely functional linked list

    class Collective::LinkedList {}

A C<Collective::LinkedList> is a linear collection of immutable values.
Each value is stored in a node that points to the next node. The nodes
are also immutable, allowing distinct linked lists to share a common tail.

A C<Collective::LinkedList> is in fact the first node of a given linked
list. Every linked list is terminated by a sentinel node that evaluates to
C<False> in Boolean context. A non-empty linked list evaluates to C<True>.

=head1 Exports

=head2 sub linkedlist

Defined as:

    sub linkedlist(|init --> Collective::LinkedList:D) is export

Calls L<C<Collective::LinkedList.new>|#method_new> with the provided
arguments.

=head1 Methods

=head2 method new

Defined as:

    proto method new(+values --> Collective::LinkedList:D)

Creates and returns a new C<Collective::LinkedList> with the provided
values.

=head2 method value

Defined as:

    method value(Collective::LinkedList:D:)

Returns the value stored in the first node of the linked list, or the
sentinel value C<IterationEnd> if the list is empty.

=head2 method next

Defined as:

    method next(Collective::LinkedList:D:)

Returns the next node of the linked list, which is the invocant node if the
list is empty.

=head2 method insert

Defined as:

    proto method insert(Collective::LinkedList:D: Mu $value
                    --> Collective::LinkedList:D)

Creates and returns a new C<Collective::LinkedList> node with the provided
value and the invocant as the next node.

=head2 Bool

Defined as:

    multi method Bool(Collective::Stack:D: --> Bool:D)

Returns C<True> if the linked list contains at least one value, C<False> if
the linked list is empty.

=end pod
