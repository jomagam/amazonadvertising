use strict;
use Amazon::Advertising::API;

# Retrieve command line args for SearchIndex and Keywords
die "Usage: $0 <space-separated entry for Search Index and Keywords>\n"
unless @ARGV;
my $searchIndex = $ARGV[0];
my $keywords = $ARGV[1];

my $EndPoint = "http://webservices.amazon.com/onca/xml";
my $service = "AWSECommerceService";
my $operation = "ItemSearch";


my %request = (
    endpoint => $EndPoint,
    Service => $service,
    Operation => $operation,
    Keywords => $keywords,
    SearchIndex => $searchIndex,
);

my $api = Amazon::Advertising::API->new(secret_file => 'config');
my $response = $api->request(\%request);

print $response->content;

