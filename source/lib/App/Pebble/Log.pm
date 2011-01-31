
=head1 NAME

App::Pebble::Log - App::Pebble logging

=cut

package App::Pebble::Log;
use Method::Signatures;

use Exporter 'import';
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Screen;
use DateTime;

our @EXPORT_OK = qw/ $log /;

our $log = Log::Dispatch->new();

use Data::Dumper;

method init($class: :$file, :$file_level = 1, :$screen_level = 3 ) {
    
    $log->add(
        Log::Dispatch::File->new(
            name      => "file",
            newline   => 1,
            mode      => ">>",
            min_level => $class->log_level_name( $file_level ),
            filename  => $file,
            callbacks => sub {
                my %args = @_;
                join( "\t", DateTime->now->datetime, $args{level}, $args{message} );
            },
        ),
    );
    $log->add(
        Log::Dispatch::Screen->new(
            name      => "screen",
            newline   => 1,
            stderr    => 1,
            min_level => $class->log_level_name( $screen_level ),
            callbacks => sub { my %args = @_; "[PBL] " . $args{message} },
        ),
    );
}

method log_level_name($class: $level ) {
    return {
        0 => "debug",
        1 => "info",
        2 => "notice",
        3 => "warning",
        4 => "error",
        5 => "critical",
        6 => "alert",
        7 => "emergency",
    }->{ $level } || "info";
}

1;
