package BOKUTIN::TraitFor::Web::App::Preloading;

use Moose::Role;

BEGIN {
    use MIME::Types;
    my $mime = MIME::Types->new;
}

after setup_finalize => sub {
    my $class = shift;

    {
        warn "preloading start";

        my $file = File::Spec->catfile(container("config")->path_to, "PRELOADING");
        if ( -f $file ) {
            my @modules = io($file)->slurp;
            @modules = map { chomp; $_ } @modules;
            for my $pkg (@modules) {
                next if $pkg =~ m{^File::ChangeNotify};
                next if $pkg =~ m{^Params::Validate};
                try { load_class($pkg) };
            }
        }

        load_class($class);

        if (my $dtx = container('dtx')->now) {
            $dtx->now;
        }

        container("email_send");

        if (my $schema = container("schema")) {
            if (my @source_names = $schema->sources) {
                $schema->resultset($source_names[0])->count;
            }
        }

        warn "preloading finish.";
    }

    my $form_class = do {
        my @fragments = split(/::/, $class);
        pop @fragments;
        push @fragments, "Form";
        join("::", @fragments);
    };

    my @forms = useall($form_class);
    warn(sprintf("Number of forms %d found.", 0+@forms));

    my @successed_comps;
    my @failed_comps;
    if (my $view = $class->view("Mason2")) {
        my $comp_root = $view->config->{comp_root};
        for my $file ( io($comp_root)->All_Files ) {
            next unless $file->pathname =~ m/\.(mc|mi|mp|mr)$/;
            next if $file->pathname =~ m/Base\.mc/;
            my $rel = File::Spec->abs2rel( $file->pathname, $comp_root );
            eval {
                no warnings 'redefine';
                $view->interp->load("/$rel");
            };
            if ($@) {
                push @failed_comps, "/$rel";
                warn $@;
            }
            else {
                push @successed_comps, "/$rel";
            }
        }
    }
    warn(sprintf("Number of mason comps (%d/%d) found. (succeeded/failed)", 0+@successed_comps, 0+@failed_comps));

    use HTTP::Request;
    use Plack::Test;
    my $app = $class->apply_default_middlewares($class->psgi_app); 
    test_psgi app => $app, client => sub {
        my $cb  = shift;
        my $req = HTTP::Request->new(GET => "/");
        my $res = $cb->($req);

        if ( $res->is_success ) {
            warn "First request succeeded for COW.";
        }
        else {
            die $res->decoded_content;
        }
    };
};

1;

__END__

=encoding utf-8

=head1 NAME

GalsManager::TraitFor::Web::App::Preloading - CatalystへのRoleです。fdol_web_serverのform前に、できるだけ事前にモジュールを読み込みます。Copy on writeを期待します。

=head1 AUTHOR

Tomohiro Hosaka E<lt>bokutin@bokut.inE<gt>

=head1 LICENSE

Copyright (C) 2011 Tomohiro Hosaka All Rights Reserved.

=cut
