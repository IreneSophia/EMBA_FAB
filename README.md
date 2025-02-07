# EMBA: using the Bayesian Brain to investigate the specificity of emotion recognition differences in autism and ADHD

Mutual social interactions require people to be aware of the affective state of their counterpart. An important source for this is facial expressions, which can be indicative of the emotions experienced by the other person. Individuals with autism spectrum disorder (ASD) often have difficulties with this function. Despite the extensive documentation of such differences, it is still unclear which processes underlie attenuated emotion recognition in ASD. In this project, we aim to use a prominent human brain theory called the Bayesian Brain to evaluate the impact of three mechanisms on emotion recognition in individuals with ASD at the neural and behavioural levels: (1) emotional face processing, (2) learning of associations between contextual cues and facial expressions associated with emotions, and (3) biased attention for faces. We also plan to include individuals with attention deficit hyperactivity disorder (ADHD) as clinical controls in addition to a sample of people with no neurodevelopmental disorder (NND). This allows us to determine whether differences in emotion recognition can be attributed to attentional deficits or are unspecific for the included developmental disorders. The results of this project will not only shed more light on the causes of deficits in emotion recognition in people with ASD, but also provide the basis for developing a model of the similarities and differences in processes of the Bayesian Brain in neurodevelopmental disorders.

## Face attention bias (FAB)

In this repository, we will focus on the paradigm measuring face attention bias (FAB) with the dot probe paradigm. In this paradigm, participants are asked to indicate the location of a black square as fast as possible. Before the target square appears, two cues are presented for a short duration (200ms), one on the left and one on the right of the fixation cross. One cue is always a face while the other is an object. We will compare reaction times to target squares and saccades between the three groups (ADHD vs. ASD vs. no neurodevelopmental disorder, NND) as well as between two conditions (target appears on the side of the face vs. target appears on the side of the object). 

