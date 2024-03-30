program eststo_wrap, nclass
syntax, model(string)
	gdistinct cvrnr if e(sample)
	loc firms = r(ndistinct)
	cap estadd sca Firms = `firms'
	eststo `model'
end