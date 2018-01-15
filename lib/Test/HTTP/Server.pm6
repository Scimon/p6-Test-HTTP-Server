use v6.c;
use Test::Util::ServerPort;
use HTTP::Server::Async;
use Test::HTTP::Server::Event;

unit class Test::HTTP::Server:ver<0.0.1>;

has Int $.port;
has Str $.dir;
has HTTP::Server::Async $!server;
has Supplier $!server-event-writer;
has Supply $!server-event-reader;
has Channel $!event-queue;
has @!events;

submethod BUILD( :$dir ) {
    $!port = get-unused-port();
    $!dir := $dir;
    $!server-event-writer = Supplier.new();
    $!server-event-reader = $!server-event-writer.Supply;
    $!server-event-reader.tap( -> $d { self!store-event( $d ) } );
    $!event-queue = Channel.new();
    
    $!server = HTTP::Server::Async.new( :port($!port) );
    
    $!server.handler( -> $req, $res { self!handle-request( $req, $res ) } );
    $!server.listen();
}

method !handle-request( $request, $response ) {

    if ( "{$.dir}{$request.uri}".IO.f ) {
        self!register-event( :code(200), :path($request.uri), :method($request.method) );
        $response.close("{$.dir}{$request.uri}".IO.slurp.chomp);
    } else {
        self!register-event( :code(404), :path($request.uri), :method($request.method) );
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


=head1 AUTHOR

Simon Proctor <simon.proctor@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Simon Proctor

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
