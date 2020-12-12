class Collective::LinkedList {
    has Mu $.value;
    has ::?CLASS $.next;
    method !SET-SELF(Mu \value, ::?CLASS \next --> ::?CLASS:D) {
        $!value := value;
        $!next  := next;
        self;
    }

    proto method insert(Mu $ --> ::?CLASS:D) {*}
    multi method insert(Mu \value is readonly) {
        self.CREATE!SET-SELF(value, self);
    }
    multi method insert(Mu $value is rw) {
        self.CREATE!SET-SELF($value<>, self);
    }

    proto method new(+values --> ::?CLASS) {*}
    multi method new() { self.WHAT }
    multi method new(Iterable \values is readonly, :$action = 'link') {
        X::Cannot::Lazy.new(:$action).throw
          if values.is-lazy;

        my $node = self.WHAT;
        $node := $node.insert($_) for values;
        $node;
    }
    multi method new(**@values is raw) {
        self.new(@values);
    }

    sub linkedlist(|init --> ::?CLASS) is export {
        ::?CLASS.new(|init);
    }
}
