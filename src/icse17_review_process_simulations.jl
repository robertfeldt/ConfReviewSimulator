# A (fun) simulation of the possible effects of the proposed ICSE 2017 author limit
# as well as some alternatives (including double-blind review, and author limit at 2 instead of 3).
#
# Motto: When lacking data and/or theory, guess and simulate! :)
#
# Feedback, comments, praise and critique:
#   Robert Feldt, robert.feldt@gmail.com, 2016-05-09
#
# Implemented and executed on a MacBook Pro 2015 running Julia 0.4.5, see http://julialang.org/
#
# BIG Disclaimer: There are many guesses and arbitrary choices below
# => I'm sure one can arrive at different conclusions if having different
# assumptions or postulating other models. Please mail me yours and we can 
# update/compare. :)
#
using Distributions
using DataFrames
using ProgressMeter


###############################################################################
# 1. Estimate the distribution of number of submission as well as acceptance rate and
#    num of reviews per paper, all based on available stats from previous ICSE conferences.
#    TODO: Update as more stats and data is found / made available.
###############################################################################

# Num of submissions ICSE 2015 [CanforaElbaum2015] 
# (http://www.icse-conferences.org/sc/ICSE/2015/ICSE2015-Technical-Track-Report-Canfora-Elbaum.pdf)
ICSE15NumSubmissions = 452

# ICSE 2015 acceptance rate of 18.5% as stated by [CanforaElbaum2015]
ICSE15AccRate = 0.185

# [CanforaElbaum2015] also gave stats so we can calc the num of reviews per paper:
ICSE15RevPerPaper = 1137 / 452 # Num of reviews / num submissions

# but we need an int number of reviews per paper so sample a truncated normal distr
# and round to an int:
minrevs = floor(Int, ICSE15RevPerPaper)
maxrevs = ceil(Int, ICSE15RevPerPaper)
DistrRevPerPaper = TruncatedNormal(ICSE15RevPerPaper, 0.5, minrevs, maxrevs)
num_reviews_for_paper() = round(Int, rand(DistrRevPerPaper)) # Must be an int in the end
# TODO: Possibly simulate the two-stage review process instead?

# Data for ICSE 2014 reported by [BriandvanHoek2014]
# (http://www.icse-conferences.org/sc/ICSE/2014/ICSE-2014-PC-Chairs-Report.pdf)
ICSE14NumSubmissions = 495
ICSE14NumAccepted = 99
ICSE14AccRate = ICSE14NumAccepted / ICSE14NumSubmissions

# Based on data we have we can estimate the ICSE acceptance rate
EstICSEAccRate = mean([ICSE15AccRate, ICSE14AccRate])

# Num submissions 2016 not known exactly but can be estimated based on known num
# of accepted papers (108, http://2016.icse.cs.txstate.edu/technical-research)
# if we assume a similar acceptance rate as 2014&2015:
ICSE16EstNumSubmissions = round(Int, 108 / EstICSEAccRate)

# And given these 3 data points we fit Normal distr to model the number of expected
# submissions (TODO: Do better fit that assumes a yearly growth rate?)
DistrNumSubmissions = fit(Normal, [ICSE14NumSubmissions, ICSE15NumSubmissions, ICSE16EstNumSubmissions])


###############################################################################
# 2. Basic assumptions of the model and how to model in face of them.
###############################################################################

# Basic assumption of this simulation (some have direct effect others might indirectly have
# affected my choices):
#   - To simplify we study research groups rather than individual researchers.
#   - There is some form of prestige bias even if it is small in probability and/or effect.
#     See Lee et al 2013 for the current view on prestige bias; the jury is still out.
#   - Unfairly treated papers, and more diverse set of authors/groups are more important
#       criteria then review effort/time unless the latter can be substantially reduced 
#       without adverse effect on the other criteria.

