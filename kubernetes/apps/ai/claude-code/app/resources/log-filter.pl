#!/usr/bin/perl
# Strips terminal escapes and drops lines repeated within 10 minutes.
use strict;
use warnings;

$| = 1;
my %last_printed;
while (my $line = <STDIN>) {
    $line =~ s/\e\[[0-9;?]*[A-Za-z]//g;    # cursor movement, clear screen
    $line =~ s/\e\]8;;[^\a]*\a//g;         # OSC 8 hyperlinks
    next if $line =~ /^\s*$/;
    my $now = time;
    next if exists $last_printed{$line} && $now - $last_printed{$line} < 600;
    $last_printed{$line} = $now;
    print $line;
}
