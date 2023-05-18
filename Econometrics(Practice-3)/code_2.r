options(scipen = 999)

library(readxl)
library(sf)
library(spdep)  
library(spatialreg) 
library(lattice)
library(RANN)
library(RColorBrewer)
library(tidyverse)
library(tmap)
library(GWmodel)
library(stars)
library(mapview)
library(dplyr)
library(readr)

# загружаем таблицу (разбивая на 2017 и 2018 год) и пространственные данные
# за исключением г. Москва
reg = st_read('~/Desktop/ДЗ №3/regions_ru.gpkg')
tab = read_xlsx('~/Desktop/ДЗ №3/data.xlsx')
tab_2017 = dplyr::filter(tab, year == 2017)
tab_2018 = dplyr::filter(tab, year == 2018)

# присоединяем таблицы за 2017 и 2018 гг. к пространственным данным
mor_src = reg

mor_2017 = reg %>% 
  left_join(tab_2017, by = c("name_local" = "region")) %>% 
  st_set_geometry('geometry')
  
mor_2018 = reg %>% 
  left_join(tab_2018, by = c("name_local" = "region")) %>% 
  st_set_geometry('geometry')

#  вычислим матрицу пространственных весов (по расстоянию)
coords <- st_centroid(st_geometry(reg), of_largest_polygon=TRUE)
rn <- row.names(reg)
k1 <- knn2nb(knearneigh(coords))
all.linked <- max(unlist(nbdists(k1, coords)))
col.nb.0.all <- dnearneigh(coords, 0, all.linked, row.names=rn)
# визиуализируем граф
opar <- par(no.readonly=TRUE)
plot(st_geometry(reg), border="grey", reset=FALSE,
     main=paste("Ближайшие соседи по расстоянию (г.Москва исключена)"))
plot(col.nb.0.all, coords, add=TRUE)


# вычислим веса нормированной матрицы
W = nb2listw(col.nb.0.all, style = "W")
# визуализация матрицы весов
M = listw2mat(W)
ramp = colorRampPalette(c("white","red"))
levels = 1 / 1:10  
levelplot(M, 
          main="Матрица весов (нормированная)", 
          at = levels, 
          col.regions=ramp(10))

# вычислим индекс Морана по всем переменным за 2017 и 2018 гг.
y_2017 = mor_2017$y
moran.test(y_2017, W)

x1_2017 = mor_2017$x1
moran.test(x1_2017, W)

x2_2017 = mor_2017$x2
moran.test(x2_2017, W)

x3_2017 = mor_2017$x3
moran.test(x3_2017, W)

x4_2017 = mor_2017$x4
moran.test(x4_2017, W)

x5_2017 = mor_2017$x5
moran.test(x5_2017, W)

y_2018 = mor_2018$y
moran.test(y_2018, W)

x1_2018 = mor_2018$x1
moran.test(x1_2018, W)

x2_2018 = mor_2018$x2
moran.test(x2_2018, W)

x3_2018 = mor_2018$x3
moran.test(x3_2018, W)

x4_2018 = mor_2018$x4
moran.test(x4_2018, W)

x5_2018 = mor_2018$x5
moran.test(x5_2018, W)


# диаграммы рассеяния
moran.plot(y_2018, W)
moran.plot(x2_2018, W)
moran.plot(x4_2018, W)

#составим уравнение пространственной регрессии модели SAR
sar_formula = y ~ x1 + x2 + x3 + x4 + x5

#2017 год
model_2017 = lagsarlm(formula = sar_formula,
                 data = mor_2017, listw = W)
summary(model_2017)

#2018 год
model_2018 = lagsarlm(formula = sar_formula,
                      data = mor_2018, listw = W)
summary(model_2018)

# для сравнения - линейная регрессия и её МНК-оценки
# 2017 год
model_lm_2017 = lm(formula = sar_formula,
                   data = tab_2017)
summary(model_lm_2017)

# 2018 год
model_lm_2018 = lm(formula = sar_formula,
                   data = tab_2018)
summary(model_lm_2018)