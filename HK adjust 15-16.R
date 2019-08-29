#2015 HK
df_hk15 <- file.choose() #HK_trade_2015_rx.csv
hk15 <- read.csv(df_hk15, header = TRUE)
hk15 <- hk15[,-c(2,8)]
names(hk15)[7]<-'vrx_un'

options(scipen = 999)
hk15_agg <- aggregate(.~hk15$t+origin_hk+consig_hk+origin_un+consig_un, hk15[-1], FUN=sum)

df_bridge <- file.choose()
bridge <- read.csv(df_bridge, header = TRUE)
head(bridge)
bridge <- bridge[,2:3]
hk15_imf <- merge(hk15_agg, bridge, by.x = c('origin_un'), by.y = c('un_code'))
names(hk15_imf)[8] <- 'origin_imf'
hk15_imf <- merge(hk15_imf, bridge, by.x = c('consig_un'), by.y = c('un_code'))
names(hk15_imf)[9] <- 'consig_imf'
names(hk15_imf)[3] <- 't'

# transfer hkd to usd using imf yearly average exchange rate (based on IMF yearly average exchange rate HKD-USD.csv)
hk15_imf$vrx_imfusd <- hk15_imf$vrx_hkd/7.75
write.csv(hk15_imf,'HK2015.csv', row.names = FALSE)


# 2016 HK
df_hk16 <- file.choose() #HK_trade_2016_rx.csv
hk16 <- read.csv(df_hk16, header = TRUE)
hk16 <- hk16[,-c(2,8)]
names(hk16)[7]<-'vrx_un'

options(scipen = 999)
hk16_agg <- aggregate(.~hk16$t+origin_hk+consig_hk+origin_un+consig_un, hk16[-1], FUN=sum)

hk16_imf <- merge(hk16_agg, bridge, by.x = c('origin_un'), by.y = c('un_code'))
names(hk16_imf)[8] <- 'origin_imf'
hk16_imf <- merge(hk16_imf, bridge, by.x = c('consig_un'), by.y = c('un_code'))
names(hk16_imf)[9] <- 'consig_imf'
names(hk16_imf)[3] <- 't'

# transfer hkd to usd using imf yearly average exchange rate
ex_rate
hk16_imf$vrx_imfusd <- hk16_imf$vrx_hkd/7.76

write.csv(hk16_imf,'HK2016.csv', row.names = FALSE)
