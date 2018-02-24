cd "~/GitHub/coffee-consumption-research"

import delimited "data/data-final.csv", clear

generate log_coffee_cons = log(coffee_cons)
generate log_time_activity = log(time_activity)
generate log_h_index = log(h_index)
generate log_i10_index = log(i10_index)

label variable coffee_cons "weekly coffee consumption"
label variable time_activity "years in activity"
label variable log_coffee_cons "log(weekly coffee consumption)"
label variable log_time_activity "log(years in activity)"
label variable h_index "H-index"
label variable i10_index "i10-index"
label variable log_h_index "log(H-index)"
label variable log_i10_index "log(i10-index)"

// -------------------------------------------------------------------------- //
// Descriptive statistics
// -------------------------------------------------------------------------- //

sum coffee_cons time_activity h_index i10_index, de

// -------------------------------------------------------------------------- //
// Main specification: lin-log
// -------------------------------------------------------------------------- //

regress h_index log_coffee_cons, robust
outreg2 using "results/lin_log_reg.tex", replace label
regress h_index log_coffee_cons log_time_activity, robust
outreg2 using "results/lin_log_reg.tex", append label

regress i10_index log_coffee_cons, robust
outreg2 using "results/lin_log_reg.tex", append label
regress i10_index log_coffee_cons log_time_activity, robust
outreg2 using "results/lin_log_reg.tex", append label

// -------------------------------------------------------------------------- //
// Alternative specification: lin-lin
// -------------------------------------------------------------------------- //

regress h_index coffee_cons, robust
outreg2 using "results/lin_lin_reg.tex", replace label
regress h_index coffee_cons log_time_activity, robust
outreg2 using "results/lin_lin_reg.tex", append label

regress i10_index coffee_cons, robust
outreg2 using "results/lin_lin_reg.tex", append label
regress i10_index coffee_cons log_time_activity, robust
outreg2 using "results/lin_lin_reg.tex", append label

// -------------------------------------------------------------------------- //
// Alternative specification: log-log
// -------------------------------------------------------------------------- //

regress log_h_index log_coffee_cons, robust
outreg2 using "results/log_log_reg.tex", replace label
regress log_h_index log_coffee_cons log_time_activity, robust
outreg2 using "results/log_log_reg.tex", append label

regress log_i10_index log_coffee_cons, robust
outreg2 using "results/log_log_reg.tex", append label
regress log_i10_index log_coffee_cons log_time_activity, robust
outreg2 using "results/log_log_reg.tex", append label
