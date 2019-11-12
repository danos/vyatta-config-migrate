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
my $interface;
my $preflen;
GetOptions("interface=s" => \$interface, "preflen" => \$preflen);


use Vyatta::Misc;
my $vm = new Vyatta::Misc();

use NetAddr::IP;  # This library is available via libnetaddr-ip-perl.deb
my $naip = $vm->getNetAddrIP($interface);
if (!defined($naip)) {
  print STDERR "Error:  Unable to determine IP subnet / netmask information.\n";
  exit(1);

}

if (defined($preflen)) {
  my $prefix_len = $naip->network()->masklen();
  print "$prefix_len\n";
} else {
  my $subnet = $naip->network()->addr();
  print "$subnet\n";
}


