/*

	8_combine_results_byCN2:
	
	This file loads the pass-through regression estimates by CN2 and brings
	them into the right format.
	
	DEPENDENCIES:
	
	Inputs:
	
	 - data/5_demand_elasticities/out/betaSC_by_CN2
	 
	Outputs:
	 
	 - data/5_demand_elasticities/out/cn2

*/

global path = "$projectpath/data/5_demand_elasticities"
cd $path
cap mkdir $path/out
	
* 1. load estimation results at cn2 level
use $path/out/betaSC_by_CN2, replace
sort cn2 
* winsorized version of betaSC
gen betaSC_w = betaSC // winsorized version
replace betaSC_w = 0 if betaSC < 0
replace betaSC_w = 1 if betaSC > 1 & betaSC ~= . 
sum beta*, det  

* 2. labelling of product categories
gen label = ""
replace label = "Meat" if cn2 == "02"
replace label = "Fish" if cn2 == "03"
replace label = "Dairy produce" if cn2 == "04"
replace label = "Other products of animal origin" if cn2 == "05"
replace label = "Vegetables" if cn2 == "07"
replace label = "Fruit and nuts" if cn2 == "08"
replace label = "Coffee, tea, spices" if cn2 == "09"
replace label = "Cereals" if cn2 == "10"
replace label = "Flour and wheat products" if cn2 == "11"
replace label = "Oil seeds" if cn2 == "12"
replace label = "Lac and gums" if cn2 == "13"
replace label = "Other vegetable material" if cn2 == "14"
replace label = "Fats and oils" if cn2 == "15"
replace label = "Prepared meats" if cn2 == "16"
replace label = "Sugar" if cn2 == "17"
replace label = "Cocoa" if cn2 == "18"
replace label = "Preparations of cereal products" if cn2 == "19"
replace label = "Preparations of vegetables and fruits" if cn2 == "20"
replace label = "Miscellaneous edible preparations" if cn2 == "21"
replace label = "Beverages" if cn2 == "22"
replace label = "Food waste" if cn2 == "23"
replace label = "Tobacco" if cn2 == "24"
replace label = "Salt, sulphur, earths, stone" if cn2 == "25"
replace label = "Ores, slag, ash" if cn2 == "26"
replace label = "Mineral fuels" if cn2 == "27"
replace label = "Inorganic chemicals" if cn2 == "28"
replace label = "Organic chemicals" if cn2 == "29"
replace label = "Pharmaceutical products" if cn2 == "30"
replace label = "Fertilisers" if cn2 == "31"
replace label = "Colors" if cn2 == "32"
replace label = "Perfumery" if cn2 == "33"
replace label = "Soap" if cn2 == "34"
replace label = "Glues" if cn2 == "35"
replace label = "Explosives" if cn2 == "36"
replace label = "Photographic goods" if cn2 == "37"
replace label = "Miscellaneous chemical products" if cn2 == "38"
replace label = "Plastics" if cn2 == "39"
replace label = "Rubber" if cn2 == "40"
replace label = "Leather" if cn2 == "41"
replace label = "Leather products" if cn2 == "42"
replace label = "Fur" if cn2 == "43"
replace label = "Wood" if cn2 == "44"
replace label = "Cork" if cn2 == "45"
replace label = "Straw" if cn2 == "46"
replace label = "Wood pulp" if cn2 == "47"
replace label = "Paper" if cn2 == "48"
replace label = "Prints" if cn2 == "49"
replace label = "Wool" if cn2 == "51"
replace label = "Cotton" if cn2 == "52"
replace label = "Other textile fibres" if cn2 == "53"
replace label = "Man-made textile materials" if cn2 == "54"
replace label = "Man-made staple fibres" if cn2 == "55"
replace label = "Wadding" if cn2 == "56"
replace label = "Carpets" if cn2 == "57"
replace label = "Woven fabrics" if cn2 == "58"
replace label = "Impregnated textile fabrics" if cn2 == "59"
replace label = "Knitted fabrics" if cn2 == "60"
replace label = "Apparel, knitted" if cn2 == "61"
replace label = "Apparel, not knitted" if cn2 == "62"
replace label = "Other made-up textile articles" if cn2 == "63"
replace label = "Footwear" if cn2 == "64"
replace label = "Headgear" if cn2 == "65"
replace label = "Umbrellas" if cn2 == "66"
replace label = "Articles of stone, cement, etc." if cn2 == "68"
replace label = "Ceramic products" if cn2 == "69"
replace label = "Glass" if cn2 == "70"
replace label = "Precious stones" if cn2 == "71"
replace label = "Iron and steel" if cn2 == "72"
replace label = "Articles of iron and steel" if cn2 == "73"
replace label = "Copper" if cn2 == "74"
replace label = "Nickel" if cn2 == "75"
replace label = "Aluminium" if cn2 == "76"
replace label = "Lead" if cn2 == "78"
replace label = "Zinc" if cn2 == "79"
replace label = "Tin" if cn2 == "80"
replace label = "Other base materials" if cn2 == "81"
replace label = "Tools, cutlery" if cn2 == "82"
replace label = "Other articles of base metal" if cn2 == "83"
replace label = "Nuclear reactors" if cn2 == "84"
replace label = "Electrical equipement" if cn2 == "85"
replace label = "Railway" if cn2 == "86"
replace label = "Vehicles" if cn2 == "87"
replace label = "Aircraft" if cn2 == "88"
replace label = "Ships" if cn2 == "89"
replace label = "Precision instruments" if cn2 == "90"
replace label = "Clocks and watches" if cn2 == "91"
replace label = "Musical instruments" if cn2 == "92"
replace label = "Arms and ammunition" if cn2 == "93"
replace label = "Furniture" if cn2 == "94"
replace label = "Toys, games" if cn2 == "95"
replace label = "Other manufactured articles" if cn2 == "96"

* 3. save
rename (label) (cn2_label)
save $path/out/cn2, replace	
