use MooseX::Declare;

class FancyMoose
{

    method doit (Int :$count, Str :$msg) {                      # have to put brace on same line to avoid MXMS bug in 5.12

        open(OUT, '>/dev/null') or die("can't open output");
        for (1..$count)
        {
            print OUT "$msg\n" for 1..10;
        }
        close(OUT);
    }

};


1;
