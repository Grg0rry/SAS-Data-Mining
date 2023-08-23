# Data Mining on Shoe Dataset using SAS and R

## Background
This is for the assignment of analytics engineering (IST2034), where we are tasked to create perform data cleaning and generate insights using the SAS programming and R.

### Dataset
Hence the dataset given is a shoe dataset consisting of 10,000 observations on both men and women shoes. The schema of the data is taken from [[link](https://developer.datafiniti.co/docs/product-data-schema )].

### Objective
The study's research questions are
1. Is the pricing for male and female shoes significantly different?
2. How different is the shoe price between the popular shoe brands and those not as popular?

## Methodology
**(1) Data Cleaning and Processing**
This stage was done using SAS programming. The IDE can be access through this [[link](https://welcome.oda.sas.com/)]

The cleaning procedures are
1. Fix the format of the data inputted
2. Filter out duplicated records
3. Filter out records unrelated to shoes
4. Perform Binning on `Shoe_Condition` to similar data together
5. Treat Missing value of `Shoe_Condition` with value of 'New'
6. Convert `Brand` to Capitalization text format
7. Treat Missing value of `Brand` through product_name or 'unbranded'
8. Compute the `Shoe_Price`

**(2) Data Analysis**
This stage was done using the R language, to understand and achieve the objective set.
