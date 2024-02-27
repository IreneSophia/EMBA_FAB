# setup
library(tidyverse)
fl.path = '/home/emba/Documents/EMBA'
dt.path = paste(fl.path, 'BVET', sep = "/")

# some info on the experiment
screenX = 2560
screenY = 1600
sizeFix = 80
sizeCue = 326
maxAng  = atan(((sizeCue/2)/sizeFix)) * (180.0 / pi)

# load the relevant saccade data in long format
df = list.files(path = dt.path, pattern = "FAB-ET.*_saccades.csv", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F), .id = "fln") %>% 
  mutate(
    subID = gsub(paste0(dt.path,"/FAB-ET-"), "", gsub("_saccades.csv", "", fln)),
    on_AOI  = case_when(
      on_xPixel   >= (screenX/2 - sizeFix/2) & on_xPixel <= (screenX/2 + sizeFix/2) &
        on_yPixel >= (screenY/2 - sizeCue/2) & on_yPixel <= (screenY/2 + sizeCue/2) ~ "fix"
    ),
    dir_xPixel = off_xPixel - on_xPixel,
    dir_yPixel = off_yPixel - on_yPixel,
    dir_degree = round(atan(dir_yPixel/dir_xPixel) * ( 180.0 / pi ), 2),
    dir_x = if_else(dir_xPixel > 0, "right", "left")
  )

# only keep relevant saccades and classify where they end
df.sac = df %>%
  filter((on_trialType == "cue" | on_trialType == "tar") & 
           on_AOI == "fix" &
           abs(dir_degree) <= maxAng &
           nchar(subID) == 10 # filters out excluded participants
         ) %>%
  mutate_if(is.character, as.factor) %>%
  # add counter for saccades per trial
  group_by(subID, on_trialNo) %>%
  arrange(subID, on) %>%
  mutate(sac_trl = row_number()) %>%
  ungroup() %>%
  mutate(
    dir_target = dir_x == on_trialTar,
    dir_face   = if_else(
      (dir_target == T & on_trialCue == "face") | (dir_target == F & on_trialCue == "object"), T,
      F
    )
  ) %>%
  rename("trl" = "on_trialNo", "cue" = "on_trialCue", "target" = "on_trialTar", 
         "stm" = "on_trialStm", "lat" = "on_timeCue") %>%
  select(subID, trl, stm, cue, target, on_trialType, off_trialType, sac_trl, dir_degree, dir_target, dir_face, lat)

# save the data for analysis
save(file = paste(dt.path, "FAB_ET_data.RData", sep = "/"), list = c("df.sac"))
