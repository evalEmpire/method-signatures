package Method::Signatures;

use strict;
use warnings;

use base 'Devel::Declare::MethodInstaller::Simple';
use Method::Signatures::Parser;
use Data::Alias;

our $VERSION = '20110324.1600_001';

our $DEBUG = $ENV{METHOD_SIGNATURES_DEBUG} || 0;

# set up some regexen using for parsing types
my $TYPENAME =      qr{   [a-z] \w* (?: \:\: \w+)*                                               }ix;
my $PARAMETERIZED = qr{   \w+ \[ $TYPENAME \]                                                    }x;
my $DISJUNCTION =   qr{   (?: $TYPENAME | $PARAMETERIZED ) \| (?: $TYPENAME | $PARAMETERIZED )   }x;

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
        return $self->{$key} = $val;        # now you know $key is always an integer
    }

    func hello($greeting, $place) {
        print "$greeting, $place!\n";
    }

    # Or, to install into another package (e.g. when bunding pragmas):

    use Method::Signatures { into => 'Some::Other::Package' };

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


=head3 C<@_>

Other than removing C<$self>, C<@_> is left intact.  You are free to
use C<@_> alongside the arguments provided by Method::Signatures.


=head3 Named parameters

Parameters can be passed in named, as a hash, using the C<:$arg> syntax.

    method foo(:$arg) {
        ...
    }

    Class->foo( arg => 42 );

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


=head3 Invocant parameter

The method invocant (i.e. C<$self>) can be changed as the first
parameter.  Put a colon after it instead of a comma.

    method foo($class:) {
        $class->bar;
    }

    method stuff($class: $arg, $another) {
        $class->things($arg, $another);
    }

Signatures have an implied default of C<$self:>.


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

Defaults will only be used if the argument is not passed in at all.
Passing in C<undef> will override the default.  That means...

    Class->add();            # $this = 23, $that = 42
    Class->add(99);          # $this = 99, $that = 42
    Class->add(99, undef);   # $this = 99, $that = undef

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

The parameter will be a copy of the argument (just like C<<my $arg = shift>>).

This is a default trait except for the C<\@foo> parameter.

=item B<alias>

The parameter will be an alias of the argument.  Any changes to the
parameter will be reflected in the caller.

This is a default trait for the C<\@foo> parameter.

=back

=head3 Traits and defaults

To have a parameter which has both a trait and a default, set the
trait first and the default second.

    method echo($message is ro = "what?") {
        return $message
    }

Think of it as C<$message is ro> being the left-hand side of the assignment.


=head3 Required and optional parameters

Parameters declared using C<$arg!> are explicitly I<required>.
Parameters declared using C<$arg?> are explicitly I<optional>.  These
declarations override all other considerations.

