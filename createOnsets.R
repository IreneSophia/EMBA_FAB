# script to divide log files properly
library(tidyverse)

# figure out which files need to be converted
pt.fls = paste('/home/iplank/Documents/EMBA', 'BVET', sep = "/")               # file path

# load in all continuous run data
df.log1 = list.files(path = pt.fls, pattern = ".*task.tsv$", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_delim(., show_col_types = F, delim = "\t"), .id = "Filename") %>% 
  rename("subID" = "Subject") %>%
  select(-Filename) %>%
  mutate(
    Run = case_when(
      Trial == 2 ~ 1,
      Trial > 2500 & `Event Type` == "Response" & Code == "5" ~ 2
    )
  ) %>%
  fill(Run) %>%
  filter(Code == "255") %>%                                       # only keep pulses
  mutate(
    subID = case_when(subID == "MXIVJZQSI" ~ "MXIVJYZQSI", 
                      subID == "NZEHEUA0OZ" ~ "NZEJEIA0OZ",
                      TRUE ~ subID)
  ) %>%
  select(subID, Run, Trial, `Event Type`, Code, Time) %>% 
  group_by(subID, Run) %>%                                        # create durations for the pulses
  mutate(
    Duration = Time - lag(Time, default = first(Time))
  ) 

idx = which(df.log1$Duration > 25000 | df.log1$Duration == 0)
idx.start = c()
for (i in 1:(length(idx)-1)) {
  if (idx[i+1] - idx[i] > 1) {
    idx.start = c(idx.start, idx[i])
  }
}
idx.start = c(idx.start, idx[i+1])

df.log1$Duration[idx.start] = 24500

df.log1 = df.log1 %>%
  fill(Run) %>%
  filter(Duration < 25000 & Duration > 0)

# do the same for separate runs
df.log2 = list.files(path = pt.fls, pattern = ".*-vMMN-task-.*.tsv$", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_delim(., show_col_types = F, delim = "\t"), .id = "Filename") %>% 
  filter(Code == "255") %>%
  rename("subID" = "Subject") %>%
  mutate(
    subID = case_when(subID == "MXIVJZQSI" ~ "MXIVJYZQSI", 
                      subID == "NZEHEUA0OZ" ~ "NZEJEIA0OZ",
                      TRUE ~ subID),
    Run   = as.numeric(gsub(".*task-", "", gsub("*\\.tsv", "", Filename)))
  ) %>%
  select(subID, Trial, Run, `Event Type`, Code, Time) %>% 
  group_by(subID, Run) %>%
  mutate(
    Duration = Time - lag(Time, default = first(Time))
  )

# find all durations at the beginning (== 0) and in between (longer than tr)
idx = which(df.log2$Duration == 0 | df.log2$Duration > 25000)

# based on this figure out the first relevant pulse -> which is one tr before the next
idx.start = c()
for (i in 1:(length(idx)-1)) {
  if (idx[i+1] - idx[i] > 1) {
    idx.start = c(idx.start, idx[i])
  }
}
idx.start = c(idx.start, idx[i+1])
df.log2[idx.start,]$Duration = 24500

df.log2 = df.log2 %>% filter(Duration != 0, Duration < 25000)

# combine both data frames to one and exclude 32 channel participants
exclude = c("T4MEQ9ZCYN", "RWAHJJ8EYU", "T0MTB7O39O", "KP8UE7DAZ7", "MXIVJYZQSI", "6WB8QM8U95", "NCUQ5GM4PG")
df.vmm = rbind(df.log1, df.log2) %>%
  arrange(subID, Run, Time) %>%
  filter(!(subID %in% exclude))

df.agg = df.vmm %>%
  group_by(subID, Run) %>%
  summarise(
    trls.vmm = n(),
    first    = min(Time)
  ) %>%
  filter(subID != "9LMQ41HBG8") %>%
  pivot_wider(names_from = Run, values_from = c(trls.vmm, first), names_prefix = "run_")

df.first = df.vmm