# We are going to sample a random research group and consider if it's prestigious
# or not and how many papers it would like to submit (if there were no limits imposed). 
# We assume this number is somewhat higher for high-prestigious groups and that circa 35%
# of groups submitting to ICSE can be considered highly prestigious.
pHP = ProbHighPrestige = 0.35
dNPH = DistrNPapersHighPrestige = Categorical([0.35, 0.35, 0.265, 0.02, 0.01, 0.005]) # mean => 2.03
dNPL = DistrNPapersLowPrestige = Categorical([0.65, 0.25, 0.085, 0.01, 0.005])          # mean => 1.52

# Sanity check: The number of times the num papers is >3 is circa 2.2% 
# since that was been mentioned as the 2016 number? (TODO: find ref to this)
N = round(Int, 1e7)
t = vcat(rand(dNPH, round(Int, pHP*N)), rand(dNPL, round(Int, (1-pHP)*N)));
sum(t .> 3) / N # is around 2.2

NumGrades = 7 # Let's assume papers are ranked from -3 to +3 but we represent it from 1-7

# An ICSE submission from a high-prestigious group tends to be of slightly higher quality
# and have less variation in quality (since there is often real reasons people have attained 
# high prestige/rank).
DistrPaperQualityHighPrestige = TruncatedNormal(0.65,0.15, 0.0, 1.0)
DistrPaperQualityLowPrestige = TruncatedNormal(0.55,0.3, 0.0, 1.0)

# Now we can sample papers from a group and their "true" quality (i.e. grade they would 
# ideally get).
function sample_papers_from_one_group(groupnum = 1)
    tag, dnp, dpq = (rand() < ProbHighPrestige) ? 
                    (:high, DistrNPapersHighPrestige, DistrPaperQualityHighPrestige) :
                    (:low, DistrNPapersLowPrestige, DistrPaperQualityLowPrestige)
    pqs = rand(dpq, round(Int, rand(dnp))) * NumGrades
    map(pq -> Any[groupnum, tag, pq], pqs)
end

# And we can then sample all papers submitted to the conferece, but the conference might
# have a limiting policy in place. We can either assume that this has an effect on the
# total number of papers submitted or that it hasn't. I beleive in the latter but let's
# try to simulate the effect.
function sample_all_submissions(numPapers, limitingPolicyFn, limitAffectsNumSubmissions = false)
    # Sample groups until we have sampled enough number of papers
    SubmittedPapers = Any[]
    WithholdPapersPerGroupType = Int[0, 0]
    groupnum = 0
    n = 0
    while n < numPapers
        papers_group_want_to_submit = sample_papers_from_one_group(groupnum += 1)
        papers_group_can_submit = limitingPolicyFn(papers_group_want_to_submit)
        if length(papers_group_can_submit) < length(papers_group_want_to_submit)
            group_type = papers_group_want_to_submit[1][2] == :high ? 1 : 2
            WithholdPapersPerGroupType[group_type] += 1
        end
        for p in papers_group_can_submit
            if length(SubmittedPapers) < numPapers
                push!(SubmittedPapers, p)
            end
        end
        if limitAffectsNumSubmissions
            n += length(papers_group_want_to_submit)
        else
            # This is lower which means we will continue sampling until we reach the requested
            # number of papers which means the limit did not have an effect.
            n += length(papers_group_can_submit)
        end
    end
    SubmittedPapers, WithholdPapersPerGroupType
end

# Pre-2017 limiting policy was to not limit at all so a group could submit as many papers
# they wanted:
no_author_limit(papers) = papers # With no limit the group submits all their potential papers

# Lets assume an author limit just leads to a group submitting the max num papers
# up to the limit and that they either select randomly or select the best ones. 
# We also assume that the max num authors acts directly on the group, i.e. basically 
# that all the authors of a group would have been authors.
function author_limit(maxNumAuthors, selectBest = true)
    if selectBest
        # return a function that selects the best papers up to the limit count
        (papers) -> sort(papers, by = p -> p[3], rev = true)[1:min(maxNumAuthors, length(papers))]
    else
        # return a function that randomly selects among the papers
        (papers) -> shuffle(papers)[1:min(maxNumAuthors, length(papers))]
    end
end

# Generate papers and check legibility
#ps1, w1 = sample_all_submissions(rand(DistrNumSubmissions), no_author_limit);
#ps2, w2 = sample_all_submissions(rand(DistrNumSubmissions), author_limit(3));


