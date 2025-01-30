# setup
library(tidyverse)
fl.path = '/home/emba/Documents/EMBA'
dt.path = paste(fl.path, 'BVET', sep = "/")
#dt.path = paste(fl.path, 'BVET-explo', sep = "/")

# some info on the experiment
screenX = 2560
screenY = 1600
sizeFix = 80
sizeCue = 326
maxAng  = atan((sizeCue/sizeFix)) * (180.0 / pi)

# load the relevant saccade data in long format
df = list.files(path = dt.path, pattern = "^FAB-ET.*_saccades.csv", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F), .id = "fln") %>% 
  mutate(
    subID = gsub(paste0(dt.path,"/FAB-ET-"), "", gsub("_saccades.csv", "", fln)),
    on_distCen  = sqrt((on_xPixel-(screenX/2))^2 + (on_yPixel-(screenY/2))^2),
    dir_xPixel = off_xPixel - on_xPixel,
    dir_yPixel = off_yPixel - on_yPixel,
    dir_degree = round(atan(dir_yPixel/dir_xPixel) * ( 180.0 / pi ), 2),
    dir_x = if_else(dir_xPixel > 0, "right", "left")
  ) %>% select(-fln)

# only keep relevant saccades and classify where they end
df.sac = df %>%
  filter((on_trialType == "cue" | on_trialType == "tar") & 
           on_distCen <= (sizeFix/2) &
           abs(dir_degree) <= maxAng
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

# check if there is someone who did not have any saccades
noSac = setdiff(unique(df$subID), unique(df.sac$subID))

# add them to dataframe with NAs
for (sub in noSac) {
  df.sac = df.sac %>% add_row(subID = sub)
}

# save the data for analysis
saveRDS(df.sac, file = file.path(dt.path, "FAB_ET_data.rds"))
