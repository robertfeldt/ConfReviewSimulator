(ICSE17) Conference Review Policy Simulation
============================================

This is mostly for fun but could at least in theory help inform decisions around changes to conference review processes. There was much discussion around the ICSE 2017 PC chairs proposal to limit the number of papers per author to 3, and some concerned researchers even [started a petition to abandon the limit](https://sites.google.com/site/icse2017petition/). The simulation script we use here is currently focused on simulating ICSE2017.

By making, what I think are decent, assumptions and guesstimates I built a stochastic simulation model for studying the effects of the proposed change (and some alternatives). By [running it for a total of 1.2 million simulated review processes](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_prestigebias_20_15_authlimitnoreduction.csv) **I conclude that the proposed author limit is unlikely to have a big effect on either the total review effort or on the number of research groups whose papers are accepted**. 

Naturally, these conclusions are heavily dependent on the initial assumptions and models used in the simulation. Thus this comes with a **BIG** **disclaimer**: **I'm sure one can arrive at different conclusions if having different assumptions or postulating other models**. Please mail me yours and we can update/compare. :)

Feel free to contact me with your proposed changes or ideas to improve this and consider more scenarios / input assumptions. Or just fork this repo and make any changes / simulations you want. :)


# Where can I find your detailed assumptions / model?

The ultimate source is [the simulation script itself](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/src/icse17_review_process_simulations.jl), I at least tried to initially comment it quite heavily. But I also try to summarize the assumptions below (and link to variable names and values in the script where appropriate). Assumption 1 just states my basic view on what we want to achieve; it may or may not have indirectly affected other choices, but have no explicit effect that I'm aware of. The rest of the assumptions directly affect the simulation:

