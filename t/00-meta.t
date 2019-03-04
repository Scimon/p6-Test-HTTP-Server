use v6;

use Test;

my &m-meta-ok;

BEGIN {
    require Test::META <&meta-ok>;

    &m-meta-ok = &meta-ok;

    CATCH {
        when X::CompUnit::UnsatisfiedDependency {
            plan 1;
            skip-rest "no Test::META - skipping";
            done-testing;
            exit;
        }
    }

}

plan 1;

m-meta-ok();

done-testing;
