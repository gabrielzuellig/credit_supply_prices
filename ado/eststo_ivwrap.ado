cap program drop eststo_ivwrap
program eststo_ivwrap, nclass
syntax, model(string)
	gdistinct cvrnr if e(sample)
	loc firms = r(ndistinct)
	estadd sca Firms = `firms'
	
	mat first = e(first)
	estadd sca rkfp = first["pvalue",1]

	eststo `model'
end