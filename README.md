# NAME

Method::Signatures - method and function declarations with signatures and no source filter

# SYNOPSIS

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

# DESCRIPTION

Provides two new keywords, `func` and `method`, so that you can write
subroutines with signatures instead of having to spell out
`my $self = shift; my($thing) = @_`

`func` is like `sub` but takes a signature where the prototype would
normally go.  This takes the place of `my($foo, $bar) = @_` and does
a whole lot more.

`method` is like `func` but specifically for making methods.  It will
automatically provide the invocant as `$self` ([by default](#invocant)).
No more `my $self = shift`.

Also allows signatures, very similar to Perl 6 signatures.

Also does type checking, understanding all the types that Moose (or Mouse)
would understand.

And it does all this with **no source filters**.

## Signature syntax

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

`$SM_EXPR` is any expression that is valid as the RHS of a smartmatch,
or else a raw block of code. See ["Value constraints"](#value-constraints).

`$AS_EXPR` is any expression that is valid as the RHS of an
assignment operator. See ["Defaults"](#defaults).

### `@_`

Other than removing `$self`, `@_` is left intact.  You are free to
use `@_` alongside the arguments provided by Method::Signatures.

### Named parameters

Parameters can be passed in named, as a hash, using the `:$arg` syntax.

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

### Aliased references

A signature of `\@arg` will take an array reference but allow it to
be used as `@arg` inside the method.  `@arg` is an alias to the
original reference.  Any changes to `@arg` will affect the original
reference.

    package Stuff;
    method add_one(\@foo) {
        $_++ for @foo;
    }

    my @bar = (1,2,3);
    Stuff->add_one(\@bar);  # @bar is now (2,3,4)

This feature requires [Data::Alias](https://metacpan.org/pod/Data::Alias) to be installed.

### Invocant parameter

The method invocant (i.e. `$self`) can be changed as the first
parameter on a per-method basis. Put a colon after it instead of a comma:

    method foo($class:) {
        $class->bar;
    }

    method stuff($class: $arg, $another) {
        $class->things($arg, $another);
    }

`method` has an implied default invocant of `$self:`, though that is
configurable by setting the [invocant parameter](#invocant) on the
`use Method::Signatures` line.

`func` has no invocant, as it is intended for creating subs that will not
be invoked on an object.

### Defaults

Each parameter can be given a default with the `$arg = EXPR` syntax.
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
Passing in `undef` will override the default.  That means ...

    Class->add();            # $this = 23, $that = 42
    Class->add(99);          # $this = 99, $that = 42
    Class->add(99, undef);   # $this = 99, $that = undef

However, you can specify additional conditions under which a default is
also to be used, using a trailing `when`. For example:

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

In other words, if you include a `when _value_` after the default,
the default is still used if the argument is missing, but is also
used if the argument is provided but smart-matches the specified _value_.

Note that the final two examples above use anonymous subroutines to
conform their complex tests to the requirements of the smartmatch
operator. Because this is useful, but syntactically clumsy, there is
also a short-cut for this behaviour. If the test after `when` consists
of a block, the block is executed as the defaulting test, with the
actual argument value aliased to `$_` (just like in a `grep` block).
So the final two examples above could also be written:

    # Use default if no argument passed OR argument is zero or less
    method get_results($how_many = 1 when {$_ <= 0}) {...}

    # Use default if no argument passed OR argument is invalid
    method get_results($how_many = 1 when {!valid($_)}) } {...}

The most commonly used form of `when` modifier is almost
certainly `when undef`:

    # Use default if no argument passed OR argument is undef
    method get_results($how_many = 1 when undef) {...}

which covers the common case where an uninitialized variable is passed
as an argument, or where supplying an explicit undefined value is
intended to indicate: "use the default instead."

This usage is sufficiently common that a short-cut is provided:
using the `//=` operator (instead of the regular assignment operator)
to specify the default. Like so:

    # Use default if no argument passed OR argument is undef
    method get_results($how_many //= 1) {...}

Earlier parameters may be used in later defaults.

    method copy_cat($this, $that = $this) {
        return $that;
    }

Any variable that has a default is considered optional.

### Type Constraints

Parameters can also be given type constraints.  If they are, the value
passed in will be validated against the type constraint provided.
Types are provided by [Any::Moose](https://metacpan.org/pod/Any::Moose) which will load [Mouse](https://metacpan.org/pod/Mouse) if
[Moose](https://metacpan.org/pod/Moose) is not already loaded.

Type constraints can be a type, a role or a class.  Each will be
checked in turn until one of them passes.

    * First, is the $value of that type declared in Moose (or Mouse)?

    * Then, does the $value have that role?
        $value->DOES($type);

    * Finally, is the $value an object of that class?
        $value->isa($type);

The set of default types that are understood can be found in
[Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints) (or [Moose::Util::TypeConstraints](https://metacpan.org/pod/Moose::Util::TypeConstraints);
they are generally the same, but there may be small differences).

    # avoid "argument isn't numeric" warnings
    method add(Int $this = 23, Int $that = 42) {
        return $this + $that;
    }

[Mouse](https://metacpan.org/pod/Mouse) and [Moose](https://metacpan.org/pod/Moose) also understand some parameterized types; see
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

### Value Constraints

In addition to a type, each parameter can also be specified with one or
more additional constraints, using the `$arg where CONSTRAINT` syntax.

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

The `where` keyword must appear immediately after the parameter name
and before any [trait](#parameter-traits) or [default](#defaults).

Each `where` constraint is smartmatched against the value of the
corresponding parameter, and an exception is thrown if the value does
not satisfy the constraint.

Any of the normal smartmatch arguments (numbers, strings, regexes,
undefs, hashrefs, arrayrefs, coderefs) can be used as a constraint.

In addition, the constraint can be specified as a raw block. This block
can then refer to the parameter variable directly by name (as in the
definition of `set_serial_num()` above), or else as `$_` (as in the
definition of `set_rating()`.

Unlike type constraints, value constraints are tested _after_ any
default values have been resolved, and in the same order as they were
specified within the signature.

### Parameter traits

Each parameter can be assigned a trait with the `$arg is TRAIT` syntax.

    method stuff($this is ro) {
        ...
    }

Any unknown trait is ignored.

Most parameters have a default traits of `is rw is copy`.

- **ro**

    Read-only.  Assigning or modifying the parameter is an error.  This trait
    requires [Const::Fast](https://metacpan.org/pod/Const::Fast) to be installed.

- **rw**

    Read-write.  It's ok to read or write the parameter.

    This is a default trait.

- **copy**

    The parameter will be a copy of the argument (just like `my $arg = shift`).

    This is a default trait except for the `\@foo` parameter (see ["Aliased references"](#aliased-references)).

- **alias**

    The parameter will be an alias of the argument.  Any changes to the
    parameter will be reflected in the caller.  This trait requires
    [Data::Alias](https://metacpan.org/pod/Data::Alias) to be installed.

    This is a default trait for the `\@foo` parameter (see ["Aliased references"](#aliased-references)).

### Mixing value constraints, traits, and defaults

As explained in ["Signature syntax"](#signature-syntax), there is a defined order when including
multiple trailing aspects of a parameter:

- Any value constraint must immediately follow the parameter name.
- Any trait must follow that.
- Any default must come last.

For instance, to have a parameter which has all three aspects:

    method echo($message where { length <= 80 } is ro = "what?") {
        return $message
    }

Think of `$message where { length <= 80 }` as being the left-hand side of the
trait, and `$message where { length <= 80 } is ro` as being the left-hand side
of the default assignment.

### Slurpy parameters

A "slurpy" parameter is a list or hash parameter that "slurps up" all
remaining arguments.  Since any following parameters can't receive values,
there can be only one slurpy parameter.

Slurpy parameters must come at the end of the signature and they must
be positional.

Slurpy parameters are optional by default.

### The "yada yada" marker

The restriction that slurpy parameters must be positional, and must
appear at the end of the signature, means that they cannot be used in
conjunction with named parameters.

This is frustrating, because there are many situations (in particular:
during object initialization, or when creating a callback) where it
is extremely handy to be able to ignore extra named arguments that don't
correspond to any named parameter.

While it would be theoretically possible to allow a slurpy parameter to
come after named parameters, the current implementation does not support
this (see ["Slurpy parameter restrictions"](#slurpy-parameter-restrictions)).

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

The `...` may appear as a separate "pseudo-parameter" anywhere in the
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
initialize, or deallocate the unused slurpy parameter `@etc`.

### Required and optional parameters

Parameters declared using `$arg!` are explicitly _required_.
Parameters declared using `$arg?` are explicitly _optional_.  These
declarations override all other considerations.

A parameter is implicitly _optional_ if it is a named parameter, has a
default, or is slurpy.  All other parameters are implicitly
_required_.

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

### The `@_` signature

The @\_ signature is a special case which only shifts `$self`.  It
leaves the rest of `@_` alone.  This way you can get $self but do the
rest of the argument handling manually.

Note that a signature of `(@_)` is exactly equivalent to a signature
of `(...)`.  See ["The yada yada marker"](#the-yada-yada-marker).

### The empty signature

If a method is given the signature of `()` or no signature at
all, it takes no arguments.

## Anonymous Methods

An anonymous method can be declared just like an anonymous sub.

    my $method = method ($arg) {
        return $self->foo($arg);
    };

    $obj->$method(42);

## Options

Method::Signatures takes some options at \`use\` time of the form

    use Method::Signatures { option => "value", ... };

### invocant

In some cases it is desirable for the invocant to be named something other
than `$self`, and specifying it in the signature of every method is tedious
and prone to human-error. When this option is set, methods that do not specify
the invocant variable in their signatures will use the given variable name.

    use Method::Signatures { invocant => '$app' };

    method main { $app->config; $app->run; $app->cleanup; }

Note that the leading sigil _must_ be provided, and the value must be a single
token that would be valid as a perl variable. Currently only scalar invocant
variables are supported (eg, the sigil must be a `$`).

This option only affects the packages in which it is used. All others will
continue to use `$self` as the default invocant variable.

### compile\_at\_BEGIN

By default, named methods and funcs are evaluated at compile time, as
if they were in a BEGIN block, just like normal Perl named subs.  That
means this will work:

    echo("something");

    # This function is compiled first
    func echo($msg) { print $msg }

You can turn this off lexically by setting compile\_at\_BEGIN to a false value.

    use Method::Signatures { compile_at_BEGIN => 0 };

compile\_at\_BEGIN currently causes some issues when used with Perl 5.8.
See ["Earlier Perl versions"](#earlier-perl-versions).

### debug

When true, turns on debugging messages about compiling methods and
funcs.  See [DEBUGGING](https://metacpan.org/pod/DEBUGGING).  The flag is currently global, but this may
change.

## Differences from Perl 6

Method::Signatures is mostly a straight subset of Perl 6 signatures.
The important differences...

### Restrictions on named parameters

As noted above, there are more restrictions on named parameters than
in Perl 6.

### Named parameters are just hashes

Perl 5 lacks all the fancy named parameter syntax for the caller.

### Parameters are copies.

In Perl 6, parameters are aliases.  This makes sense in Perl 6 because
Perl 6 is an "everything is an object" language.  Perl 5 is not, so
parameters are much more naturally passed as copies.

You can alias using the "alias" trait.

### Can't use positional params as named params

Perl 6 allows you to use any parameter as a named parameter.  Perl 5
lacks the named parameter disambiguating syntax so it is not allowed.

### Addition of the `\@foo` reference alias prototype

In Perl 6, arrays and hashes don't get flattened, and their
referencing syntax is much improved.  Perl 5 has no such luxury, so
Method::Signatures added a way to alias references to normal variables
to make them easier to work with.

### Addition of the `@_` prototype

Method::Signatures lets you punt and use @\_ like in regular Perl 5.

# PERFORMANCE

There is no run-time performance penalty for using this module above
what it normally costs to do argument handling.

There is also no run-time penalty for type-checking if you do not
declare types.  The run-time penalty if you do declare types should be
very similar to using [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints) (or
[Moose::Util::TypeConstraints](https://metacpan.org/pod/Moose::Util::TypeConstraints)) directly, and should be faster than
using a module such as [MooseX::Params::Validate](https://metacpan.org/pod/MooseX::Params::Validate).  The magic of
[Any::Moose](https://metacpan.org/pod/Any::Moose) is used to give you the lightweight [Mouse](https://metacpan.org/pod/Mouse) if you have
not yet loaded [Moose](https://metacpan.org/pod/Moose), or the full-bodied [Moose](https://metacpan.org/pod/Moose) if you have.

Type-checking modules are not loaded until run-time, so this is fine:

    use Method::Signatures;
    use Moose;
    # you will still get Moose type checking
    # (assuming you declare one or more methods with types)

# DEBUGGING

One of the best ways to figure out what Method::Signatures is doing is
to run your code through B::Deparse (run the code with -MO=Deparse).

Setting the `METHOD_SIGNATURES_DEBUG` environment variable will cause
Method::Signatures to display debugging information when it is
compiling signatures.

# EXAMPLE

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

# EXPERIMENTING

If you want to experiment with the prototype syntax, start with
`Method::Signatures::parse_func`.  It takes a method prototype
and returns a string of Perl 5 code which will be placed at the
beginning of that method.

If you would like to try to provide your own type checking, subclass
[Method::Signatures](https://metacpan.org/pod/Method::Signatures) and either override `type_check` or
`inject_for_type_check`.  See ["EXTENDING"](#extending), below.

This interface is experimental, unstable and will change between
versions.

# EXTENDING

If you wish to subclass Method::Signatures, the following methods are
good places to start.

## too\_many\_args\_error, named\_param\_error, required\_arg, type\_error, where\_error

These are class methods which report the various run-time errors
(extra parameters, unknown named parameter, required parameter
missing, parameter fails type check, and parameter fails where
constraint respectively).  Note that each one calls
`signature_error`, which your versions should do as well.

## signature\_error

This is a class method which calls `signature_error_handler` (see
below) and reports the error as being from the caller's perspective.
Most likely you will not need to override this.  If you'd like to have
Method::Signatures errors give full stack traces (similar to
`$Carp::Verbose`), have a look at [Carp::Always](https://metacpan.org/pod/Carp::Always).

## signature\_error\_handler

By default, `signature_error` generates an error message and
`die`s with that message.  If you need to do something fancier with
the generated error message, your subclass can define its own
`signature_error_handler`.  For example:

    package My::Method::Signatures;

    use Moose;
    extends 'Method::Signatures';

    sub signature_error_handler {
        my ($class, $msg) = @_;
        die bless { message => $msg }, 'My::ExceptionClass';
    };

## type\_check

This is a class method which is called to verify that parameters have
the proper type.  If you want to change the way that
Method::Signatures does its type checking, this is most likely what
you want to override.  It calls `type_error` (see above).

## inject\_for\_type\_check

This is the object method that actually inserts the call to
["type\_check"](#type_check) into your Perl code.  Most likely you will not need to
override this, but if you wanted different parameters passed into
`type_check`, this would be the place to do it.

# BUGS, CAVEATS and NOTES

Please report bugs and leave feedback at
<bug-Method-Signatures> at <rt.cpan.org>.  Or use the
web interface at [http://rt.cpan.org](http://rt.cpan.org).  Report early, report often.

## One liners

If you want to write "use Method::Signatures" in a one-liner, do a
`-MMethod::Signatures` first.  This is due to a bug/limitation in
Devel::Declare.

## Close parends in quotes or comments

Because of the way [Devel::Declare](https://metacpan.org/pod/Devel::Declare) parses things, an unbalanced
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

## No source filter

While this module does rely on the black magic of [Devel::Declare](https://metacpan.org/pod/Devel::Declare) to
access Perl's own parser, it does not depend on a source filter.  As
such, it doesn't try to parse and rewrite your source code and there
should be no weird side effects.

Devel::Declare only affects compilation.  After that, it's a normal
subroutine.  As such, for all that hairy magic, this module is
surprisingly stable.

## Earlier Perl versions

The most noticeable is if an error occurs at compile time, such as a
strict error, perl might not notice until it tries to compile
something else via an `eval` or `require` at which point perl will
appear to fail where there is no reason to fail.

We recommend you use the [compile\_at\_BEGIN](https://metacpan.org/pod/compile_at_BEGIN) flag to turn off
compile-time parsing.

You can't use any feature that requires a smartmatch expression (i.e.
conditional ["Defaults"](#defaults) and ["Value Constraints"](#value-constraints)) in Perl 5.8.

Method::Signatures cannot be used with Perl versions prior to 5.8
because [Devel::Declare](https://metacpan.org/pod/Devel::Declare) does not work with those earlier versions.

## What about class methods?

Right now there's nothing special about class methods.  Just use
`$class` as your invocant like the normal Perl 5 convention.

There may be special syntax to separate class from object methods in
the future.

## What about the return value?

Currently there is no support for declaring the type of the return
value.

## How does this relate to Perl's built-in prototypes?

It doesn't.  Perl prototypes are a rather different beastie from
subroutine signatures.  They don't work on methods anyway.

A syntax for function prototypes is being considered.

    func($foo, $bar?) is proto($;$)

## Error checking

Here's some additional checks I would like to add, mostly to avoid
ambiguous or non-sense situations.

\* If one positional param is optional, everything to the right must be optional

    method foo($a, $b?, $c?)  # legal

    method bar($a, $b?, $c)   # illegal, ambiguous

Does `->bar(1,2)` mean $a = 1 and $b = 2 or $a = 1, $c = 3?

\* Positionals are resolved before named params.  They have precedence.

## Slurpy parameter restrictions

Slurpy parameters are currently more restricted than they need to be.
It is possible to work out a slurpy parameter in the middle, or a
named slurpy parameter.  However, there's lots of edge cases and
possible nonsense configurations.  Until that's worked out, we've left
it restricted.

## What about...

Method traits are in the pondering stage.

An API to query a method's signature is in the pondering stage.

Now that we have method signatures, multi-methods are a distinct possibility.

Applying traits to all parameters as a short-hand?

    # Equivalent?
    method foo($a is ro, $b is ro, $c is ro)
    method foo($a, $b, $c) is ro

[Role::Basic](https://metacpan.org/pod/Role::Basic) roles are currently not recognized by the type system.

A "go really fast" switch.  Turn off all runtime checks that might
bite into performance.

Method traits.

    method add($left, $right) is predictable   # declarative
    method add($left, $right) is cached        # procedural
                                               # (and Perl 6 compatible)

# THANKS

Most of this module is based on or copied from hard work done by many
other people.

All the really scary parts are copied from or rely on Matt Trout's,
Florian Ragwitz's and Rhesa Rozendaal's [Devel::Declare](https://metacpan.org/pod/Devel::Declare) work.

The prototype syntax is a slight adaptation of all the
excellent work the Perl 6 folks have already done.

The type checking and method modifier work was supplied by Buddy
Burden (barefootcoder).  Thanks to this, you can now use
Method::Signatures (or, more properly,
[Method::Signatures::Modifiers](https://metacpan.org/pod/Method::Signatures::Modifiers)) instead of
[MooseX::Method::Signatures](https://metacpan.org/pod/MooseX::Method::Signatures), which fixes many of the problems
commonly attributed to [MooseX::Declare](https://metacpan.org/pod/MooseX::Declare).

Value constraints and default conditions (i.e. "where" and "when")
were added by Damian Conway, who also rewrote some of the signature
parsing to make it more robust and more extensible.

Also thanks to Matthijs van Duin for his awesome [Data::Alias](https://metacpan.org/pod/Data::Alias) which
makes the `\@foo` signature work perfectly and [Sub::Name](https://metacpan.org/pod/Sub::Name) which
makes the subroutine names come out right in caller().

And thanks to Florian Ragwitz for his parallel
[MooseX::Method::Signatures](https://metacpan.org/pod/MooseX::Method::Signatures) module from which I borrow ideas and
code.

# LICENSE

The original code was taken from Matt S. Trout's tests for [Devel::Declare](https://metacpan.org/pod/Devel::Declare).

Copyright 2007-2012 by Michael G Schwern <schwern@pobox.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://www.perl.com/perl/misc/Artistic.html`

# SEE ALSO

[MooseX::Method::Signatures](https://metacpan.org/pod/MooseX::Method::Signatures) for an alternative implementation.

[Perl6::Signature](https://metacpan.org/pod/Perl6::Signature) for a more complete implementation of Perl 6 signatures.

[Method::Signatures::Simple](https://metacpan.org/pod/Method::Signatures::Simple) for a more basic version of what Method::Signatures provides.

[Function::Parameters](https://metacpan.org/pod/Function::Parameters) for a subset of Method::Signature's features without using [Devel::Declare](https://metacpan.org/pod/Devel::Declare).

[signatures](https://metacpan.org/pod/signatures) for `sub` with signatures.

Perl 6 subroutine parameters and arguments -  [http://perlcabal.org/syn/S06.html#Parameters\_and\_arguments](http://perlcabal.org/syn/S06.html#Parameters_and_arguments)

[Moose::Util::TypeConstraints](https://metacpan.org/pod/Moose::Util::TypeConstraints) or [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints) for
further details on how the type-checking works.
