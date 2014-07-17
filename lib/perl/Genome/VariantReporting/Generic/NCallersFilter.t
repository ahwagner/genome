#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::Exception;
use Test::More;
use Genome::File::Vcf::Entry;

my $pkg = "Genome::VariantReporting::Generic::NCallersFilter";
use_ok($pkg);
my $factory = Genome::VariantReporting::Framework::Factory->create();
isa_ok($factory->get_class('filters', $pkg->name), $pkg);

subtest "sample 1" => sub {
    my $filter = $pkg->create(
        sample_name => "S1",
        min_callers => 2,
    );
    lives_ok(sub {$filter->validate}, "Filter validates ok");

    my $entry = create_entry();

    my %expected_return_values = (
        C => 1,
        G => 0,
    );
    is_deeply({$filter->filter_entry($entry)}, \%expected_return_values, "Sample 1 return values as expected");
};

subtest "sample 2" => sub {
    my $filter = $pkg->create(
        sample_name => "S2",
        min_callers => 2,
    );
    lives_ok(sub {$filter->validate}, "Filter validates ok");

    my $entry = create_entry();

    my %expected_return_values = (
        C => 0,
        G => 0,
    );
    is_deeply({$filter->filter_entry($entry)}, \%expected_return_values, "Sample 1 return values as expected");
};

subtest "Nonexistent Caller" => sub {
    my $filter = $pkg->create(
        sample_name => "S1",
        min_callers => 2,
        valid_callers => ['NonexistentCaller'],
    );
    lives_ok(sub {$filter->validate}, "Filter validates ok");

    my $entry = create_entry();

    my %expected_return_values = (
        C => 0,
        G => 0,
    );
    $DB::single=1;
    is_deeply({$filter->filter_entry($entry)}, \%expected_return_values, "Sample 1 return values as expected");
};

done_testing;

sub create_vcf_header {
    my $header_txt = <<EOS;
##fileformat=VCFv4.1
##FILTER=<ID=PASS,Description="Passed all filters">
##FILTER=<ID=BAD,Description="This entry is bad and it should feel bad">
##INFO=<ID=A,Number=1,Type=String,Description="Info field A">
##INFO=<ID=C,Number=A,Type=String,Description="Info field C (per-alt)">
##INFO=<ID=E,Number=0,Type=Flag,Description="Info field E">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">
##FORMAT=<ID=FT,Number=.,Type=String,Description="Filter">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	S1	S1-[VarscanSomatic]	S1-[Sniper]	S1-[Strelka]	S2	S2-[VarscanSomatic]	S2-[Sniper]	S2-[Strelka]
EOS
    my @lines = split("\n", $header_txt);
    my $header = Genome::File::Vcf::Header->create(lines => \@lines);
    return $header
}

sub create_entry {
    my @fields = (
        '1',            # CHROM
        10,             # POS
        '.',            # ID
        'A',            # REF
        'C,G',            # ALT
        '10.3',         # QUAL
        'PASS',         # FILTER
        'A=B;C=8,9;E',  # INFO
        'GT:DP',     # FORMAT
        "0/1:12",   # FIRST_SAMPLE
        "0/0:12",   # FIRST_SAMPLE_Varscan
        "1/1:12",   # First_SAMPLE_Sniper
        "1/2:12",   # First_SAMPLE_Strelka
        "0/0:12",   # SECOND_SAMPLE
        ".",   # SECOND_SAMPLE_Varscan
        ".",   # SECOND_SAMPLE_Sniper
        "1/2:12",   # Second_SAMPLE_Strelka
    );

    my $entry_txt = join("\t", @fields);
    my $entry = Genome::File::Vcf::Entry->new(create_vcf_header(), $entry_txt);
    return $entry;
}