Conference Review Simulation
============================

This is mostly for fun but might help inform decisions around changes to conference review processes. There was much discussion around the ICSE 2017 PC chairs propoal to limit the number of papers per author to 3, and some concerned researchers even (started a petition to abandon the limit)[https://sites.google.com/site/icse2017petition/]. 

By making, what I think are decent, assumptions and guesstimates I built a stochastic simulation model for studying the effects of the proposed change (and some alternatives). By [running it for a total of 1.2 million simulated review processes](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_prestigebias_20_15_authlimitnoreduction.csv) I conclude that the proposed author limit is unlikely to have a big effect on either the total review effort or on the number of research groups whose papers are accepted. 

Naturally, these conclusions are heavily dependent on the initial assumptions and models used in the simulation. Thus this comes with a **BIG** **disclaimer**: **I'm sure one can arrive at different conclusions if having different assumptions or postulating other models**. Please mail me yours and we can update/compare. :)

Feel free to contact me with your proposed changes or ideas to improve this and consider more scenarios / input assumptions. Or just fork this repo and make any changes / simulations you want. :)

# So what are the conclusions?

It so heavily depends on what you think are reasonable "input" models for the "true" quality of submitted papers, and many other assumptions, that I dare not say much. 

But when I use what I think are at least fairly reasonable assumptions the [results can be seen here](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_prestigebias_20_15_authlimitnoreduction.csv). This is the result of a simulation where the number of total submissions is basically unchanged since I think that any reduction due to the limit is likely to be offset by new groups submitting papers (since they think ICSE is now more "open" to outsiders) or existing submitters submitting more papers (for similar reasons). 

And even if you think that there actually will be a reduction in the number of submitted papers the effect seems to be a few percent less total hours spent on reviewing (column RevTimeDays [in this result](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_noprestigebias_authlimitreducessubmissions.csv) shows 155 days of review effort for AuthLimit3Best vs 157.7 for NoAuthLimit, a 1.7% reduction).

# Which scenarios and policys have you used?

I have investigated the effect of the proposed author limit of 3 either when the submitting groups sends the best (policy named AuthLimit3Best) among their potential papers to submit, or when they select randomly among their potential papers (AuthLimit3Rnd). I also included the same two policys but with a limit of 2 instead of 3. Additionally I included a policy using double blind review (DoubleBlind) as well as the combination of the author limit of 3 with double blind (DB+AuthLimit3Best and DB+AuthLimit3Rnd, respectively). The base case, i.e. with no limit and no double blind, is called NoAuthorLimit.

There are three overall scenarios investigated for all the above 8 policys and they are combined from two types of prestige bias models:

- PB0. No prestige bias
- PB1. A small/moderate prestige bias in that 20% of papers from high-prestigious groups get an increased review grade of 15%, same low/high prestigious

and two types of true quality models:

- QM1. low-prestigious groups produce papers with slightly lower average but higher variance in quality than high-prestigious groups
- QM2. low- and high-prestigious groups have same distribution of true quality of their produced papers

- [Scenario 1](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_noprestigebias_authlimitreducessubmissions.csv) combines PB0+QM1, 
- [Scenario 2](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_prestigebias_20_15_authlimitnoreduction.csv) combines PB1+QM1, while 
- [Scenario 3](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_prestigebias_20_15_authlimitnoreduction_sameqdistr.csv) combines PB1+QM2. 

Scenario 3 is mostly a sensitivity check to see how sensitive results are to the quality models. It is easy to run more scenarios so I might do that later.

# Which effect variables are studied?

The columns in the resulting csv files linked above are:

- Methods = which policy does this row correspond to
- NumSubm = number of submitted papers
- RevTimeDays = review time in days
- Withhold = papers withhold due to a limit (if any)
- NumGroups = number of unique groups with accepted papers
- Unfair = percent of unfairly rejected or accepted papers compared to if review process would have been ideal (and based on the "true" score of a paper)
- UnfairRej = percent of unfairly rejected papers
- UnfairAcc = percent of unfairly accepted papers (should be same as UnfairRej)
- MAPE = Mean Absolute Percentage Error in assigned from true score of the papers
- AccRateHiPr = acceptance rate for papers submitted by high-prestigious groups
- AccRateLoPr = acceptance rate for papers submitted by low-prestigious groups

The result files are based either on 10,000 or 50,000 simulations per policy per scenario. Results seems fairly stable already for 10,000 simulations.

# I totally disagree with your modeling assumptions!

This is totally understandable; I'm sure I've made many mistakes and might even change/improve them over time. Sorry for that. By sharing what I did at least it is reproduceable and you are free to change it to your liking. If you do please share your results.
