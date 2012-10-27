package Method::Signatures;

use strict;
use warnings;

use base 'Devel::Declare::MethodInstaller::Simple';
use Method::Signatures::Parser;
use Data::Alias;
use Devel::Pragma qw(my_hints);

our $VERSION = '20121025.2315_001';

our $DEBUG = $ENV{METHOD_SIGNATURES_DEBUG} || 0;

our @CARP_NOT;

sub DEBUG {
    return unless $DEBUG;

    require Data::Dumper;
    print STDERR "DEBUG: ", map { ref $_ ? Data::Dumper::Dumper($_) : $_ } @_;
}


=head1 NAME

Method::Signatures - method and function declarations with signatures and no source filter

=head1 SYNOPSIS

    package Foo;

    use Method::Signatures;

    method new (%args) {
        return bless {%args}, $self;
    }

    method get ($key) {
        return $self->{$key};
    }

    method set ($key, $val) {
        return $self->{$key} = $val;
    }

    # Can also get type checking if you like:

    method set (Str $key, Int $val) {
        return $self->{$key} = $val;        # now you know $val is always an integer
    }

    func hello($greeting, $place) {
        print "$greeting, $place!\n";
    }


=head1 DESCRIPTION

Provides two new keywords, C<func> and C<method>, so that you can write subroutines with signatures instead of having to spell out C<my $self = shift; my($thing) = @_>

C<func> is like C<sub> but takes a signature where the prototype would
normally go.  This takes the place of C<my($foo, $bar) = @_> and does
a whole lot more.

C<method> is like C<func> but specifically for making methods.  It will
automatically provide the invocant as C<$self>.  No more C<my $self =
shift>.

Also allows signatures, very similar to Perl 6 signatures.

Also does type checking, understanding all the types that Moose (or Mouse) would understand.

And it does all this with B<no source filters>.


=head2 Signature syntax

    func echo($message) {
        print "$message\n";
    }

is equivalent to:

    sub echo {
        my($message) = @_;
        print "$message\n";
    }

except the original line numbering is preserved and the arguments are
checked to make sure they match the signature.

Similarly

    method foo($bar, $baz) {
        $self->wibble($bar, $baz);
    }

is equivalent to:

    sub foo {
        my $self = shift;
        my($bar, $baz) = @_;
        $self->wibble($bar, $baz);
    }

again with checks to make sure the arguments passed in match the
signature.

The full signature syntax for each parameter is:

          Int|Str  \:$param!  where $SM_EXPR  is ro  = $AS_EXPR  when $SM_EXPR
          \_____/  ^^\____/^  \____________/  \___/  \________/  \___________/
             |     ||   |  |        |           |        |           |
       Type_/      ||   |  |        |           |        |           |
       Aliased?___/ |   |  |        |           |        |           |
       Named?______/    |  |        |           |        |           |
       Parameter var___/   |        |           |        |           |
       Required?__________/         |           |        |           |
       Parameter constraint(s)_____/            |        |           |
       Parameter trait(s)______________________/         |           |
       Default value____________________________________/            |
       When default value should be applied_________________________/

Every component except the parameter name is optional.  Note that you
cannot use both \ and : in front of the variable name.

C<$SM_EXPR> is any expression that is valid as the RHS of a smartmatch,
or else a raw block of code. See L<"Value constraints">.

C<$AS_EXPR> is any expression that is valid as the RHS of an
assignment operator. See L<"Defaults">.


=head3 C<@_>

Other than removing C<$self>, C<@_> is left intact.  You are free to
use C<@_> alongside the arguments provided by Method::Signatures.


=head3 Named parameters

Parameters can be passed in named, as a hash, using the C<:$arg> syntax.

    method foo(:$arg) {
        ...
    }

    $object->foo( arg => 42 );

Named parameters are optional by default.

Required positional parameters and named parameters can be mixed, but
the named params must come last.

    method foo( $a, $b, :$c )   # legal

Named parameters are passed in as a hash after all positional arguments.

    method display( $text, :$justify = 'left', :$enchef = 0 ) {
        ...
    }

    # $text = "Some stuff", $justify = "right", $enchef = 0
    $obj->display( "Some stuff", justify => "right" );

You cannot mix optional positional params with named params, as that
leads to ambiguities.

    method foo( $a, $b?, :$c )  # illegal

    # Is this $a = 'c', $b = 42 or $c = 42?
    $obj->foo( c => 42 );


=head3 Aliased references

A signature of C<\@arg> will take an array reference but allow it to
be used as C<@arg> inside the method.  C<@arg> is an alias to the
original reference.  Any changes to C<@arg> will affect the original
reference.

    package Stuff;
    method add_one(\@foo) {
        $_++ for @foo;
    }

    my @bar = (1,2,3);
    Stuff->add_one(\@bar);  # @bar is now (2,3,4)

Named parameters cannot be aliased in this way.


=head3 Invocant parameter

The method invocant (i.e. C<$self>) can be changed as the first
parameter.  Put a colon after it instead of a comma.

    method foo($class:) {
        $class->bar;
    }

    method stuff($class: $arg, $another) {
        $class->things($arg, $another);
    }

C<method> has an implied default invocant of C<$self:>.  C<func> has
no invocant.


=head3 Defaults

Each parameter can be given a default with the C<$arg = EXPR> syntax.
For example,

    method add($this = 23, $that = 42) {
        return $this + $that;
    }

Almost any expression can be used as a default.

    method silly(
        $num    = 42,
        $string = q[Hello, world!],
        $hash   = { this => 42, that => 23 },
        $code   = sub { $num + 4 },
        @nums   = (1,2,3),
    )
    {
        ...
    }

