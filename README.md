[![Build Status](https://travis-ci.org/Scimon/p6-Test-HTTP-Server.svg?branch=master)](https://travis-ci.org/Scimon/p6-Test-HTTP-Server)

NAME
====

Test::HTTP::Server - Simple to use wrapper around HTTP::Server::Async designed for tests

SYNOPSIS
========

    use Test::HTTP::Server;

    # Simple usage
    # $path is a folder with a selection of test files including index.html
    my $test-server = Test::HTTP::Server.new( :dir($path) );

    # method-to-test expects a web host and will make a GET request to host/index.html
    ok method-to-test( :host( "http://localhost:{$test-server.port}" ) ), "This is a test";
    # Other tests on the results here.

    my @events = $test-server.events;
    is @events.elems, 1, "One request made";
    is @events[0].path, '/index.html', "Expected path called";
    is @events[0].method, 'GET', "Expected method used";
    is @events[0].code, 200, "Expected response code";

DESCRIPTION
===========

Test::HTTP::Server is a wrapper around HTTP::Server::Asnyc designed to allow for simple Mock testing of web services. 

AUTHOR
======

Simon Proctor <simon.proctor@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Simon Proctor

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
