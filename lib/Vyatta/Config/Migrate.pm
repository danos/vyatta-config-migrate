#! /usr/bin/perl
#
# Copyright (c) 2019, AT&T Intellectual Property. All rights reserved.
#
# Copyright (c) 2015, Brocade Communications Systems, Inc.
# All Rights Reserved.
#
# SPDX-License-Identifier: GPL-2.0-only
#
# Helper module for migration scripts.
#
# You can call migrate with a list of callbacks to perform the
# migrations you want, or use the other functions to help navigate
# through the config.

package Vyatta::Config::Migrate;

use warnings;
use strict;
use File::Copy;
use File::Temp qw(tempfile);
use lib '/opt/vyatta/share/perl5/';
use XorpConfigParser;
use English qw( -no_match_vars );
use Carp;
use base qw(Exporter);

use vars qw( @EXPORT_OK $VERSION );

@EXPORT_OK =
  qw(migrate for_each_subnode for_each_subnode_with_match find_nodes find_leafs);
$VERSION = 1.00;

# Returns a list of the child nodes of $node whose name starts with $prefix.
sub find_nodes {
    my ( $xcp, $node, $prefix ) = @_;

    my @nodes = ();
    foreach my $subnode ( @{ $node->{children} } ) {
        my $name = $subnode->{name};
        next if not defined $name or $name !~ /^$prefix/msx;

        push @nodes, $subnode;
    }
    return @nodes;
}

# Returns a list of hashes, each of which represents a leaf node along
# the hierarchy described by @branches. Each hash provides a reference
# to the node itself and the path array used by the Xorp parser to
# locate it.
sub find_leafs {
    my ( $xcp, $path, $root, @branches ) = @_;
    my @node_path = @{$path}[ 0 .. $#{$path} - 1 ];
    my @nodes = ( { node => $root, path => \@node_path } );

    foreach my $branch (@branches) {
        my @child_nodes = ();
        foreach my $node (@nodes) {
            foreach
              my $child_node ( find_nodes( $xcp, $node->{node}, $branch ) )
            {
                my $child_path = [ @{ $node->{path} }, $node->{node}->{name} ];
                push @child_nodes,
                  {
                    node => $child_node,
                    path => $child_path
                  };
            }
        }
        @nodes = @child_nodes;
    }

    foreach my $node (@nodes) {
        $node->{path} = [ @{ $node->{path} }, $node->{node}->{name} ];
    }
    return @nodes;
}

# Calls $callback for every child node of $node whose name
# begins with $prefix.
sub for_each_subnode {
    my ( $xcp, $path, $node, $prefix, $callback ) = @_;

    foreach my $subnode ( find_nodes( $xcp, $node, $prefix ) ) {
        $callback->( $xcp, [ @{$path}, $subnode->{name} ], $subnode );
    }
    return 1;
}

# Calls $callback for every child node of $node whose name matches
# $match. Also passes through the matches to the callback.
sub for_each_subnode_with_match {
    my ( $xcp, $path, $node, $match, $callback ) = @_;
    foreach my $subnode ( @{ $node->{children} } ) {
        my $name = $subnode->{name};
        next if not defined $name;
        my @matches = ( $name =~ /$match/msx );
        if ( scalar @matches ) {
            $callback->( $xcp, $path, $subnode, $node, @matches );
        }
    }
    return 1;
}

# This is a helper for the migration scripts. Given a file name and a
# list of migration callbacks to run, it will parse the config in the
# file, perform the migrations and then write the results back into the
# file.
sub migrate {
    my ( $orig_cfg, @callbacks ) = @_;

    croak "Usage: $PROGRAM_NAME configfile\n"
      if !defined $orig_cfg;

    my $xcp = XorpConfigParser->new();
    $xcp->parse($orig_cfg);

    foreach my $callback (@callbacks) {
        $callback->($xcp);
    }

    my ( $tmp, $tmpname ) = tempfile('/tmp/vyatta_migrate.XXXX');

    select $tmp;
    $xcp->output(0);
    select STDOUT;
    close $tmp
      or croak "Failed to close $tmpname successfully: $ERRNO";

    move( $tmpname, $orig_cfg )
      or croak " Move $tmpname to $orig_cfg failed : $ERRNO ";

    return 1;
}

1;