Normally, defaults will only be used if the argument is not passed in at all.
Passing in C<undef> will override the default.  That means...

    Class->add();            # $this = 23, $that = 42
    Class->add(99);          # $this = 99, $that = 42
    Class->add(99, undef);   # $this = 99, $that = undef

However, you can specify additional conditions under which a default is
also to be used, using a trailing C<when>. For example:

    # Use default if no argument passed
    method get_results($how_many = 1) {...}

    # Use default if no argument passed OR argument is undef
    method get_results($how_many = 1 when undef) {...}

    # Use default if no argument passed OR argument is empty string
    method get_results($how_many = 1 when "") {...}

    # Use default if no argument passed OR argument is zero
    method get_results($how_many = 1 when 0) {...}

    # Use default if no argument passed OR argument is zero or less
    method get_results($how_many = 1 when sub{ $_[0] <= 0 }) {...}

    # Use default if no argument passed OR argument is invalid
    method get_results($how_many = 1 when sub{ !valid($_[0]) }) {...}

In other words, if you include a C<when I<value>> after the default,
the default is still used if the argument is missing, but is also
used if the argument is provided but smart-matches the specified I<value>.

Note that the final two examples above use anonymous subroutines to
conform their complex tests to the requirements of the smartmatch
operator. Because this is useful, but syntactically clumsy, there is
also a short-cut for this behaviour. If the test after C<when> consists
of a block, the block is executed as the defaulting test, with the
actual argument value aliased to C<$_> (just like in a C<grep> block).
So the final two examples above could also be written:

    # Use default if no argument passed OR argument is zero or less
    method get_results($how_many = 1 when {$_ <= 0}) {...}

    # Use default if no argument passed OR argument is invalid
    method get_results($how_many = 1 when {!valid($_)}) } {...}

The most commonly used form of C<when> modifier is almost
certainly C<when undef>:

    # Use default if no argument passed OR argument is undef
    method get_results($how_many = 1 when undef) {...}

which covers the common case where an uninitialized variable is passed
as an argument, or where supplying an explicit undefined value is
intended to indicate: "use the default instead".

