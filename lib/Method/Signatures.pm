package Method::Signatures;

use strict;
use warnings;

use Lexical::SealRequireHints;
use base 'Devel::Declare::MethodInstaller::Simple';
use Method::Signatures::Utils;
use Method::Signatures::Parameter;
use Method::Signatures::Signature;

our $VERSION = '20170211';

our $DEBUG = $ENV{METHOD_SIGNATURES_DEBUG} || 0;

our $INF = ( 0 + "inf" ) == 0 ? 9e9999 : "inf";

# copied from Devel::Pragma
sub my_hints() {
    $^H |= 0x20000;
    return \%^H;
}


=head1 NAME

Method::Signatures - method and function declarations with signatures and no source filter

=for readme plugin version

=head1 SYNOPSIS

    package Foo;

    use Method::Signatures;

    method new (%args) {
        return bless {%args}, $self;
    }

=for readme stop 

    method get ($key) {
        return $self->{$key};
    }

    method set ($key, $val) {
        return $self->{$key} = $val;
    }

=for readme start

    # Can also get type checking if you like:

    method set (Str $key, Int $val) {
        return $self->{$key} = $val;        # now you know $val is always an integer
    }

=for readme stop

    func hello($greeting, $place) {
        print "$greeting, $place!\n";
    }

=for readme start

=head1 DESCRIPTION

Provides two new keywords, C<func> and C<method>, so that you can write
subroutines with signatures instead of having to spell out
C<my $self = shift; my($thing) = @_>

C<func> is like C<sub> but takes a signature where the prototype would
normally go.  This takes the place of C<my($foo, $bar) = @_> and does
a whole lot more.

C<method> is like C<func> but specifically for making methods.  It will
automatically provide the invocant as C<$self> (L<by default|/invocant>).
No more C<my $self = shift>.

=begin :readme

=head1 INSTALLATION 

This module sources are hosted on github 
https://github.com/evalEmpire/method-signatures.git 
and uses C<Module::Build> to generate the distribution. It can be 
istalled:

=over 

=item directly

 cpanm git://github.com/evalEmpire/method-signatures.git

=item from CPAN

 cpan Method::Signatures
 cpanm Method::Signatures

=item maualy cloninig the repository:

 git clone https://github.com/evalEmpire/method-signatures.git
 cd method-signatures
 perl Build.PL
 ./Build install 

=back
 
=for readme plugin requires

=end :readme

=for readme stop

Also allows signatures, very similar to Perl 6 signatures.

Also does type checking, understanding all the types that Moose (or Mouse)
would understand.

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

Every component except the parameter name (with sigil) is optional.

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

This feature requires L<Data::Alias> to be installed.



=head3 Invocant parameter

The method invocant (i.e. C<$self>) can be changed as the first
parameter on a per-method basis. Put a colon after it instead of a comma:

    method foo($class:) {
        $class->bar;
    }

    method stuff($class: $arg, $another) {
        $class->things($arg, $another);
    }

C<method> has an implied default invocant of C<$self:>, though that is
configurable by setting the L<invocant parameter|/invocant> on the
C<use Method::Signatures> line.

C<func> has no invocant, as it is intended for creating subs that will not
be invoked on an object.


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
Passing in C<undef> will override the default.  That means ...

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
intended to indicate: "use the default instead."

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


=head3 Placeholder parameters

A positional argument can be ignored by using a bare C<$> sigil as its name.

    method foo( $a, $, $c ) {
        ...
    }

The argument's value doesn't get stored in a variable, but the caller must
still supply it.  Value and type constraints can be applied to placeholders.

    method bar( Int $ where { $_ < 10 } ) {
        ...
    }


=head3 Parameter traits

Each parameter can be assigned a trait with the C<$arg is TRAIT> syntax.

    method stuff($this is ro) {
        ...
    }

Any unknown trait is ignored.

Most parameters have a default traits of C<is rw is copy>.

=over 4

=item B<ro>

Read-only.  Assigning or modifying the parameter is an error.  This trait
requires L<Const::Fast> to be installed.

=item B<rw>

Read-write.  It's ok to read or write the parameter.

This is a default trait.

=item B<copy>

