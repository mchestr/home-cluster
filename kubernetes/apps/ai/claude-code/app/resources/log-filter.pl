#!/usr/bin/perl
# Remote Control redraws its status block about once a second with cursor
# escapes; without a TTY each redraw lands in the pod log as a fresh copy.
# Strip the escapes and print a line only if it was not printed in the last
# 10 minutes, so changes show at once and the status repeats as a heartbeat.
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
