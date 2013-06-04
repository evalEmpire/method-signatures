
package MyCompany::Bar;

use Moose;
use MooseX::Params::Validate;

use namespace::autoclean;

extends 'MyCompany::Foo';

sub adjusted_rate
{
    my ($self, $type, $discount) = validated_list(
            \@_,
            type        =>  { isa => 'Str' },
            discount    =>  { isa => 'Int', default => 0 }
    );

    return $self->rate($type) * (1 - $discount / 100);
}

around 'total' => sub
{
    my $orig = shift;
    my $self = shift;
    my ($rate_type, @costs) = pos_validated_list(
            \@_,
            { isa => 'Str' },
            MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1,
    );

    my $total =  $self->$orig(@costs)
            * $self->adjusted_rate(
                    type        =>  $rate_type,
                    discount    =>  $self->current_discount
            );
    return $total;
};

__PACKAGE__->meta->make_immutable;

1;
