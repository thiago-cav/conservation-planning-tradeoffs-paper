# Load required libraries
library(prioritizr)
library(terra)
library(dplyr)

# Clear the workspace
rm(list=ls())

# Load feature raster data files
file_list <- list.files("./data", pattern = "tif$", full.names = TRUE)
features <- terra::rast(file_list)
print(features)
plot(features[[1:6]], axes = FALSE)

# Load and process planning units without costs
r <- rast("zonation/output_CAZ2/rankmap.tif")
plot(r)
# Set all non-NA values to 1
r[!is.na(r)] <- 1
plan_unit <- r
plot(plan_unit)

# Clean unnecessary objects from global environment
rm(file_list)

# Create a folder for the output
output_folder <- "prioritzr"

dir.create(output_folder, showWarnings = FALSE)

# Create a conservation problem with no targets and run preliminary calculations
p <-
  problem(plan_unit, features) %>%
  add_min_set_objective() %>%
  add_binary_decisions() %>%
  add_cbc_solver() %T>%  
  run_calculations()

# Create copies of p and add targets
p1 <- p %>% add_relative_targets(0.1)
p2 <- p %>% add_relative_targets(0.2)
p3 <- p %>% add_relative_targets(0.3)

# Example: create a conservation problem with loglinear targets
# p_loglinear <- p %>% add_loglinear_targets(1732, 0.95, 58316, 0.2)

# Solve all different problems 
s1 <- solve(p1)
s2 <- solve(p2)
s3 <- solve(p3)

# Write each solve object as a binary GeoTIFF with modified raster naming
for (i in 1:3) {
  target <- c(0.1, 0.2, 0.3)[i]
  filename <- paste0(output_folder, "/solution", i, "_target", target, ".tif")
  writeRaster(get(paste0("s", i)), filename = filename, 
              datatype = "INT1U", 
              overwrite = TRUE)
}

##### evaluating the solutions #####
# calculate number of selected planning units for each solution
eval1 <- eval_n_summary(p1, s1)
eval2 <- eval_n_summary(p2, s2)
eval3 <- eval_n_summary(p3, s3)

# Combine the tibbles into a single data frame and rearrange columns
combined_df <- bind_rows(
  eval1 %>% mutate(solution = "solution 1"),
  eval2 %>% mutate(solution = "solution 2"),
  eval3 %>% mutate(solution = "solution 3")
) %>%
  select(solution, everything())  # Move solution column to the front

# Write the combined data frame to a CSV file
write.csv(combined_df, file = file.path(output_folder, "combined_results.csv"), row.names = FALSE)

# Feature representation summary
eval4 <- eval_feature_representation_summary(p1, s1)
eval5 <- eval_feature_representation_summary(p2, s2)
eval6 <- eval_feature_representation_summary(p3, s3)

# Combine the tibbles into a single data frame and rearrange columns
combined_df2 <- bind_rows(
  eval4 %>% mutate(solution = "solution 1"),
  eval5 %>% mutate(solution = "solution 2"),
  eval6 %>% mutate(solution = "solution 3")
) %>%
  select(solution, everything())  # Move solution column to the front

# Write the combined data frame to a CSV file
write.csv(combined_df2, file = file.path(output_folder, "combined_results2.csv"), row.names = FALSE)

# Target coverage summary
eval7 <- eval_target_coverage_summary(p1, s1)
eval8 <- eval_target_coverage_summary(p2, s2)
eval9 <- eval_target_coverage_summary(p3, s3)

combined_df3 <- bind_rows(
  eval7 %>% mutate(solution = "solution 1"),
  eval8 %>% mutate(solution = "solution 2"),
  eval9 %>% mutate(solution = "solution 3")
) %>%
  select(solution, everything())  # Move solution column to the front

write.csv(combined_df3, file = file.path(output_folder, "combined_results3.csv"), row.names = FALSE)


