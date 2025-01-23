# settings and library
library(tidyverse)       # tibble stuff

fl.path = '/home/emba/Documents/EMBA'
dt.path = paste(fl.path, 'BVET', sep = "/")
dt.path = paste(fl.path, 'BVET-explo', sep = "/")

# how long does one flip of the screen take in ms?
flip = 1000/60

# load the relevant data in long format
df.tsk = list.files(path = dt.path, pattern = "FAB-BV_*", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F, col_types = "cddddddddcd"), .id = "fln") %>% 
  mutate(subID = substr(fln, nchar(fln)-27, nchar(fln)-18),
         target = as.factor(target),
         target = recode(target, 
                         "1" = "left",
                         "2" = "right"),
         # sometimes participants used wrong row or caps was on
         choice = recode(key,
                         "4" = "left",
                         "LeftArrow" = "left", 
                         "1" = "left", 
                         "RightArrow" = "right", 
                         "6" = "right", 
                         "+" = "right"),
         acc = target == choice,
         cue = as.factor(congruent),
         cue = recode_factor(cue,
                             "1" = "face",
                             "0" = "object"),
         stm = if_else(left < right, paste(left, right, sep = "_"), paste(right, left, sep = "_"))) %>%
  filter(nchar(subID) == 10) %>% 
  # outlier detection with IQR method
  group_by(subID) %>%
  mutate(rt.up = quantile(rt, 0.75) + 1.5 * IQR(rt),
         rt.lo = quantile(rt, 0.25) - 1.5 * IQR(rt),
         # which rts should be used for analyses?
         use   = case_when(!is.na(rt) & 
                             acc &                  # answer is accurate
                             rt > rt.lo &           # IQR lower boundary
                             rt < rt.up &           # IQR upper boundary
                             cue_dur < 200 + flip & # cue duration not more than one screen flip off
                             cue_dur > 200 - flip
                           ~ T,
                           T ~ F),
         rt.cor = if_else(use, rt, NA)
  ) %>%
  select(subID, trl, stm, rt, rt.cor, acc, use, cue, target) 

df.tsk_acc = df.tsk %>%
  group_by(subID) %>%
  summarise(
    acc = mean(use)
  )

# does anyone have to be excluded?
exc = df.tsk_acc %>% filter(acc < 2/3)
exc = as.character(exc$subID)

# load pilot participants and add to the list. 
pilot = read_csv(paste0(dt.path, "/pilot-subIDs.csv"), show_col_types = F)
# save the excluded subjects
write(setdiff(exc, pilot$subID), file.path(dt.path, "FAB_exc.txt"))
exc   = c(exc, pilot$subID)

# exclude these participants
df.tsk = df.tsk %>% filter(!(subID %in% exc))

# save data frame
saveRDS(df.tsk, paste0(dt.path, "/df_FAB.RDS"))