A parameter is implictly I<optional> if it is a named parameter, or it
has a default.  All other parameters are implicitly I<required>.

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

    my $arg = shift;
    if (defined $arg) {
        if (ref $arg) {
            $DEBUG  = $arg->{debug}  if exists $arg->{debug};
            $caller = $arg->{into}   if exists $arg->{into};
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


sub code_for {
    my($self, $name) = @_;

    my $code = $self->SUPER::code_for($name);

    if( defined $name ) {
        require Devel::BeginLift;
        Devel::BeginLift->setup_for_cv($code);
    }

    return $code;
}


sub _strip_ws {
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
}


# Overriden method from D::D::MS
sub parse_proto {
    my $self = shift;
    return $self->parse_signature( proto => shift, invocant => $self->{invocant} );
}


# Parse a signature
sub parse_signature {
    my $self = shift;
    my %args = @_;
    my @protos = $self->_split_proto($args{proto} || []);
    my $signature = $args{signature} || {};

    # Special case for methods, they will pass in an invocant to use as the default
    if( $signature->{invocant} = $args{invocant} ) {
        if( @protos ) {
            $signature->{invocant} = $1 if $protos[0] =~ s{^ ([^:\s]+) : (?! :) \s* }{}x;
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

        my $sig   = {};
        $sig->{proto} = $proto;

        # $TYPENAME, $PARAMETERIZED, and $DISJUNCTION defined up at top, for performance reasons
        $sig->{type} = $1 if $proto =~ s{^ ($TYPENAME | $PARAMETERIZED | $DISJUNCTION) \s+ }{}iox;

        $sig->{named} = $proto =~ s{^:}{};

        if( !$sig->{named} ) {
            $sig->{idx} = $idx;
            $idx++;
        }

        $sig->{is_at_underscore}    = $proto eq '@_';
        $sig->{is_ref_alias}        = $proto =~ s{^\\}{};

        while ($proto =~ s{ \s+ is \s+ (\S+) }{}x) {
            $sig->{traits}{$1}++;
        }
        $sig->{default} = $1 if $proto =~ s{ \s* = \s* (.*) }{}x;

        my($sigil, $name) = $proto =~ m{^ (.)(.*) }x;
        $sig->{is_optional} = ($name =~ s{\?$}{} or exists $sig->{default} or $sig->{named});
        $sig->{is_optional} = 0 if $name =~ s{\!$}{};
        $sig->{sigil}       = $sigil;
        $sig->{name}        = $name;
        $sig->{var}         = $sigil . $name;
        $sig->{is_slurpy}   = ($sigil =~ /^[%@]$/ and !$sig->{is_ref_alias});

        check_signature($sig, $signature);

        if( $sig->{named} ) {
            push @{$signature->{named}}, $sig;
        }
        else {
            push @{$signature->{positional}}, $sig;
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

    # Then turn it into Perl code
    my $inject = $self->inject_from_signature($signature);
    DEBUG( "inject: $inject\n" );
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


sub check_signature {
    my($sig, $signature) = @_;

    die("signature can only have one slurpy parameter") if
      $sig->{is_slurpy} and $signature->{overall}{num_slurpy} >= 1;

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


# Turn the parsed signature into Perl code
sub inject_from_signature {
    my $self      = shift;
    my $signature = shift;

    my @code;
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

        push @code, 'Method::Signatures::named_param_error(\%args) if %args;' if $signature->{overall}{num_named};
    }

    my $max_argv = $signature->{overall}{max_argv_size};
    my $max_args = $signature->{overall}{max_args};
    push @code, qq[Method::Signatures::too_many_args_error($max_args) if \@_ > $max_argv; ]
        unless $max_argv == "inf";

    # All on one line.
    return join ' ', @code;
}


sub too_many_args_error {
    my($max_args) = @_;

    signature_error("was given too many arguments, it expects $max_args");
}


sub named_param_error {
    my $args = shift;
    my @keys = keys %$args;

    signature_error("does not take @keys as named argument(s)");
}


sub inject_for_sig {
    my $self = shift;
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
        $rhs = "delete \$args{$sig->{name}}";
    }
    else {
        $rhs = $sig->{is_ref_alias}       ? "${sigil}{\$_[$idx]}" :
               $sig->{sigil} =~ /^[@%]$/  ? "\@_[$idx..\$#_]"     :
                                            "\$_[$idx]"           ;
    }

    my $check_exists = $sig->{named} ? "exists \$args{$sig->{name}}" : "(\@_ > $idx)";
    # Handle a default value
    if( defined $sig->{default} ) {
        $rhs = "$check_exists ? ($rhs) : ($sig->{default})";
    }

    if( !$sig->{is_optional} ) {
        push @code, qq[Method::Signatures::required_arg('$sig->{var}') unless $check_exists; ];
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

    if( $sig->{type} ) {
        push @code, $self->inject_for_type_check($sig);
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

    return "${class}->type_check('$sig->{type}', $sig->{var}, '$sig->{name}');";
}

sub signature_error {
    my $msg = shift;
    my $height = shift || 1;

    my($pack, $file, $line, $method) = caller($height + 1);
    die "$method() $msg at $file line $line.\n";
}

sub required_arg {
    my $var = shift;

    signature_error("missing required argument $var");
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
my %mutc;

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
    my ($type) = @_;

    _init_mutc() unless $mutc{class};

    # Look for basic types (Int, Str, Bool, etc).  This will also create a new constraint for any
    # parameterized types (e.g. ArrayRef[Int]) or any disjunctions (e.g. Int|ScalarRef[Int]).
    my $constr = eval { $mutc{findit}->($type) };
    if ($@)
    {
        _type_error("the type $type is unrecognized (looks like it doesn't parse correctly)");
    }
    return $constr if $constr;

    # Check for roles.  Note that you *must* check for roles before you check for classes, because a
    # role ISA class.
    return $mutc{make_role}->($type) if $mutc{isa_role}->check($type);

    # Now check for classes.
    return $mutc{make_class}->($type) if $mutc{isa_class}->check($type);

    _type_error("the type $type is unrecognized (perhaps you forgot to load it?)");
}

# This is a helper function to throw errors from type checking so that they appear to be from the
# point of the calling sub, not any of the Method::Signatures subs.
sub _type_error
{
    my ($msg) = @_;

    my $caller;
    my $pkg = __PACKAGE__;
    my $level = 1;
    do {
        $caller = (caller($level++))[3];
    } while $caller =~ /^$pkg/;

    require Carp;
    local $Carp::CarpLevel = 1;
    Carp::croak "In call to $caller : $msg";
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
    $mutc{cache}->{$type} ||= _make_constraint($type);

    # throw an error if the type check fails
    unless ($mutc{cache}->{$type}->check($value))
    {
        $value = defined $value ? qq{"$value"} : 'undef';
        _type_error(qq{the '$name' parameter ($value) is not of type $type});
    }

    # $mutc{cache} = {};
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

If you want to experiment with the prototype syntax, replace
C<Method::Signatures::make_proto_unwrap>.  It takes a method prototype
and returns a string of Perl 5 code which will be placed at the
beginning of that method.

If you would like to try to provide your own type checking, subclass
L<Method::Signatures> and either override C<type_check> or
C<inject_for_type_check>.  The former is probably fine for most
applications; you might need the latter if you want to modify what
parameters are passed into the type checking method.

This interface is experimental, unstable and will change between
versions.


=head1 BUGS, CAVEATS and NOTES

Please report bugs and leave feedback at
E<lt>bug-Method-SignaturesE<gt> at E<lt>rt.cpan.orgE<gt>.  Or use the
web interface at L<http://rt.cpan.org>.  Report early, report often.

=head2 Debugging

You can see the Perl code Method::Signatures translates to by using B::Deparse.

=head2 One liners

If you want to write "use Method::Signatures" in a one-liner, do a
C<-MMethod::Signatures> first.  This is due to a bug/limitation in
Devel::Declare.

=head2 No source filter

While this module does rely on the black magic of L<Devel::Declare> to
access Perl's own parser, it does not depend on a source filter.  As
such, it doesn't try to parse and rewrite your source code and there
should be no weird side effects.

Devel::Declare only effects compilation.  After that, it's a normal
subroutine.  As such, for all that hairy magic, this module is
surprisingly stable.

=head2 What about regular subroutines?

L<Devel::Declare> cannot yet change the way C<sub> behaves.  It's
being worked on and when it works I'll release another module unifying
method and sub.

I might release something using C<func>.

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

There currently is very little checking done on the prototype syntax.
Here's some basic checks I would like to add, mostly to avoid
ambiguous or non-sense situations.

* If one positional param is optional, everything to the right must be optional

    method foo($a, $b?, $c?)  # legal

    method bar($a, $b?, $c)   # illegal, ambiguous

Does C<<->bar(1,2)>> mean $a = 1 and $b = 2 or $a = 1, $c = 3?

* If you're have named parameters, all your positional params must be required.

    method foo($a, $b, :$c);    # legal
    method bar($a?, $b?, :$c);   # illegal, ambiguous

Does C<<->bar(c => 42)>> mean $a = 'c', $b = 42 or just $c = 42?

* Positionals are resolved before named params.  They have precedence.


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

Also thanks to Matthijs van Duin for his awesome L<Data::Alias> which
makes the C<\@foo> signature work perfectly and L<Sub::Name> which
makes the subroutine names come out right in caller().

And thanks to Florian Ragwitz for his parallel
L<MooseX::Method::Signatures> module from which I borrow ideas and
code and L<Devel::BeginLift> which lets the methods be declared
at compile time.


=head1 LICENSE

The original code was taken from Matt S. Trout's tests for L<Devel::Declare>.

Copyright 2007-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 SEE ALSO

L<MooseX::Method::Signatures> for a method keyword that also works with Moose.

L<Perl6::Signature> for a more complete implementation of Perl 6 signatures.

L<Method::Signatures::Simple> for a more basic version of what Method::Signatures provides.

L<signatures> for C<sub> with signatures.

Perl 6 subroutine parameters and arguments -  L<http://perlcabal.org/syn/S06.html#Parameters_and_arguments>

L<Moose::Util::TypeConstraints> or L<Mouse::Util::TypeConstraints> for
further details on how the type-checking works.

=cut


1;
