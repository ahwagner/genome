package Genome::InstrumentData::Gatk::BaseRecalibratorResult;

use strict;
use warnings;

use Genome;

# recalibrator
#  bam [from indel realigner]
#  ref [fasta]
#  known_sites [knownSites]
#  > grp [gatk report file]
#
# print reads
#  bam [from indel realigner]
#  ref [fasta]
#  grp [from recalibrator]
#  > bam
class Genome::InstrumentData::Gatk::BaseRecalibratorResult { 
    is => 'Genome::InstrumentData::Gatk::BaseWithKnownSites',
    has_output => [
        recalibration_table_file => {
            is_output => 1,
            calculate_from => [qw/ output_dir bam_source /],
            calculate => q| return $output_dir.'/'.$bam_source->id.'.bam.grp'; |,
        },
    ],
};

sub create {
    my $class = shift;

    my $self = $class->SUPER::create(@_);
    return if not $self;

    $self->status_message('Bam source: '.$self->bam_source->id);
    $self->status_message('Reference: '.$self->reference_build->id);
    $self->status_message('Knowns sites: '.$self->known_sites->id);

    my $run_recalibrator = $self->_run_base_recalibrator;
    return if not $run_recalibrator;

    my $print_reads = $self->_print_reads;
    return if not $print_reads;

    my $run_flagstat = $self->run_flagstat_on_output_bam_file;
    return if not $run_flagstat;

    my $allocation = $self->disk_allocations;
    eval { $allocation->reallocate };

    return $self;
}

sub _run_base_recalibrator {
    my $self = shift;
    $self->status_message('Run base recalibrator...');

    my $recalibration_table_file = $self->recalibration_table_file;
    my %base_recalibrator_params = (
        version => 2.4,
        input_bam => $self->input_bam_file,
        reference_fasta => $self->reference_fasta,
        output_recalibration_table => $recalibration_table_file,
    );
    $base_recalibrator_params{known_sites} = $self->known_sites_vcfs if @{$self->known_sites_vcfs};
    $self->status_message('Params: '.Data::Dumper::Dumper(\%base_recalibrator_params));

    my $base_recalibrator = Genome::Model::Tools::Gatk::BaseRecalibrator->create(%base_recalibrator_params);
    if ( not $base_recalibrator ) {
        $self->error_message('Failed to create base recalibrator creator!');
        return;
    }
    if ( not eval{ $base_recalibrator->execute; } ) {
        $self->error_message($@) if $@;
        $self->error_message('Failed to execute base recalibrator creator!');
        return;
    }

    if ( not -s $recalibration_table_file ) {
        $self->error_message('Ran base recalibrator creator, but failed to make a recalibration table file!');
        return;
    }
    $self->status_message('Recalibration table file: '.$recalibration_table_file);

    $self->status_message('Run base recalibrator...done');
    return 1;
}

sub _print_reads {
    my $self = shift;
    $self->status_message('Print reads...');
            
    my $bam_file = $self->bam_file;
    my $print_reads = Genome::Model::Tools::Gatk::PrintReads->create(
        version => 2.4,
        input_bams => [ $self->input_bam_file ],
        reference_fasta => $self->reference_fasta,
        output_bam => $bam_file,
        bqsr => $self->recalibration_table_file,
    );
    if ( not $print_reads ) {
        $self->error_message('Failed to create indel realigner!');
        return;
    }
    if ( not $print_reads->execute ) {
        $self->error_message('Failed to execute indel realigner!');
        return;
    }

    if ( not -s $bam_file ) {
        $self->error_message('Ran print reads, but failed to create the output bam!');
        return;
    }
    $self->status_message('Bam file: '.$bam_file);

    $self->status_message('Print reads...done');
    return 1;
}

1;