###############################################################################
# 3. Simple modeling of the review process and its assigned scores
###############################################################################

# Now let's simulate a simple review model where there is some probability of PrestigeBias.
# There is some evidence for this according to a recent review although there is also
# evidence against it:
#  Lee, Carole J., et al. "Bias in peer review." Journal of the American Society for 
#  Information Science and Technology 64.1 (2013): 2-17.
# We assume there is a small probability that a high-prestigious group gets an 
# increased grade by a reviewer.
# We also assume a 3-part paper review model where papers above a cutoff in quality are clearly
# identified as ClearAccept and reviewers have only limited variance in their grades, similarly
# for a low cutoff leading to ClearRejects, while papers in the "Messy Middle" have a larger 
# variance in review scores.
LowCut = 0.3 * NumGrades
HighCut = 0.7 * NumGrades
varClear = 0.10
varMessy = 0.50

ismessymiddlepaper(truescore) = LowCut < truescore <= HighCut

# If any prestige bias kicks in our default is to assume it is moderate and 
# only leads to a 15% higher score.
PrestigeBiasSize = 0.15 * NumGrades

# Given the true score of a paper simulate its average assigned score based on the review
# model. Double blind reviewing leads to no prestige bias except for the empirically supported
# around 25-42% of times when a reviewer can guess the authors anyway. In the latter case we 
# assume there is the same type of prestige bias as if there was not double blind reviewing.
# The figure of 25-42% is from Budden et al 2008:
#   http://www.csz-scz.ca/documents/news/scientific_reviews.pdf
function review_score(truescore, pPrestigeBias = 0.0, doubleBlindReview = false, 
    pbSize = PrestigeBiasSize)

    variance = ismessymiddlepaper(truescore) ? varMessy : varClear
    assignedscore = rand(Normal(truescore, variance))

    if doubleBlindReview
        # Not clear from Budden where in stated range of 25 to 42% that reviewers correctly
        # identified authors so lets randomly sample uniformaly in that range
        prob_identified = rand(Uniform(0.25, 0.42))
        if rand() < prob_identified # Chance that they guess the right authors
            if rand() < pPrestigeBias
                assignedscore = min(assignedscore + PrestigeBiasSize, NumGrades)
            end
        end
    elseif rand() < pPrestigeBias # if reviewing is not double blind
        assignedscore = min(assignedscore + PrestigeBiasSize, NumGrades)
    end

    # Scores are only given as integers. Assume simple rounding.
    round(Int, assignedscore)
end


###############################################################################
# 4. Simple modeling of the review time
###############################################################################

# A simple model for the time taken to review based on data from table 2 on page 25
# of the paper: Van Rooyen, Susan, et al. "Effect of open peer review on quality of 
# reviews and on reviewers' recommendations: a randomised trial." Bmj 318.7175 (1999): 23-27.
# We add the constraint that each review takes at least one hour:
DistrTimeToReview = TruncatedNormal(2.25, 1.46, 1.0, Inf)
# but we also extend this model since it seems likely to us that it is easier to spot 
# papers that are clear rejects and thus they take somewhat shorter time to review:
DistrTimeToReviewClearRejects = TruncatedNormal(1.25, 1.0, 0.5, Inf)
# and we assume that the discussion time is somewhat longer for the "Messy Middle" papers
# since there is more disagreement between reviewers:
DistrTimeToDiscussMiddle = TruncatedNormal(1.0, 0.5, 0.25, Inf)
DistrTimeToDiscuss = TruncatedNormal(0.5, 0.5, 0.25, Inf)

function review_time(paperscore, numPaperReviews)
    dRevTime = (paperscore < LowCut) ? DistrTimeToReviewClearRejects : DistrTimeToReview
    dDiscTime = ismessymiddlepaper(paperscore) ? DistrTimeToDiscussMiddle : DistrTimeToDiscuss
    sum(rand(dRevTime, numPaperReviews)) + rand(dDiscTime)
end


