package BOKUTIN::TraitFor::Web::App::ElapsedTime;

use Moose::Role;

use Time::HiRes qw(gettimeofday tv_interval);

around dispatch => sub {
    my $orig = shift;
    my $c = shift;

    my $started = [gettimeofday];
    my $ret     = $c->$orig(@_);

    if ($c->res->has_body and $c->res->content_type =~ m{^text/html}) {
        my $ended   = [gettimeofday];

        my $elapsed = sprintf '%f', tv_interval($started, $ended);
        my $rps     = $elapsed == 0 ? '??' : sprintf '%.3f', 1/$elapsed;
        my $label   = "${elapsed}s, $rps/s";

        $c->res->body( $c->res->body =~ s/ElapsedTime/$label/r );
    }

    $ret;
};

1;