Participants also perform three additional paradigms: a facial emotion recognition task (FER), a probabilistic associative learning task (PAL) and a visual mismatch task (VMM). The preregistrations for this project are on [OSF](https://osf.io/znrht) and currently embargoed as the data collection is still ongoing. The preregistrations will be made public when manuscripts are submitted. 

This repository is a work in progress. The script are continuously augmented.

## How to run this analysis

This repository includes scripts for the presentation of the paradigm, preprocessing of the data and analysis. Due to privacy issues, we only share preprocessed and anonymised data. Therefore, only the following analysis RMarkdown scripts can actually be run based on this repository: 

* `brms-analyses_FAB.Rmd` : behavioural analysis > run this first
* `brms-analyses_FAB-ET.Rmd` : eye tracking analysis

These scripts also use scripts from the `helpers` folder. There are some absolute paths in these scripts within if statements. Downloading everything in this repository should ensure that these are not executed. 

We also share the models and the results of the simulation-based calibration. **Rerunning these, especially the SBC, can take days depending on the specific model.** Runtime of the scripts using the models and SBC shared in this repository should only take a few minutes. The scripts will create all relevant output that was used in the manuscript. If you need access to other data associated with this project or want to use the stimuli / paradigm, please contact the project lead (Irene Sophia Plank, 10planki@gmail.com). 

The `experiment` folder contains the scripts needed to present the experiment as well as the RMarkdown containing all information regarding the stimulus evaluation and selection. 

The `prepro` folder contains scripts used during preprocessing. All scripts contain information in the header regarding their use. 

### Versions and installation

Each html file contains an output of the versions used to run that particular script. It is important to install all packages mentioned in the html file before running a specific analysis file. Not all packages can be installed with `install.packages`, please consult the respective installation pages of the packages for more information. If the models are rerun, ensure a valid cmdstanr installation. 

To render the RMarkdown file as a PDF, an installation of pdflatex is mandatory. 

For preprocessing of the eye tracking data, MATLAB R2023a was used. 

## Variables

Data is shared in one RData `FAB_data.RData` file which can be read into R. This file contains the following data frames: 

`df.fab` and `df.exp`

* subID : anonymised participant ID
* diagnosis: diagnostic status of this participant, either ADHD, ASD, ADHD+ASD or COMP (comparison group, no psychiatric diagnoses)
* trl : trial number (1 to 432)
* stm : number of the face and object pictures shown in this trial
* rt  : reaction time with which the participant logged their answer (left or right)
* rt.cor : reaction time of trials where use is TRUE, others are set to NA
* acc : whether the location was chosen correctly
* use : TRUE if answer was correct, reaction time not an outlier for this participant (IQR method) and cue presentation duration was within one refresh rate of the monitor
* cue : whether the target appeared at the previous location of the face or object
* target : whether the target appeared on the left or right side
* ASRS_total : outcome of the ASRS questionnaire
* RAADS_total : outcome of the RADS-R questionnaire

`df.sac`

* subID : anonymised participant ID
* trl : trial number (1 to 64)
* stm : number of the face and object pictures shown in this trial
* cue : whether the target appeared at the previous location of the face or object
* target : whether the target appeared on the left or right side
* on_trialType : during which part of the trial did this saccade start? Either during the presentation of the target (tar) or the cue (cue).
* off_trialType : during which part of the trial did this saccade end? Either during the presentation of the target (tar), the cue (cue) or the fixation cross (fix).
* sac_trl : n-th saccade of this trial
* dir_degree : direction of the saccade in degrees
* dir_target : whether the saccades produced was towards the target
* dir_face : whether the saccade produced was towards the (previous) location of the face
* lat : latency, starting with the presentation of the cue
* diagnosis: diagnostic status of this participant, either ADHD, ASD, ADHD+ASD or COMP (comparison group, no psychiatric diagnoses)

`df.table`

* measurement : questionnaire or socio-demographic variable
* ADHD : mean and standard errors or counts for the gender identities for the ADHD group
* ASD : mean and standard errors or counts for the gender identities for the ASD group
* COMP : mean and standard errors or counts for the gender identities for the COMP group
* BOTH : mean and standard errors or counts for the gender identities for the ADHD+ASD group
* logBF10 : logarithmic Bayes Factor comparing the model including diagnosis to the null model

as well as `df.exc` (group and number of excluded participants for behavioural analysis), `df.nosac` (group and number of participants without any relevant saccades despite useable eye tracking data), `df.sht` (outcome of shapiro test for the demographic and questionnaire values) and the results of the contingency tables (`ct.full` containing the full dataset and `ct.mf` only containing male and female participants).

## Result files

All results are saved in RDS files which can be read into R. The following files are shared: 

`m_cnt-cue.rds`: brms model assessing the number of cue-elicited saccades the predictors diagnostic status and whether the saccade was towards a face cue or not as well as their interaction.

`m_cnt-face.rds`: brms model assessing the total number of saccades with the predictors diagnostic status and whether the saccade was towards a face cue or not as well as their interaction.

`m_err.rds`: brms model assessing the error rates to targets with the predictors diagnostic status and cue side (face or object) as well as their interaction.

`m_fab_final.rds`: brms model assessing aggregated reaction times to targets with the predictors diagnostic status and cue side (face or object) as well as their interaction.

`m_fab_full.rds`: brms model assessing reaction times to targets with the predictors diagnostic status and cue side (face or object) as well as their interaction.

`m_fab_sac.rds`: brms model assessing aggregated reaction times to targets with the predictors number of saccades, diagnostic status and cue side (face or object) as well as the interaction between diagnostic status and cue.

`m_lat.rds`: brms model assessing the saccade latencies with the predictors diagnostic status and cue side (face or object) as well as their interaction.

`m_lat_agg.rds`: brms model assessing the aggregated target-elicited saccade latencies with the predictors diagnostic status and cue side (face or object) as well as their interaction.

`m_lat-cue_agg.rds`: brms model assessing the aggregated cue-elicited saccade latencies with the predictors diagnostic status and direction (face or object) as well as their interaction.

`rho_ASRS.rds`: rho samples of the Bayesian spearman correlation between the ASRS questionnaire and the face attention bias being the difference in reaction time to targets appearing on the side of the object minus reaction times to targets appearing on the side of the face. 

`rho_CNT.rds`: rho samples of the Bayesian spearman correlation between the number of saccades towards the side of the face cue and the face attention bias being the difference in reaction time to targets appearing on the side of the object minus reaction times to targets appearing on the side of the face. 

`rho_RADS.rds`: rho samples of the Bayesian spearman correlation between the RADS-R questionnaire and the face attention bias being the difference in reaction time to targets appearing on the side of the object minus reaction times to targets appearing on the side of the face. 

`rho_RT.rds`: rho samples of the Bayesian spearman correlation between the overall reaction times and the face attention bias being the difference in reaction time to targets appearing on the side of the object minus reaction times to targets appearing on the side of the face. 

## Project members

* Project lead: Irene Sophia Plank
* NEVIA lab PI: Christine M. Falter-Wagner
* Project members (alphabetically): Krasniqi, Kaltrina; Nowak, Julia; Pior, Alexandra; Yurova, Anna

## Licensing

GNU GENERAL PUBLIC LICENSE
