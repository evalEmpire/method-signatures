package PlainMoose;

use Moose;
use MooseX::Params::Validate;


sub doit
{
    my ($self, $count, $msg) = validated_list( \@_,
            count => { isa => 'Int' }, msg => { isa => 'Str' } );

    open(OUT, '>/dev/null') or die("can't open output");
    for (1..$count)
    {
        print OUT "$msg\n" for 1..10;
    }
    close(OUT);
}


1;
