
=head1 NAME

App::Pebble::IO::ObjectArray - Lke IO::ScalarArray, except for pure objects

=head1 DESCRIPTION

ScalarArray is sooo close to doing what I want, this is a minimal hack
to not treat things line lines of text.

=cut

package App::Pebble::IO::ObjectArray;
use parent "IO::ScalarArray";

sub print {
    my $self = shift;
    push @{*$self->{AR}}, @_;
    $self->_setpos_to_eof;
    1;
}

sub getline {
    my $self = shift;
    $self->eof and return undef;
    return *$self->{AR}->[ *$self->{Str}++ ];
}

sub eof {
    my $self = shift;
    
    return *$self->{Str} >= @{ *$self->{AR} };
}


1;
