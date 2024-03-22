library(ggpubr)
library(rstatix)
library(data.table)


df <- fread("../temp/data_choices_for_R.csv")
df_lostgirls <- df[df$ad_condition == 0 | df$ad_condition <= 3]
df_stateline <- df[df$ad_condition == 0 | df$ad_condition >= 4]
df_lostgirls$book <- "Lost Girls"
df_stateline$book <- "Stateline"
df_lostgirls$purchased <- df_lostgirls$purchased_203
df_stateline$purchased <- df_stateline$purchased_303
df_lostgirls$searched <- df_lostgirls$clicked_203
df_stateline$searched <- df_stateline$clicked_303
df_master <- rbind(df_lostgirls, df_stateline)

setwd("../output/graphs/main_ate/")



### Plot 1: purchases (advertised book) ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(purchased ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "purchased", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Purchase rate of the advertised book", x ="Advertised book", y = "Purchased ad book") +
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("purchases.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)


### Plot 2: searches (advertised book) ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(searched ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "searched", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Search rate of the advertised book", x ="Advertised book", y = "Searched ad book") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("searches.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)

### Plot 3: total time ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(session_duration ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "session_duration", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Session duration in minutes", x ="Advertised book", y = "Session duration (min)") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("total_time.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)


### Plot 4: total searches ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(num_unique ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "num_unique", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Num. products searched (all)", x ="Advertised book", y = "Unique products searched") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("total_searches.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)


### Plot 5: total searches (non-advertised) ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(num_unique_nonad ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "num_unique_nonad", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Num. products searched (non-advertised)", x ="Advertised book", y = "Unique products searched") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("total_searches_noad.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)


### Plot 6: opened second page ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(opened_second_page ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "opened_second_page", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Prob. opened second page", x ="Advertised book", y = "Opened second page in product list") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("total_second_page.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)


### Plot 7: num product list pages opened ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(pages_opened ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "pages_opened", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Opened product list pages", x ="Advertised book", y = "Pages opened") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("total_pages_opened.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)


### Plot 8: kept book after study ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(dual_response ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "dual_response", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Kept book after study", x ="Advertised book", y = "Prob. kept book") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("total_kept_book.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)


### Plot 9: num product list pages opened ###
# T-test
stat.test <- df_master %>%
  group_by(book)       %>%
  t_test(genre_rank_purchased ~ ad_type, ref.group = "1ad")
stat.test

# Plot
bp <- ggbarplot(
  df_master, x = "book", y = "genre_rank_purchased", fill = "ad_type",
  add = "mean_ci", add.params = list(group = "ad_type"),
  position = position_dodge(0.8)
) 

p <- bp + scale_fill_brewer(palette="Blues", labels=c('No Ads', 'Plain Ad', 'Genre Ad' , 'Price Ad')) + 
  labs(title="Genre rank of purchased book", x ="Advertised book", y = "Genre rank") + 
  theme(legend.title=element_blank(), legend.position="bottom", plot.title = element_text(hjust = 0.5))
p
ggsave("total_genre_rank.png", plot = p, width = 1500, height = 1200, units = "px", dpi = 300)











