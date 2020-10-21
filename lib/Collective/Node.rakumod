class Collective::Node {
    has Mu $.value;
    has Collective::Node $.next;

    # Private initializer; expects decontainerized arguments
    method !SET-SELF(Mu \value, \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    # Default initializer invoked by pubic .bless
    submethod BUILD(Mu :$value!, :$next) {
        $!value := $value<>;
        $!next  := $next<>;
    }

    # Define insert method
    method insert(::?CLASS: Mu \value) {
        self.CREATE!SET-SELF(value<>, self);
    }
}
