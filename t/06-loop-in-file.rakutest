use v6;
use Test;
use File::Temp;
use Test::HTTP::Server;
use HTTP::UserAgent;

my $server = Test::HTTP::Server.new( :dir( "{$*PROGRAM.dirname}/t06test/" ) );

my $ua = HTTP::UserAgent.new();

my $response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 404, "First time file requested the config says give a 404";
$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 200, "Next time file requested the config says return the file so it's a 200";
$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 404, "Then we have a loop so back to 404";
$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 200, "And then it's a 200 again";

my $data = "{$*PROGRAM.dirname}/t06test/config.yml".IO.slurp();
is-deeply $response.content, $data, "File content matches";
is $response.field('Content-Type').values, [ 'text/yaml' ], "Content type is correct";

is $server.events.elems, 4, "4 Events lodged";
is $server.events[0].code, 404, "404";
is $server.events[1].code, 200, "200";
is $server.events[2].code, 404, "404 again";
is $server.events[3].code, 200, "200 again";

$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 404, "Make another request";

$server.clear-events;
$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 404, "Clearing events resets the counter";

done-testing;
