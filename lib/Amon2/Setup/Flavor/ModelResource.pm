package Amon2::Setup::Flavor::ModelResource;
use 5.008001;
use strict;
use warnings;

use parent qw/ Amon2::Setup::Flavor /;

our $VERSION = "0.01";


sub run {
    my $self = shift;

    $self->_write_loader;
    $self->_write_web;
    $self->_write_model;
    $self->_write_resource;
}


sub _write_loader {
    my ($self) = @_;

    $self->write_file("lib/<<PATH>>/Loader.pm", <<'...');
package <% $module %>::Loader;
use strict;
use warnings;
use utf8;

use Class::Load;
use Exporter::Lite;

our @EXPORT_OK = qw/model resource/;

sub resource { _load_class('::Resource', shift) }

sub model { _load_class('::Model', shift) }


sub _load_class {
    my ($base_name, $subclass) = @_;

    my $klass = join '::', $base_name, $subclass;
    Class::Load::load_class($klass);
    return $klass;
}

1;
...

}

sub _write_web {
    my ($self) = @_;

    $self->write_file("lib/<<PATH>>/Web.pm", <<'...');
package <% $module %>::Web;
use strict;
use warnings;
use utf8;
use parent qw/<% $module %> Amon2::Web/;
use <% $module %>::Loader qw/model resource/;
use File::Spec;
# dispatcher
use <% $module %>::Web::Dispatcher;
sub dispatch {
    return (<% $module %>::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}
# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::JSON',
    '+<% $module %>::Web::Plugin::Session',
);
# setup view
use <% $module %>::Web::View;
{
    sub create_view {
        my $view = <% $module %>::Web::View->make_instance(__PACKAGE__);
        no warnings 'redefine';
        *<% $module %>::Web::create_view = sub { $view }; # Class cache.
        $view
    }
    sub auto_render {
        my $self = shift;
        my @args;
        (caller 1)[3] =~ /^<% $module %>::Web::([^:]+)::C::(.+)/;

        my @path = (lc $1, lc $2);
        $path[1] =~ s!::!/!g;
        my $file_path = join '/', @path;
        my @arg = @_;
        $arg[0]->{js_path}  = $file_path . '.js';
        $arg[0]->{css_path} = $file_path . '.css';
        @args = ($file_path . '.tx', @arg);
        $self->render(@args);
    }
}
# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );
        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);
1;
...

}

sub _write_model {
    my ($self) = @_;

    $self->write_file("lib/<<PATH>>/Model.pm", <<'...');
package <% $module %>::Model;
use strict;
use warnings;
use utf8;
use <% $module %>::Loader qw/model resource/;
1;
...

}

sub _write_resource {
    my ($self) = @_;

    $self->write_file("lib/<<PATH>>/Resource.pm", <<'...');
package <% $module %>::Resource;
use strict;
use warnings;
use utf8;

use <% $module %>;
use DBIx::Sunny;

sub db {
    return DBIx::Sunny->connect(%{<% $module %>->context->config->{DBI}});
}

1;
...

}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Setup::Flavor::ModelResource - It's new $module

=head1 SYNOPSIS

    use Amon2::Setup::Flavor::ModelResource;

=head1 DESCRIPTION

Amon2::Setup::Flavor::ModelResource is ...

=head1 LICENSE

Copyright (C) meru_akimbo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

meru_akimbo E<lt>merukatoruayu0@gmail.comE<gt>

=cut