###############################################################################
# 5. Now we are ready to simulate large numbers of ICSE review processes, given
#    different assumptions, processes and limiting policys.
###############################################################################

function simulate_review_process(numReps, limitingPolicyFn, probPrestigeBias, doubleBlindReview;
    acceptancerate = EstICSEAccRate,
    pbSize = PrestigeBiasSize,
    limitAffectsNumSubmissions = false
    )

    stats = zeros(Float64, 11, numReps) # 11 different stats collected per simulation

    @showprogress 1 "Simulating..." for i in 1:numReps
        papers, withhold = sample_all_submissions(rand(DistrNumSubmissions), limitingPolicyFn, limitAffectsNumSubmissions)

        # Review all papers and add their average score to the array describing them. Also
        # sum up the review times.
        total_review_and_discussion_time = 0.0
        apesum = 0.0 # Sum the Absolute Percentage Error between assigned and true score
        for p in papers
            numreviews = num_reviews_for_paper()
            truescore = p[3]
            scores = Float64[review_score(truescore, probPrestigeBias, doubleBlindReview, pbSize) for i in 1:numreviews]
            meanscore = mean(scores)
            push!(p, meanscore) # p[4] is now the assigned mean score
            ape = 100.0 * abs(meanscore - truescore) / truescore
            apesum += ape
            total_review_and_discussion_time += review_time(p[3], numreviews)
        end
        mape = apesum / length(papers)

        # Sort them on their average score and then select the top ones to give the desired
        # acceptance rate. We consider everything inside of 0.01 in grade to be a tie and
        # randomly sample among tied papers.
        papers_sorted = sort(papers, by = p -> p[4], rev=true)
        numaccepted = round(Int, acceptancerate * length(papers))
        cutoff = papers_sorted[numaccepted][4]
        clearly_accepted = filter(p -> p[4] >= cutoff + 0.01, papers)
        tied_papers = filter(p -> cutoff - 0.01 < p[4] < cutoff + 0.01, papers)
        accepted_from_tied = shuffle(tied_papers)[1:(numaccepted-length(clearly_accepted))]
        accepted_papers = vcat(clearly_accepted, accepted_from_tied)
        rejected_papers = filter(p -> !in(p, accepted_papers), papers)

        # Calc stats and save them
        NP = stats[1, i] = length(papers) # Num submitted papers
        NPH = length(filter(p -> p[2] == :high, papers))
        NPL = length(filter(p -> p[2] == :low, papers))

        # Acceptance rates for the High and Low prestige groups
        stats[2, i] = length(filter(p -> p[2] == :high, accepted_papers)) / NPH
        stats[3, i] = length(filter(p -> p[2] == :low, accepted_papers)) / NPL

        # One measure of community "broadness" can be the number of accepted groups
        stats[4, i] = num_accepted_groups = length(unique(map(t -> t[1], accepted_papers)))

        # We calc unfairness by calculating the ideal cutoff and accepted papers if the reviews
        # would have estimated the true quality of all papers. Any ties that arise are resolved
        # via random sampling (among papers with exact same quality as the cutoff). Unfairness
        # is then defined as papers that are rejected/accepted in actual process that would have
        # been accepted/rejected if review process was ideal. We judge errors within 0.01 in grade
        # to indicate a tie.
        papers_sorted_ideal = sort(papers, by = p -> p[3], rev=true)
        ideal_cutoff = papers_sorted_ideal[numaccepted][3]
        clearly_accepted_ideal = filter(p -> p[3] >= ideal_cutoff + 0.01, papers)
        tied_papers_ideal = filter(p -> ideal_cutoff - 0.01 < p[3] < ideal_cutoff + 0.01, papers)
        accepted_from_tied_ideal = shuffle(tied_papers_ideal)[1:(numaccepted-length(clearly_accepted_ideal))]
        ideally_accepted = vcat(clearly_accepted_ideal, accepted_from_tied_ideal)
        unfairly_rejected = filter(p -> in(p, ideally_accepted), rejected_papers)
        unfairly_accepted = filter(p -> !in(p, ideally_accepted), accepted_papers)

        # Num unfairly treated papers compared to an ideal process
        stats[5, i] = length(unfairly_rejected) / NP
        stats[6, i] = length(unfairly_accepted) / NP # should be same as unfairly_rejected but lets have it as sanity check
        stats[7, i] = stats[5, i] + stats[6, i]
        stats[8, i] = mape

        # Number of papers withhold
        stats[9, i] = withhold[1]
        stats[10, i] = withhold[2]

        # Total review and discussion time in days
        stats[11, i] = (total_review_and_discussion_time / 24.0)
    end

    stats
