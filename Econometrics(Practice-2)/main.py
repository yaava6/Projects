import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

import statsmodels.api as sm
import statsmodels.tsa.api as smt
from statsmodels.tsa.seasonal import seasonal_decompose
from pmdarima.arima.utils import ndiffs

from datetime import datetime
from dateutil.relativedelta import relativedelta
from statsmodels.tsa.stattools import adfuller
from numpy import log
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.arima.model import ARIMAResults
import pmdarima as pm
from dateutil.parser import parse
from statsmodels.graphics.tsaplots import plot_acf
from statsmodels.graphics.tsaplots import plot_pacf
from statsmodels.tsa.stattools import acf

p = print

def tsplot(y, lags=None, figsize=(14, 8), style='bmh'):
    if not isinstance(y, pd.Series):
        y = pd.Series(y)
    y  = pd.DataFrame(data=y)
    rolmean = y.rolling(50).mean()
    rolstd = y.rolling(50).std()
    with plt.style.context(style):
        plt.figure(figsize=figsize)
        layout = (5, 1)
        ts_ax = plt.subplot2grid(layout, (0, 0), rowspan=2)
        acf_ax = plt.subplot2grid(layout, (2, 0))
        pacf_ax = plt.subplot2grid(layout, (3, 0))
        qq_ax = plt.subplot2grid(layout, (4, 0))

        y.plot(ax=ts_ax, color='blue', label='data')
        rolmean.plot(ax=ts_ax, color='red')
        rolstd.plot(ax=ts_ax, color='black')
        ts_ax.set_title('Original(blue), Rolling Mean(red) & Standard Deviation(black)')

        smt.graphics.plot_acf(y, lags=lags, ax=acf_ax, alpha=0.05)
        smt.graphics.plot_pacf(y, lags=lags, ax=pacf_ax, alpha=0.05)
        sm.qqplot(y, line='s', ax=qq_ax)
        qq_ax.set_title('QQ Plot')

        plt.tight_layout()
    return

# tsplot(y, lags=None, figsize=(14, 8), style='bmh')
#######################
# разложение на компаненты
#########################
def seasonal_decompose_plot(y,  freq=None):
    if not isinstance(y, pd.Series): # не является рядом?
        y = pd.Series(y) # преобразовать в ряд
    decomposition = seasonal_decompose(y)
    # fig = plt.figure()
    fig = decomposition.plot()
    fig.set_size_inches(15, 8)
    return
################
 # Dickey-Fuller
##################
def test_stationarity(timeseries):
    print('Results of Dickey-Fuller Test:')
    dftest = adfuller(timeseries, autolag='AIC')
    dfoutput = pd.Series(dftest[0:4], index=['Test Statistic', 'p-value', '#Lags Used', 'Number of Observations Used'])
    for [key, value] in dftest[4].items():
        dfoutput['Critical Value (%s)' % key] = value
    p(dfoutput)

# Загрузим данные
df = pd.read_csv('C:/PycharmProjects/pythonProject/Sem16/Data_Example.csv', names=['value'], header=0)
df.head()

plt.xlabel('Date')
plt.ylabel('Agriculture')
plt.plot(df.value)

result = adfuller(df.value.dropna())
print('ADF Statistic: %f' % result[0])
print('p-value: %f' % result[1])

df.index = pd.DatetimeIndex(df.index.values, freq=df.index.inferred_freq)

plt.rcParams.update({'figure.figsize':(9,7), 'figure.dpi':120})
# Original Series
fig, axes = plt.subplots(3, 2, sharex=True)
axes[0, 0].plot(df.value); axes[0, 0].set_title('Original Series')
plot_acf(df.value, ax=axes[0, 1])

# 1st Differencing
axes[1, 0].plot(df.value.diff()); axes[1, 0].set_title('1st Order Differencing')
plot_acf(df.value.diff().dropna(), ax=axes[1, 1])

# 2nd Differencing
axes[2, 0].plot(df.value.diff().diff()); axes[2, 0].set_title('2nd Order Differencing')
plot_acf(df.value.diff().diff().dropna(), ax=axes[2, 1])

plt.show()

s = df.value

tsplot(df.value, lags=10)

s = s - s.shift(1)
s = s.dropna(inplace=False)
tsplot(s, lags=10)


# Тест на стационарность для первичных данных и для "очищенных от сезонности"
test_stationarity(df.value)
test_stationarity(s)
result = adfuller(s.dropna())
print('ADF Statistic: %f' % result[0])
print('p-value: %f' % result[1])

s.index = pd.DatetimeIndex(s.index.values, freq=s.index.inferred_freq)

# PACF график для первой разности
fig, axes = plt.subplots(1, 2, sharex=True)
axes[0].plot(df.value.diff()); axes[0].set_title('1st Differencing')
axes[1].set(ylim=(0,1.2))
plot_pacf(df.value.diff().dropna(), ax=axes[1], lags=10)

plt.show()

# ACF график для первой разности
fig, axes = plt.subplots(1, 2, sharex=True)
axes[0].plot(df.value.diff()); axes[0].set_title('1st Differencing')
axes[1].set(ylim=(0,1.2))
plot_acf(df.value.diff().dropna(), ax=axes[1])

plt.show()

# 1,1,1 ARIMA Model
model = ARIMA(df.value, order=(1,1,1))
model_fit = model.fit()
print(model_fit.summary())

#mdl = ARIMA(s, order=(2, 1, 1)).fit()
#p(mdl.summary())

# Plot residual errors
residuals = pd.DataFrame(model_fit.resid)
fig, ax = plt.subplots(1,2)
residuals.plot(title="Residuals", ax=ax[0])
residuals.plot(kind='kde', title='Density', ax=ax[1])
plt.show()



# Seasonal - fit stepwise auto-ARIMA
smodel = pm.auto_arima(df.value, start_p=1, start_q=1,
                         test='adf',
                         max_p=3, max_q=3,
                         start_P=0,
                         d=None, D=1, trace=True,
                         error_action='ignore',
                         suppress_warnings=True,
                         stepwise=True)

smodel.summary()

smodel.plot_diagnostics(figsize=(7,5))
plt.show()

# Forecast
n_periods = 5
fc, confint = smodel.predict(n_periods=n_periods, return_conf_int=True)
index_of_fc = np.arange(len(df.value), len(df.value)+n_periods)

# make series for plotting purpose
fc_series = pd.Series(fc, index=index_of_fc)
lower_series = pd.Series(confint[:, 0], index=index_of_fc)
upper_series = pd.Series(confint[:, 1], index=index_of_fc)

# Plot
plt.plot(df.value)
plt.plot(fc_series, color='darkgreen')
plt.fill_between(lower_series.index,
                 lower_series,
                 upper_series,
                 color='k', alpha=.15)

plt.title("Final Forecast of Y")
plt.show()


# Import Data
data = pd.read_csv('C:/PycharmProjects/pythonProject/Sem16/Data_Exog_2.csv', parse_dates=['Year'], index_col='Year')

# SARIMAX Model
sxmodel = pm.auto_arima(data[['Y']], exogenous=data[['food_export_share', 'rur_pop_share', 'gov_exp_share', 'fdi_share', 'agri_export_share']],
                           start_p=1, start_q=1,
                           test='adf',
                           max_p=3, max_q=3,
                           start_P=0,
                           d=None, D=1, trace=True,
                           error_action='ignore',
                           suppress_warnings=True,
                           stepwise=True)

sxmodel.summary()


#train = df.value[:20]
#test = df.value[20:]
