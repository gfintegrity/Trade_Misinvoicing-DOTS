library('tidyr')
a <- read.csv('DOTS.csv', as.is = T, encoding = 'UTF-8') # Mac seems to prefer fileEncoding = "UTF-8"
unique(a$Indicator.Code)
a <- a[a$Attribute=='Value'&a$Indicator.Code!="TBG_USD",]
a$X <- NULL; a$Attribute <- NULL; a[,grep('.Name$', colnames(a))] <- NULL
a <- gather(a, key = 'years', value = 'value', X2015:X2018)
sum(is.na(a$value))
a[a$value=='','value'] <- NA
sum(is.na(a$value))
a <- a[!is.na(a$value),]
im <- a[grep('^TMG', a$Indicator.Code),]
ex <- a[grep('^TXG', a$Indicator.Code),]
imp <- merge(im, ex, by.x = c("Country.Code","Counterpart.Country.Code","years"), by.y = c("Counterpart.Country.Code","Country.Code","years"), all.x = T)
sum(is.na(imp$value.y)) # number of import orphan
exp <- merge(ex, im, by.x = c("Country.Code","Counterpart.Country.Code","years"), by.y = c("Counterpart.Country.Code","Country.Code","years"), all.x = T)
sum(is.na(exp$value.y)) # number of export orphan
nrow(imp)-sum(is.na(imp$value.y)) # number of matched trades from the perspective of importer
nrow(exp)-sum(is.na(exp$value.y)) # number of matched trades from the perspective of exporter
