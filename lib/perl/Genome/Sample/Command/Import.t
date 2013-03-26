#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
}

use strict;
use warnings;

use above "Genome";

use Test::More;

use_ok('Genome::Sample::Command::Import') or die;
Genome::Sample::Command::Import::_create_import_command_for_config({
        namespace => 'Test',
        nomenclature => 'TeSt',
        sample_name_match => '[\w\d]+\-\d\w\-\d+',
        sample_attributes => [qw/ extraction_type tissue_desc /],
        individual_name_match => '\d+',
        individual_attributes => [qw/ gender race /],
    });
ok(Genome::Sample::Command::Import::Test->__meta__, 'class meta for command to import test namespace sample');

my $patient_name = 'TeSt-1111';
my $name = $patient_name.'-A1A-1A-1111';
my $import = Genome::Sample::Command::Import::Test->create(
    name => $name,
    gender => 'female',
    race => 'caucasian',
    tissue_desc => 'blood',
    extraction_type => 'genomic dna',
    sample_attributes => [qw/ age_baseline=50 mi_baseline=11.45 /],
    individual_attributes => [qw/ common_name=first /],
);
ok($import, 'create');
ok($import->execute, 'execute');

is($import->_individual->name, $patient_name, 'patient name');
is($import->_individual->nomenclature, 'TeSt', 'patient nomenclature');
is($import->_individual->gender, 'female', 'patient gender');
is($import->_individual->race, 'caucasian', 'patient race');
is($import->_individual->common_name, 'first', 'patient common_name');
is($import->_sample->name, $name, 'sample name');
is($import->_sample->nomenclature, 'TeSt', 'sample nomenclature');
is($import->_sample->extraction_label, $name, 'sample extraction label');
is($import->_sample->extraction_type, 'genomic dna', 'sample extraction type');
is($import->_sample->tissue_desc, 'blood', 'sample tissue');
is(eval{ $import->_sample->attributes(attribute_label => 'age_baseline')->attribute_value; }, 50, 'sample age_baseline');
is(eval{ $import->_sample->attributes(attribute_label => 'mi_baseline')->attribute_value; }, 11.45, 'sample mi_baseline');
is_deeply($import->_sample->source, $import->_individual, 'sample source');
my $library_name = $name.'-extlibs';
is($import->_library->name, $library_name, 'library name');
is_deeply($import->_library->sample, $import->_sample, 'library sample');
is(@{$import->_created_objects}, 3, 'created 3 objects');

# Fail - invalid name (nomenclature)
$import = Genome::Sample::Command::Import::Test->create(
    name => 'TEST-1111-A1A-1A-1111',
    gender => 'female',
    race => 'caucasian',
    tissue_desc => 'blood',
    extraction_type => 'genomic dna',
    sample_attributes => [qw/ age_baseline= /],
);
ok($import, 'create');
ok(!$import->execute, 'execute fails b/c of invalid nomenclature');
is($import->error_message, "Name (TEST-1111-A1A-1A-1111) is invalid!", 'correct error message');

# Fail - invalid name (sample)
$import = Genome::Sample::Command::Import::Test->create(
    name => 'TeSt-1111-A1?A-1A-1111',
    gender => 'female',
    race => 'caucasian',
    tissue_desc => 'blood',
    extraction_type => 'genomic dna',
    sample_attributes => [qw/ age_baseline= /],
);
ok($import, 'create');
ok(!$import->execute, 'execute fails b/c of invalid sample name');
is($import->error_message, "Name (TeSt-1111-A1?A-1A-1111) is invalid!", 'correct error message');

# Fail - invalid name (individual)
$import = Genome::Sample::Command::Import::Test->create(
    name => 'TeSt-1A11-A1A-1A-1111',
    gender => 'female',
    race => 'caucasian',
    tissue_desc => 'blood',
    extraction_type => 'genomic dna',
    sample_attributes => [qw/ age_baseline= /],
);
ok($import, 'create');
ok(!$import->execute, 'execute fails b/c of invalid individual name');
is($import->error_message, "Name (TeSt-1A11-A1A-1A-1111) is invalid!", 'correct error message');

# Fail - invalid sample attrs
$import = Genome::Sample::Command::Import::Test->create(
    name => $name,
    gender => 'female',
    race => 'caucasian',
    tissue_desc => 'blood',
    extraction_type => 'genomic dna',
    sample_attributes => [qw/ age_baseline= /],
);
ok($import, 'create');
ok(!$import->execute, 'execute fails b/c of invalid sample attributes');
is($import->error_message, "Sample attribute label (age_baseline) does not have a value!", 'correct error message');

# Fail - invalid individual attrs
$import = Genome::Sample::Command::Import::Test->create(
    name => $name,
    gender => 'female',
    race => 'caucasian',
    tissue_desc => 'blood',
    extraction_type => 'genomic dna',
    individual_attributes => [qw/ eye_color= /],
);
ok($import, 'create');
ok(!$import->execute, 'execute fails b/c of invalid individual attributes');
is($import->error_message, "Individual attribute label (eye_color) does not have a value!", 'correct error message');

done_testing();
