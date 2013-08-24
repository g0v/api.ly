use Plack::Builder;

# requires listening on 5000 for now.
# requires this version: https://github.com/clkao/Plack-App-Proxy/

use Plack::App::Proxy;

builder {
  enable sub {
    my $app = shift;
    sub {
      my $env = shift;
      delete $env->{HTTP_COOKIE};
      $env->{HTTP_REFERER} =~ s!^http://localhost:5000/!http://lis.ly.gov.tw/!;
      my $res = $app->($env);
      return $res;
    };

  };
  mount "/" => Plack::App::Proxy->new(
    backend => 'LWP',
    options => { keep_alive => 1 },
    remote => "http://lis.ly.gov.tw")->to_app;
};
