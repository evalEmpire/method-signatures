use MooseX::Declare;

class MyCompany::Foo
{
    use List::Util qw< sum >;

    sub rate {
        return 1;
    }

    method total (Int @costs) {
        return sum(@costs);
    }
}

1;
