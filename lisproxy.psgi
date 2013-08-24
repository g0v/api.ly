use Plack::Builder;
use Encode;

# requires listening on 5000 for now.
# requires this version: https://github.com/clkao/Plack-App-Proxy/

use Plack::App::Proxy;
use Plack::Response;

builder {
  enable sub {
    my $app = shift;
    sub {
      my $env = shift;
      delete $env->{HTTP_COOKIE};
      $env->{HTTP_REFERER} =~ s!^http://localhost:5000/!http://lis.ly.gov.tw/!;
      $env->{'psgi.streaming'} = Plack::Util::FALSE;

      my $res = $app->($env);
      my $resp = Plack::Response->new(@$res);
      if ($resp->content_type eq 'text/html') {
        if ($resp->body->[0] =~ s!<META HTTP-EQUIV=Content-Type Content="text/html; charset=big5">!<META HTTP-EQUIV=Content-Type Content="text/html; charset=utf-8">!i) {
          my @res = map {
            Encode::from_to($_, 'big5', 'utf-8');
          } @{$resp->body};
          return $resp->finalize;
        }

      }
      return $res;
    };

  };
  enable "BufferedStreaming";

  mount "/" => Plack::App::Proxy->new(
    backend => 'LWP',
    options => { keep_alive => 1 },
    remote => "http://lis.ly.gov.tw")->to_app;
};