The parameter will be a copy of the argument (just like C<< my $arg = shift >>).

This is a default trait except for the C<\@foo> parameter (see L<Aliased references>).

=item B<alias>

The parameter will be an alias of the argument.  Any changes to the
parameter will be reflected in the caller.  This trait requires
L<Data::Alias> to be installed.

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
    $tree->traverse( func($node, ...) { $node->print } );

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

The bare C<@> sigil is a synonym for C<...>.  A bare C<%> sigil is also a
synonym for C<...>, but requires that there must be an even number of extra
arguments, such as would be assigned to a hash.


=head3 Required and optional parameters

Parameters declared using C<$arg!> are explicitly I<required>.
Parameters declared using C<$arg?> are explicitly I<optional>.  These
declarations override all other considerations.

A parameter is implicitly I<optional> if it is a named parameter, has a
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

Note that a signature of C<(@_)> is exactly equivalent to a signature
of C<(...)>.  See L<"The yada yada marker">.


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

=head3 invocant

In some cases it is desirable for the invocant to be named something other
than C<$self>, and specifying it in the signature of every method is tedious
and prone to human-error. When this option is set, methods that do not specify
the invocant variable in their signatures will use the given variable name.

    use Method::Signatures { invocant => '$app' };

    method main { $app->config; $app->run; $app->cleanup; }

Note that the leading sigil I<must> be provided, and the value must be a single
token that would be valid as a perl variable. Currently only scalar invocant
variables are supported (eg, the sigil must be a C<$>).

This option only affects the packages in which it is used. All others will
continue to use C<$self> as the default invocant variable.

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

    # default invocant var - end-user can change with 'invocant' option.
    my $inv_var = '$self';

    my $hints = my_hints;
    $hints->{METHOD_SIGNATURES_compile_at_BEGIN} = 1;  # default to on

    my $arg = shift;
    if (defined $arg) {
        if (ref $arg) {
            $DEBUG  = $arg->{debug}     if exists $arg->{debug};
            $caller = $arg->{into}      if exists $arg->{into};
            $hints->{METHOD_SIGNATURES_compile_at_BEGIN} = $arg->{compile_at_BEGIN}
                                        if exists $arg->{compile_at_BEGIN};
            if (exists $arg->{invocant}) {
                $inv_var = $arg->{invocant};
                # ensure (for now) the specified value is a valid variable
                # name (with '$' sigil) and nothing more.
                if ($inv_var !~ m{ \A \$ [^\W\d]\w* \z }x) {
                    require Carp;
                    Carp::croak("Invalid invocant name: '$inv_var'");
                }
            }
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
        invocant        => $inv_var,
    );

    $class->install_methodhandler(
        into            => $caller,
        name            => 'func',
    );

    DEBUG("import for $caller done\n");
    DEBUG("method invocant is '$inv_var'\n");
}


# Inject special code to make named functions compile at BEGIN time.
# Otherwise we leave injection to Devel::Declare.
sub inject_if_block
{
    my ($self, $inject, $before) = @_;

    my $name  = $self->{function_name};
    my $attrs = $self->{attributes} || '';

    DEBUG( "attributes: $attrs\n" );

    # Named function compiled at BEGIN time
    if( defined $name && $self->_do_compile_at_BEGIN ) {
        # Devel::Declare needs the code ref which has been generated.
        # Fortunately, "sub foo {...}" happens at compile time, so we
        # can use \&foo at runtime even if it comes before the sub
        # declaration in the code!
        $before = qq[\\&$name; sub $name $attrs ];
    }

    DEBUG( "inject: $inject\n" );
    DEBUG( "before: $before\n" );
    DEBUG( "linestr before: ".$self->get_linestr."\n" ) if $DEBUG;
    my $ret = $self->SUPER::inject_if_block($inject, $before);
    DEBUG( "linestr after: ". $self->get_linestr."\n" ) if $DEBUG;

    return $ret;
}


