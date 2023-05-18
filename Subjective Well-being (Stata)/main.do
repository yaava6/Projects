
clear
import excel "C:\Users\Yaava\Desktop\WELFARE\Data.xlsx", sheet("Sheet1") firstrow

ssc install margeff
ssc install estout, replace

keep if lifesat>0
keep if age>0 
keep if children>0 
keep if town>0 
keep if health>0 
keep if trust>0 
keep if patriot>0 
keep if religion>0 
keep if religion>0 
keep if gender>0 
keep if marital>0 
keep if employm>0 
keep if income>0

histogram lifesat, discrete by(country wave)
sum age
histogram age
kdensity age
histogram lifesat
sum lifesat age children town health trust patriot religion marital employm income
sum lifesat age children town health trust patriot religion marital employm income if gender == 1
sum lifesat age children town health trust patriot religion marital employm income if gender == 2
sum lifesat age children town health trust patriot religion marital employm income if country = 1
sum lifesat age children town health trust patriot religion marital employm income if country = 0
sum lifesat age children town health trust patriot religion marital employm income if wave = 1
sum lifesat age children town health trust patriot religion marital employm income if (wave == 1 & country == 1)
sum lifesat age children town health trust patriot religion marital employm income if (wave == 0 & country == 1)
sum lifesat age children town health trust patriot religion marital employm income if (wave == 1 & country == 0)
sum lifesat age children town health trust patriot religion marital employm income if (wave == 0 & country == 0)
sum wave counrte

tab lifesat

recode lifesat 1 2 3 4 = 4
recode children 1 2 3 4 5 6 7 8 = 1

correlate lifesat age children town health trust patriot religion marital employm income
collin lifesat age children town health trust patriot religion marital employm income

ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration

eststo clear
eststo: ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration
eststo: oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration
esttab, cells(b(star fmt(3)) se(par fmt(3))) label nocons

eststo clear
eststo: oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (country == 1)
eststo: oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (country == 0)
esttab, cells(b(star fmt(3)) se(par fmt(3))) label nocons

eststo clear
eststo: oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (wave == 1)
eststo: oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (wave == 0)
esttab, cells(b(star fmt(3)) se(par fmt(3))) label nocons

eststo clear
eststo: oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (gender == 2)
eststo: oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (gender == 1)
esttab, cells(b(star fmt(3)) se(par fmt(3))) label nocons



oprobit lifesat c.age c.age#c.age c.children i.town c.health i.trust i.patriot c.religion i.marital i.employm c.income
estimates store oprobit_model
gen oprobit_model_sample = e(sample)
margins, dydx(*)
margins, dydx(*) atmeans

predict p0 p1 p2 p3 p4 p5 p6, pr
* Получим бинарные переменные на принадлежность к каждому из классов
gen z_0 = 0 if e(sample)
gen z_1 = 0 if e(sample)
gen z_2 = 0 if e(sample)
gen z_3 = 0 if e(sample)
gen z_4 = 0 if e(sample)
gen z_5 = 0 if e(sample)
gen z_6 = 0 if e(sample)
replace z_0 = 1 if ((p0 >= p1) & (p0 >= p2) & (p0 >= p3) & (p0 >= p4) & e(sample))
replace z_1 = 1 if ((p1 >= p1) & (p1 >= p2) & (p1 >= p3) & (p1 >= p4) & e(sample))
replace z_2 = 1 if ((p2 >= p1) & (p2 >= p2) & (p2 >= p3) & (p2 >= p4) & e(sample))
replace z_3 = 1 if ((p3 >= p1) & (p3 >= p2) & (p3 >= p3) & (p3 >= p4) & e(sample))
replace z_4 = 1 if ((p4 >= p1) & (p4 >= p2) & (p4 >= p3) & (p4 >= p4) & e(sample))
replace z_5 = 1 if ((p5 >= p1) & (p5 >= p2) & (p5 >= p3) & (p5 >= p4) & e(sample))
replace z_6 = 1 if ((p6 >= p1) & (p6 >= p2) & (p6 >= p3) & (p6 >= p4) & e(sample))
* Создадим переменную на предсказанный класс
gen z_class = z_0 * 1 + z_1 * 2 + z_2 * 3 + z_3 * 4 + z_4 * 5 + z_5 * 6 + z_6 * 7
* Посчитаем число корректных предсказаний
gen z_correct = . if (oprobit_model_sample)
replace z_correct = 1 if ((lifesat == z_class) & (oprobit_model_sample))
replace z_correct = 0 if ((lifesat != z_class) & (oprobit_model_sample))
	* Доля верных предсказаний (количество единиц делить на обхем выборки)
tab z_correct if e(sample)

	* Наивный прогноз (количество индивидов, принадлежащих к самой распространенной)
	* категории следует поделить на общее число индивидов
