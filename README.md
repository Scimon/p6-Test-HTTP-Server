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
    $test-server.clear-events;

DESCRIPTION
===========

Test::HTTP::Server is a wrapper around HTTP::Server::Asnyc designed to allow for simple Mock testing of web services. 

The constructor accepts a 'dir' and an optional 'port' parameter.

The server will server up any files that exist in 'dir' on the given port (if not port is given then one will be assigned, the '.port' method can be acccesed to find what port is being used).

All requests are logged in a basic even log allowing for testing. If you make multiple async requests to the server the ordering of the events list cannot be assured and tests should be written based on this.

If a file doesn't exist then the server will return a 404.

Currently the server returns all files as 'text/plain' except files with the follwing extensions :

  * `html` => `text/html`

  * `png` => `image/png`

  * `jpg` => `image/jpeg`

  * `jpeg` => `image/jpeg`

  * `gif` => `image/gif`

  * `js` => `application/javascript`

  * `json` => `application/json`

  * `css` => `text/css`

  * `xml` => `application/xml`

CONFIG
------

You can include a file called `config.yml` in the file which allows for additional control over the responses. The following keys are available :

### mime

Hash representation of extension and mime type header allows adding additional less common mime types.

### paths

Hash where keys are paths to match (including leading `/`), values are hashes with the currently allowed keys :

#### returns

A list of commands to specify the return result, currently valid values. Any 3 digit code will return that HTTP status. "file" returns the file at the given path.

Each time a request is made to the given path the next repsonse in the list will be given. If the end of the list is reached then this result will be returned from then on.

METHODS
-------

### events

Returns the list of event objects giving the events registered to the server. Note if async requests are bineg made the order of events cannot be assured.

Events objects have the following attributes :

  * `path` Path of the request

  * `method` Method of the request

  * `code` HTTP code of the response 

### clear-events

Clear the event list allowing the server to be reused in further tests. Calling this method will also reset all the indexes on 'returns' in the config files. Further requests will start from the first registered resonse.

### mime-types

Returns a hash of mime-types registered with the server including any added in `config.yml` file. 

TODO
----

This is a very basic version of the server in order to allow other development to be worked on. Planned is to allow a config.yml file to exist in the top level directory. If the file exists it will allow you control different paths and their responses.

This is intended to allow the system to replicate errors to allow for error testing.

AUTHOR
======

Simon Proctor <simon.proctor@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Simon Proctor

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
