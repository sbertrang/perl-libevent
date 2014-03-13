use strict;
use warnings;
use Test::More;

use LibEvent;
use POSIX ();

my $base = LibEvent::EventBase->new;

pipe(my $rh, my $wh) or die("Can't create pipe: $!");

my $parent_pid = $$;

if (my $child_pid = fork) {
    my $ev = $base->event_new( $rh, LibEvent::EV_READ, sub {
      my $fh = shift->fh();
      my $st = <$fh>;
      is $st, "CHILD OK\n", "child ok";
    } );
    $ev->add( 1.0 );
    my $timer = $base->timer_new( 0, sub {
      ok kill( HUP => $child_pid ) > 0, "sighup to child";
    } );
    $timer->add( 0.5 );
    my $sig = $base->signal_new( POSIX::SIGHUP, LibEvent::EV_SIGNAL, sub {
      ok 1, "sighup from child";
    } );
    $sig->add();
    $base->loop();
}
else {
    $base->reinit;
    my $ev = $base->signal_new( POSIX::SIGHUP, LibEvent::EV_READ, sub {
      kill HUP => $parent_pid;
      print $wh "CHILD OK\n";
    } );
    $ev->add();
    $base->loop();
    exit;
}

done_testing;
