use v6;
use Test;
use File::Temp;
use Test::HTTP::Server;
use HTTP::UserAgent;

my $server = init_env();

my $ua = HTTP::UserAgent.new();

for { "file.txt" => {
            "bin" => False,
            "type" => "text/plain"
        },
      "file.html" => {
            "bin" => False,            
            "type" => "text/html"
        },
       "file.png" => {
            "bin" => True,
            "type" => "image/png",
        },
       "file.jpg" => {
            "bin" => True,
            "type" => "image/jpeg",
        },
       "file.jpeg" => {
            "bin" => True,
            "type" => "image/jpeg",
        },
       "file.gif" => {
            "bin" => True,
            "type" => "image/gif",
        },
       "file.js" => {
            "bin" => False,
            "type" => "application/javascript",
        },
       "file.json" => {
            "bin" => False,
            "type" => "application/json",
        },
       "file.css" => {
            "bin" => False,
            "type" => "text/css",
        },
       "file.xml" => {
            "bin" => False,
            "type" => "application/xml",
        },

    }.kv -> $file, %details {
    subtest "$file reading", {
        my $response = $ua.get( "http://127.0.0.1:{$server.port}/{$file}" );
        is $response.code, 200, "File exists. So it's a 200";
        my $data = get-content($file, %details<bin>);
        is-deeply $response.content, $data, "File content matches";
        is $response.field('Content-Type').values, [ %details<type> ], "Content type is correct";

        my @events = $server.events;
        is @events[0].path, "/{$file}", "Expected path called";
        is @events[0].method, 'GET', "Expected method used";
        is @events[0].code, 200, "Expected response code";
        is $server.clear-events, 1, "One event cleared from the list";
    }
}
        
done-testing;

sub init_env() {
    Test::HTTP::Server.new( :dir( "{$*PROGRAM.dirname}/t04data/" ) );
}

multi sub get-content ( $file, $bin where *.so ) {
    Buf.new( "{$*PROGRAM.dirname}/t04data/{$file}".IO.slurp( :bin ) );
}

multi sub get-content ( $file, $bin where !*.so ) {
    "{$*PROGRAM.dirname}/t04data/{$file}".IO.slurp();
}

