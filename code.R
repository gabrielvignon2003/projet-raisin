# Importation des bibliothèques
library(ggplot2)
library(readxl)
library(corrplot)
library(FactoMineR) # pour le PCA automatique

# Partie 1 : analyse non supervisée

## Analyse descriptive

### Lecture du dataset :
data <- read_excel("Raisin.xlsx")
dimension <- dim(data)
n <- dimension[1]
p <- dimension[2]
entete <- head(data)
data_pcaume <- summary(data)
### Quelques graphiques pour comprendre le dataset :
data_plot <- plot(data, col = as.factor(data$Class))
equilibre_des_classes <- ggplot(data = data, aes(x = Class)) + geom_bar(stat = "count")
plot_correlations <- corrplot(cor(data[, -p]), method = "circle")

## ACP

### Centrer et réduire
data_cr <- scale(data[, -p], center = TRUE, scale = TRUE) / sqrt((n - 1) / n)
### PCA avec FactoMineR
data_pca <- PCA(data[, -p])
### Etude des resultats
variances_des_axes_pca <- round(data_pca$eig, 4)
somme_vp_pca <- (sum(data_pca$eig[, 1])) # doit être égal à p - 1, i.e à 7
### Graphique des valeurs propres
vp_corr <- data.frame(
  Dim = paste("Dim", 1:nrow(data_pca$eig)),     # paste = concaténation de vecteurs
  Inertie = data_pca$eig[, 2]
)
vp_pca <- ggplot(vp_corr) +
  geom_col(aes(x = Dim, y = Inertie)) +
  geom_hline(yintercept = 100 / 7) +
  labs(title = "% inertie", x = "Dimensions", y = "Inertie") # on ne garde que les deux premiers axes principaux
### Variables et cercle des corrélations
variables_pca <- data_pca$var
### qualité de représentation
cos2_variables_pca <- V$cos2
### corrélation
correlations_variables_pca <- V$cor
###contribution à l'axe
contribution_pca <- V$contrib
### visualisation simultanée individus/variables dans le premier plan
plt1 <- plot(data_pca, axes = c(1, 2), choix = "ind", label = "none")
plt2 <- plot(data_pca, axes = c(1, 2), choix = "var")
ggsave("premier_plan_pca.png", cowplot::plot_grid(plt1, plt2, ncol = 2, nrow = 1))


## Clustering par Classification hiérarchique ascendante
