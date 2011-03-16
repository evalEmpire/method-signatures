# package for t/role_check_basic.t


# the role

{
    package BasicRole;

    use Role::Basic;
}


# a class that composes the role

{
    package WithBasicRole;

    use Role::Basic 'with';
    with 'BasicRole';

    sub new { bless {}, __PACKAGE__; }
}


1;
