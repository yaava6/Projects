// Загрузка данных
import excel "data.xlsx", sheet("Лист1") firstrow
rename Год Year
rename Регион Region
rename номер Number
xtset Number Year

// Описательные статистики
sum y х1 x2 x3 x4 x5

//Построение графиков
twoway scatter y х1
twoway scatter y х2
twoway scatter y х3
twoway scatter y х4
twoway scatter y х5

// Выбор функциональной формы
//Тест Бокса-Кокса
boxcox y х1 x2 x3 x4 x5, model (theta)
boxcox y х1 x2 x3 x4 x5, model (lambda)
//Создадим логарифмы по всем переменным
gen ln_y = ln( y )
gen ln_x1 = ln( х1 )
gen ln_x2 = ln( x2 )
gen ln_x3 = ln( x3 )
gen ln_x4 = ln( x4 )
gen ln_x5 = ln( x5 )

// РЕ-теста МакКиннона, Уайта и Дэвидсона 
reg y х1 x2 x3 x4 x5
predict y_hat
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5
predict ln_y_hat
gen lin_add= ln_y_hat-ln( y_hat )
reg y х1 x2 x3 x4 x5 lin_add
gen log_add=y_hat - exp( ln_y_hat )
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5 log_add

//Тест Чоу
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5
scalar rssp = e(rss)
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5 if дамми==1
scalar rss1 = e(rss)
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5 if дамми==0
scalar rss2 = e(rss)
scalar F = ((rssp - rss1 - rss2)/6)/ ((rss1+rss2)/(162-2*6))
display F
//Рассчитанное значение F-статистики = 8.0248041
//Критическое значение = F(0.95; 6; 150) = 2.159517
// Таким образом, рассчитанное значение больше критического, следовательно нулевая гипотеза 
// отвергается.
// Следовательно, следует рассматривать зависимости отдельно по двум выбранным катеориям.

// Тест Рамсея
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5
ovtest
gen x4_2 = ln_x4 ^2
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5 x4_2
ovtest

// Мультиколлинеарность
corr ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5
vif

//Гетероскедастичность
// Тест Уайта
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5 x4_2
estat imtest, white
// Тест Бройша Пагана
estat hettest, rhs mtest
// Решение проблемы гетероскедастичности
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5 x4_2, robust

// Модели с усеченными т цензурированными зависимыми переменными
//Посмотрим гистограмму по ВРП на душу населения
histogram y
disp ln(1000000)
* ln(1000 000) = 13.8155
reg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5
est store ols
truncreg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5, ul(13.8155)
est store tr_ul5
truncreg ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5, ll(13.8155)
est store tr_ll5
tobit ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5, ul(13.8155)
est store tob_ul5
tobit ln_y ln_x1 ln_x2 ln_x3 ln_x4 ln_x5, ll(13.8155)
est store tob_ll5
outreg2 [ols tr_ul5 tr_ll5 tob_ul5 tob_ll5] using models.doc, see word replace