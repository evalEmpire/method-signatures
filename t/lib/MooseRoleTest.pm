# package for t/role_check_moose.t


# the role

{
    package MooseRole;

    use Moose::Role;
}


# a class that composes the role

{
    package WithMooseRole;

    use Moose;
    with 'MooseRole';
}


1;