# Check if compile_at_BEGIN is set in this scope.
sub _do_compile_at_BEGIN {
    my $hints = my_hints;

    # Default to on.
    return 1 if !exists $hints->{METHOD_SIGNATURES_compile_at_BEGIN};

    return $hints->{METHOD_SIGNATURES_compile_at_BEGIN};
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


# Largely copied from Devel::Declare::MethodInstaller::Simple::parser()
# The original expects things in this order:
# <keyword> name ($$@) :attr1 :attr2 {
# * name
# * prototype
# * attributes
# * an open brace
# We want to support the prototype coming after the attributes as well as before,
# but D::D::strip_attrs() looks for the open brace, and gets into an endless
# loop if it doesn't find one.  Meanwhile, D::D::strip_proto() doesn't find anything
# if the attributes are before the prototype.
sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;
    my $name   = $self->strip_name;

    my $linestr = Devel::Declare::get_linestr;

    my($proto, $attrs);
    my($char) = $linestr =~ m/(\(|:)/;
    if (defined($char) and $char eq '(') {
        $proto = $self->strip_proto;
        $attrs = $self->strip_attrs;
    } else {
        $attrs = $self->strip_attrs;
        $proto = $self->strip_proto;
    }

    my @decl   = $self->parse_proto($proto);
    my $inject = $self->inject_parsed_proto(@decl);
    if (defined $name) {
        $inject = $self->scope_injector_call() . $inject;
    }
    $self->inject_if_block($inject, $attrs ? "sub ${attrs} " : '');

    $self->install( $name );

    return;
}


# Capture the function name
sub strip_name {
    my $self = shift;

    my $name = $self->SUPER::strip_name(@_);
    $self->{function_name} = $name;

    return $name;
}


# Capture the attributes
# A copy of the method of the same name from Devel::Declare::Context::Simple::strip_attrs()
# The only change is that the while() loop now terminates if it finds an open brace _or_
# open paren.  This is necessary to allow the function signature to come after the attributes.
sub strip_attrs {
    my $self = shift;

    $self->skipspace;

    my $linestr = Devel::Declare::get_linestr;
    my $attrs   = '';

    if (substr($linestr, $self->offset, 1) eq ':') {
        while (substr($linestr, $self->offset, 1) ne '{'
               and substr($linestr, $self->offset, 1) ne '('
        ) {
            if (substr($linestr, $self->offset, 1) eq ':') {
                substr($linestr, $self->offset, 1) = '';
                Devel::Declare::set_linestr($linestr);

                $attrs .= ':';
            }

            $self->skipspace;
            $linestr = Devel::Declare::get_linestr();

            if (my $len = Devel::Declare::toke_scan_word($self->offset, 0)) {
                my $name = substr($linestr, $self->offset, $len);
                substr($linestr, $self->offset, $len) = '';
                Devel::Declare::set_linestr($linestr);

                $attrs .= " ${name}";

                if (substr($linestr, $self->offset, 1) eq '(') {
                    my $length = Devel::Declare::toke_scan_str($self->offset);
                    my $arg    = Devel::Declare::get_lex_stuff();
                    Devel::Declare::clear_lex_stuff();
                    $linestr = Devel::Declare::get_linestr();
                    substr($linestr, $self->offset, $length) = '';
                    Devel::Declare::set_linestr($linestr);

                    $attrs .= "(${arg})";
                }
            }
        }

        $linestr = Devel::Declare::get_linestr();
    }

    $self->{attributes} = $attrs;

    return $attrs;
}


# Overriden method from D::D::MS
sub parse_proto {
    my $self = shift;
    my $proto = shift;

    # Before we try to compile signatures, make sure there isn't a hidden compilation error.
    die $@ if _parser_is_fucked;

    $self->{signature} = Method::Signatures::Signature->new(
        signature_string        => defined $proto ? $proto : "",
        invocant                => $self->{invocant},
        pre_invocant            => $self->{pre_invocant}
    );

    # Then turn it into Perl code
    my $inject = $self->inject_from_signature();

    return $inject;
}


# Turn the parsed signature into Perl code
sub inject_from_signature {
    my $self      = shift;
    my $class     = ref $self || $self;
    my $signature = $self->{signature};

    $self->{line_number} = 1;

    my @code;
    push @code, "my @{[$signature->pre_invocant]} = shift;" if $signature->pre_invocant;
    push @code, "my @{[$signature->invocant]} = shift;"     if $signature->invocant;

    for my $sig (@{$signature->positional_parameters}) {
        push @code, $self->inject_for_sig($sig);
    }

    if( @{$signature->named_parameters} ) {
        my $first_named_idx = @{$signature->positional_parameters};
        if (grep { $_->is_ref_alias or $_->traits->{alias} } @{$signature->named_parameters})
        {
            require Data::Alias;
            push @code, "Data::Alias::alias( my (\%args) = \@_[$first_named_idx..\$#_] );";
        }
        else
        {
            push @code, "my (\%args) = \@_[$first_named_idx..\$#_];";
        }

        for my $sig (@{$signature->named_parameters}) {
            push @code, $self->inject_for_sig($sig);
        }

        push @code, $class . '->named_param_error(\%args) if keys %args;'
            if $signature->num_named && !$signature->num_yadayada;
    }

    my $max_argv = $signature->max_argv_size;
    my $max_args = $signature->max_args;
    push @code, qq[$class->too_many_args_error($max_args) if scalar(\@_) > $max_argv; ]
        unless $max_argv == $INF;

    # Add any additional trailing newlines so the body is on the right line.
    push @code, $self->inject_newlines( $signature->num_lines - $self->{line_number} );

    # All on one line.
    return join ' ', @code;
}


sub too_many_args_error {
    my($class, $max_args) = @_;

    $class->signature_error("was given too many arguments; it expects $max_args");
}


sub odd_number_args_error {
    my($class) = @_;

    $class->signature_error('was given an odd number of arguments for a placeholder hash');
}


sub named_param_error {
    my ($class, $args) = @_;
    my @keys = keys %$args;

    $class->signature_error("does not take @keys as named argument(s)");
}

# Regex to determine if a where clause is a block.
my $when_block_re = qr{
    ^
    \s*
    \{
      (?:
          .* ; .*         |     # statements separated by semicolons
          (?:(?! => ). )+       # doesn't look like a hash with fat commas
      )
    \}
    \s*
    $
}xs;

sub inject_for_sig {
    my $self = shift;
    my $class = ref $self || $self;
    my $sig = shift;

    return if $sig->is_at_underscore;

    my @code;

    # Add any necessary leading newlines so line numbers are preserved.
    push @code, $self->inject_newlines($sig->first_line_number - $self->{line_number});

    if( $sig->is_hash_yadayada ) {
        my $is_odd = $sig->position % 2;
        push @code, qq[$class->odd_number_args_error() if scalar(\@_) % 2 != $is_odd;];
        return @code;
    }

    my $sigil = $sig->sigil;
    my $name  = $sig->variable_name;
    my $idx   = $sig->position;
    my $var   = $sig->variable;

    # These are the defaults.
    my $lhs = "my $var";
    my ($rhs, $deletion_target);

    if( $sig->is_named ) {
        $sig->passed_in("\$args{$name}");
        $rhs = $deletion_target = $sig->passed_in;
        $rhs = "${sigil}{$rhs}" if $sig->is_ref_alias;
    }
    else {
        $rhs = $sig->is_ref_alias       ? "${sigil}{\$_[$idx]}" :
               $sig->sigil =~ /^[@%]$/  ? "\@_[$idx..\$#_]"     :
                                          "\$_[$idx]"           ;
        $sig->passed_in($rhs);
    }

    my $check_exists = $sig->is_named ? "exists \$args{$name}" : "( scalar(\@_) > $idx)";
    $sig->check_exists($check_exists);

    my $default = $sig->default;
    my $when    = $sig->default_when;

    # Handle a default value
    if( defined $when ) {
        # Handle default with 'when { block using $_ }'
        if ($when =~ $when_block_re) {
            $rhs = "!$check_exists ? ($default) : do{ no warnings; my \$arg = $rhs; (grep $when \$arg) ? ($default) : \$arg}";
        }

        # Handle default with 'when anything_else'
        else {
            $rhs = "!$check_exists ? ($default) : do{ no warnings; my \$arg = $rhs; \$arg ~~ ($when) ? ($default) : \$arg }";
        }
    }
    # Handle simple defaults
    elsif( defined $default ) {
        $rhs = "$check_exists ? ($rhs) : ($default)";
    }

    if( $sig->is_required ) {
        if( $sig->is_placeholder ) {
            push @code, qq[${class}->required_placeholder_arg('$idx') unless $check_exists; ];
        } else {
            push @code, qq[${class}->required_arg('$var') unless $check_exists; ];
        }
    }

    # Handle \@foo
    if ( $sig->is_ref_alias or $sig->traits->{alias} ) {
        require Data::Alias;
        push @code, sprintf 'Data::Alias::alias(%s = %s);', $lhs, $rhs;
    }
    # Handle "is ro"
    elsif ( $sig->traits->{ro} ) {
        require Const::Fast;
        push @code, "Const::Fast::const( $lhs => $rhs );";
    } else {
        push @code, "$lhs = $rhs;";
    }

    if( $sig->type ) {
        push @code, $self->inject_for_type_check($sig);
    }

    # Named arg has been handled, so don't pass to error handler
    push @code, "delete( $deletion_target );" if $deletion_target;

    # Handle 'where' constraints (after defaults are resolved)
    for my $constraint ( @{$sig->where} ) {
        # Handle 'where { block using $_ }'
        my $constraint_impl =
          $constraint =~ m{^ \s* \{ (?: .* ; .* | (?:(?! => ). )* ) \} \s* $}xs
                ? "sub $constraint"
                : $constraint;

        my( $error_reporter, $var_name ) =
            $sig->is_placeholder
                ? ( 'placeholder_where_error',  $sig->position )
                : ( 'where_error',              $var );
        my $error = sprintf q{ %s->%s(%s, '%s', '%s') }, $class, $error_reporter, $var, $var_name, $constraint;
		push @code, "$error unless do { no if \$] >= 5.017011, warnings => 'experimental::smartmatch'; grep { \$_ ~~ $constraint_impl } $var }; ";
    }

    if( $sig->is_placeholder ) {
        unshift @code, 'do {';
        push @code, '};';
    }

    # Record the current line number for the next injection.
    $self->{line_number} = $sig->first_line_number;

    return @code;
}

sub __magic_newline() { die "newline() should never be called"; }

# Devel::Declare cannot normally inject multiple lines.
# This is a way to trick it, the parser will continue through
# a function call with a newline in the argument list.
sub inject_newlines {
    my $self = shift;
    my $num_newlines = shift;

    return if $num_newlines == 0;

    return sprintf q[ Method::Signatures::__magic_newline(%s) if 0; ],
                   "\n" x $num_newlines;
}


# A hook for extension authors
# (see also type_check below)
sub inject_for_type_check
{
    my $self = shift;
    my $class = ref $self || $self;
    my ($sig) = @_;

    my $check_exists = $sig->is_optional && !defined $sig->default
      ? $sig->check_exists : '';

    # This is an optimization to unroll typecheck which makes Mouse types about 40% faster.
    # It only happens when type_check() has not been overridden.
    if( $class->can("type_check") eq __PACKAGE__->can("type_check") ) {
        my $check = sprintf q[($%s::mutc{cache}{'%s'} ||= %s->_make_constraint('%s'))->check(%s)],
          __PACKAGE__, $sig->type, $class, $sig->type, $sig->variable;

        my( $error_reporter, $variable_name ) =
            $sig->is_placeholder
                ? ( 'placeholder_type_error',   $sig->position )
                : ( 'type_error',               $sig->variable_name );
        my $error = sprintf q[%s->%s('%s', %s, '%s') ],
          $class, $error_reporter, $sig->type, $sig->variable, $variable_name;
        my $code = "$error if ";
        $code .= "$check_exists && " if $check_exists;
        $code .= "!$check";
        return "$code;";
    }
    # If a subclass has overridden type_check(), we must use that.
    else {
        my $name = $sig->variable_name;
        my $code = "${class}->type_check('@{[$sig->type]}', @{[$sig->passed_in]}, '$name')";
        $code .= "if $check_exists" if $check_exists;
        return "$code;";
    }
}

# This class method just dies with the message generated by signature_error.
# If necessary it can be overridden by a subclass to do something fancier.
#
sub signature_error_handler {
    my ($class, $msg) = @_;
    die $msg;
}

# This is a common function to throw errors so that they appear to be from the point of the calling
# sub, not any of the Method::Signatures subs.
sub signature_error {
    my ($proto, $msg) = @_;
    my $class = ref $proto || $proto;

    my ($file, $line, $method) = carp_location_for($class);
    $class->signature_error_handler("In call to $method(), $msg at $file line $line.\n");
}

sub required_arg {
    my ($class, $var) = @_;

    $class->signature_error("missing required argument $var");
}


sub required_placeholder_arg {
    my ($class, $idx) = @_;

    $class->signature_error("missing required placeholder argument at position $idx");
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

sub placeholder_type_error
{
    my ($class, $type, $value, $idx) = @_;
    $value = defined $value ? qq{"$value"} : 'undef';
    $class->signature_error(qq{the placeholder parameter at position $idx ($value) is not of type $type});
}

# Errors from `where' constraints are handled here.
sub where_error
{
    my ($class, $value, $name, $constraint) = @_;
    $value = defined $value ? qq{"$value"} : 'undef';
    $class->signature_error(qq{$name value ($value) does not satisfy constraint: $constraint});
}

sub placeholder_where_error
{
    my ($class, $value, $idx, $constraint) = @_;
    $value = defined $value ? qq{"$value"} : 'undef';
    $class->signature_error(qq{the placeholder parameter at position $idx value ($value) does not satisfy constraint: $constraint});
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

This is a class method which calls C<signature_error_handler> (see
below) and reports the error as being from the caller's perspective.
Most likely you will not need to override this.  If you'd like to have
Method::Signatures errors give full stack traces (similar to
C<$Carp::Verbose>), have a look at L<Carp::Always>.

=head2 signature_error_handler

By default, C<signature_error> generates an error message and
C<die>s with that message.  If you need to do something fancier with
the generated error message, your subclass can define its own
C<signature_error_handler>.  For example:

    package My::Method::Signatures;

    use Moose;
    extends 'Method::Signatures';

    sub signature_error_handler {
        my ($class, $msg) = @_;
        die bless { message => $msg }, 'My::ExceptionClass';
    };

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

=head2 Close parends in quotes or comments

Because of the way L<Devel::Declare> parses things, an unbalanced
close parend inside a quote or comment could throw off the signature
parsing.  For instance:

    func foo (
        $foo,       # $foo might contain )
        $bar
    )

is going to produce a syntax error, because the parend inside the
comment is perceived as the end of the signature.  On the other hand,
this:

    func foo (
        $foo,       # (this is the $foo parend)
        $bar
    )

is fine, because the parends in the comments are balanced.

If you absolutely can't avoid an unbalanced close parend, such as in
the following signature:

    func foo ( $foo, $bar = ")" )       # this won't parse correctly

you can always use a backslash to tell the parser that that close
parend doesn't indicate the end of the signature:

    func foo ( $foo, $bar = "\)" )      # this is fine

This even works in single quotes:

    func foo ( $foo, $bar = '\)' )      # default is ')', *not* '\)'!

although we don't recomment that form, as it may be surprising to
readers of your code.

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

We recommend you use the L<"compile_at_BEGIN"> flag to turn off
compile-time parsing.

You can't use any feature that requires a smartmatch expression (i.e.
conditional L<"Defaults"> and L<"Value Constraints">) in Perl 5.8.

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

Copyright 2007-2012 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 SEE ALSO

L<MooseX::Method::Signatures> for an alternative implementation.

L<Perl6::Signature> for a more complete implementation of Perl 6 signatures.

L<Method::Signatures::Simple> for a more basic version of what Method::Signatures provides.

L<Function::Parameters> for a subset of Method::Signature's features without using L<Devel::Declare>.

L<signatures> for C<sub> with signatures.

Perl 6 subroutine parameters and arguments -  L<http://perlcabal.org/syn/S06.html#Parameters_and_arguments>

L<Moose::Util::TypeConstraints> or L<Mouse::Util::TypeConstraints> for
further details on how the type-checking works.

=cut


1;
