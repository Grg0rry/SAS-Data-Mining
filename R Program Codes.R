#Load Packages
install.packages("sas7bdat")
require(sas7bdat)
install.packages("ggplot2")
library(ggplot2)
install.packages("grid")
library(grid)
install.packages("gridExtra")
library(gridExtra)

#Import Shoedataset
shoedataset <- read.sas7bdat("data/shoedataset.sas7bdat")

###########################
#1: Descriptive Analysis
###########################
#Summary Statistics
describe(shoedataset)

#Box Plot
boxplot <- boxplot(shoedataset$shoe_price,
                   main="Boxplot of Shoe_Price")
boxplot$stats
boxplot$out #Outliers
length(boxplot$out)


###########################
#2.1: Research Question 1
###########################
#Histogram Plot of Male/Female Shoe Price
#Male Shoes
maleshoe <- subset(shoedataset, (Gender=='Male'))
maleshoehist1 <- hist(maleshoe$shoe_price, 
                      xlab="Male_Shoe_Price",
                      ylim=c(0,8000),
                      main="Histogram of Shoe_Price for Male")
text(maleshoehist1$mids,maleshoehist1$counts,labels=maleshoehist1$counts, adj=c(0.5, -0.5))
#Female Shoes
femaleshoe <- subset(shoedataset, (Gender=='Female'))
femaleshoehist1 <- hist(femaleshoe$shoe_price,
                        xlab="Female_Shoe_Price",
                        main="Histogram of Shoe_Price for Female",
                        ylim=c(0,8000))
text(femaleshoehist1$mids,femaleshoehist1$counts,labels=femaleshoehist1$counts, adj=c(0.5, -0.5))

#Overlapping Histogram of Shoe_Price between Male and Female
c1 <- rgb(173,216,230,max = 255, alpha = 80, names = "lt.blue") #Customized Transparent Colour
c2 <- rgb(255,192,203, max = 255, alpha = 80, names = "lt.pink")
maleshoehist2 <- hist(maleshoe$shoe_price, 
                      xlab="Shoe_Price",
                      main="Histogram of Shoe_Price between Gender",
                      ylim=c(0,6000),
                      breaks=59,
                      col=c1)
femaleshoehist2 <- hist(femaleshoe$shoe_price,
                        col=c2,
                        add=TRUE)
legend("topright", c("Male", "Female"), box.lty = 1,lty = 1, col = c(c1, c2), lwd = 10)

#Break and Counts of Male and Female Histogram
while(length(maleshoehist2$breaks) != length(maleshoehist2$counts)){
  maleshoehist2$counts <- append(maleshoehist2$counts,0)
}
while(length(maleshoehist2$breaks) != length(femaleshoehist2$counts)){
  femaleshoehist2$counts <- append(femaleshoehist2$counts,0)
}
histogramVal <- data.frame(maleshoehist2$breaks,maleshoehist2$counts,femaleshoehist2$counts)
histogramVal <- t(histogramVal)
histogramVal

#Line Plot of the Maximum Shoe_Price for each Shoe_Condition of both Genders
#Initiate
conditionlevel <- levels(factor(shoedataset$shoe_condition))
male_maximumShoePrice=c()
female_maximumShoePrice=c()
#For loop to get the maximum values
for (i in 1:length(conditionlevel))
{
  #Male
  male_shoeprice <- subset(shoedataset, (shoe_condition==conditionlevel[i] & Gender=="Male"))[,c('shoe_price')]
  male_maximumShoePrice[i] = max(male_shoeprice)
  #Female
  female_shoeprice <- subset(shoedataset, (shoe_condition==conditionlevel[i] & Gender=="Female"))[,c('shoe_price')]
  female_maximumShoePrice[i] = max(female_shoeprice)
}
plottingvaluesmale <- data.frame(conditionlevel, maximum=male_maximumShoePrice, gender="Male")
plottingvaluesfemale <- data.frame(conditionlevel, maximum=female_maximumShoePrice, gender="Female")
plottingvalues <- rbind(plottingvaluesmale,plottingvaluesfemale)
#Line Plot
ggplot(plottingvalues, aes(x=conditionlevel, y=maximum, group=gender)) + 
  geom_line(aes(color=gender))+
  geom_point(aes(color=gender))+
  ylab("Shoe_Price") +
  xlab("Shoe_Condition") +
  ggtitle("Line Plot of the Maximum Shoe_Price for each Shoe_Condition of both Genders") +
  geom_text(aes(label=maximum), position=position_dodge(width=0.9), vjust=-1) +
  theme(
    plot.title = element_text(size=14, face="bold",hjust = 0.5),
  )


###########################
#2.2: Research Question 2
###########################
#Top 10 popular Brands
pbrand <- c("Nike","Adidas","New Balance","Skechers","Converse","Under Armour", "Asics","Puma","Timberland","Fila") 
popbrands <- shoedataset
popbrands$brand <- factor(popbrands$brand,order=TRUE,levels=pbrand)

#Average Shoe_Price of each popular brand
averageVal=c()
for (i in 1:10)
{
  temp <- subset(shoedataset, (brand==pbrand[i]))[,c('shoe_price')]
  averageVal[i] <- mean(temp)
}
group <- data.frame(pbrand,averageVal)

#Line Plot
ggplot(group, aes(x=pbrand, y=averageVal, group=2)) + 
  geom_line(aes(colour="Popular Brand"))+
  geom_line(aes(y = mean(subset(popbrands, is.na(popbrands$brand))[,c('shoe_price')]), colour="Non Popular")) +
  geom_point(aes(colour="Popular Brand")) +
  ylab("Shoe_Price") +
  xlab("Brands") +
  ggtitle("Line Plot of Top 10 Most Popular Brands' Average Shoe Price \n Against the Average Shoe Price of those that are not as Popular") +
  theme(
    plot.title = element_text(size=14, face="bold",hjust = 0.5),
  )

#Table Grid
group <- data.frame(pbrand,averageVal)
other <- data.frame("Non Popular",mean(subset(popbrands, is.na(popbrands$brand))[,c('shoe_price')]))
names(other) <- c('pbrand','averageVal')
group <- rbind(group, other)
group$averageVal <- round(group$averageVal,digits=2)
group <- group[order(group$averageVal, decreasing = TRUE),]
group <- cbind(c(1:11), group)
colnames(group) <- c("Rank","Brand", "Average Shoe Price")
grid.table(group, rows=NULL)
