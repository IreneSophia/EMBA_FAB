# setup
library(tidyverse)

# paths
fl.path  = '/home/emba/Documents/EMBA'
dt.path  = paste(fl.path, 'BVET', sep = "/")
dt.explo = paste(fl.path, 'BVET-explo', sep = "/")

# some info on the experiment
screenX = 2560
screenY = 1600
sizeFix = 80
sizeCue = 326

# fixation data
df.fix = c(list.files(path = dt.path,  pattern = "^FAB-ET.*_fixations.csv", full.names = T),
           list.files(path = dt.explo, pattern = "^FAB-ET.*_fixations.csv", full.names = T))%>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F), .id = "fln") %>% 
  mutate(
    subID = gsub(".*FAB-ET-(.+)_fixations.*", "\\1", fln), 
    fln   = NULL
  ) %>%
  # only keep fixations that started within a trial and ended on the same trial
  filter(!is.na(on_trialType) & (on_trialNo == off_trialNo)) %>%
  mutate_if(is.character, as.factor) %>%
  rename("trl" = "on_trialNo", "stm" = "on_trialStm", "cue" = "on_trialCue") %>%
  # only keep the fixations that are on the cue areas
  filter(
    # left cue area
    ((meanX_pix >= (screenX/2 - sizeCue - sizeFix/2) & meanX_pix <= (screenX/2 - sizeFix/2)) | 
    # right cue area
      (meanX_pix >= (screenX/2 + sizeFix/2) & meanX_pix <= (screenX/2 + sizeCue + sizeFix/2))) &
    # vertical area
      (meanY_pix <= (screenY/2 + sizeCue/2) & meanY_pix >= (screenY/2 - sizeCue/2))
  ) %>%
  # only keep fixations that started before or at the threshold between cue
  # and target-elicited saccades
  filter(on_timeCue <= 331) %>%
  select(subID, trl, stm, cue, meanX_pix, meanY_pix, duration, 
         on_timeCue, off_timeCue, on_trialTar) 

# add whether fixation was on the side of the face or not
df.fix = df.fix %>%
  mutate(
    side  = if_else(meanX_pix >= screenX/2, "right", "left"),
    onTar = on_trialTar == side,
    ROI = case_when(
      cue == "face"   &  onTar ~ "face",
      cue == "face"   & !onTar ~ "object",
      cue == "object" &  onTar ~ "object",
      cue == "object" & !onTar ~ "face"
    )
  )

# are there any people without any relevant fixations? Yes, 2
length(setdiff(levels(df.fix$subID), unique(df.fix$subID)))

# load excluded participants (low accuracy, change)
exc = c(scan(file.path(dt.path, 'FAB_exc.txt'), what="character", sep=NULL),
        scan(file.path(dt.explo, 'FAB_exc.txt'), what="character", sep=NULL))

# merge with the diagnosis information
df.fix = merge(read_csv(file.path("/home/emba/Documents/EMBA/CentraXX", "EMBA_centraXX.csv"), 
                  show_col_types = F) %>% 
                 mutate(diagnosis = recode(diagnosis, "CTR" = "COMP")) %>%
                 # exclude one person due to change in diagnosis
                 filter(!(subID %in% exc)) %>%
                 select(subID, diagnosis), 
               df.fix) %>%
  mutate_if(is.character, as.factor) %>%
  # anonymise the data
  mutate(
    subID = as.factor(as.numeric(subID))
  )

# save the data for analysis
saveRDS(df.fix, file = file.path("FAB_ET_fix.rds"))
