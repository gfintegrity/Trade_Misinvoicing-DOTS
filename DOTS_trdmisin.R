# Read in
df <- file.choose() #DOT_05-25-2019 09-02-19-50_timeSeries.csv
dot <-  read.csv(df, header = T, fileEncoding = "UTF-8", na.strings=c("","NA"), as.is = T)


# Remove leve TBG in indicator col
dot <- subset(dot,Indicator.Code != l) 


# Remove status level in attribute col and remove col
dot <- subset(dot, Attribute=='Value') 
dot$Attribute <- NULL  


# Add year col and move attributes from X2015 to x2018 into it
library(tidyr)
dot_year <- dot %>% 
  gather(year, value, X2015:X2018)
dot_year$year <- sub('X', '', dot_year$year)


# Remove NA after transposing
names(dot_year)[1] <- 'Country.Name' #Due to differences bet windows and mac
dot_year$X <- NULL
dot_year[,grep('X.', colnames(dot_year))] <- NULL
dot_year <- dot_year[!is.na(dot_year$value),]
sum(is.na(dot_year))


# CIF is deflated by 1.06
dot_year$value <- as.numeric(dot_year$value)
dot_year$value <- ifelse(dot_year$Indicator.Code=='TMG_CIF_USD', dot_year$value/1.06, dot_year$value)


# Split into 2 datasets by import and export 
dot_m <- dot_year[grep('^TMG', dot_year$Indicator.Code),]
dot_x <- dot_year[grep('^TXG', dot_year$Indicator.Code),]

names(dot_m) <- c('ctyname_m','ctycode_m','indname_m','indcode_m','pctyname_m','pctycode_m','year_m','value_m')
names(dot_x) <- c('ctyname_x','ctycode_x','indname_x','indcode_x','pctyname_x','pctycode_x','year_x','value_x')


# Find Orphaned Records (Use imf_code instead of un_code)
library(sqldf)
dot_join1 <- sqldf("Select * From dot_m Left Join dot_x On dot_m.'ctycode_m'=dot_x.'pctycode_x' And dot_x.'ctycode_x'=dot_m.'pctycode_m' And dot_m.year_m=dot_x.year_x")
library("aws.s3")
usr <- 'aws00'
keycache <- read.csv('accesscodes.csv', header = TRUE, stringsAsFactors = FALSE)
ec2env(keycache,usr)
library(pkg)
inlist <- subset(in_bridge(c("imf_code","d_gfi", "un_code")), d_gfi==1, c("imf_code", "un_code"))
dot_join1 <- dot_join1[(dot_join1$ctycode_m %in% inlist$imf_code & dot_join1$pctycode_m %in% inlist$imf_code),]
library(dplyr)
or_list <- dot_join1[(is.na(dot_join1$value_x)),c(1:8)] %>% arrange(ctycode_m) %>% mutate(ol = 'orphaned')


# Find Lost Records
dot_join2 <- sqldf("Select * From dot_x Left Join dot_m On dot_m.'ctycode_m'=dot_x.'pctycode_x' And dot_x.'ctycode_x'=dot_m.'pctycode_m' And dot_m.year_m=dot_x.year_x")
dot_join2 <- dot_join2[(dot_join2$ctycode_x %in% inlist$imf_code & dot_join2$pctycode_x %in% inlist$imf_code),]
lo_list <- dot_join2[(is.na(dot_join2$value_m)),c(1:8)] %>% arrange(ctycode_x) %>% mutate(ol = 'lost')


# Check num of rows
nrow(dot_join1)-sum(is.na(dot_join1$value_x)) #92100
nrow(dot_join2)-sum(is.na(dot_join2$value_m)) #92100


# Matched records
dot_match1 <- dot_join1[!is.na(dot_join1$value_x),]
dot_match2 <- dot_join2[!is.na(dot_join2$value_m),]

# Deal with HK 15&16 data
## 2015 HK
hk15 <- in_hkrx(2015, c("k", "origin_hk", "vrx_un", "consig_hk"), io = F)
hk15 <- hk15[hk15$origin_un %in% inlist$un_code & hk15$consig_un %in% inlist$un_code,]

