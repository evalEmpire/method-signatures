package NoAlias;

# This is here to test the compile time error of missing Data::Alias.

{
    package Stuff;

    use Test::More;
    use Method::Signatures;
    BEGIN { $Method::Signatures::HAVE_DATA_ALIAS = 0; }

#line 13 NoAlias.pm
    method add_meaning($arg is alias) {
        $arg += 42;
    }

    my $life = 23;
    Stuff->add_meaning($life);
    is $life, 23 + 42;
}