end

# Compare: NoAuthorLimit, AuthLimit3, AuthLimit2, DoubleBlind, DB+AuthLimit3
function compare_scenarios(N, probPrestigeBias, pbSize, limitAffectsNumSubmissions,
    acceptanceRate)

    println("No Author limit, No double blind")
    snl = simulate_review_process(N, no_author_limit, probPrestigeBias, false; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);
    println(mean(snl, 2))

    println("Author limit 3, No double blind, Groups sends best papers")
    sl3b = simulate_review_process(N, author_limit(3, true), probPrestigeBias, false; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);
    println(mean(sl3b, 2))

    println("Author limit 3, No double blind, Groups sends random papers")
    sl3r = simulate_review_process(N, author_limit(3, false), probPrestigeBias, false; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);
    println(mean(sl3r, 2))

    println("Author limit 2, No double blind, Groups sends best papers")
    sl2b = simulate_review_process(N, author_limit(2, true), probPrestigeBias, false; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);
    println(mean(sl2b, 2))

    println("Author limit 2, No double blind, Groups sends random papers")
    sl2r = simulate_review_process(N, author_limit(2, false), probPrestigeBias, false; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);
    println(mean(sl2r, 2))

    println("No Author limit, Double blind")
    sdb = simulate_review_process(N, no_author_limit, probPrestigeBias, true; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);
    println(mean(sdb, 2))

    println("Author limit 3, Double blind, Groups sends best papers")
    sdb3b = simulate_review_process(N, author_limit(3, true), probPrestigeBias, true; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);
    println(mean(sdb3b, 2))

    println("Author limit 3, Double blind, Groups sends random papers")
    sdb3r = simulate_review_process(N, author_limit(3, false), probPrestigeBias, true; 
        pbSize = pbSize, limitAffectsNumSubmissions = limitAffectsNumSubmissions, acceptancerate = acceptanceRate);

    res = hcat(mean(snl, 2), mean(sl3b, 2), mean(sl3r, 2), mean(sl2b, 2), mean(sl2r, 2), 
        mean(sdb, 2), mean(sdb3b, 2), mean(sdb3r, 2))

    digits = 1
    df = DataFrame(
        Methods = AbstractString["NoAuthLimit", "AuthLimit3Best", "AuthLimit3Rnd", 
            "AuthLimit2Best", "AuthLimit2Rnd", "DoubleBlind", "DB+AuthLimit3Best", "DB+AuthLimit3Rnd"]
    )
    df[:NumSubm] = map(v -> round(v, digits), res[1,:][:])
    df[:RevTimeDays] = map(v -> round(v, digits), res[11,:][:])
    df[:Withhold] = map(v -> round(v, digits), res[9,:][:] .+ res[10,:][:])
    df[:NumGroups] = map(v -> round(v, digits), res[4,:][:])
    df[:Unfair] = map(v -> round(100.0 * v, digits), res[7,:][:])
    df[:UnfairRej] = map(v -> round(100.0 * v, digits), res[5,:][:])
    df[:UnfairAcc] = map(v -> round(100.0 * v, digits), res[6,:][:])
    df[:MAPE] = map(v -> round(v, digits), res[8,:][:])
    df[:AccRateHiPr] = map(v -> round(100.0 * v, digits), res[2,:][:])
    df[:AccRateLoPr] = map(v -> round(100.0 * v, digits), res[3,:][:])

    return res, df, Any[snl, sl3b, sl3rm, sl2b, sl2r, sdb, sdb3b, sdb3r]
end

