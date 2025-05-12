# Importation des bibliothèques
library(ggplot2)
library(readxl)

# Partie 1 : analyse non supervisée
data <- read_excel("Raisin.xlsx")
entete <- head(data)
resume <- summary(data)
plot(data)
