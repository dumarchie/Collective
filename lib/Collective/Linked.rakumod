role Collective::Linked {
    has Mu $.value;
    has Collective::Linked $.rest;
    method !SET-SELF(Mu \value, \rest) {
        $!value := value;
        $!rest  := rest;
        self;
    }

    method empty() { self.WHAT }

    method bless(Mu :$value!, :$rest = self.empty, *%attrinit) {
        # Note: the BUILDALL signature is not documented...
        self.CREATE!SET-SELF($value<>, $rest<>).BUILDALL(Empty, %attrinit);
    }

    proto method insert(|) {*}
    multi method insert(::?CLASS:U: Mu \value) {
        self.CREATE!SET-SELF(value, self.empty);
    }
    multi method insert(::?CLASS:U: Mu $value is rw) {
        self.CREATE!SET-SELF($value<>, self.empty);
    }
    multi method insert(::?CLASS:D: Mu \value) {
        self.CREATE!SET-SELF(value, self);
    }
    multi method insert(::?CLASS:D: Mu $value is rw) {
        self.CREATE!SET-SELF($value<>, self);
    }
}

proto sub linked(|) is export {*}
multi sub linked() { Collective::Linked.empty }
multi sub linked(Mu \value, Collective::Linked $rest?) {
    $rest.insert(value);
}

=begin pod

=TITLE role Collective::Linked

=SUBTITLE Node that links a value to another node

    role Collective::Linked { }

A common role for objects that represent a I<node> of a recursive data
structure such as a linked list or a tree. A C<Collective::Linked> object
has two attributes: the C<$!value> defines the I<value> of the node and the
C<$!rest> is a C<Collective::Linked> type that defines the I<rest> of the
values in the data structure.

By default, an I<empty> data structure is represented by the type object. A
type that C<does Collective::Linked> may define its own C<method empty()>
to return an object instance that evaluates to C<False> in Boolean context.

The C<Collective::Linked> type can be used directly as a purely functional
linked list. For example, the following code creates a linked list storing
a C<Range> of values in reverse order and then prints the values:

    my $list = linked; # empty
    $list .= insert($_) for ^10;
    say $list.value;   # OUTPUT: «9␤»
    say $list.value    # OUTPUT: «8␤» .. «0␤»
     while $list .= rest;

=head1 Exports

=head2 sub linked

Defined as:

    multi sub linked()
    multi sub linked(Mu \value, Collective::Linked $rest?)

Returns the C<Collective::Linked> type object if called without arguments.
Otherwise returns a Collective::Linked object instance with the provided
I<value> and I<rest>.

=head1 Methods

=head2 method value

Returns the value of the C<$!value> attribute.

=head2 method rest

Returns the value of the C<$!rest> attribute.

=head2 method !SET-SELF

Defined as:

    method !SET-SELF(Mu \value, \rest)

This private method allows a type that C<does Collective::Linked> to
initialize the C<$!value> and C<$!rest> attributes by binding them to the
respective arguments.

=head2 method empty

Defined as:

    method empty()

Returns the invocant's type object.

=head2 method bless

Defined as:

    method bless(Mu :$value!, :$rest = self.empty, *%attrinit)

Low-level object construction method that L<binds|#method_!SET-SELF> the
C<Collective::Linked> attributes to the decontainerized C<$value> and
C<$rest> before C<.BUILDALL> is called. Provided to support the L<default
method new|https://docs.raku.org/type/Mu#method_new> while still allowing a
class that C<does Collective::Linked> to define additional attributes and
initialize them with a C<submethod BUILD>.

=head2 method insert

Defined as:

    multi method insert(::?CLASS:U: Mu \value)
    multi method insert(::?CLASS:U: Mu $value is rw)
    multi method insert(::?CLASS:D: Mu \value)
    multi method insert(::?CLASS:D: Mu $value is rw)

Creates and returns a new object with the C<$!value> attribute bound to the
provided C<value> or decontainerized C<$value>. If called on a type object,
the C<$!rest> attribute is bound to the C<.empty> representation of the
class. Otherwise the C<$!rest> attribute is bound to the invocant C<self>.

=end pod
