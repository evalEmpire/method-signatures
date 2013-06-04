package SigsOnly;

use strict;
use warnings;

use Method::Signatures;


sub new { return bless {}, __PACKAGE__ }


method doit (:$count, :$msg)
{
    open(OUT, '>/dev/null') or die("can't open output");
    for (1..$count)
    {
        print OUT "$msg\n" for 1..10;
    }
    close(OUT);
}


1;
