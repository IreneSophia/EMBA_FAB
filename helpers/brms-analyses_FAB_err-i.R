ls.packages = c("brms",             # Bayesian lmms
                "SBC",              # plots for checking computational faithfulness
                "tidyverse"         # tibble stuff
                )

lapply(ls.packages, library, character.only=TRUE)

# set cores
options(mc.cores = parallel::detectCores())

setwd('..')

# settings for the SBC package
use_cmdstanr = getOption("SBC.vignettes_cmdstanr", TRUE) # Set to false to use rst
options(brms.backend = "cmdstanr")
cache_dir = "./_brms_SBC_cache"
if(!dir.exists(cache_dir)) {
  dir.create(cache_dir)
}

# Using parallel processing
library(future)

# get data information
load("FAB_data.RData")
  
# set and print the contrasts
contrasts(df.fab$cue) = contr.sum(2)
contrasts(df.fab$cue)
contrasts(df.fab$diagnosis) = contr.sum(3)
contrasts(df.fab$diagnosis)

# number of simulations
nsim = 250

code = "FAB_err"

# increase iterations a bit to improve rhats
iter = 4000
warm = 2000

# code accuracy to track errors
df.fab.full = rbind(df.fab, df.exp) %>%
  mutate(
    error = if_else(acc,0,1)
  )

# set the levels of the diagnosis factor
df.fab$diagnosis = factor(df.fab$diagnosis, 
                          levels = c("ADHD", "ASD", "BOTH", "COMP"))

# set the formula
f.err = brms::bf(error ~ diagnosis * cue + (cue | subID) + (diagnosis * cue | stm) )

# set weakly informed priors
priors = c(
  prior(normal(6.0,   1.00), class = Intercept),
  prior(normal(1.0,   0.50), class = sd),
  prior(lkj(2),  class = cor),
  # no specific expectations for the rest of the effects
  prior(normal(0,     1.00), class = b)
)

# get number which have been created already
ls.files = list.files(path = cache_dir, pattern = sprintf("res_%s_.*", code))
if (is_empty(ls.files)) {
  i = 1
} else {
  i = max(readr::parse_number(ls.files)) + 1
}
m = 25

# set seed
set.seed(248+i) 

gen = SBC_generator_brms(f.err, data = df.fab.full, prior = priors, 
                         thin = 50, warmup = 10000, refresh = 2000,
                         generate_lp = TRUE, family = bernoulli, init = 0.1)
if (!file.exists(file.path(cache_dir, sprintf("dat_%s.rds", code)))) {
  dat = generate_datasets(gen, nsim)
  saveRDS(dat, file.path(cache_dir, sprintf("dat_%s.rds", code)))
} else {
  dat = readRDS(file.path(cache_dir, sprintf("dat_%s.rds", code)))
}

write(sprintf('%s: %s %d', now(), code, i), sprintf("%slog_FAB-full.txt", "./logfiles/"), append = TRUE)

bck = SBC_backend_brms_from_generator(gen, chains = 4, thin = 1,
                                      warmup = warm, iter = iter)
plan(multisession)
print("start res")
res = compute_SBC(SBC_datasets(dat$variables[((i-1)*m + 1):(i*m),], 
                               dat$generated[((i-1)*m + 1):(i*m)]), 
                  bck,
                  cache_mode     = "results", 
                  cache_location = file.path(cache_dir, sprintf("res_%s_%02d", code, i)))
                  
write(sprintf('%s: DONE %d', now(), i), sprintf("%slog_FAB-err.txt", "./logfiles/"), append = TRUE)