This usage is sufficiently common that a short-cut is provided:
using the C<//=> operator (instead of the regular assignment operator)
to specify the default. Like so:

    # Use default if no argument passed OR argument is undef
    method get_results($how_many //= 1) {...}


Earlier parameters may be used in later defaults.

    method copy_cat($this, $that = $this) {
        return $that;
    }

Any variable that has a default is considered optional.


=head3 Type Constraints

Parameters can also be given type constraints.  If they are, the value
passed in will be validated against the type constraint provided.
Types are provided by L<Any::Moose> which will load L<Mouse> if
L<Moose> is not already loaded.

Type constraints can be a type, a role or a class.  Each will be
checked in turn until one of them passes.

    * First, is the $value of that type declared in Moose (or Mouse)?

    * Then, does the $value have that role?
        $value->DOES($type);

    * Finally, is the $value an object of that class?
        $value->isa($type);

The set of default types that are understood can be found in
L<Mouse::Util::TypeConstraints> (or L<Moose::Util::TypeConstraints>;
they are generally the same, but there may be small differences).

    # avoid "argument isn't numeric" warnings
    method add(Int $this = 23, Int $that = 42) {
        return $this + $that;
    }

L<Mouse> and L<Moose> also understand some parameterized types; see
their documentation for more details.

    method add(Int $this = 23, Maybe[Int] $that) {
        # $this will definitely be defined
        # but $that might be undef
        return defined $that ? $this + $that : $this;
    }

You may also use disjunctions, which means that you are willing to
accept a value of either type.

    method add(Int $this = 23, Int|ArrayRef[Int] $that) {
        # $that could be a single number,
        # or a reference to an array of numbers
        use List::Util qw<sum>;
        my @ints = ($this);
        push @ints, ref $that ? @$that : $that;
        return sum(@ints);
    }

If the value does not validate against the type, a run-time exception
is thrown.

    # Error will be:
    # In call to Class::add : the 'this' parameter ("cow") is not of type Int
    Class->add('cow', 'boy'); # make a cowboy!

You cannot declare the type of the invocant.

    # this generates a compile-time error
    method new(ClassName $class:) {
        ...
    }


=head3 Value Constraints

In addition to a type, each parameter can also be specified with one or
more additional constraints, using the C<$arg where CONSTRAINT> syntax.

    method set_name($name where qr{\S+ \s+ \S+}x) {
        ...
    }

    method set_rank($rank where \%STD_RANKS) {
        ...
    }

    method set_age(Int $age where [17..75] ) {
        ...
    }

    method set_rating($rating where { $_ >= 0 } where { $_ <= 100 } ) {
        ...
    }

    method set_serial_num(Int $snum where {valid_checksum($snum)} ) {
        ...
    }

The C<where> keyword must appear immediately after the parameter name
and before any L<trait|"Parameter traits"> or L<default|"Defaults">.

Each C<where> constraint is smartmatched against the value of the
corresponding parameter, and an exception is thrown if the value does
not satisfy the constraint.

Any of the normal smartmatch arguments (numbers, strings, regexes,
undefs, hashrefs, arrayrefs, coderefs) can be used as a constraint.

In addition, the constraint can be specified as a raw block. This block
can then refer to the parameter variable directly by name (as in the
definition of C<set_serial_num()> above), or else as C<$_> (as in the
definition of C<set_rating()>.

Unlike type constraints, value constraints are tested I<after> any
default values have been resolved, and in the same order as they were
specified within the signature.


=head3 Parameter traits

Each parameter can be assigned a trait with the C<$arg is TRAIT> syntax.

    method stuff($this is ro) {
        ...
    }

Any unknown trait is ignored.

Most parameters have a default traits of C<is rw is copy>.

=over 4

=item B<ro>

Read-only.  Assigning or modifying the parameter is an error.

=item B<rw>

Read-write.  It's ok to read or write the parameter.

This is a default trait.

=item B<copy>

The parameter will be a copy of the argument (just like C<< my $arg = shift >>).

This is a default trait except for the C<\@foo> parameter (see L<Aliased references>).

=item B<alias>

The parameter will be an alias of the argument.  Any changes to the
parameter will be reflected in the caller.

This is a default trait for the C<\@foo> parameter (see L<Aliased references>).

=back

=head3 Mixing value constraints, traits, and defaults

As explained in L<Signature syntax>, there is a defined order when including
multiple trailing aspects of a parameter:

=over 4

=item * Any value constraint must immediately follow the parameter name.

=item * Any trait must follow that.

=item * Any default must come last.

=back

For instance, to have a parameter which has all three aspects:

    method echo($message where { length <= 80 } is ro = "what?") {
        return $message
    }

Think of C<$message where { length <= 80 }> as being the left-hand side of the
trait, and C<$message where { length <= 80 } is ro> as being the left-hand side
of the default assignment.


=head3 Slurpy parameters

A "slurpy" parameter is a list or hash parameter that "slurps up" all
remaining arguments.  Since any following parameters can't receive values,
there can be only one slurpy parameter.

Slurpy parameters must come at the end of the signature and they must
be positional.

Slurpy parameters are optional by default.

=head3 The "yada yada" marker

The restriction that slurpy parameters must be positional, and must
appear at the end of the signature, means that they cannot be used in
conjunction with named parameters.

This is frustrating, because there are many situations (in particular:
during object initialization, or when creating a callback) where it
is extremely handy to be able to ignore extra named arguments that don't
correspond to any named parameter.

While it would be theoretically possible to allow a slurpy parameter to
come after named parameters, the current implementation does not support
this (see L<"Slurpy parameter restrictions">).

Instead, there is a special syntax (colloquially known as the "yada yada")
that tells a method or function to simply ignore any extra arguments
that are passed to it:

    # Expect name, age, gender, and simply ignore anything else
    method BUILD (:$name, :$age, :$gender, ...) {
        $self->{name}   = uc $name;
        $self->{age}    = min($age, 18);
        $self->{gender} = $gender // 'unspecified';
    }

    # Traverse tree with node-printing callback
    # (Callback only interested in nodes, ignores any other args passed to it)
    $tree->traverse( func($node,...) { $node->print } );

The C<...> may appear as a separate "pseudo-parameter" anywhere in the
signature, but is normally placed at the very end. It has no other
effect except to disable the usual "die if extra arguments" test that
the module sets up within each method or function.

This means that a "yada yada" can also be used to ignore positional
arguments (as the second example above indicates). So, instead of:

    method verify ($min, $max, @etc) {
        return $min <= $self->{val} && $self->{val} <= $max;
    }

you can just write:

    method verify ($min, $max, ...) {
        return $min <= $self->{val} && $self->{val} <= $max;
    }

This is also marginally more efficient, as it does not have to allocate,
initialize, or deallocate the unused slurpy parameter C<@etc>.


=head3 Required and optional parameters

Parameters declared using C<$arg!> are explicitly I<required>.
Parameters declared using C<$arg?> are explicitly I<optional>.  These
declarations override all other considerations.

A parameter is implictly I<optional> if it is a named parameter, has a
default, or is slurpy.  All other parameters are implicitly
I<required>.

    # $greeting is optional because it is named
    method hello(:$greeting) { ... }

    # $greeting is required because it is positional
    method hello($greeting) { ... }

    # $greeting is optional because it has a default
    method hello($greeting = "Gruezi") { ... }

    # $greeting is required because it is explicitly declared using !
    method hello(:$greeting!) { ... }

    # $greeting is required, even with the default, because it is
    # explicitly declared using !
    method hello(:$greeting! = "Gruezi") { ... }


=head3 The C<@_> signature

The @_ signature is a special case which only shifts C<$self>.  It
leaves the rest of C<@_> alone.  This way you can get $self but do the
rest of the argument handling manually.


=head3 The empty signature

If a method is given the signature of C<< () >> or no signature at
all, it takes no arguments.


=head2 Anonymous Methods

An anonymous method can be declared just like an anonymous sub.

    my $method = method ($arg) {
        return $self->foo($arg);
    };

    $obj->$method(42);


=head2 Options

Method::Signatures takes some options at `use` time of the form

    use Method::Signatures { option => "value", ... };

=head3 compile_at_BEGIN

By default, named methods and funcs are evaluated at compile time, as
if they were in a BEGIN block, just like normal Perl named subs.  That
means this will work:

    echo("something");

    # This function is compiled first
    func echo($msg) { print $msg }

You can turn this off lexically by setting compile_at_BEGIN to a false value.

    use Method::Signatures { compile_at_BEGIN => 0 };

compile_at_BEGIN currently causes some issues when used with Perl 5.8.
See L<Earlier Perl versions>.

=head3 debug

When true, turns on debugging messages about compiling methods and
funcs.  See L<DEBUGGING>.  The flag is currently global, but this may
change.

=head2 Differences from Perl 6

Method::Signatures is mostly a straight subset of Perl 6 signatures.
The important differences...

=head3 Restrictions on named parameters

As noted above, there are more restrictions on named parameters than
in Perl 6.

=head3 Named parameters are just hashes

Perl 5 lacks all the fancy named parameter syntax for the caller.

=head3 Parameters are copies.

In Perl 6, parameters are aliases.  This makes sense in Perl 6 because
Perl 6 is an "everything is an object" language.  Perl 5 is not, so
parameters are much more naturally passed as copies.

You can alias using the "alias" trait.

=head3 Can't use positional params as named params

Perl 6 allows you to use any parameter as a named parameter.  Perl 5
lacks the named parameter disambiguating syntax so it is not allowed.

=head3 Addition of the C<\@foo> reference alias prototype

In Perl 6, arrays and hashes don't get flattened, and their
referencing syntax is much improved.  Perl 5 has no such luxury, so
Method::Signatures added a way to alias references to normal variables
to make them easier to work with.

=head3 Addition of the C<@_> prototype

Method::Signatures lets you punt and use @_ like in regular Perl 5.

=cut

sub import {
    my $class = shift;
    my $caller = caller;
    # default values

    my $hints = my_hints;
    $hints->{METHOD_SIGNATURES_compile_at_BEGIN} = 1;  # default to on

    my $arg = shift;
    if (defined $arg) {
        if (ref $arg) {
            $DEBUG  = $arg->{debug}  if exists $arg->{debug};
            $caller = $arg->{into}   if exists $arg->{into};
            $hints->{METHOD_SIGNATURES_compile_at_BEGIN} = $arg->{compile_at_BEGIN}
                                     if exists $arg->{compile_at_BEGIN};
        }
        elsif ($arg eq ':DEBUG') {
            $DEBUG = 1;
        }
        else {
            require Carp;
            Carp::croak("Invalid Module::Signatures argument $arg");
        }
    }

    $class->install_methodhandler(
        into            => $caller,
        name            => 'method',
        invocant        => '$self'
    );

    $class->install_methodhandler(
        into            => $caller,
        name            => 'func',
    );

    DEBUG("import for $caller done\n");
}


# Generally, the code that calls inject_if_block decides what to put in front of the actual
# subroutine body.  For instance, if it's an anonymous sub, the $before parameter would contain
# "sub ".  In our case, we want the "sub " all the time: it fixes a weird error on Perl 5.10,
# and doesn't cause any problems anywhere else.
sub inject_if_block
{
    my ($self, $inject, $before) = @_;

    my $name  = $self->{function_name};
    my $attrs = $self->{attributes} || '';

    DEBUG( "attributes: $attrs\n" );

    # Named function compiled at BEGIN time
    if( defined $name && $self->_do_compile_at_BEGIN ) {
        # Devel::Declare needs the code ref which has been generated.
        # Forunately, "sub foo {...}" happens at compile time, so we
        # can use \&foo at runtime even if it comes before the sub
        # declaration in the code!
        $before = qq[\\&$name; sub $name $attrs ];
    }
    # Anonymous function or compiled at runtime.
    elsif( defined $name ) {
        $before = qq[sub $attrs ];
    }

    DEBUG( "inject: $inject\n" );
    $self->SUPER::inject_if_block($inject, $before);
}


# Check if compile_at_BEGIN is set in this scope.
sub _do_compile_at_BEGIN {
    my $hints = my_hints;

    # Default to on.
    return 1 if !exists $hints->{METHOD_SIGNATURES_compile_at_BEGIN};

    return $hints->{METHOD_SIGNATURES_compile_at_BEGIN};
}


sub _strip_ws {
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
}


# Sometimes a compilation error will happen but not throw an error causing the
# code to continue compiling and producing an unrelated error down the road.
#
# A symptom of this is that eval STRING no longer works.  So we detect if the
# parser is a dead man walking.
sub _parser_is_fucked {
    local $@;
    return eval 42 ? 0 : 1;
}


# Capture the function name
sub strip_name {
    my $self = shift;

    my $name = $self->SUPER::strip_name(@_);
    $self->{function_name} = $name;

    return $name;
}


# Capture the attributes
sub strip_attrs {
    my $self = shift;

    my $attrs = $self->SUPER::strip_attrs(@_);
    $self->{attributes} = $attrs;

    return $attrs;
}


# Overriden method from D::D::MS
sub parse_proto {
    my $self = shift;
    my $proto = shift;

    # Before we try to compile signatures, make sure there isn't a hidden compilation error.
    die $@ if _parser_is_fucked;

    return $self->parse_signature(
        proto           => $proto,
        invocant        => $self->{invocant},
        pre_invocant    => $self->{pre_invocant}
    );
}


# Parse a signature
sub parse_signature {
    my $self = shift;
    my %args = @_;
    my @protos = $self->_split_proto($args{proto} || []);
    my $signature = $args{signature} || {};

    # JIC there's anything we need to pull out before the invocant
    # (primary example would be the $orig for around modifiers in Moose/Mouse
    $signature->{pre_invocant} = $args{pre_invocant};

    # Special case for methods, they will pass in an invocant to use as the default
    if( $signature->{invocant} = $args{invocant} ) {
        if( @protos ) {
            $signature->{invocant} = $_ for extract_invocant(\$protos[0]);
            shift @protos unless $protos[0] =~ /\S/;
        }
    }

    return $self->parse_func( proto => \@protos, signature => $signature );
}


sub _split_proto {
    my $self = shift;
    my $proto = shift;

    my @protos;
    if( ref $proto ) {
        @protos = @$proto;
    }
    else {
        _strip_ws($proto);
        @protos = split_proto($proto);
    }

    return @protos;
}


# Parse a subroutine signature
sub parse_func {
    my $self = shift;
    my %args = @_;
    my @protos = $self->_split_proto($args{proto} || []);
    my $signature = $args{signature} || {};

    $signature->{named}      = [];
    $signature->{positional} = [];
    $signature->{overall}    = {
        num_optional            => 0,
        num_optional_positional => 0,
        num_named               => 0,
        num_positional          => 0,
        has_invocant            => $signature->{invocant} ? 1 : 0,
        num_slurpy              => 0
    };

    my $idx = 0;
    for my $proto (@protos) {
        DEBUG( "proto: $proto\n" );

        my $sig = split_parameter($proto, \$idx);

        # Handle "don't care" specifier
        if ($sig->{yadayada}) {
            $signature->{overall}{num_slurpy}++;
            $signature->{overall}{yadayada}++;
            next;
        }

        $self->_check_sig($sig, $signature);

        if( $sig->{named} ) {
            push @{$signature->{named}}, $sig;
        }
        else {
            push @{$signature->{positional}}, $sig;
            $sig->{position} = @{$signature->{positional}};
        }

        my $overall = $signature->{overall};
        $overall->{num_optional}++              if $sig->{is_optional};
        $overall->{num_named}++                 if $sig->{named};
        $overall->{num_positional}++            if !$sig->{named};
        $overall->{num_optional_positional}++   if $sig->{is_optional} and !$sig->{named};
        $overall->{num_slurpy}++                if $sig->{is_slurpy};

        DEBUG( "sig: ", $sig );
    }

    $self->{signature} = $signature;

    $self->_calculate_max_args;
    $self->_check_signature;

    # Then turn it into Perl code
    my $inject = $self->inject_from_signature($signature);
    return $inject;
}


sub _calculate_max_args {
    my $self = shift;
    my $overall = $self->{signature}{overall};

    # If there's a slurpy argument, the max is infinity.
    if( $overall->{num_slurpy} ) {
        $overall->{max_argv_size} = 'inf';
        $overall->{max_args}      = 'inf';

        return;
    }

    # How big can @_ be?
    $overall->{max_argv_size} = ($overall->{num_named} * 2) + $overall->{num_positional};

    # The maxmimum logical arguments (name => value counts as one argument)
    $overall->{max_args} = $overall->{num_named} + $overall->{num_positional};

    return;
}


# Check the integrity of one piece of the signature
sub _check_sig {
    my($self, $sig, $signature) = @_;

    if( $sig->{is_slurpy} ) {
        $self->signature_error("signature can only have one slurpy parameter") if
          $signature->{overall}{num_slurpy} >= 1;
        $self->signature_error("slurpy parameter $sig->{var} cannot be named, use a reference instead") if
          $sig->{named};
    }

    if( $sig->{named} ) {
        if( $signature->{overall}{num_optional_positional} ) {
            my $pos_var = $signature->{positional}[-1]{var};
            die("named parameter $sig->{var} mixed with optional positional $pos_var\n");
        }
    }
    else {
        if( $signature->{overall}{num_named} ) {
            my $named_var = $signature->{named}[-1]{var};
            die("positional parameter $sig->{var} after named param $named_var\n");
        }
    }
}


# Check the integrity of the signature as a whole
sub _check_signature {
    my $self = shift;
    my $signature = $self->{signature};
    my $overall   = $signature->{overall};

    # Check that slurpy arguments come at the end
    if(
        $overall->{num_slurpy}                  &&
        !($overall->{yadayada} || $signature->{positional}[-1]{is_slurpy})
    )
    {
        my($slurpy_param) = $self->_find_slurpy_params;
        $self->signature_error("slurpy parameter $slurpy_param->{var} must come at the end");
    }
}


sub _find_slurpy_params {
    my $self = shift;
    my $signature = $self->{signature};

    return grep { $_->{is_slurpy} } @{ $signature->{named} }, @{ $signature->{positional} };
}


# Turn the parsed signature into Perl code
sub inject_from_signature {
    my $self      = shift;
    my $class     = ref $self || $self;
    my $signature = shift;

    my @code;
    push @code, "my $signature->{pre_invocant} = shift;" if $signature->{pre_invocant};
    push @code, "my $signature->{invocant} = shift;" if $signature->{invocant};

    for my $sig (@{$signature->{positional}}) {
        push @code, $self->inject_for_sig($sig);
    }

    if( @{$signature->{named}} ) {
        my $first_named_idx = @{$signature->{positional}};
        push @code, "my \%args = \@_[$first_named_idx..\$#_];";

        for my $sig (@{$signature->{named}}) {
            push @code, $self->inject_for_sig($sig);
        }

        push @code, $class . '->named_param_error(\%args) if %args;'
            if $signature->{overall}{num_named} && !$signature->{overall}{yadayada};
    }

    push @code, $class . '->named_param_error(\%args) if %args;' if $signature->{overall}{has_named};

    my $max_argv = $signature->{overall}{max_argv_size};
    my $max_args = $signature->{overall}{max_args};
    push @code, qq[$class->too_many_args_error($max_args) if \@_ > $max_argv; ]
        unless $max_argv == "inf";

    # All on one line.
    return join ' ', @code;
}


sub too_many_args_error {
    my($class, $max_args) = @_;

    $class->signature_error("was given too many arguments, it expects $max_args");
}


sub named_param_error {
    my ($class, $args) = @_;
    my @keys = keys %$args;

    $class->signature_error("does not take @keys as named argument(s)");
}


sub inject_for_sig {
    my $self = shift;
    my $class = ref $self || $self;
    my $sig = shift;

    return if $sig->{is_at_underscore};

    my @code;

    my $sigil = $sig->{sigil};
    my $name  = $sig->{name};
    my $idx   = $sig->{idx};

    # These are the defaults.
    my $lhs = "my $sig->{var}";
    my $rhs;

    if( $sig->{named} ) {
        $sig->{passed_in} = "\$args{$sig->{name}}";
        $rhs = "delete $sig->{passed_in}";
    }
    else {
        $rhs = $sig->{is_ref_alias}       ? "${sigil}{\$_[$idx]}" :
               $sig->{sigil} =~ /^[@%]$/  ? "\@_[$idx..\$#_]"     :
                                            "\$_[$idx]"           ;
        $sig->{passed_in} = $rhs;
    }

    my $check_exists = $sig->{check_exists} = $sig->{named} ? "exists \$args{$sig->{name}}" : "(\@_ > $idx)";

    # Handle a default value
    if( defined $sig->{default_when} ) {
        # Handle default with 'when { block using $_ }'
        if ($sig->{default_when} =~ m{^ \s* \{ (?: .* ; .* | (?:(?! => ). )* ) \} \s* $}xs) {
            $rhs = "!$check_exists ? ($sig->{default}) : do{ no warnings; my \$arg = $rhs; (grep $sig->{default_when} \$arg) ? ($sig->{default}) : \$arg}";
        }

        # Handle default with 'when anything_else'
        else {
            $rhs = "!$check_exists ? ($sig->{default}) : do{ no warnings; my \$arg = $rhs; \$arg ~~ ($sig->{default_when}) ? ($sig->{default}) : \$arg }";
        }
    }

    # Handle simple defaults
    elsif( defined $sig->{default} ) {
        $rhs = "$check_exists ? ($rhs) : ($sig->{default})";
    }

    if( !$sig->{is_optional} ) {
        push @code, qq[${class}->required_arg('$sig->{var}') unless $check_exists; ];
    }

    if( $sig->{type} ) {
        push @code, $self->inject_for_type_check($sig);
    }

    # Handle \@foo
    if ( $sig->{is_ref_alias} or $sig->{traits}{alias} ) {
        push @code, sprintf 'Data::Alias::alias(%s = %s);', $lhs, $rhs;
    }
    # Handle "is ro"
    elsif ( $sig->{traits}{ro} ) {
        require Const::Fast;
        push @code, "Const::Fast::const( $lhs => $rhs );";
    } else {
        push @code, "$lhs = $rhs;";
    }

    # Handle 'where' constraints (after defaults are resolved)
    if ( $sig->{where} ) {
        for my $constraint ( keys %{$sig->{where}} ) {
            # Handle 'where { block using $_ }'
            my $constraint_impl =
                $constraint =~ m{^ \s* \{ (?: .* ; .* | (?:(?! => ). )* ) \} \s* $}xs
                    ? "sub $constraint"
                    : $constraint;
            my $error = sprintf q{ %s->where_error(%s, '%s', '%s') }, $class, $sig->{var}, $sig->{var}, $constraint;
            push @code, "$error unless grep { \$_ ~~ $constraint_impl } $sig->{var}; ";
        }
    }

    return @code;
}

# A hook for extension authors
# (see also type_check below)
sub inject_for_type_check
{
    my $self = shift;
    my $class = ref $self || $self;
    my ($sig) = @_;

    my $check_exists = $sig->{is_optional} ? "$sig->{check_exists}" : '';

    # This is an optimization to unroll typecheck which makes Mouse types about 40% faster.
    # It only happens when type_check() has not been overridden.
    if( $class->can("type_check") eq __PACKAGE__->can("type_check") ) {
        my $check = sprintf q[($%s::mutc{cache}{'%s'} ||= %s->_make_constraint('%s'))->check(%s)],
          __PACKAGE__, $sig->{type}, $class, $sig->{type}, $sig->{passed_in};
        my $error = sprintf q[%s->type_error('%s', %s, '%s') ],
          $class, $sig->{type}, $sig->{passed_in}, $sig->{name};
        my $code = "$error if ";
        $code .= "$check_exists && " if $check_exists;
        $code .= "!$check";
        return "$code;";
    }
    # If a subclass has overridden type_check(), we must use that.
    else {
        my $code = "${class}->type_check('$sig->{type}', $sig->{passed_in}, '$sig->{name}')";
        $code .= "if $check_exists" if $check_exists;
        return "$code;";
    }
}

# This is a common function to throw errors so that they appear to be from the point of the calling
# sub, not any of the Method::Signatures subs.
sub signature_error {
    my ($proto, $msg) = @_;
    my $class = ref $proto || $proto;

    my ($file, $line, $method) = carp_location_for($class);
    die "In call to $method(), $msg at $file line $line.\n";
}

sub required_arg {
    my ($class, $var) = @_;

    $class->signature_error("missing required argument $var");
}


# STUFF FOR TYPE CHECKING

# This variable will hold all the bits we need.  MUTC could stand for Moose::Util::TypeConstraint,
# or it could stand for Mouse::Util::TypeConstraint ... depends on which one you've got loaded (or
# Mouse if you have neither loaded).  Because we use Any::Moose to allow the user to choose
# whichever they like, we'll need to figure out the exact method names to call.  We'll also need a
# type constraint cache, where we stick our constraints once we find or create them.  This insures
# that we only have to run down any given constraint once, the first time it's seen, and then after
# that it's simple enough to pluck back out.  This is very similar to how MooseX::Params::Validate
# does it.
our %mutc;

# This is a helper function to initialize our %mutc variable.
sub _init_mutc
{
    require Any::Moose;
    Any::Moose->import('::Util::TypeConstraints');

    no strict 'refs';
    my $class = any_moose('::Util::TypeConstraints');
    $mutc{class} = $class;

    $mutc{findit}     = \&{ $class . '::find_or_parse_type_constraint' };
    $mutc{pull}       = \&{ $class . '::find_type_constraint'          };
    $mutc{make_class} = \&{ $class . '::class_type'                    };
    $mutc{make_role}  = \&{ $class . '::role_type'                     };

    $mutc{isa_class}  = $mutc{pull}->("ClassName");
    $mutc{isa_role}   = $mutc{pull}->("RoleName");
}

# This is a helper function to find (or create) the constraint we need for a given type.  It would
# be called when the type is not found in our cache.
sub _make_constraint
{
    my ($class, $type) = @_;

    _init_mutc() unless $mutc{class};

    # Look for basic types (Int, Str, Bool, etc).  This will also create a new constraint for any
    # parameterized types (e.g. ArrayRef[Int]) or any disjunctions (e.g. Int|ScalarRef[Int]).
    my $constr = eval { $mutc{findit}->($type) };
    if ($@)
    {
        $class->signature_error("the type $type is unrecognized (looks like it doesn't parse correctly)");
    }
    return $constr if $constr;

    # Check for roles.  Note that you *must* check for roles before you check for classes, because a
    # role ISA class.
    return $mutc{make_role}->($type) if $mutc{isa_role}->check($type);

    # Now check for classes.
    return $mutc{make_class}->($type) if $mutc{isa_class}->check($type);

    $class->signature_error("the type $type is unrecognized (perhaps you forgot to load it?)");
}

# This method does the actual type checking.  It's what we inject into our user's method, to be
# called directly by them.
#
# Note that you can override this instead of inject_for_type_check if you'd rather.  If you do,
# remember that this is a class method, not an object method.  That's because it's called at
# runtime, when there is no Method::Signatures object still around.
sub type_check
{
    my ($class, $type, $value, $name) = @_;

    # find it if isn't cached
    $mutc{cache}->{$type} ||= $class->_make_constraint($type);

    # throw an error if the type check fails
    unless ($mutc{cache}->{$type}->check($value))
    {
        $class->type_error($type, $value, $name);
    }

    # $mutc{cache} = {};
}

# If you just want to change what the type failure errors look like, just override this.
# Note that you can call signature_error yourself to handle the croak-like aspects.
sub type_error
{
    my ($class, $type, $value, $name) = @_;
    $value = defined $value ? qq{"$value"} : 'undef';
    $class->signature_error(qq{the '$name' parameter ($value) is not of type $type});
}

# Errors from `where' constraints are handled here.
sub where_error
{
    my ($class, $value, $name, $constraint) = @_;
    $value = defined $value ? qq{"$value"} : 'undef';
    $class->signature_error(qq{$name value ($value) does not satisfy constraint: $constraint});
}


=head1 PERFORMANCE

There is no run-time performance penalty for using this module above
what it normally costs to do argument handling.

There is also no run-time penalty for type-checking if you do not
declare types.  The run-time penalty if you do declare types should be
very similar to using L<Mouse::Util::TypeConstraints> (or
L<Moose::Util::TypeConstraints>) directly, and should be faster than
using a module such as L<MooseX::Params::Validate>.  The magic of
L<Any::Moose> is used to give you the lightweight L<Mouse> if you have
not yet loaded L<Moose>, or the full-bodied L<Moose> if you have.

Type-checking modules are not loaded until run-time, so this is fine:

    use Method::Signatures;
    use Moose;
    # you will still get Moose type checking
    # (assuming you declare one or more methods with types)


=head1 DEBUGGING

One of the best ways to figure out what Method::Signatures is doing is
to run your code through B::Deparse (run the code with -MO=Deparse).

Setting the C<METHOD_SIGNATURES_DEBUG> environment variable will cause
Method::Signatures to display debugging information when it is
compiling signatures.

=head1 EXAMPLE

Here's an example of a method which displays some text and takes some
extra options.

  use Method::Signatures;

  method display($text is ro, :$justify = "left", :$fh = \*STDOUT) {
      ...
  }

  # $text = $stuff, $justify = "left" and $fh = \*STDOUT
  $obj->display($stuff);

  # $text = $stuff, $justify = "left" and $fh = \*STDERR
  $obj->display($stuff, fh => \*STDERR);

  # error, missing required $text argument
  $obj->display();

The display() method is equivalent to all this code.

  sub display {
      my $self = shift;

      croak('display() missing required argument $text') unless @_ > 0;
      const my $text = $_[0];

      my(%args) = @_[1 .. $#_];
      my $justify = exists $args{justify} ? $args{justify} : 'left';
      my $fh      = exists $args{fh}      ? $args{'fh'}    : \*STDOUT;

      ...
  }


=head1 EXPERIMENTING

If you want to experiment with the prototype syntax, start with
C<Method::Signatures::parse_func>.  It takes a method prototype
and returns a string of Perl 5 code which will be placed at the
beginning of that method.

If you would like to try to provide your own type checking, subclass
L<Method::Signatures> and either override C<type_check> or
C<inject_for_type_check>.  See L</EXTENDING>, below.

This interface is experimental, unstable and will change between
versions.


=head1 EXTENDING

If you wish to subclass Method::Signatures, the following methods are
good places to start.

=head2 too_many_args_error, named_param_error, required_arg, type_error, where_error

These are class methods which report the various run-time errors
(extra parameters, unknown named parameter, required parameter
missing, parameter fails type check, and parameter fails where
constraint respectively).  Note that each one calls
C<signature_error>, which your versions should do as well.

=head2 signature_error

This is a class method which calls C<die> and reports the error as
being from the caller's perspective.  Most likely you will not need to
override this.  If you'd like to have Method::Signatures errors give
full stack traces (similar to C<$Carp::Verbose>), have a look at
L<Carp::Always>.

=head2 type_check

This is a class method which is called to verify that parameters have
the proper type.  If you want to change the way that
Method::Signatures does its type checking, this is most likely what
you want to override.  It calls C<type_error> (see above).

=head2 inject_for_type_check

This is the object method that actually inserts the call to
L</type_check> into your Perl code.  Most likely you will not need to
override this, but if you wanted different parameters passed into
C<type_check>, this would be the place to do it.


=head1 BUGS, CAVEATS and NOTES

Please report bugs and leave feedback at
E<lt>bug-Method-SignaturesE<gt> at E<lt>rt.cpan.orgE<gt>.  Or use the
web interface at L<http://rt.cpan.org>.  Report early, report often.

=head2 One liners

If you want to write "use Method::Signatures" in a one-liner, do a
C<-MMethod::Signatures> first.  This is due to a bug/limitation in
Devel::Declare.

=head2 No source filter

While this module does rely on the black magic of L<Devel::Declare> to
access Perl's own parser, it does not depend on a source filter.  As
such, it doesn't try to parse and rewrite your source code and there
should be no weird side effects.

Devel::Declare only affects compilation.  After that, it's a normal
subroutine.  As such, for all that hairy magic, this module is
surprisingly stable.

=head2 Earlier Perl versions

The most noticeable is if an error occurs at compile time, such as a
strict error, perl might not notice until it tries to compile
something else via an C<eval> or C<require> at which point perl will
appear to fail where there is no reason to fail.

We recommend you use the L<compile_at_BEGIN> flag to turn off
compile-time parsing.

Method::Signatures cannot be used with Perl versions prior to 5.8
because L<Devel::Declare> does not work with those earlier versions.

=head2 What about class methods?

Right now there's nothing special about class methods.  Just use
C<$class> as your invocant like the normal Perl 5 convention.

There may be special syntax to separate class from object methods in
the future.

=head2 What about the return value?

Currently there is no support for declaring the type of the return
value.

=head2 How does this relate to Perl's built-in prototypes?

It doesn't.  Perl prototypes are a rather different beastie from
subroutine signatures.  They don't work on methods anyway.

A syntax for function prototypes is being considered.

    func($foo, $bar?) is proto($;$)

=head2 Error checking

Here's some additional checks I would like to add, mostly to avoid
ambiguous or non-sense situations.

* If one positional param is optional, everything to the right must be optional

    method foo($a, $b?, $c?)  # legal

    method bar($a, $b?, $c)   # illegal, ambiguous

Does C<< ->bar(1,2) >> mean $a = 1 and $b = 2 or $a = 1, $c = 3?

* Positionals are resolved before named params.  They have precedence.


=head2 Slurpy parameter restrictions

Slurpy parameters are currently more restricted than they need to be.
It is possible to work out a slurpy parameter in the middle, or a
named slurpy parameter.  However, there's lots of edge cases and
possible nonsense configurations.  Until that's worked out, we've left
it restricted.

=head2 What about...

Method traits are in the pondering stage.

An API to query a method's signature is in the pondering stage.

Now that we have method signatures, multi-methods are a distinct possibility.

Applying traits to all parameters as a short-hand?

    # Equivalent?
    method foo($a is ro, $b is ro, $c is ro)
    method foo($a, $b, $c) is ro

L<Role::Basic> roles are currently not recognized by the type system.

A "go really fast" switch.  Turn off all runtime checks that might
bite into performance.

Method traits.

    method add($left, $right) is predictable   # declarative
    method add($left, $right) is cached        # procedural
                                               # (and Perl 6 compatible)


=head1 THANKS

Most of this module is based on or copied from hard work done by many
other people.

All the really scary parts are copied from or rely on Matt Trout's,
Florian Ragwitz's and Rhesa Rozendaal's L<Devel::Declare> work.

The prototype syntax is a slight adaptation of all the
excellent work the Perl 6 folks have already done.

The type checking and method modifier work was supplied by Buddy
Burden (barefootcoder).  Thanks to this, you can now use
Method::Signatures (or, more properly,
L<Method::Signatures::Modifiers>) instead of
L<MooseX::Method::Signatures>, which fixes many of the problems
commonly attributed to L<MooseX::Declare>.

Value constraints and default conditions (i.e. "where" and "when")
were added by Damian Conway, who also rewrote some of the signature
parsing to make it more robust and more extensible.

Also thanks to Matthijs van Duin for his awesome L<Data::Alias> which
makes the C<\@foo> signature work perfectly and L<Sub::Name> which
makes the subroutine names come out right in caller().

And thanks to Florian Ragwitz for his parallel
L<MooseX::Method::Signatures> module from which I borrow ideas and
code.


=head1 LICENSE

The original code was taken from Matt S. Trout's tests for L<Devel::Declare>.

Copyright 2007-2011 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 SEE ALSO

L<MooseX::Method::Signatures> for an alternative implementation.

L<Perl6::Signature> for a more complete implementation of Perl 6 signatures.

L<Method::Signatures::Simple> for a more basic version of what Method::Signatures provides.

L<signatures> for C<sub> with signatures.

Perl 6 subroutine parameters and arguments -  L<http://perlcabal.org/syn/S06.html#Parameters_and_arguments>

L<Moose::Util::TypeConstraints> or L<Mouse::Util::TypeConstraints> for
further details on how the type-checking works.

=cut


1;