N = 50000 # Seems stable after 1e4 but why not go longer; we have the CPU power & mem... ;)

# Let's assume there is no Prestige Bias and author limit has effect on num submissions:
probPrestigeBias = 0.0
sizePrestigeBias = 0.0*NumGrades
AuthLimitReducesSubmissions = true
@time res_0_0_eff, df_0_0_eff, ad_0_0_eff = compare_scenarios(N, 
    probPrestigeBias, sizePrestigeBias, AuthLimitReducesSubmissions, EstICSEAccRate);
println(sort!(df_0_0_eff, cols = [:Unfair, :Withhold, :RevTimeDays]))

# Robert's case: I think there is some Prestige bias but quite low probability and 
# quite low in effect, let's estimate 20% chance it has an effect and that the effect 
# is a 15% higher grade. I also think any author limit is not likely to affect the total.
probPrestigeBias = 0.20
sizePrestigeBias = 0.15*NumGrades
AuthLimitReducesSubmissions = false
@time res_20_15_noeff, df_20_15_noeff, ad_20_15_noeff = compare_scenarios(N, 
    probPrestigeBias, sizePrestigeBias, AuthLimitReducesSubmissions, EstICSEAccRate);
println(sort!(df_20_15_noeff, cols = [:Unfair, :Withhold, :RevTimeDays]))

# But this is likely to be very sensitive to the distribution one guesstimates for the
# true quality of papers. For example if we rerun Roberts scenario but assuming papers
# from low-prestigious groups have same quality as high-prestigious ones we get:
DistrPaperQualityLowPrestige = DistrPaperQualityHighPrestige
@time res_20_15_noeff_samedistr, df_20_15_noeff_samedistr, ad_20_15_noeff_samedistr = compare_scenarios(N, 
    probPrestigeBias, sizePrestigeBias, AuthLimitReducesSubmissions, EstICSEAccRate);

# Sort based on prio: 1. Least unfair, 2. Fewest papers withhold, 3. Review time in days
println(sort!(df_0_0_eff, cols = [:Unfair, :Withhold, :RevTimeDays]))
println(sort!(df_20_15_noeff, cols = [:Unfair, :Withhold, :RevTimeDays]))
println(sort!(df_20_15_noeff_samedistr, cols = [:Unfair, :Withhold, :RevTimeDays]))

TotalNumSimulations = 8 * N * 3

# Save results as csv files:
Conf = "ICSE17"
ts = Libc.strftime("%Y%m%d_%H%M%S_$(round(Int, N/1000))k", time())
writetable("results/$(Conf)_$(ts)_noprestigebias_authlimitreducessubmissions.csv", df_0_0_eff)
writetable("results/$(Conf)_$(ts)_prestigebias_20_15_authlimitnoreduction.csv", df_20_15_noeff)
writetable("results/$(Conf)_$(ts)_prestigebias_20_15_authlimitnoreduction_sameqdistr.csv", df_20_15_noeff_samedistr)

# Save raw data as serialized julia data if we need to read it back in for further analysis:
open(fh -> serialize(fh, res_0_0_eff), "results/$(Conf)_$(ts)_noprestigebias_authlimitreducessubmissions.jldata", "w")
open(fh -> serialize(fh, res_20_15_noeff), "results/$(Conf)_$(ts)_prestigebias_20_15_authlimitnoreduction.jldata", "w")
open(fh -> serialize(fh, res_20_15_noeff_samedistr), "results/$(Conf)_$(ts)_prestigebias_20_15_authlimitnoreduction_sameqdistr.jldata", "w")
open(fh -> serialize(fh, ad_0_0_eff), "results/$(Conf)_$(ts)_noprestigebias_authlimitreducessubmissions_all.jldata", "w")
open(fh -> serialize(fh, ad_20_15_noeff), "results/$(Conf)_$(ts)_prestigebias_20_15_authlimitnoreduction_all.jldata", "w")
open(fh -> serialize(fh, ad_20_15_noeff_samedistr), "results/$(Conf)_$(ts)_prestigebias_20_15_authlimitnoreduction_sameqdistr_all.jldata", "w")
