#Loading Necessary Packages
library(readr)
library(forecast)
library(Kendall)
library(tseries)
library(trend)
#Loading metadata and taking avg temp of India from 1880 to August 2013
GlobalLandTemperaturesByCountry <- read_csv("Datasets/GlobalLandTemperaturesByCountry.csv")
df<-data.frame(GlobalLandTemperaturesByCountry[which(GlobalLandTemperaturesByCountry$Country=="India"),])
temperatureData <- df[1009:2613,]
temperatureData <- na.omit(temperatureData$AverageTemperature)

#Let us perform a quick summary statistic of the data
summary(temperatureData)

#We are converting it into a time series with frequency 12 (yearly cycles)
avg_temp<-ts(temperatureData, frequency = 12)
plot(avg_temp, xlab= "Years", ylab = "Average Temp", main = "Average Temperature of India from 1880 to 2013", col="blue", lwd=1)
#For easy visualisation
plot(avg_temp[1:120], xlab = "Months", ylab = "Average Temp", main = "Average Temperature of India from 1880 to 1889", col="blue", lwd=1, type = "l")
#As evident from the plots, they show a clear seasonal pattern
#Performing a KPSS test to check if its stationary or not
s<-kpss.test(avg_temp)
ifelse ((s$p.value <0.05), "Non-Stationary", "Stationary")
#Judging by the p-value it is a non stationary process
#We will now employ a Seasonal Mann-Kendall trend test to check for any trend in this seasonal data
smk_test<-smk.test(avg_temp)
ifelse((smk_test$p.value<0.05), print("There exists a trend"), print("There exists no trend"))
#Thus there is a trend in the data
#We will split the train and test from the national data to help in forecasting
sample_size<-floor(0.8*length(avg_temp))
train_index<-c(1:sample_size)
avg_temp_train<-ts(avg_temp[train_index], frequency = 12)
avg_temp_test<-ts(avg_temp[-train_index], frequency = 12)
avg_temp_train1<-ts(avg_temp[train_index], frequency = 12)

#We difference the series by a lag of 1 to remove the trend
avg_temp_train<-diff(avg_temp_train)
plot(avg_temp_train, xlab = "Time in Years", ylab = "Differenced Temp", main = "Differenced Series(Lag of 1 month)", col = "blue")
smk.test(avg_temp_train)
#As the smk test has a higher p-value we can safely say there is no trend now in the data
#We now difference by a lag of 12 again to remove the seasonal component 
avg_temp_train<-diff(avg_temp_train, lag=12)
plot(avg_temp_train, xlab = "Time in Years", ylab = "Differenced Temp", main = "Differenced Series(Lag of 12 months after a lag of 1 month)", col = "blue")
#As judged by the p-value we can see the series has no upward or downward trend thus indicating no trend
#We now employ two tests to check the series is stationary
kpss.test(avg_temp_train)
adf.test(avg_temp_train)
#From the p-values it is clear that the differenced time series is now stationary
#We now look at the ACF and PACF plots
par(mfrow=c(1,2))
acf(avg_temp_train, lag.max=120)
pacf(avg_temp_train, lag.max=120)
par(mfrow=c(1,1))
#From the plots it is clear that the series has a seasonal MA(1) component. ACF almost cuts off after lag 1 or 2 and PACF perseveres indicating a MA(1) or MA(2) process
#We now have two candidate models SARIMA(0,1,1)(0,1,1)[12] and SARIMA(0,1,2)(0,1,1)[12]. We fit both of them and see which one is better using RMSE and Ljung-Box Test
#Now we fit a SARIMA(0,1,1)(0,1,1)(12) model
model1 <- arima(avg_temp_train1, order = c(0,1,1),
               seasonal = list(order = c(0,1,1), period = 12))
Box.test(residuals(model1), lag = 12, type = "Ljung")
#Carried out portmanteau test to check whether the residuals are iid or not. Low p-value indicates the errors are still correlated
#Now we fit a SARIMA(0,1,2)(0,1,1)[12] model
model2 <- arima(avg_temp_train1, order = c(0,1,2),
                seasonal = list(order = c(0,1,1), period = 12))
Box.test(residuals(model2), lag = 12, type = "Ljung")
#High p-value of the model indicates the model has fitted well
#We now also check the RMSE
sqrt(mean(residuals(model1)^2))
sqrt(mean(residuals(model2)^2))
#Both by the RMSE and Ljung-Box test we see that SARIMA(0,1,2)(0,1,1)[12] is a better model
#Now we have fit the model. We will forecast for the upcoming 321 months
h <- length(avg_temp_test)
fc <- predict(model2, n.ahead = h)
fc_ts <- ts(fc$pred,
            start = end(avg_temp_train1) + c(0,1),
            frequency = frequency(avg_temp_train))
avg_temp_test<-ts(avg_temp_test, start = end(avg_temp_train1)+c(0,1), frequency = 12)
#Plotting the fitted series
ts.plot(
        avg_temp_test,
        fc_ts,
        col = c("blue", "red"),
        lty = 1,
        xlab = "Time",
        ylab = "Temperature",
        main = "Predicted Avg Temperature of India from Dec 1986 to Aug 2013")
time_forecast <- time(avg_temp_train)[length(avg_temp_train)] + (1:h)/frequency(avg_temp_train)
#Calculating the CI for each prediction
upper <- fc$pred + 1.96 * fc$se
lower <- fc$pred - 1.96 * fc$se

# Adding confidence bands
lines(time_forecast, upper, col = "black", lty = 2)
lines(time_forecast, lower, col = "green", lty = 2)

