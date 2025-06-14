#############
### SETUP ###
#############

# install.packages(c("ggplot2", "tidyverse"))
library(ggplot2)
library(tidyverse)
library(broom)
library(dplyr)

# set seed
set.seed(8)

#######################
### NBA FREE THROWS ###
#######################

# load data
nba_players = read.csv("../data/08_nba-free-throws.csv", sep=";")
glimpse(nba_players)
nba_players = nba_players %>%
  mutate(FTA=round(FTA*G,0), 
         FT=round(FT*G,0)) %>% 
  select(Player, FTA,FT,G) %>% 
  group_by(Player) %>% 
  summarise(FTA=sum(FTA), FT=sum(FT), FTP=FT/FTA, G=sum(G)) %>%
  filter(FTA > 25) %>% 
  mutate(AC=(FT+2)/(FTA+4)) 
glimpse(nba_players)
# plot free throw percentage
ggplot(nba_players, aes(x=FTP)) +
  geom_histogram(binwidth=0.05, fill="blue", color="black") +
  labs(title="NBA Free Throw Percentage Distribution",
       x="Free Throw Percentage",
       y="Count") +
  theme_minimal()
# plot adjusted free throw percentage
ggplot(nba_players, aes(x=AC)) +
  geom_histogram(binwidth=0.05, fill="blue", color="black") +
  labs(title="NBA Adjusted Free Throw Percentage Distribution",
       x="Adjusted Free Throw Percentage",
       y="Count") +
  theme_minimal()
# plot free throw percentage vs adjusted free throw percentage
ggplot(nba_players, aes(x=FTP, y=AC)) +
  geom_point() +
  geom_smooth(method="lm", color="red") +
  labs(title="Free Throw Percentage vs Adjusted Free Throw Percentage",
       x="Free Throw Percentage",
       y="Adjusted Free Throw Percentage") +
  theme_minimal()
nba_players<-nba_players %>%
  mutate(WaldL=FTP-1.96*sqrt((FTP-FTP^2)/G),
         WaldH=FTP+1.96*sqrt((FTP-FTP^2)/G),
         ACL=AC-1.96*sqrt((AC-AC^2)/G),
         ACH=AC+1.96*sqrt((AC-AC^2)/G)) %>% 
  slice_sample(n=30) 

# plot free throw percentage with confidence intervals
ggplot(nba_players, aes(x=FTP, y=fct_reorder(Player,FTP))) +
  geom_point() +
  geom_errorbarh(aes(xmin=WaldL, xmax=WaldH), height=0.2, color="blue") +
  labs(title="NBA Free Throw Percentage with Wald Confidence Intervals",
       x="Free Throw Percentage",
       y="Player") +
  theme_minimal()
# plot adjusted free throw percentage with confidence intervals
ggplot(nba_players, aes(x=AC, y=fct_reorder(Player,FTP))) +
  geom_point() +
  geom_errorbarh(aes(xmin=ACL, xmax=ACH), height=0.2, color="blue") +
  labs(title="NBA Adjusted Free Throw Percentage with Wald Confidence Intervals",
       x="Adjusted Free Throw Percentage",
       y="Player") +
  theme_minimal()
## I the high values of FTP tend to be brought down towards the middle, which is exactly what we'd expect

### Part 2
# Step 1: Define p and n values
x <- ppoints(1000)  # 1000 values in (0, 1)
n_vals <- c(10, 50, 100, 250, 500, 1000)

# Step 2: Define the Wald confidence interval function
wald_ci <- function(p, n) {
  S <- rbinom(1, n, p)
  phat <- S / n
  se <- sqrt((phat * (1 - phat)) / n)
  lower <- phat - 1.96 * se
  upper <- phat + 1.96 * se
  return(c(lower, upper))
}
ac_ci <- function(p, n) {
  S <- rbinom(1, n, p)
  phat <- (S+2) / (n+4)
  se <- sqrt((phat * (1 - phat)) / n)
  lower <- phat - 1.96 * se
  upper <- phat + 1.96 * se
  return(c(lower, upper))
}
# Step 3: Loop over each n and compute CIs for all p
wald_list <- lapply(n_vals, function(n_val) {
  ci_matrix <- t(sapply(x, function(p_val) wald_ci(p_val, n_val)))
  data.frame(
    p = x,
    n = n_val,
    lower = ci_matrix[, 1],
    upper = ci_matrix[, 2]
  )
})
ac_list<-lapply(n_vals, function(n_val){
  ci_matrix<-t(sapply(x, function(p_val) ac_ci(p_val, n_val)))
  data.frame(
    p = x,
    n = n_val,
    lower = ci_matrix[, 1],
    upper = ci_matrix[, 2]
  )
})
# Step 4: Combine results into one data frame
wald_df <- bind_rows(wald_list)
ac_df <- bind_rows(ac_list)
# Step 5: Plot
ggplot(wald_df, aes(x = p)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = "skyblue", alpha = 0.4) +
  geom_line(aes(y = lower), color = "blue", linewidth = 0.4) +
  geom_line(aes(y = upper), color = "blue", linewidth = 0.4) +
  geom_line(aes(y = p), color = "black", linetype = "dashed", linewidth = 0.4) +
  facet_wrap(~ n, scales = "free_y") +
  labs(title = "Wald Confidence Intervals for One Binomial Draw",
       x = "True Free Throw Percentage (p)",
       y = "Confidence Interval") +
  theme_minimal()
