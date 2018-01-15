use v6.c;
use Test;
use File::Temp;
use Test::HTTP::Server;
use HTTP::UserAgent;

my $empty-folder = tempdir();

my $server = Test::HTTP::Server.new( :dir($empty-folder) );
my $port = $server.port;

ok $server.port, "Server has a port assigned to it";
is $server.port, $port, "Server port is unchanged";
is $server.dir, $empty-folder, "Server directory path is queryable";
is $server.events, [], "No requests made to server, events list is empty";

my $server2 = Test::HTTP::Server.new( :dir($empty-folder) );

isnt $server.port, $server2.port, "Second server has a new port";

my $ua = HTTP::UserAgent.new();
my $response = $ua.get( "http://localhost:{$server.port}/nothing.html" );
is $response.code, 404, "Empty folder gives a 404 on requests";

done-testing;
