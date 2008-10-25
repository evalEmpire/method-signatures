package Foo;

use strict;
use warnings;

use Method::Signatures;

method echo($msg) {
    return $msg
}

print Foo->echo(42);