ggplot(ac_df, aes(x = p)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = "skyblue", alpha = 0.4) +
  geom_line(aes(y = lower), color = "blue", linewidth = 0.4) +
  geom_line(aes(y = upper), color = "blue", linewidth = 0.4) +
  geom_line(aes(y = p), color = "black", linetype = "dashed", linewidth = 0.4) +
  facet_wrap(~ n, scales = "free_y") +
  labs(title = "Adjusted Confidence Intervals for One Binomial Draw",
       x = "True Free Throw Percentage (p)",
       y = "Confidence Interval") +
  theme_minimal()

# Step 1: Define n_trials
n_trials <- 100

# Step 2: Define the Wald CI function (returns logical: TRUE if p in CI)
wald_contains_p <- function(p, n) {
  contains <- replicate(n_trials, {
    S <- rbinom(1, n, p)
    phat <- S / n
    se <- sqrt(phat * (1 - phat) / n)
    lower <- phat - 1.96 * se
    upper <- phat + 1.96 * se
    p >= lower & p <= upper
  })
  mean(contains)  # proportion of times CI contained true p
}
ac_contains_p <- function(p, n) {
  contains <- replicate(n_trials, {
    S <- rbinom(1, n, p)
    phat <- (S + 2) / (n + 4)
    se <- sqrt(phat * (1 - phat) / n)
    lower <- phat - 1.96 * se
    upper <- phat + 1.96 * se
    p >= lower & p <= upper
  })
  mean(contains)  # proportion of times CI contained true p
}
# Step 3: Apply this over grid of p and n
wald_coverage_list <- lapply(n_vals, function(n_val) {
  coverage <- sapply(x, function(p_val) wald_contains_p(p_val, n_val))
  data.frame(p = x, n = n_val, coverage = coverage)
})
ac_coverage_list <- lapply(n_vals, function(n_val) {
  coverage <- sapply(x, function(p_val) ac_contains_p(p_val, n_val))
  data.frame(p = x, n = n_val, coverage = coverage)
})
# Step 4: Combine and plot
wald_coverage_df <- do.call(rbind, wald_coverage_list)
ac_coverage_df <- do.call(rbind, ac_coverage_list)
# Step 5: Plot
ggplot(wald_coverage_df, aes(x = p, y = coverage)) +
  geom_line(color = "blue") +
  geom_hline(yintercept = 0.95, linetype = "dashed", color = "red") +
  facet_wrap(~n) +
  labs(title = "Wald CI Coverage by Sample Size and True p",
       x = "True p",
       y = "Coverage (Proportion of CIs that Contain p)") +
  theme_minimal()
ggplot(ac_coverage_df, aes(x = p, y = coverage)) +
  geom_line(color = "blue") +
  geom_hline(yintercept = 0.95, linetype = "dashed", color = "red") +
  facet_wrap(~n) +
  ylim(0,1)+
  labs(title = "Adjusted CI Coverage by Sample Size and True p",
       x = "True p",
       y = "Coverage (Proportion of CIs that Contain p)") +
  theme_minimal()

## part 3, 
\documentclass{article}
\usepackage{graphicx} % Required for inserting images

\title{WSABI}
\author{spiveym }
\date{June 2025}

\begin{document}

\maketitle

\section{Introduction}
\[
  \hat{p} = \arg\max_p P(x_1, x_2, \ldots, x_n \mid p)
  \]

\[
  P(x_1, x_2, \ldots, x_n \mid p) = p^{S_n} (1 - p)^{n - S_n}
  \]

\[
  \ln P = S_n \ln p + (n - S_n) \ln (1 - p)
  \]

\[
  \frac{d}{dp} \ln P = \frac{S_n}{p} - \frac{n - S_n}{1 - p} = 0
  \]

\[
  S_n - S_n p - n p + S_n p = S_n - n p = 0
  \]

\[
  \Rightarrow \quad p = \frac{S_n}{n}
  \]

\[
  \boxed{\hat{p} = \frac{S_n}{n}} \quad \text{Q.E.D.}
  \]

\end{document}

# I would set n>=(1/p-1)*1.96^2