options(scipen = 999)
hk15_agg <- aggregate(.~t+origin_un+consig_un, hk15, FUN=sum)

hk15_imf <- merge(hk15_agg, inlist, by.x = c('origin_un'), by.y = c('un_code'), all.x = T)
names(hk15_imf)[match('imf_code', colnames(hk15_imf))] <- 'origin_imf'
hk15_imf <- merge(hk15_imf, inlist, by.x = c('consig_un'), by.y = c('un_code'))
names(hk15_imf)[match('imf_code', colnames(hk15_imf))] <- 'consig_imf'


## transfer hkd to usd using imf yearly average exchange rate (based on IMF yearly average exchange rate HKD-USD.csv)
hk15_imf$vrx_imfusd <- hk15_imf$vrx_hkd/7.75


## 2016 HK
hk16 <- in_hkrx(2016, c("k", "origin_hk", "vrx_un", "consig_hk"), io = F)
hk16 <- hk16[hk16$origin_un %in% inlist$un_code & hk16$consig_un %in% inlist$un_code,]

options(scipen = 999)
hk16_agg <- aggregate(.~t+origin_un+consig_un, hk16, FUN=sum)

hk16_imf <- merge(hk16_agg, inlist, by.x = c('origin_un'), by.y = c('un_code'), all.x = T)
names(hk16_imf)[match('imf_code', colnames(hk16_imf))] <- 'origin_imf'
hk16_imf <- merge(hk16_imf, inlist, by.x = c('consig_un'), by.y = c('un_code'))
names(hk16_imf)[match('imf_code', colnames(hk16_imf))] <- 'consig_imf'


## transfer hkd to usd using imf yearly average exchange rate
hk16_imf$vrx_imfusd <- hk16_imf$vrx_hkd/7.76


# Make HK adjustment and Calculate trade misinovicing
hk <- rbind(hk15_imf, hk16_imf)

## gen impmisbilat = impfob - ptn_exp - hkrx_consig_zeros
## gen expmisbilat = ptn_impfob - exp - hkrx_origin_zeros

dot_adj1 <- merge(dot_match1, hk, all.x = T, by.x = c('ctycode_m','ctycode_x','year_m'), by.y = c('consig_imf','origin_imf','t'))
dot_adj2 <- merge(dot_match2, hk, all.x = T, by.x = c('ctycode_x','ctycode_m','year_x'), by.y = c('origin_imf','consig_imf','t'))

dot_adj1$vrx_imfusd[is.na(dot_adj1$vrx_imfusd)] <- 0
dot_adj1$impmisbilat <- dot_adj1$value_m - dot_adj1$value_x - dot_adj1$vrx_imfusd

dot_adj2$vrx_imfusd[is.na(dot_adj2$vrx_imfusd)] <- 0
dot_adj2$expmisbilat <- dot_adj2$value_x - dot_adj2$value_m - dot_adj2$vrx_imfusd

dot_adj <- merge(dot_adj1[,-c(17:20)], dot_adj2[,c(1:3,6,8,12,14,21)], all.x = T, 
                 by.x = c('ctycode_m','ctycode_x','pctycode_m','pctycode_x','year_m','indcode_m','indcode_x'), 
                 by.y = c('pctycode_x','pctycode_m','ctycode_x','ctycode_m','year_x','indcode_m','indcode_x'))

dot_adj$uo_m <- ifelse(dot_adj$impmisbilat>0, 'over', ifelse(dot_adj$impmisbilat<0, 'under', 'none'))
dot_adj$uo_x <- ifelse(dot_adj$expmisbilat>0, 'over', ifelse(dot_adj$expmisbilat<0, 'under', 'none'))
dot_adj$impmisbilat <- abs(dot_adj$impmisbilat)
dot_adj$expmisbilat <- abs(dot_adj$expmisbilat)


# Write out 
write.csv(dot_adj, "DOTS_trdmisin.csv", row.names = F, fileEncoding = "UTF-8")
colnames(or_list) <- sub("_m",'',colnames(or_list)); colnames(lo_list) <- sub("_x",'',colnames(lo_list))
ol <- rbind(or_list, lo_list)
write.csv(ol, "DOTS_orphaned&lost.csv", row.names = F, fileEncoding = "UTF-8")
