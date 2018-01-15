use v6.c;
use Test;
use File::Temp;
use Test::HTTP::Server;
use HTTP::UserAgent;

my $server = init_env();

my $ua = HTTP::UserAgent.new();
my $response = $ua.get( "http://localhost:{$server.port}/file.txt" );
is $response.code, 200, "File exists. So it's a 200";
is $response.content, text-content(), "File content matches";

my @events = $server.events;
is @events[0].path, '/file.txt', "Expected path called";
is @events[0].method, 'GET', "Expected method used";
is @events[0].code, 200, "Expected response code";
is $server.clear-events, 1, "One event cleared from the list";

done-testing;


sub init_env() {
    my $folder = tempdir();
    
    my $fh = "$folder/file.txt".IO.open :w;
    $fh.put( text-content() );
    
    $fh.close;
    
    Test::HTTP::Server.new( :dir($folder) );

}

sub text-content() {
    q:to/EOF/;
    Text file
    EOF
}
