
=head1 NAME

App::Pebble::Command - Base class for Pebble Commands

=cut

package App::Pebble::Command;
use Moose;
use App::Pebble::Object;

sub name    { undef }
sub command { undef }

sub run {
    my $class = shift;
    my ($user_cmd) = @_;

    my $cmd = $user_cmd;
    my $name = $class->name;
    $cmd =~ s/^$name/ $class->command /e;
    
    open( my $fh, "-|", $cmd ) or die( "Could not read from command ($cmd) ($user_cmd)\n" );

    return $fh;
}

1;
