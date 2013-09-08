$mod_one = "itest";
$mod_two = "voltbuild";

sub get_item_name {
	my ($full_string);
	($full_string) = @_;
	@item_names = ($full_string =~ /$mod_one:(\w*)?\d\d\d\d\d\d/g);
	return @item_names;
}

sub uniques {
	my (%uniques,$var);
	foreach $var (@_) {
		$uniques{"$var"} = $var;
	}
	return %uniques;
}

@output = ();
foreach $input (<>){
	foreach $name (&get_item_name($input)) {
		push(@output,"$name");
	}
}

%u = &uniques(@output);
@tname_parts = ("00","01","10","11");
foreach $key (keys %u) {
	foreach $tpartx (@tname_parts) {
		foreach $tparty (@tname_parts) {
			foreach $tpartz(@tname_parts) {
				if ("$tpart$tparty$tpartz" != "000000" ) {
					$tname = "$tpartx$tparty$tpartz";
					print("minetest.register_alias(\"$mod_one:$u{$key}$tname\",\"$mod_two:$u{$key}$tname\")\n");
				}
			}
		}
	}
}
