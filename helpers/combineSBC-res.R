library(SBC)
library(tidyverse)

setwd("..")

code = "FAB_err"
cache_dir = "_brms_SBC_cache"

full_dir = file.path(getwd(), cache_dir)

fl.ls = list.files(path = full_dir, 
                   pattern = sprintf("^res_%s_.*.rds", code), full.names = T)

#fl.ls = c(fl.ls[1], fl.ls[3:10], fl.ls[2])

tictoc::tic()
res = readRDS(fl.ls[1])

stats    = res$result$stats
errors   = res$result$errors
outputs  = res$result$outputs
warnings = res$result$warnings
messages = res$result$messages
backend_diagnostics = res$result$backend_diagnostics
default_diagnostics = res$result$default_diagnostics

rm(res)
gc()

tictoc::toc()

count = length(messages)

for (i in 2:(length(fl.ls))) {
  tictoc::tic()
  res       = readRDS(fl.ls[i])
  stats     = rbind(stats, res$result$stats %>% mutate(sim_id = sim_id + count))
  errors    = c(errors,    res$result$errors)
  outputs   = c(outputs,   res$result$outputs)
  messages  = c(messages,  res$result$messages)
  warnings  = c(warnings,  res$result$warnings)
  backend_diagnostics = rbind(backend_diagnostics, res$result$backend_diagnostics %>% mutate(sim_id = sim_id + count))
  default_diagnostics = rbind(default_diagnostics, res$result$default_diagnostics %>% mutate(sim_id = sim_id + count))
  count = length(messages)
  rm(res)
  gc()
  tictoc::toc()
}

# add missing sim_ids for models that failed
sim_ids = 1:length(messages)
missing = setdiff(sim_ids, backend_diagnostics$sim_id)
for (i in missing) {
  backend_diagnostics[nrow(backend_diagnostics) + 1, ] = NA
  backend_diagnostics[nrow(backend_diagnostics),]$sim_id = i
  default_diagnostics[nrow(default_diagnostics) + 1, ] = NA
  default_diagnostics[nrow(default_diagnostics),]$sim_id = i
}
default_diagnostics = default_diagnostics %>% arrange(sim_id)
backend_diagnostics = backend_diagnostics %>% arrange(sim_id)

res = SBC_results(
  stats,
  fits = as.list(rep(NA, times = length(messages))),
  backend_diagnostics,
  default_diagnostics,
  outputs,
  messages,
  warnings,
  errors
)

saveRDS(res, file.path(cache_dir, paste0("res_", code, ".rds")))
saveRDS(res$stats, file = file.path(cache_dir, paste0("df_res_", code, ".rds")))
saveRDS(res$backend_diagnostics, file = file.path(cache_dir, paste0("df_div_", code, ".rds")))

stats %>% 
  group_by(sim_id) %>% 
  summarise(rhat = max(rhat, na.rm = T)) %>% 
  filter(rhat >= 1.05) %>% count()

backend_diagnostics %>% 
  filter(n_divergent > 0) %>% count()
