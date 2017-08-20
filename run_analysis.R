## Created by: Olga Hartoog
## 12-08-2017
## Getting and Cleaning data - Assignment
library(dplyr)


# download the data unless already present
tmp <- tempfile()
if(!file.exists('./data/UCI HAR Dataset')) {
  download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip",tmp)
  unzip(tmp,exdir = './data')
}


# read in the data 
# general
activity_labels <- read.table(file="./data/UCI HAR Dataset/activity_labels.txt", sep = "",header = F)
features <- read.table(file="./data/UCI HAR Dataset/features.txt", sep = "",header = F)

# train data
x_train <- read.table(file="./data/UCI HAR Dataset/train/X_train.txt", sep = "",header = F)
y_train <- read.table(file="./data/UCI HAR Dataset/train/Y_train.txt", sep = "",header = F)
subject_train <- read.table(file="./data/UCI HAR Dataset/train/subject_train.txt", sep = "",header = F)

# test data
x_test <- read.table(file="./data/UCI HAR Dataset/test/X_test.txt", sep = "",header = F)
y_test <- read.table(file="./data/UCI HAR Dataset/test/Y_test.txt", sep = "",header = F)
subject_test <- read.table(file="./data/UCI HAR Dataset/test/subject_test.txt", sep = "",header = F)

# combining data sets
# add column names to the features in x_train
# convert the features to a vector for easy application as column names
features_vector <- as.vector(features$V2)
# make a second vector with more descriptive names (only the ones that will be used later)
features_vector_descriptive <- gsub("^t","Time",features_vector)
features_vector_descriptive <- gsub("^f","Frequency",features_vector_descriptive)
features_vector_descriptive <- gsub("BodyAcc","BodyAcceleration",features_vector_descriptive)
features_vector_descriptive <- gsub("GravAcc","GravityAcceleration",features_vector_descriptive)
features_vector_descriptive <- gsub("Mag","Magnitude",features_vector_descriptive)
features_vector_descriptive <- gsub("-mean\\(\\)","MeanValue",features_vector_descriptive)
features_vector_descriptive <- gsub("-std\\(\\)","StandardDeviation",features_vector_descriptive)
features_vector_descriptive <- gsub("-X","Xdirection",features_vector_descriptive)
features_vector_descriptive <- gsub("-Y","Ydirection",features_vector_descriptive)
features_vector_descriptive <- gsub("-Z","Zdirection",features_vector_descriptive)

colnames(x_train) <- features_vector_descriptive
colnames(x_test)  <- features_vector_descriptive

colnames(activity_labels) <- c("activity_label","Activity")

colnames(y_train) <- c("activity_label")
colnames(y_test)  <- c("activity_label")
colnames(subject_train) <- c("SubjectID")
colnames(subject_test) <- c("SubjectID")

# remove the columns that are not a mean or stdv measure
# identify which columns names contain either mean() or std()
a <- grep("-mean\\(\\)",features_vector)
b <- grep("-std\\(\\)",features_vector)
c <- sort(unique(union(a,b)))
x_train <- x_train[,c]
x_test  <- x_test[,c]

# add the activities and subjectIDs columns to x_train
data_train <- cbind(subject_train,y_train,x_train)
# merge the descriptions of the activities (reordering is no problem)
data_train <- merge(data_train,activity_labels)
# add a column to indicate the origin (the experiment group)
data_train$Group <- "train"
# reorder columns and leave the activity label out
data_train_select <- select(data_train,SubjectID,Group,Activity,3:69)

# add the activities and subjectIDs columns to x_test
data_test <- cbind(subject_test,y_test,x_test)
# merge the descriptions of the activities (reordering is no problem)
data_test <- merge(data_test,activity_labels)
# add a column to indicate the origin (the experiment group)
data_test$Group <- "test"
# reorder columns and leave the activity label out
data_test_select <- select(data_test,SubjectID,Group,Activity,3:69)



# combine the two data sets
data_tidy <- rbind(data_train_select,data_test_select)

# make the second data set
# group to identify with columns should not me averages, but act as the group by
data_groups <- group_by(data_tidy,SubjectID,Activity)

# now calculte means of all remaining columns
# this piece of code is based on mnel's answer to a question on Stckoverflow
#'https://stackoverflow.com/questions/21295936/can-dplyr-summarise-over-several-variables-without-listing-each-one'
# make an array of all columns that need to be averaged
columns <- names(data_groups)[-(1:3)]
# make a list (flist) that has 66 items with named like the variable, and a value that is a string "mean(variable)"
flist <- sapply(columns ,function(x) substitute(mean(x), list(x=as.name(x))))
# call summarize with help of the list to get the desired answer
data_means <- do.call(summarize, c(list(.data=data_groups), flist))
# make the vcolumns names more descriptive by adding _Mean
newcolumns <- paste(columns,"_Mean",sep='')
# add thenew column names to the data_means
colnames(data_means) <- union(colnames(data_means)[1:2],newcolumns)

# write data to same folder as the script      
write.table(data_means,"tidydata.txt")
data <- read.table("tidydata.txt", header = TRUE) #if they used some other way of saving the file than a default write.table, this step will be different
View(data)