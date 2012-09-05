#!/usr/bin/perl

use Test::More;
use strict;
use warnings;

BEGIN {
    use_ok 'DBIx::Mint';
    use_ok 'DBIx::Mint::ResultSet';
}

# Tests for ResultSet data fetching methods

my $dbh  = DBI->connect('dbi:SQLite:dbname='bloodbowl.db', '', '',
    { AutoCommit => 1, RaiseError => 1 });
my $mint = DBIx::Mint->instance( dbh => $dbh );
isa_ok( $mint, 'DBIx::Mint');

my $coaches_rs = DBIx::Mint::ResultSet->new( table => 'coaches' );
isa_ok( $coaches_rs, 'DBIx::Mint::ResultSet' );

# Test fetching all records
{
    my @all = $coaches_rs->all;
    is( scalar @all, 4,       'Fetching all records from a table works correctly');
    is( ref $all[0], 'HASH',  'Records were not inflated (target class is unknown)');
    my ($coach) = grep {$_->{name} eq 'julio_f'} @all;
    is( $coach->{id}, 2,      'Record fetched correctly');
}
{
    my @all = $coaches_rs->target_class('Bloodbowl::Coach')->all;
    is( scalar @all, 4,       'Fetching all records from a table works correctly');
    is( ref $all[0], 'Bloodbowl::Coach', 
                              'Records were inflated to target_class');
    my ($coach) = grep {$_->{name} eq 'julio_f'} @all;
    is( $coach->{id}, 2,      'Record fetched correctly');
}

# Test fetching a single record
{
    my $coach = $coaches_rs->search({ name => 'julio_f'})->single;
    is( ref $coach, 'HASH',   'Retrieved a record, not inflated (unknown target_class)');
    is( $coach->{id}, 2,      'Record fetched correctly');
}
{
    my $coach = $coaches_rs->target_class('Bloodbowl::Coach')->search({ name => 'julio_f'})->single;
    is( ref $coach, 'Bloodbowl::Coach',   
                              'Retrieved a record, not inflated (unknown target_class)');
    is( $coach->{id}, 2,      'Record fetched correctly');
}

# Test getting the count of records from a table
{
    my $count = $coaches_rs->count;
    is($count, 4,             'Count of records retrieved correctly');
}

# Tests for iterators
{
    ok( !$coaches_rs->has_iterator, 'ResultSet does not have iterator before calling as_iterator');
    my $iter_rs = $coaches_rs->as_iterator;
    isa_ok($iter_rs, 'DBIx::Mint::ResultSet');
    ok( $iter_rs->has_iterator, 'as_iterator creates an iterator attribute in the ResultSet');
    
    my $count = 0;
    while (my $row = $iter_rs->next) {
        $count++ if ref $row eq 'HASH';
    }
    is($count, 4,                'Iterator works correctly');
}
{
    my $iter_rs = $coaches_rs->target_class('Bloodbowl::Coach')->as_iterator;
    isa_ok($iter_rs, 'DBIx::Mint::ResultSet');
    ok( $iter_rs->has_iterator, 'as_iterator creates an iterator attribute in the ResultSet');
    
    my $count = 0;
    while (my $row = $iter_rs->next) {
        $count++ if ref $row eq 'Bloodbowl::Coach';
    }
    is($count, 4,                'Iterator inflates rows correctly');
}

done_testing();
