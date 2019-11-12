#!/usr/bin/perl
# Copyright (c) 2019, AT&T Intellectual Property. All rights reserved.
#
# Copyright (c) 2014-2015 by Brocade Communications Systems, Inc.
# All rights reserved.
#
# SPDX-License-Identifier: GPL-2.0-only


use strict;
use warnings;
use lib "/opt/vyatta/share/perl5";

use Getopt::Long;
my $subnet;
GetOptions("subnet=s" => \$subnet );


my $ifconfig_out = `ifconfig`;
my @ifconfig_out_lines = split /\n/, $ifconfig_out;

my @interfaces;
{
  my $line;
  foreach $line (@ifconfig_out_lines) {
    $line =~ /()/;;
    $line =~ /(.{10})Link encap:Ethernet/;
    my $interface = $1;
    if ($interface ne '') {
      push(@interfaces, $interface);
    }
  }
}


use Vyatta::Misc;
my $vm = new Vyatta::Misc();

use NetAddr::IP;  # This library is available via libnetaddr-ip-perl.deb

my $interface;
foreach $interface (@interfaces) {
  my $naip = $vm->getNetAddrIP($interface);
  if (!defined($naip)) {
    print STDERR "Error:  Unable to determine IP subnet / netmask information.\n";
    exit(1);
  }
  my $subnet_here = $naip->network()->addr();
  if ($subnet_here eq $subnet) { 
    print "$interface\n";
  }
}


