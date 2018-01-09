use v6.c;
use Test::Util::ServerPort;

unit class Test::HTTP::Server:ver<0.0.1>;

has Int $.port;
has Str $.dir;

submethod BUILD( :$dir ) {
    $!port = get-unused-port();
    $!dir := $dir;
}

method events() { [] }


=begin pod

=head1 NAME

Test::HTTP::Server - blah blah blah

=head1 SYNOPSIS

  use Test::HTTP::Server;

=head1 DESCRIPTION

Test::HTTP::Server is ...

=head1 AUTHOR

Simon Proctor <simon.proctor@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Simon Proctor

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
