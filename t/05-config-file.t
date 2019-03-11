use v6;
use Test;
use File::Temp;
use Test::HTTP::Server;
use HTTP::UserAgent;

my $server = Test::HTTP::Server.new( :dir( "{$*PROGRAM.dirname}/t05test1/" ) );

my $ua = HTTP::UserAgent.new();

ok $server.mime-types<atom>:exists, "Atom type registered";

my $response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 404, "First time file requested the config says give a 404";
$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 200, "Next time file requested the config says return the file so it's a 200";
$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 200, "No loop so we stay at file";

my $data = "{$*PROGRAM.dirname}/t05test1/config.yml".IO.slurp();
is-deeply $response.content, $data, "File content matches";
is $response.field('Content-Type').values, [ 'text/yaml' ], "Content type is correct";

is $server.events.elems, 3, "3 Events lodged";
is $server.events[0].code, 404, "404";
is $server.events[1].code, 200, "200";
is $server.events[2].code, 200, "200";

$server.clear-events;
$response = $ua.get( "http://127.0.0.1:{$server.port}/config.yml" );
is $response.code, 404, "Clearing events resets the file counters.";

$response = $ua.get( "http://127.0.0.1:{$server.port}/not-found" );
is $response.code, 404, "Not found is not found.";

done-testing;
