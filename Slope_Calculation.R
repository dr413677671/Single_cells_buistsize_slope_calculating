# ===========================================================================
#
#               Single Cells' Expression Data Slope Calculator Based on different treatments
#
#  The code inferenced some code from:
#  Steve et al.,
#  Slope Calculator application makes it easy to identify differentially expressed genes in different treatments from single cells expression data.
#
#  Before used. Please make sure the raw data are untared and stored in the relevant directory as stated in the source code.
#
#  The program is able to cope with single cell expression data, and merged them 
#  in genes order.The script automatically generated 
#  the outcome Quality Control data in mutiple statistical-graphes. It then filtered unusual outliers,  
#  and merged the data in treatments order. Identification of slope by mean-variance ratio in the regression model is conducted.
#  The outcome contains the slopes in different treatments and the quantified values of it.
#  The result could be operated in excel automatically.
#
#  As of Rstudio >= 3.4.3, the script require some R standard packages. For 
#  users who still need to support  are required: 
#  string and dplyr; but also may support older R versions.
#
# ===========================================================================
#
# Author:  Ran D
#
# Program Features:  
#   Read and merged burst size result 
#   Calculate average burst size ratio for different genes.
#   Filtered the data
#   Retrieved the covariance slope and print it in a table
#
# ========================




library("stringr")
library("dplyr")


raw <- read.csv("induced_genes_raw_data.csv")

means = setNames(aggregate(raw[,"expression"],list(gene = raw$gene,condition = raw$condition), mean),c("gene","condition","mean"))
variances = aggregate(raw[,"expression"],list(gene = raw$gene, condition = raw$condition), var)
count = aggregate(raw[,"expression"],list(gene = raw$gene,condition = raw$condition), length)

data = cbind(means,
             variance = variances$x,
             log10mean = log10(means$mean), 
             log10variance = log10(variances$x),
             noise = sqrt(variances$x)/means$mean,
             burst_size = variances$x/means$mean,
             frequency = means$mean/((variances$x/means$mean) - 1),
             n = count$x)

#sort conditions

data$condition = as.character (data$condition)


index<-1  
while(index<=length(data$condition)){  
     data$condition[index] <-(str_replace_all(string = data$condition[index], pattern = "_[:digit:]h",replacement = ""))
    index<-index+1  
}  

index<-1  
while(index<=length(data$condition)){  
     data$condition[index] <-(  str_replace_all(string = data$condition[index], pattern = "_t[:digit:]",replacement = "") )
    index<-index+1  
}  


# Extract gene list from data
gene_list = levels(data[!duplicated(data$gene),"gene"])
condition_list = data[!duplicated(data$condition),"condition"]


# Intialise a dataframe of correct size to store results

results = data.frame(matrix(NA, ncol = 3, nrow = (length(gene_list))*(length(condition_list))))
colnames(results) <- c("gene","condition","slope")



# Iterate through each gene in the gene list

k <- 2
for (gene in gene_list){
  # Subset data of just one gene
  single = data[data$gene == gene & data$mean != 0 & data$n > 10 ,]

  
      # Exclude linear outliers based on mahalanobis distance
      m_dist <- mahalanobis(single[,c("mean","variance")],
                          colMeans(single[,c("mean","variance")]), 
                          cov(single[,c("mean","variance")]))

    # Exclude log outliers based on mahalanobis distance
    m_dist <- mahalanobis(single[,c("log10mean","log10variance")],
                          colMeans(single[,c("log10mean","log10variance")]), 
                          cov(single[,c("log10mean","log10variance")]))
   
	for (each_condition in condition_list){
		single_condition = single[single$condition == each_condition,]
if(length(single_condition$variance)!=0){
    		linear_model = lm(formula = single_condition$variance ~ single_condition$mean)
		slope = linear_model$coefficients[[2]]
 		results = rbind(results,c(gene,each_condition, slope))
		
			
	k <- k+1}
  
 
       }
}

# Save results to a dataframe
results = results[complete.cases(results),]
write.csv(results,"results_exc_outliers.csv")


data = read.csv("results_exc_outliers.csv")

quantified <-array()
index <- 2
while(index  <= length(data$gene)){
  
  single = data[data[index,"gene"] == data$gene  ,]
	s_mean <- mean(single$slope)
	quantified <- append(quantified, ( data[index,"slope"]  -  s_mean)/s_mean) 
       	index  <- index+1
}

data <- cbind(data,quantified)
write.csv(data,"quantified.csv")