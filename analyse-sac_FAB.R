# setup
library(tidyverse)
fl.path = '/home/emba/Documents/EMBA'
dt.path = paste(fl.path, 'BVET', sep = "/")

# some info on the experiment
screenX = 2560
screenY = 1600
sizeFix = 80
sizeCue = 326

# load the relevant saccade data in long format
df.sac = list.files(path = dt.path, pattern = "FAB-ET.*_saccades.csv", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F), .id = "fln") %>% 
  mutate(
    subID = gsub(paste0(dt.path,"/FAB-ET-"), "", gsub("_saccades.csv", "", fln)),
    on_AOI  = case_when(
      on_xPixel   >= (screenX/2 - sizeFix/2) & on_xPixel <= (screenX/2 + sizeFix/2) &
        on_yPixel >= (screenY/2 - sizeCue/2) & on_yPixel <= (screenY/2 + sizeCue/2) ~ "fix",
      on_xPixel   >= (screenX/2 - sizeFix/2 - sizeCue) & on_xPixel < (screenX/2 - sizeFix/2) &
        on_yPixel >= (screenY/2 - sizeCue/2) & on_yPixel <= (screenY/2 + sizeCue/2) ~ "left",
      on_xPixel   >= (screenX/2 + sizeFix/2) & on_xPixel < (screenX/2 + sizeFix/2 + sizeCue) &
        on_yPixel >= (screenY/2 - sizeCue/2) & on_yPixel <= (screenY/2 + sizeCue/2) ~ "right"
    ),
    off_AOI = case_when(
      off_xPixel   >= (screenX/2 - sizeFix/2) & off_xPixel <= (screenX/2 + sizeFix/2) &
        off_yPixel >= (screenY/2 - sizeCue/2) & off_yPixel <= (screenY/2 + sizeCue/2) ~ "fix",
      off_xPixel   >= (screenX/2 - sizeFix/2 - sizeCue) & off_xPixel < (screenX/2 - sizeFix/2) &
        off_yPixel >= (screenY/2 - sizeCue/2) & off_yPixel <= (screenY/2 + sizeCue/2) ~ "left",
      off_xPixel   >= (screenX/2 + sizeFix/2) & off_xPixel < (screenX/2 + sizeFix/2 + sizeCue) &
        off_yPixel >= (screenY/2 - sizeCue/2) & off_yPixel <= (screenY/2 + sizeCue/2) ~ "right"
    )
  )

# saccades that end up at the area of the correct target
df.lat = df.sac %>%
  # filter only saccades during targets and cues
  filter(on_trialType != "fix" & !is.na(on_trialType) & 
           # where the saccade starts at the fixation cross and ends at the correct target
           on_AOI == "fix" & off_AOI == off_trialTar & 
           # and where the start and finish is within the same trial
           on_trialNo == off_trialNo) %>%
  # outlier detection with IQR method
  group_by(subID) %>%
  mutate(
         lat.up = quantile(on_timeTar, 0.75, na.rm = T) + 1.5 * IQR(on_timeTar, na.rm = T),
         lat.lo = quantile(on_timeTar, 0.25, na.rm = T) - 1.5 * IQR(on_timeTar, na.rm = T),
         lat    = case_when(on_timeTar > lat.lo & on_timeTar < lat.up ~ on_timeTar)
  ) %>% 
  filter(!is.na(lat)) %>%
  # only keep the latency of the first saccade of a trial
  group_by(subID, on_trialNo) %>%
  arrange(subID, on_trialNo) %>%
  filter(row_number() == 1) %>%
  group_by(subID, off_trialCue) %>%
  summarise(
    n.tar    = sum(!is.na(lat)),
    lat.tar  = median(lat, na.rm = T)
  ) %>%
  filter(n.tar >= 5)

df.lat

# saccades towards the face
df.cnt = df.sac %>%
  filter(on_trialType != "fix" & on_AOI == "fix") %>%
  mutate(
    sac_cue = case_when(
      (on_trialCue == "face" & off_AOI == on_trialTar) |
      (on_trialCue == "object" & on_trialTar == "left" & off_AOI == "right") |
      (on_trialCue == "object" & on_trialTar == "right" & off_AOI == "left") ~ "face",
      (on_trialCue == "object" & off_AOI == on_trialTar) |
      (on_trialCue == "face" & on_trialTar == "left" & off_AOI == "right") |
      (on_trialCue == "face" & on_trialTar == "right" & off_AOI == "left") ~ "object"
    )
  ) %>%
  filter(!is.na(sac_cue)) %>% 
  group_by(subID, sac_cue) %>% 
  summarise(
    n.cue = n()
  )

df.cnt

# visualise the distributions
ggplot(data = df.cnt, aes(x = n.cue)) +
  geom_density(alpha = .3, colour = "lightgrey", fill = "lightblue") + 
  theme_bw()

ggplot(data = df.lat, aes(x = lat.tar)) +
  geom_density(alpha = .3, colour = "lightgrey", fill = "lightblue") + 
  theme_bw()