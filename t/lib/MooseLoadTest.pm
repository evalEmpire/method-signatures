# package for t/typeload_moose.t
# (see comments there for why check_paramized_sref is here)

package Foo::Bar;

use Moose;
use Method::Signatures;

method check_int (Int $bar) {};
method check_paramized_sref (ScalarRef[Num] $bar) {};

1;
