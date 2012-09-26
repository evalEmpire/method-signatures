#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Stuff;

    use Test::More;
    use Method::Signatures;

    method add($this = 23 when {$_ < 23}, $that = 42 when {42 < $_}) {
        return $this + $that;
    }

    # Check that it recognizes hashes
    method add_block($this = 23 when { 2 => 'bad' }, $that = 42 when { 42 < $_ } ) {
        return $this + $that;
    }

    # Check that it disambiguates blocks
    method add_dis($this = 23 when {; 2 => 'bad' }, $that = 42 when { 42 < $_ } ) {
        return $this + $that;
    }

    method minus($this is ro = 23 when undef, $that is ro = 42 when {($_ % 2)}) {
        return $this - $that;
    }

    is( Stuff->add(),      23 + 42 );
    is( Stuff->add(undef), 23 + 42 );
    is( Stuff->add(99),    99 + 42 );
    is( Stuff->add(2,3),   23 + 3  );
    is( Stuff->add(24,3),  24 + 3  );

    is( Stuff->add_block(),      23 + 42 );
    is( Stuff->add_block(99),    99 + 42 );
    is( Stuff->add_block(2,3),   23 + 3  );
    is( Stuff->add_block(4,3),    4 + 3  );
    is( Stuff->add_block(24,3),  24 + 3  );

    is( Stuff->add_dis(),      23 + 42 );
    is( Stuff->add_dis(99),    23 + 42 );
    is( Stuff->add_dis(2,3),   23 + 3  );
    is( Stuff->add_dis(4,3),   23 + 3  );
    is( Stuff->add_dis(24,3),  23 + 3  );

    is( Stuff->minus(),         23 - 42 );
    is( Stuff->minus(undef),    23 - 42 );
    is( Stuff->minus(99),       99 - 42 );
    is( Stuff->minus(2, 3),      2 - 42 );
    is( Stuff->minus(2, 4),      2 - 4  );
}


