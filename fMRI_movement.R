# (c) Irene Sophia Plank (10planki@gmail.com)

# libraries
library(purrr)
library(tidyverse)

# set working directory
path = '/home/iplank/Documents/fmriprep/'
setwd(path)

# get list of files
ls.fl = list.files(pattern = "_desc-confounds_timeseries.tsv$", recursive = T)

# columns of interest
cols = c("trans_x", "trans_y", "trans_z",
         "rot_x", "rot_y", "rot_z", "framewise_displacement")

# read in the data
df = set_names(ls.fl) %>%
  map(read_delim, col_select = cols, show_col_types = F) %>%
  list_rbind(names_to = "path") %>% 
  mutate(
    subject = substr(path, 1, 14),
    task    = substr(path, 36, 41)
  ) %>%
  select(-path) %>%
  relocate(subject, task)

# create a df showing maxima
df.agg = df %>%
  group_by(subject, task) %>%
  mutate(
    across(where(is.numeric), abs)
  ) %>%
  summarise(across(
    .cols = where(is.numeric),
    .fns = list(max = max), na.rm = T,                                          # list(mean = mean, sd = sd, max = max), na.rm = T,
    .names = "{col}_{fn}"
  ))

# check if someone has to be excluded
df.agg %>% 
  filter(if_any(where(is.numeric), ~ .x > 3))
