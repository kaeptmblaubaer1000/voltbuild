#perl script that modifies files in place with the regexes
use strict;
use warnings;

my @exemptfiles = ("voltbuild_objects.lua","textures","tools");
my($arg);
foreach $arg (@ARGV) {
	my($exempt,$break,$nextFile);
	for $exempt (@exemptfiles) {
		if ($arg eq $exempt) {
			$nextFile = 1;
			last;
		}
	}
	if ($nextFile) {
		next;
	}
	print("finding and replacing in $arg\n");
	open(FILE, $arg) or die("Couldn't open $arg for reading\n");
	my @lines = <FILE>;
	close(FILE) or die("Couldn't close $arg after reading\n");
	open(FILE, "+>", $arg) or die("Couldn't open $arg for writing\n");
	my($str);
	foreach $str (@lines){
		$str =~ s/\"size\[8,9\]\"/voltbuild.size_spec/g;
		$str =~ s/\"list\[current_name;charge;2,1;1,1;\]\"/voltbuild.charge_spec/g;
		$str =~ s/\"list\[current_name;discharge;2,3;1,1;\]\"/voltbuild.discharge_spec/g;
		$str =~ s/\"list\[current_player;main;0,5;8,4;\]\"/voltbuild.player_inventory_spec/g;
		$str =~ s/\s*\"list\[current_name;src;2,1;1,1;\]\"\.\.\n\s*//g;
		$str =~ s/\"list\[current_name;dst;5,1;2,2;\]\"/voltbuild.production_spec/g;
		print FILE $str;
	}
	close(FILE) or die("Couldn't close $arg after writing\n");
}

