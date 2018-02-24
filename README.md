# Data and replication codes for the paper “Does Drinking Coffee Improve Research Output? Evidence from the Paris School of Economics”

Data and replication codes for the paper [“Does Drinking Coffee Improve Research Output? Evidence from the Paris School of Economics.”](https://github.com/thomasblanchet/coffee-consumption-research/raw/master/paper.pdf) The public data was anonymized.

Although this paper is written as a joke, all the data and regressions are genuine.

## How to run the programs

I provide the R code `create-dataset.R`, which does the web scraping and the dataset matching. However, you cannot run this program in its integrality because the original data on coffee consumption is not available for privacy reasons.

The anonymized output of that program is provided directly in the file `data/data-final.csv`. The Stata program `run-regressions.do` imports it and provides all the results in the paper.
