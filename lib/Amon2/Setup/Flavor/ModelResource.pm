package Amon2::Setup::Flavor::ModelResource;
use 5.008001;
use strict;
use warnings;

use parent qw/ Amon2::Setup::Flavor /;

our $VERSION = "0.01";

sub run {
    my $self = shift;

    $self->_write_myapp;
    $self->_write_loader;
    $self->_write_dispatcher;
    $self->_write_model;
    $self->_write_resource;
}

sub _write_myapp {
    my ($self) = @_;

    $self->write_file("lib/<<PATH>>.pm", <<'...');
package <% $module %>;
use strict;
use warnings;
use utf8;

our $VERSION='0.01';
use 5.008001;

use parent qw/Amon2/;
# Enable project local mode.
__PACKAGE__->make_local_context();

1;
...

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

sub _write_dispatcher {
    my ($self) = @_;

    $self->write_file("lib/<<PATH>>/Web/Dispatcher.pm", <<'...');
package <% $module %>::Web;
use strict;
use warnings;
use utf8;
use parent qw/<% $module %> Amon2::Web/;
use <% $module %>::Loader qw/model resource/;
use <% $module %>::Web::Dispatcher;

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
use <% $module %>::DB::Schema;
use <% $module %>::DB;
my $schema = <% $module %>::DB::Schema->instance;

sub db {
    my $conf = <% $module %>->context->config->{DBI}
        or die "Missing configuration about DBI";
    $c->{db} = <% $module %>::DB->new(
        schema       => $schema,
        connect_info => [@$conf],
        # I suggest to enable following lines if you are using mysql.
        # on_connect_do => [
        #     'SET SESSION sql_mode=STRICT_TRANS_TABLES;',
        # ],
    );
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

