package Amazon::Advertising::API;

use LWP::UserAgent;
use Date::Format;
use URI::Escape;
use Digest::SHA qw{hmac_sha256_base64};
use Data::Dumper;

sub new {
    my $this = shift;
    my %args = @_;

    die "Specify secret_file" unless $args{secret_file};

    my $package = ref($this) || $this;

    my $self = {};
    bless $self, $package;

    $self->load_config($args{secret_file});
    return $self;
}

sub load_config {
    my $self = shift;
    my $file = shift;

    open F, $file or die "Could not open $file: $!";
    my @lines = <F>;
    close(F);

    chomp(@lines);

    foreach my $line (@lines){
	my ($key, $value) = split /\t/, $line;
	$self->{config}{$key} = $value;
    }
}

sub timestamp {
    my $self = shift;
    return time2str("%Y-%m-%dT%H:%M:%SZ", shift || time, 'GMT');
}

sub request {
    my $self = shift;
    my $args = shift;

    my $endpoint = delete $args->{endpoint} or die "Specify endpoint: " . Dumper($args);

    $args->{AWSAccessKeyId} = $self->accesskey;
    $args->{Timestamp} = $self->timestamp;
    $args->{Version} = $self->version;
    $args->{AssociateTag} = $self->associatetag;

    $self->escape($args);
    my $signature = $self->signature($args, $endpoint);

    my $ua = new LWP::UserAgent;
    $ua->timeout(30);
    my $request = "$endpoint?" . join '&', map { "$_=$args->{$_}" } sort keys %$args;

    $request .= "&Signature=$signature&";
    warn $request;

    my $response = $ua->get($request);

    return $response;
}

sub escape {
    my $self = shift;
    my $args = shift;

    foreach my $key (keys %$args){
	$args->{$key} = uri_escape($args->{$key});
    }
}

sub signature {
    my $self = shift;
    my $args = shift || {};
    my $endpoint = shift;

    my ($domain, $uri) = $endpoint =~ m{^https?://(.*?)(/.*)};
    die "bad endpoint: $endpoint" unless $domain and $uri;

    my $getargs = join '&', map { "$_=$args->{$_}" } sort keys %$args;

    my $request = "GET\n$domain\n$uri\n$getargs";

    my $signature = hmac_sha256_base64($request, $self->secretkey);

    $signature .= '=' unless substr $signature, 1, -1 eq '='; # Amazon wants an "=" at the end and hmac_sha256_base64 doesn't do that

    $signature = uri_escape($signature);
    return $signature;
}

sub accesskey { 
    my $self = shift;
    return $self->{config}{accesskey}
}

sub secretkey {
    my $self = shift;
    return $self->{config}{secretkey}
}

sub associatetag {
    my $self = shift;
    return $self->{config}{associatetag}
}

sub version   { '2011-08-01' }

1;
