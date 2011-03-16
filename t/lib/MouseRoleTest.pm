# package for t/role_check_mouse.t


# the role

{
    package MouseRole;

    use Mouse::Role;
}


# a class that composes the role

{
    package WithMouseRole;

    use Mouse;
    with 'MouseRole';
}


1;
