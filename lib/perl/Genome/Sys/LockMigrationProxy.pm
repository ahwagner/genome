package Genome::Sys::LockMigrationProxy;

use strict;
use warnings;

use Carp qw(croak);
use Genome::Sys::Lock qw();
use Genome::Sys::LockProxy qw();
use Params::Validate qw(validate validate_with HASHREF);

require Scope::Guard;

=item new()

Keyword Arguments:

=over

=item old

A hash reference containing the constructor parameters for the existing/old lock.

=item new

A hash reference containing the constructor parameters for the desired/new lock.

=cut

sub new {
    my $class = shift;
    if (ref $class) {
        croak 'new() should be called as a class method';
    }
    my %params = validate(@_, {
        old => { type => HASHREF },
        new => { type => HASHREF },
    });

    my $primoridal_ooze = {
        old => Genome::Sys::LockProxy->new(%{$params{old}}),
        new => Genome::Sys::LockProxy->new(%{$params{new}}),
    };

    return bless $primoridal_ooze, $class;
}

=item lock()

C<lock()> is an instance method with optional parameters C<block_sleep>,
C<max_try>, or C<wait_announce_interval>.  It behaves similar to
C<Genome::Sys::Lock::lock_resource()> but on sucess C<lock()> returns an
instance of C<Genome::Sys::LockMigrationProxy> that can later be unlocked with
C<unlock()>.  Both the C<old> lock and the C<new> lock will be acquired, in
that order, or neither will.

=cut

sub lock {
    my $self = shift;
    my %params = validate_with(
        params => \@_,
        spec => Genome::Sys::Lock::PROXY_LOCK_PARAMS_SPEC(),
    );

    unless ($self->{old}->lock(%params)) {
        return;
    }

    unless ($self->{new}->lock(%params)) {
        $self->{old}->unlock();
        return;
    }

    return $self;
}

=item unlock()

C<unlock()> is an instance method that will unlock both the C<new> lock and the
C<old> lock, in that order, and should throw an exception if it fails to
release either lock.

=cut

sub unlock {
    my $self = shift;

    unless ($self->{new}->unlock()) {
        return;
    }

    # If old fails to unlock we can't relock new due to lack of context so I
    # would like to die but I am hoping that unlock already does that as
    # `lock_resource` is documented as doing.
    unless ($self->{old}->unlock()) {
        return;
    }

    return $self;
}

=item unlock_guard()

C<unlock_guard()> returns a Scope::Guard that will unlock the
C<Genome::Sys::LockMigrationProxy> object.

=cut

sub unlock_guard {
    my $self = shift;
    return Scope::Guard->new( sub { $self->unlock() } );
}

1;
