
use MooseX::Declare;
use OverrideErrors;

class MyCompany::Bar extends MyCompany::Foo
{
    method adjusted_rate (Str :$type!, Int :$discount = 0) {
        return $self->rate($type) * (1 - $discount / 100);
    }

    around total (Str $rate_type, Int @costs)
    {
        my $total =  $self->$orig(@costs)
                * $self->adjusted_rate(
                        type        =>  $rate_type,
                        discount    =>  $self->current_discount
                );
        return $total;
    }
}

1;
