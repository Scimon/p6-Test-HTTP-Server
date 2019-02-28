use v6.c;
use Test::Util::ServerPort;
use HTTP::Server::Async;
use Test::HTTP::Server::Event;
use YAMLish;

unit class Test::HTTP::Server:ver<0.3.1>:auth<github:scimon>;

has Int $.port;
has Str $.dir;
has HTTP::Server::Async $!server;
has Supplier $!server-event-writer;
has Supply $!server-event-reader;
has Channel $!event-queue;
has @!events;
has %!type-map;
has %!path-index;
has %!path-rules;

submethod BUILD( :$dir ) {
    $!port = get-unused-port();
    $!dir := $dir;
    $!server-event-writer = Supplier.new();
    $!server-event-reader = $!server-event-writer.Supply;
    $!server-event-reader.tap( -> $d { self!store-event( $d ) } );
    $!event-queue = Channel.new();
    %!type-map = (
        'html' => 'text/html',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif'  => 'image/gif',
        'js'   => 'application/javascript',
        'json' => 'application/json',
        'css'  => 'text/css',
        'xml'  => 'application/xml',
    );
    %!path-index = ();
    %!path-rules = ();
    
    $!server = HTTP::Server::Async.new( :port($!port) );
    
    $!server.handler( -> $req, $res { self!handle-request( $req, $res ) } );
    $!server.listen();

    if ( "{$!dir}config.yml".IO.f ) {
        my %data = load-yaml( "{$!dir}config.yml".IO.slurp );
        if %data<mime>:exists {
            %!type-map = ( |%!type-map, |%data<mime> );
        }
        if %data<paths>:exists {
            %!path-rules = (|%data<paths>);
        }
    }
    
}

method mime-types() {
    return %!type-map;
}

method !get-type ( $path ) {
    %!type-map{$path.IO.extension} // 'text/plain';
}

method !handle-request( $request, $response ) {
    my $uri = $request.uri;
    if ( %!path-rules{$uri}:exists ) {
        %!path-index{$uri} //= 0;
        my $rule =  %!path-rules{$uri}<returns>[%!path-index{$uri}];
        if ( $rule ~~ m/^\d ** 3$/ ) {
            self!register-event( :code($rule), :path($uri), :method($request.method) );
            $response.status = $rule;
            $response.close();
        } elsif ( $rule ~~ "file" ) {
            self!register-event( :code(200), :path($uri), :method($request.method) );
            $response.headers<Content-Type> = self!get-type( "{$.dir}{$uri}" );
            $response.close("{$.dir}{$uri}".IO.slurp(:bin));
        }
        
        %!path-index{$uri}++ unless %!path-index{$uri} == %!path-rules{$uri}<returns>.elems-1;
    }
    elsif ( "{$.dir}{$uri}".IO.f ) {
        self!register-event( :code(200), :path($uri), :method($request.method) );
        $response.headers<Content-Type> = self!get-type( "{$.dir}{$uri}" );
        $response.close("{$.dir}{$uri}".IO.slurp(:bin));
    } else {
        self!register-event( :code(404), :path($uri), :method($request.method) );
        $response.status = 404;
        $response.close();
    }
}

method !register-event( :$code, :$path, :$method ) {
    $!server-event-writer.emit( { :code($code), :path($path), :method($method) } );
}

method !store-event( %data ) {
    my $event = Test::HTTP::Server::Event.new( |%data );
    $!event-queue.send( $event );
}

method events() {
    $!event-queue.close;
    @!events.push($_) for $!event-queue.list;
    $!event-queue = Channel.new();    
    @!events.clone;
}

method clear-events() {
    my $elems = @!events.elems;
    @!events = [];
    %!path-index = ();
    return $elems;
}

=begin pod

=head1 NAME

Test::HTTP::Server - Simple to use wrapper around HTTP::Server::Async designed for tests

=head1 SYNOPSIS

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
  
=head1 DESCRIPTION

Test::HTTP::Server is a wrapper around HTTP::Server::Asnyc designed to allow for simple Mock testing of web services. 

The constructor accepts a 'dir' and an optional 'port' parameter.

The server will server up any files that exist in 'dir' on the given port (if not port is given then one will be assigned, the '.port' method can be acccesed to find what port is being used).

All requests are logged in a basic even log allowing for testing. If you make multiple async requests to the server the ordering of the events list cannot be assured and tests should be written based on this.

If a file doesn't exist then the server will return a 404.

Currently the server returns all files as 'text/plain' except files with the follwing extensions :

=item1 C<html> => C<text/html>
=item1 C<png>  => C<image/png>
=item1 C<jpg>  => C<image/jpeg>
=item1 C<jpeg> => C<image/jpeg>
=item1 C<gif>  => C<image/gif>
=item1 C<js>   => C<application/javascript>
=item1 C<json> => C<application/json>
=item1 C<css>  => C<text/css>
=item1 C<xml>  => C<application/xml>

=head2 CONFIG

You can include a file called C<config.yml> in the file which allows for additional control over the responses.
The following keys are available :

=head3 mime

Hash representation of extension and mime type header allows adding additional less common mime types.

=head3 paths

Hash where keys are paths to match (including leading C</>), values are hashes with the currently allowed keys :

=head4 returns

A list of commands to specify the return result, currently valid values. Any 3 digit code will return that HTTP status.
"file" returns the file at the given path.

Each time a request is made to the given path the next repsonse in the list will be given. If the end of the list is reached then this result will
be returned from then on.

=head2 METHODS

=head3 events

Returns the list of event objects giving the events registered to the server. Note if async requests are bineg made the order of events cannot be assured.

Events objects have the following attributes :

=item1 C<path> Path of the request
=item1 C<method> Method of the request
=item1 C<code> HTTP code of the response 

=head3 clear-events

Clear the event list allowing the server to be reused in further tests.
Calling this method will also reset all the indexes on 'returns' in the config files. Further requests will start from the first registered resonse.

=head3 mime-types

Returns a hash of mime-types registered with the server including any added in C<config.yml> file. 

=head2 TODO

This is a very basic version of the server in order to allow other development to be worked on. Planned is to allow a config.yml file to exist in the top level directory. If the file exists it will allow you control different paths and their responses.

This is intended to allow the system to replicate errors to allow for error testing.

=head1 AUTHOR

Simon Proctor <simon.proctor@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Simon Proctor

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