1. There are criteria that are more important than the review time:
  1. Unfairly treated papers (i.e. accepted/rejected due to non-ideal review process,
  2. Diversity in the set of authors/groups that gets accepted, and
  3. Review effort/time should be as low as possible unless it has adverse effect on the other criteria.
2. To simplify we study research groups rather than individual researchers. So an author limit of 3 here means that each group can only submit a maximum of 3 papers. For some large groups in reality this would mean they can be approximated as multiple, smaller groups in this simulation.
3. There is some form of prestige bias even if it is small in probability and/or effect.
  1. See [Lee et al 2013](https://www.researchgate.net/profile/Cassidy_Sugimoto/publication/260409966_Bias_in_peer_review/links/0a85e53172a4e122ca000000.pdf) for a recent view on prestige bias; the jury is still out.
4. 35% of research groups that submit to ICSE can be considered highly prestigious.
5. Highly prestigious groups produce papers of slightly higher true quality, with less variation in quality.
  1. `DistrPaperQualityHighPrestige = TruncatedNormal(0.65, 0.15, 0.0, 1.0)`
  2. `DistrPaperQualityLowPrestige = TruncatedNormal(0.55, 0.3, 0.0, 1.0)`
6. High-prestige groups are also more likely to want to submit more papers. We model these distributions as categoricals:
  1. `DistrNPapersHighPrestige = Categorical([0.35, 0.35, 0.265, 0.02, 0.01, 0.005])`
  2. `DistrNPapersLowPrestige = Categorical([0.65, 0.25, 0.085, 0.01, 0.005])`
7. Papers are graded differently if they are in the "messy middle", i.e. not clear rejects or clear accepts. This seems to be in line with analyses of the "NIPS experiment".
  1. We assume grading happens on a 7-point scale, corresponding to -3 (clear reject) to +3 (clear accept) but measured as 1-7.
  2. Papers with a true quality below 0.3*7=2.1 are clear rejects.
  3. Papers with a true quality above 0.7*7=4.9 are clear accepts.
  4. Papers that are not clear rejects or clear accepts are in the "messy middle".
  5. The variation in scoring is much higher for "messy middle" papers since opinions tend to vary more about their (relative) merits.
    - `varClear = 0.10`
    - `varMessy = 0.50`
8. Review times are modeled based on the [van Rooyen et al 1999](https://www.researchgate.net/profile/Richard_Smith61/publication/13415327_Effect_of_open_peer_review_on_quality_of_reviews_and_on_reviewers'_recommendations_a_randomised_trial/links/54100e410cf2df04e75a55a6.pdf) paper but we assume a review takes at least one hour and that clear rejects take shorter time to review.
  1. `DistrTimeToReview = TruncatedNormal(2.25, 1.46, 1.0, Inf)`
  2. `DistrTimeToReviewClearRejects = TruncatedNormal(1.25, 1.0, 0.5, Inf)`
9. Review discussion time is higher for "messy middle" papers but at least 15 mins for all papers.
  1. `DistrTimeToDiscussMiddle = TruncatedNormal(1.0, 0.5, 0.25, Inf)`
  2. `DistrTimeToDiscuss = TruncatedNormal(0.5, 0.5, 0.25, Inf)`
10. Double blind review means that there is no prestige bias unless the reviewer can correctly identify/guess the authors. According to [Budden2008](http://www.csz-scz.ca/documents/news/scientific_reviews.pdf) this happens between 25-42% of the time. Distribution not known so we sample a probability uniformly in the Budden range (for each review). If the authors are identified we assume the same risk and size of prestige bias as when no double blind is used.
  1. `prob_identified = rand(Uniform(0.25, 0.42))`

Note that several of these choices are arbitrary but I tried to stay close to the literature on this that I know of. Or I tried to "guesstimate" based on my own experience. In hindsight I can see that some choices are maybe too extreme (5 times higher variation in review scores for messy middle seems excessive). But with the script it is now easy to study alternative choices and I intend to do so. 

TODO: The distribution of review scores for ICSE2014 can indirectly be found in the report from that year so can be used to refine some of the models.


# So what are the conclusions?

It so heavily depends on what you think are reasonable "input" models for the "true" quality of submitted papers, and many other assumptions, that I dare not say much. 

But when I use what I think are at least fairly reasonable assumptions the [results can be seen here](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_prestigebias_20_15_authlimitnoreduction.csv). This is the result of a simulation where the number of total submissions is basically unchanged since I think that any reduction due to the limit is likely to be offset by new groups submitting papers (since they think ICSE is now more "open" to outsiders) or existing submitters submitting more papers (for similar reasons). 

And even if you think that there actually will be a reduction in the number of submitted papers the effect seems to be a few percent less total hours spent on reviewing (column RevTimeDays [in this result](https://github.com/robertfeldt/ConfReviewSimulator/blob/master/results/ICSE17_20160509_191337_50k_noprestigebias_authlimitreducessubmissions.csv) shows 155 days of review effort for AuthLimit3Best vs 157.7 for NoAuthLimit, a 1.7% reduction).


# But really, what are the conclusions?

To me it **seems that double blind review would have similar or better effect** while not having much negative effects. It increases fairness somewhat without requiring people to withhold papers from submission. It [also seems right in general and like the right thing to do](http://www.robertfeldt.net/advice/double_blind_reviewing/). But note that differences between policys are quite small overall. It is interesting to note that few of the policys have much or any effect on the diversity of the groups that are accepted at ICSE; the number of unique groups stays almost the same regardless of policy.

However, please note that a policy change also communicates values and might affect how people perceive and thus act in relation to the conference. This is not something that one can easily model or simulate IMHO. You should thus use these results with a grain of salt, please.


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


# I found a strange thing in your results!

I'm sure there are some bugs here; I did this while on parental leave while my little one was taking naps throughout the day. Please be gentle. :) But contact me to point out the problem so I can fix it, thanks.

To me it seem strange that the MAPE for DoubleBlind can sometimes be higher than for NoAuthLimit while the unfairness always seems lower. But I guess the mean in MAPE can be tricked by a few outliers.

It also seem strange to me that there is so little effect on the number of groups that gets accepted. But it does increase for AuthLimit2Best and Rnd which seems in line with what I expected. That this is not seen for DoubleBlind might be because it just reflects that DB makes the process more fair so that, as modeled here, high-prestigious groups get more papers in which outweighs any other effect.