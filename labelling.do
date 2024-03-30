
label define labBinary 0 "No" 1 "Yes", modify

label define labTreat 1 "Treatment" 0 "Control", modify

label define labMarketType 1 "Import" 2 "Domestic" 3 "Export" 5 "Services", modify

label define labFirmSize 1 "1-5" 2 "5-20" 3 "20-50" 4 "50-250" 5 "250+", modify

label define labFIREstatus 0 "No FIRE" 1 "FIRE, jkod=R" 2 "FIRE, to be used", modify

label define labIndu1 1 "Agriculture, forestry and fishing" ///
	2 "Mining and quarrying" ///
	3 "Manufacturing" ///
	4 "Electricity, gas, steam and air conditioning supply" ///
	5 "Water supply; sewerage, waste management and remediation activities" ///
	6 "Construction" ///
	7 "Wholesale and retail trade; repair of motor vehicles and motorcycles" ///
	8 "Transportation and storage" ///
	9 "Accommodation and food service activities" ///
	10 "Information and communication" ///
	11 "Financial and insurance activities" ///
	12 "Real estate activities" ///
	13 "Professional, scientific and technical activities" ///
	14 "Adminsitrative and support service activities" ///
	15 "Public administration and defence; compulsory social security" ///
	16 "Education" ///
	17 "Human health and social work activities" ///
	18 "Arts, entertainment and recreation" ///
	19 "Other service activities", modify

label define labIndu2 1 "Crop and animal production, hunting and related service activities" ///
	2 "Forestry and logging" ///
	3 "Fishing and aquaculture" ///
	6 "Extraction of crude petroleum and natural gase" ///
	8 "Other mining and quarrying" ///
	9 "Mining support service activities" ///
	10 "Manufacture of food products" ///
	11 " - beverages" ///
	12 " - tobacco products" ///
	13 " - textiles" ///
	14 " - wearing apparel" ///
	15 " - leather and related products" ///
	16 " - wood" ///
	17 " - paper" ///
	18 "Printing, reprod. of recorded media" ///
	19 "Manuf. of coke, ref. petroleum products" ///
	20 " - chemicals, chemical products" ///
	21 " - pharmaceutical products" ///
	22 " - rubber, plastic products" ///
	23 " - other non-metallic mineral products" ///
	24 " - basic metals" ///
	25 " - fabricated metal products" ///
	26 " - computer, electronic, optical products" ///
	27 " - electrical equipment" ///
	28 " - machinery and equipment n.e.c." ///
	29 " - motor vehicles, trailers and semi-trailers" ///
	30 " - other transport equipment" ///
	31 " - furniture" ///
	32 "Other manufacturing" ///
	33 "Repair, installation of machinery" ///
	35 "Electricity, gas, steam and air conditioning supply" ///
	36 "Water collection" ///
	37 "Sewerage" ///
	38 "Waste collection, transment and disposal activities; material recovery" ///
	39 "Remediation activities" ///
	41 "Construction and buildings" ///
	42 "Civil engineering" ///
	43 "Specialised construction activities" ///
	45 "Wholesale and retail trade and repair of motor vehicles and motorcycles" ///
	46 "Wholesale trade" ///
	47 "Retail trade, except of motor vehicles and motorcycles" ///
	49 "Land transport and transport via pipelines" ///
	50 "Water transport" ///
	51 "Air transport" ///
	52 "Warehousing and support activities for transportation" ///
	53 "Postal and courier activities" ///
	55 "Accommodation" ///
	56 "Food and beverage service activities" ///
	58 "Publishing activities" ///
	59 "Motion picture, video and television programme production, sound recording and music publishing activities" ///
	60 "Programming and broadcasting activities" ///
	61 "Telecommunications" ///
	62 "Computer programming, consultancy and related activities" ///
	63 "Information service activities" ///
	64 "Financial service activities, except insurance and pension funding" ///
	66 "Activities auxiliary to financial services" ///
	68 "Real estate activities" ///
	69 "Legal and accounting activities" ///
	70 "Activities of head offices; management consultancy activities" ///
	71 "Architectural and engineering activities; technical testing and analysis" ///
	72 "Scientific research and development" ///
	73 "Advertising and market research" ///
	74 "Other professional, scientific and technical activities" ///
	75 "Veterinary activities" ///
	77 "Rental and leasing activities" ///
	78 "Employment activities" ///
	79 "Travel agency" ///
	80 "Security and investigation activities" ///
	81 "Services to buildings and landscape activities" ///
	82 "Office administrative, office support and other business support activities" ///
	84 "Public administration" ///
	85 "Education" ///
	86 "Human health activities" ///
	87 "Residential care" ///
	88 "Social work" ///
	90 "Crative, arts, entertainment" ///
	91 "Libraries" ///
	92 "Gambling" ///
	93 "Sports activities" ///
	94 "Activities of membership organizations" ///
	95 "Repair of computers and personal and household goods" ///
	96 "Other personal services" ///
	97 "Activities of households" ///
	99 "Extraterritorial organizations", modify
	
label define labInduPlot 10 "10-11 Manuf. of food & beverages" ///
						 12 "12 - of tobacco" ///
						 13 "13-15 - textiles & leather" ///
						 16 "16-18 - wood, paper & printing" ///
						 19 "19 - coke & refined petroleum" ///
						 20 "20-23 - chem., pharm. & plastic" ///
						 24 "24-25 - metal products" ///
						 26 "26-27 - computer & el. equipment" ///
						 28 "28-30 - machines & equipment" ///
						 31 "31-33 - furniture & o. manuf." ///
						 46 "46 Wholesale", modify
	
cap confirm variable nace2d 
if !_rc{
cap drop nace2d_plot 
gen nace2d_plot = nace2d
qui replace nace2d_plot = 10 if nace2d == 11
qui replace nace2d_plot = 13 if nace2d == 14
qui replace nace2d_plot = 13 if nace2d == 15
qui replace nace2d_plot = 16 if nace2d == 17
qui replace nace2d_plot = 16 if nace2d == 18
qui replace nace2d_plot = 20 if nace2d == 21
qui replace nace2d_plot = 20 if nace2d == 22
qui replace nace2d_plot = 20 if nace2d == 23
qui replace nace2d_plot = 24 if nace2d == 25
qui replace nace2d_plot = 26 if nace2d == 27
qui replace nace2d_plot = 28 if nace2d == 29
qui replace nace2d_plot = 28 if nace2d == 30
qui replace nace2d_plot = 31 if nace2d == 32
qui replace nace2d_plot = 31 if nace2d == 33
label val nace2d_plot labInduPlot
} 

