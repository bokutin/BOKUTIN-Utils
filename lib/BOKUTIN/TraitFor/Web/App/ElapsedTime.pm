package BOKUTIN::TraitFor::Web::App::ElapsedTime;

use Moose::Role;

use Time::HiRes qw(gettimeofday tv_interval);

around dispatch => sub {
    my $orig = shift;
    my $c = shift;

    my $start   = [gettimeofday];
    my $ret     = $c->$orig(@_);
    my $end     = [gettimeofday];
    my $elapsed = tv_interval($start, $end);

    if ($c->res->has_body and $c->res->content_type =~ m{^text/html}) {
        my $sec = sprintf('%.2f', $elapsed);
        $c->res->body( $c->res->body =~ s/ElapsedTime/$sec/r );
    }

    $ret;
};

1;
