library(dplyr)
rm(list = ls()) 

##### Feature list creation #####

# Load all raster data files (.tif) from the 'data' folder inside the repository
file_list <- list.files("./data", pattern = "tif$", full.names = TRUE)

# Create relative paths for Zonation input.
# Paths are relative to the 'zonation' folder, so start with "../data/"
filename <- file.path("..", "data", basename(file_list))

# Combine filenames into a data frame (required format for Zonation)
data_df <- data.frame(filename)

# Quote the column names with double quotes as required by Zonation
col_names_quoted <- sprintf("\"%s\"", names(data_df))
names(data_df) <- col_names_quoted

# Create 'zonation' folder if it doesn't exist (will contain config files)
dir.create("zonation", recursive = TRUE, showWarnings = FALSE)

# Write the feature list file that Zonation will read
write.table(data_df, file = "zonation/feature_list.txt", quote = FALSE, 
            row.names = FALSE, sep = "\t", col.names = TRUE)

##### Settings file creation #####

# Define settings file content pointing to the feature list
settings <- "feature list file = feature_list.txt"

# Write the settings file in the 'zonation' folder
writeLines(settings, "zonation/settings.z5")

##### Command file creation #####

generate_cmd_file <- function(folder = "zonation") {
  # Define the path to the command file
  output_file <- file.path(folder, "command_file.cmd")
  
  # Define command file content to run Zonation with GUI mode and CAZ2 mode
  cmd_content <- paste0(
    "@setlocal\n",
    "@PATH=C:\\Program Files (x86)\\Zonation5;%PATH%\n\n",
    "z5 --mode=CAZ2 --gui settings.z5 output_CAZ2\n",
    "@pause"
  )
  
  # Write the command content to the command file
  writeLines(cmd_content, output_file)
  
  # Notify the user
  cat("🍺🎉 Command file generated 🎉🍺:", output_file, "\n")
}

# Generate the command file in the default 'zonation' folder
generate_cmd_file()