tab lifesat if e(sample)
* Проверим возможность исключить из модели переменную на town
oprobit lifesat c.age c.age#c.age c.children c.health i.trust i.patriot c.religion i.marital i.employm c.income if (oprobit_model_sample)
estimates store oprobit_model_town
	* Смотрим на p-value и отвергаем нулевую гипотезу на уровне значимости 5%
lrtest oprobit_model_town oprobit_model

* Проверим возможность исключить из модели переменную на religion
oprobit lifesat c.age c.age#c.age c.children i.town c.health i.trust i.patriot i.marital i.employm c.income if (oprobit_model_sample)
estimates store oprobit_model_religion
	* Смотрим на p-value и отвергаем нулевую гипотезу на уровне значимости 5%
lrtest oprobit_model_religion oprobit_model

* Проверим возможность исключить из модели переменную на patriot
oprobit lifesat c.age c.age#c.age c.children i.town c.health i.trust c.religion i.marital i.employm c.income if (oprobit_model_sample)
estimates store oprobit_model_patriot
	* Смотрим на p-value и отвергаем нулевую гипотезу на уровне значимости 5%
lrtest oprobit_model_patriot oprobit_model

* Проверим возможность исключить из модели переменную на marital
oprobit lifesat c.age c.age#c.age c.children i.town c.health i.trust i.patriot c.religion i.employm c.income if (oprobit_model_sample)
estimates store oprobit_model_marital
	* Смотрим на p-value и отвергаем нулевую гипотезу на уровне значимости 5%
lrtest oprobit_model_marital oprobit_model

* Проверим возможность исключить из модели переменную на employm
oprobit lifesat c.age c.age#c.age c.children i.town c.health i.trust i.patriot c.religion i.marital c.income if (oprobit_model_sample)
estimates store oprobit_model_employm
	* Смотрим на p-value и отвергаем нулевую гипотезу на уровне значимости 5%
lrtest oprobit_model_employm oprobit_model

* Проверим возможность исключить из модели переменную на income
oprobit lifesat c.age c.age#c.age c.children i.town c.health i.trust i.patriot c.religion i.marital i.employm if (oprobit_model_sample)
estimates store oprobit_model_income
	* Смотрим на p-value и отвергаем нулевую гипотезу на уровне значимости 5%
lrtest oprobit_model_income oprobit_model

* Проверим возможность исключить из модели переменную на children
oprobit lifesat c.age c.age#c.age c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if (oprobit_model_sample)
estimates store oprobit_model_children
	* Смотрим на p-value и отвергаем нулевую гипотезу на уровне значимости 5%
lrtest oprobit_model_town oprobit_model




* Построим порядковую модель для совершеннолетних мужчин
ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income 
estimates store ologit_model
* Добавим отношения шансов
* При интерпретации отношений шансов учитывайте, что для любого номера категории k изменение в отношениях шансов p(z>k)/p(z<=k) остается прежним
ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income, or











*Country CHN
*Wave 7
*Gender Male
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 1) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans
*Gender Female
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 1) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans
*Wave 6
*Gender Male
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 1) & (wave == 0))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans
*Gender Female
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 1) & (wave == 0))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans
*Country KAZ
*Wave 7
*Gender Male
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 0) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans
*Gender Female
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 0) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans
*Wave 6
*Gender Male
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 0) & (wave == 0))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans
*Gender Female
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 0) & (wave == 0))
estimates store oprobit_model
margins, dydx(*)
margins, dydx(*) atmeans




*
**Country CHN
*Wave 7
gen age_square = age * age
oprobit lifesat c.age c.age_square c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((country == 1) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((country == 1) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
oprobit lifesat c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((country == 1) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
*
oprobit lifesat c.age c.age_square c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((country == 0) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((country == 0) & (wave == 1))
estimates store oprobit_model
margins, dydx(*)
*







***
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (country == 1)
estimates store oprobit_model
margins, dydx(*)
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration if (country == 0)
estimates store oprobit_model
margins, dydx(*)
oprobit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration
estimates store oprobit_model
margins, dydx(*)
***



ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 1) & (wave == 1))


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 1) & (wave == 1))


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 1) & (wave == 0))


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 1) & (wave == 0))


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 0) & (wave == 1))


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 0) & (wave == 1))


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 0) & (wave == 0))


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 0) & (wave == 0))







ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 1) & (wave == 1)), or


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 1) & (wave == 1)), or


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 1) & (wave == 0)), or


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 1) & (wave == 0)), or


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 0) & (wave == 1)), or


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 0) & (wave == 1)), or


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 1) & (country == 0) & (wave == 0)), or


ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income if ((gender == 2) & (country == 0) & (wave == 0)), or






ologit lifesat c.age c.age#c.age c.children c.town c.health i.trust i.patriot c.religion i.marital i.employm c.income gdp inflation gini lifespan emigration
brant, detail








