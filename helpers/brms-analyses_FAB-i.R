ls.packages = c("knitr",            # kable
                "ggplot2",          # plots
                "brms",             # Bayesian lmms
                "designr",          # simLMM
                "bridgesampling",   # bridge_sampler
                "tidyverse",        # tibble stuff
                "ggpubr",           # ggarrange
                "ggrain",           # geom_rain
                "bayesplot",        # plots for posterior predictive checks
                "SBC",              # plots for checking computational faithfulness
                "rstatix",          # anova
                "BayesFactor"
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

# get demographic information
load("FAB_data.RData")
  
# set and print the contrasts
contrasts(df.fab$cue) = contr.sum(2)
contrasts(df.fab$cue)
contrasts(df.fab$diagnosis) = contr.sum(3)
contrasts(df.fab$diagnosis)

# number of simulations
nsim = 250

code = "FAB"

# full model formula
f.fab = brms::bf(rt.cor ~ diagnosis * cue + (cue | subID) + (cue * diagnosis | stm) )

# set informed priors based on previous results
priors = c(
  # general priors based on SBV
  prior(normal(6, 0.3),  class = Intercept),
  prior(normal(0, 0.5),  class = sigma),
  prior(normal(0, 0.1),  class = sd),
  prior(lkj(2),          class = cor),
  # face attention bias effect based on Jakobsen et al. (2021)
  prior(normal(-0.01, 0.04), class = b, coef = cue1),
  # ADHD subjects being slower based on Pievsky & McGrath (2018)
  prior(normal(0.025, 0.04),   class = b, coef = diagnosis1),
  # ASD subjects being slower based on Morrison et al. (2018)
  prior(normal(0.025, 0.04),   class = b, coef = diagnosis2),
  # decreased FAB in ASD subjects based on Moore et al. (2012)
  prior(normal(0.01,  0.04),   class = b, coef = diagnosis2:cue1),
  # no specific expectations for FAB in ADHD
  prior(normal(0,     0.04), class = b),
  # shift
  prior(normal(200,   100), class = ndt)
)

# get number which have been created already
ls.files = list.files(path = cache_dir, pattern = sprintf("res_%s_.*", code))
if (is_empty(ls.files)) {
  i = 1
} else {
  i = max(readr::parse_number(ls.files)) + 1
}
m = 10

# set seed
set.seed(248+i) 

# create the data and the results
gen  = SBC_generator_brms(f.fab, data = df.fab, prior = priors, family = shifted_lognormal,
                          thin = 50, warmup = 20000, refresh = 2000)
if (!file.exists(file.path(cache_dir, paste0("dat_", code, ".rds")))){
  dat = generate_datasets(gen, nsim) 
  saveRDS(dat, file = file.path(cache_dir, paste0("dat_", code, ".rds")))
} else {
  dat = readRDS(file = file.path(cache_dir, paste0("dat_", code, ".rds")))
}

write(sprintf('%s: %s %d', now(), code, i), sprintf("%slog_FAB-full.txt", "./logfiles/"), append = TRUE)

bck = SBC_backend_brms_from_generator(gen, chains = 4, thin = 1,
                                      init = 0.1, warmup = 1000, iter = 3000)
plan(multisession)
print("start res")
res = compute_SBC(SBC_datasets(dat$variables[((i-1)*m + 1):(i*m),], 
                               dat$generated[((i-1)*m + 1):(i*m)]), 
                  bck,
                  cache_mode     = "results", 
                  cache_location = file.path(cache_dir, sprintf("res_%s_%02d", code, i)))
                  
write(sprintf('%s: DONE %d', now(), i), sprintf("%slog_FAB-full.txt", "./logfiles/"), append = TRUE)
