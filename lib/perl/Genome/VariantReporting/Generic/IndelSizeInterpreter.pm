package Genome::VariantReporting::Generic::IndelSizeInterpreter;

use strict;
use warnings;
use Genome;

class Genome::VariantReporting::Generic::IndelSizeInterpreter {
    is => 'Genome::VariantReporting::Framework::Component::Interpreter',
};

sub name {
    return 'indel-size';
}

sub requires_experts {
    return qw/ /;
}

sub available_fields {
    return qw/
        indel_size
    /;
}

sub interpret_entry {
    my $self = shift;
    my $entry = shift;

    my %return_values;
    for my $alt_allele ( @{$entry->{alternate_alleles}} ) {
        my $indel_size = abs( length($entry->{reference_allele}) - length($alt_allele) );
        $return_values{$alt_allele} = {
            indel_size => $indel_size
        };
    }

    return %return_values;
}

1;

