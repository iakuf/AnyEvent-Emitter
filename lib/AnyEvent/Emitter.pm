package AnyEvent::Emitter;
use strict;
use Scalar::Util qw(blessed weaken);

our $VERSION = 0.02;

use constant DEBUG => $ENV{EMITTER_DEBUG} || 0;

sub new {
    my $class = shift;
    my $reference = { events => {} };
    return bless( $reference, $class );
}

sub catch { $_[0]->on(error => $_[1]) and return $_[0] }

sub emit {
  my ($self, $name) = (shift, shift);

  if (my $s = $self->{events}{$name}) {
    warn "-- Emit $name in @{[blessed $self]} (@{[scalar @$s]})\n" if DEBUG;
    for my $cb (@$s) { $self->$cb(@_) }
  }
  else {
    warn "-- Emit $name in @{[blessed $self]} (0)\n" if DEBUG;
    die "@{[blessed $self]}: $_[0]" if $name eq 'error';
  }

  return $self;
}

sub has_subscribers { !!shift->{events}{shift()} }

sub on { push @{$_[0]{events}{$_[1]}}, $_[2] and return $_[2] }

sub once {
  my ($self, $name, $cb) = @_;

  weaken $self;
  my $wrapper;
  $wrapper = sub {
    $self->unsubscribe($name => $wrapper);
    $cb->(@_);
  };
  $self->on($name => $wrapper);
  weaken $wrapper;

  return $wrapper;
}

sub subscribers { shift->{events}{shift()} || [] }

sub unsubscribe {
  my ($self, $name, $cb) = @_;

  # One
  if ($cb) {
    $self->{events}{$name} = [grep { $cb ne $_ } @{$self->{events}{$name}}];
    delete $self->{events}{$name} unless @{$self->{events}{$name}};
  }

  # All
  else { delete $self->{events}{$name} }

  return $self;
}


1;

=encoding utf8

=head1 NAME

AnyEvent::Emitter - Event emitter base class (Mojo::EventEmitter porting).

=head1 SYNOPSIS

  package Cat;
  use 5.010;
  use base 'AnyEvent::Emitter';

  # Emit events
  sub poke {
    my $self = shift;
    $self->emit(roar => 3);
  }

  package main;

  # Subscribe to events
  my $tiger = Cat->new;
  $tiger->on(roar => sub {
    my ($tiger, $times) = @_;
    say 'RAWR!' for 1 .. $times;
  });
  $tiger->poke;

=head1 DESCRIPTION

L<AnyEvent::Emitter> is a simple base class for event emitting objects(Mojo::EventEmitter porting).

=head1 EVENTS

L<AnyEvent::Emitter> can emit the following events.

=head2 error

  $e->on(error => sub {
    my ($e, $err) = @_;
    ...
  });

This is a special event for errors, it will not be emitted directly by this
class but is fatal if unhandled.

  $e->on(error => sub {
    my ($e, $err) = @_;
    say "This looks bad: $err";
  });

=head1 METHODS

=head2 catch

  $e = $e->catch(sub {...});

Subscribe to L</"error"> event.

  # Longer version
  $e->on(error => sub {...});

=head2 emit

  $e = $e->emit('foo');
  $e = $e->emit('foo', 123);

Emit event.

=head2 has_subscribers

  my $bool = $e->has_subscribers('foo');

Check if event has subscribers.

=head2 on

  my $cb = $e->on(foo => sub {...});

Subscribe to event.

  $e->on(foo => sub {
    my ($e, @args) = @_;
    ...
  });

=head2 once

  my $cb = $e->once(foo => sub {...});

Subscribe to event and unsubscribe again after it has been emitted once.

  $e->once(foo => sub {
    my ($e, @args) = @_;
    ...
  });

=head2 subscribers

  my $subscribers = $e->subscribers('foo');

All subscribers for event.

  # Unsubscribe last subscriber
  $e->unsubscribe(foo => $e->subscribers('foo')->[-1]);

=head2 unsubscribe

  $e = $e->unsubscribe('foo');
  $e = $e->unsubscribe(foo => $cb);

Unsubscribe from event.

=head1 DEBUGGING

You can set the C<EMITTER_DEBUG> environment variable to get some
advanced diagnostics information printed to C<STDERR>.

  EMITTER_DEBUG=1

=head1 SEE ALSO

L<Mojo::EventEmitter>

=cut
