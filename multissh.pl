#!/usr/bin/perl
# Copyright (C) Kost. Distributed under GPL.

use strict;
use Net::SSH2;
use Getopt::Long;

my $configfile="$ENV{HOME}/.multissh";
my %config;
$config{'verbose'}=0;

if (-e $configfile) {
	open(CONFIG,"<$configfile") or next;
	while (<CONFIG>) {
	    chomp;                  # no newline
	    s/#.*//;                # no comments
	    s/^\s+//;               # no leading white
	    s/\s+$//;               # no trailing white
	    next unless length;     # anything left?
	    my ($var, $value) = split(/\s*=\s*/, $_, 2);
	    $config{$var} = $value;
	} 
	close(CONFIG);
}

Getopt::Long::Configure ("bundling");

my $result = GetOptions (
	"c|command=s" => \$config{'command'},
	"C|commandfile=s" => \$config{'commandfile'},
	"P|prefixfile=s" => \$config{'prefixfile'},
	"i|host=s" => \$config{'host'},
	"I|hostfile=s" => \$config{'hostfile'},
	"u|user=s" => \$config{'username'},
	"p|password=s" => \$config{'password'},
	"s|verifyssl!" => \$config{'verifyssl'},
	"v|verbose+"  => \$config{'verbose'},
	"h|help" => \&help
);

my @commands;
if ($config{'prefixfile'}) {
	open (PREFIXFILE,"<$config{'prefixfile'}") or die ("cannot open prefix file: $!");
	@commands=<PREFIXFILE>;
	close (PREFIXFILE);
}
if ($config{'commandfile'}) {
	open (COMMANDFILE,"<$config{'commandfile'}") or die ("cannot open commands file: $!");
	my @cmds=<COMMANDFILE>;
	push (@commands,@cmds);
	close (COMMANDFILE);
}

my @hosts;
if ($config{'hostfile'}) {
	open (HOSTFILE,"<$config{'hostfile'}") or die ("cannot open host file: $!");
	@hosts=<HOSTFILE>;
	close (HOSTFILE);
}

push @hosts, $config{'host'} if ($config{'host'});
push @commands, $config{'command'} if ($config{'command'});	

foreach my $host (@hosts) {
	print STDERR "Working on host: $host\n";

	my $ssh2 = Net::SSH2->new();
	$ssh2->connect($host) or warn ("cannot connect to host $host: $!");
	if ($ssh2->auth_password($config{'username'},$config{'password'})) {
		my $chan = $ssh2->channel();
		foreach my $command (@commands) {
			print STDERR "[$host] Command: $command\n";
			my $output = $chan->exec($command);
			print $output."\n";
		} # foreach
	} # if
	$ssh2->disconnect();
} # foreach

sub help {
	print "Multi-SSH. Copyright (C) Kost. Distributed under GPL.\n\n";
	print "Usage: $0 -u <username> -p <password> [options]  \n";
	print "\n";
	print " -c <s>	command to execute\n";
	print " -C <s>	name of file with commands\n";
	print " -P <s>	prefix of file with prefixed commands (useful for enable)\n";
	print " -i <s>	IP to execute\n";
	print " -I <s>	name of file with IPs to execute commands on\n";
	print " -u <s>	Use username <s>\n";
	print " -p <s>	Use password <s>\n";
	print " -s	verify SSL cert\n";
	print " -v	verbose (-vv will be more verbose)\n";
	print "\n";

	print "Example: $0 -u user -p password -c \"show ver\" -i 127.0.0.1\n";
	print "Example: $0 -u user -p password -C commands.txt -I hosts-ip.txt\n";
	print "Example: $0 # with username,password, commands and IPs in $configfile\n";
	
	exit 0;
}
