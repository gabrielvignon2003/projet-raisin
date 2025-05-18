# Importation des bibliothèques

library(ggplot2)
library(readxl)
library(corrplot)
library(FactoMineR) # pour le PCA automatique
library(ggdendro) # pour le dendrogramme version ggplot
library(GGally) # pour ggpairs
library(factoextra) # pour le PCA (au-delà de FactoMineR)
library(cowplot) # pour grid_plot
library(MASS) # pour stepAIC
library(glmnet) # pour les régressions lassos
library(e1071) # pour les SVM
library(ROCR) # pour les courbes ROC

# Partie 1 : analyse non supervisée

## Analyse descriptive

### Lecture du dataset

data <- read_excel("Raisin.xlsx")
dimension <- dim(data)
n <- dimension[1]
p <- dimension[2]
entete <- head(data)
description <- summary(data)

### Quelques graphiques pour comprendre le dataset

data_plot <- ggpairs(data[, -p], mapping = aes(color = data$Class))
equilibre_des_classes <- ggplot(data = data, aes(x = Class)) + geom_bar(stat = "count")
corrplot(cor(data[, -p]), method = "circle")

## ACP

### PCA avec FactoMineR (centre et réduit automatiquement)

data_pca <- PCA(data, quali.sup = which(names(data) == "Class")) # on ajoute Class en variable quali supplémentaire pour le plot

### Etude des resultats

variances_des_axes_pca <- round(data_pca$eig, 4)
somme_vp_pca <- (sum(data_pca$eig[, 1])) # doit être égal à p - 1, i.e à 7

### Graphique des valeurs propres

vp_corr <- data.frame(
  Dim = paste("Dim", 1:nrow(data_pca$eig)),     # paste = concaténation de vecteurs
  Inertie = data_pca$eig[, 2]
)
graphique_inertie_pca <- ggplot(vp_corr) +
  geom_col(aes(x = Dim, y = Inertie)) +
  geom_hline(yintercept = 100 / 7) +
  labs(title = "% inertie", x = "Dimensions", y = "Inertie") # on ne garde que les deux premiers axes principaux

### Variables et cercle des corrélations

variables_pca <- data_pca$var

### qualité de représentation

cos2_variables_pca <- data_pca$var$cos2

### corrélation

correlations_variables_pca <- data_pca$var$cor

###contribution à l'axe

contributions_variables_pca <- data_pca$var$contrib

### visualisation individus et variables dans le premier plan

p_individus <- fviz_pca_ind(data_pca, habillage   = "Class")
p_variables <- fviz_pca_var(data_pca)
combinaison <- plot_grid(p_individus, p_variables, ncol   = 2)
#ggsave("pca_indiv_vars_cowplot.png", combinaison, width = 16, height = 6)

## CAH

### CAH (méthode complète avec la distance euclidienne)

data_cr <- scale(data[, -p], center = TRUE, scale = TRUE) / sqrt((n - 1) / n)
cah <- hclust(dist(data_cr)) # il faut prendre le dataset centré réduit, sinon cela fausse les distances
dendrogramme <- ggdendrogram(cah, rotate = TRUE)
barplot(rev(cah$height)[1:15], main = "diagramme des hauteurs")
# au vu de l'allure du dendrogramme, choisir 3 groupes semble pertinent.
groupes_cah <- cutree(cah, k = 2)
# Matrice de confusion entre les groupes trouvés et les vraies classes
confusion <- table(Groupes = groupes_cah, ClasseReelle = data$Class) # la classification semble mauvaise !
# Calcul de l'erreur de classification
table_correspondances <- table(groupes_cah, data$Class)
# Si groupe 1 = Kecimen et groupe 2 = Besni
erreur1 <- 1 - (table_correspondances[1, "Kecimen"] + table_correspondances[2, "Besni"]) / sum(table_correspondances)
# Si groupe 1 = Besni et groupe 2 = Kecimen
erreur2 <- 1 - (table_correspondances[1, "Besni"] + table_correspondances[2, "Kecimen"]) / sum(table_correspondances)
# On prend la plus petite des erreurs
erreur <- min(erreur1, erreur2)

## CAH sur les k premières composantes principales

erreurs_k <- c()
for (k in 1:5) {
  coord_k <- data_pca$ind$coord[, 1:k] # les k premières composantes principales
  cah_k <- hclust(dist(coord_k))
  groupes_k <- cutree(cah_k, k = 2)
  table_correspondances <- table(groupes_k, data$Class)
  erreur1 <- 1 - (table_correspondances[1, "Kecimen"] + table_correspondances[2, "Besni"]) / sum(table_correspondances)
  erreur2 <- 1 - (table_correspondances[1, "Besni"] + table_correspondances[2, "Kecimen"]) / sum(table_correspondances)
  erreur_k <- min(erreur1, erreur2)
  erreurs_k <- c(erreurs_k, erreur_k)
}

# Affichage de l’erreur en fonction de k

plot(1:5, erreurs_k, type = "b", pch = 19,
    xlab = "Nombre de composantes principales (k)",
    ylab = "Erreur de classification",
    main = "Erreur de classification selon k")

cat("Erreur 2 groupes sans ACP :", erreur, ". Erreur 2 groupes avec ACP : ", erreurs_k[2])
meilleur_k <- which.min(erreurs_k)
cat("\nk optimal =", meilleur_k, "avec une erreur de", round(erreurs_k[meilleur_k], 3))

# Partie 2

set.seed(1)
train <- sample(c(TRUE, FALSE), n, rep = TRUE, prob = c(2/3, 1/3))

## ACP

train_data <- data[train, ]
test_data <- data[!train, ]
pca_train <- PCA(data[, -p], ind.sup = which(!train)) #on indique déjà les individus de test pour le plot plus tard
test_cr <- scale(test_data[, -p])
test_proj <- predict(pca_train, newdata = test_cr)
coord_test_proj <- test_proj$coord[, 1:2]
entete_acp_partie2 <- head(test_proj)
# 2. On crée un vecteur factor indiquant train vs test
groupe <- factor(ifelse(train, "train", "test"))[train]
ggsave("k.png", fviz_pca_ind(pca_train, habillage = groupe))

## Régression logistique

X <- scale(data[, -p])
y <- data$Class == "Kecimen"  # TRUE = Kecimen, FALSE = Besni
X_train <- X[train, ]
X_test <- X[!train, ]
y_train <- y[train]
y_test <- y[!train]

### Modèle complet

modele_complet <- glm(y_train ~ ., data = as.data.frame(X_train), family = binomial)
prob_complet <- predict(modele_complet, newdata = as.data.frame(X_test), type = "response")

### Modèle avec les 2 premières composantes principales

pca_partie2 <- PCA(X_train, graph = FALSE)
pca_premier_plan_individus <- pca_partie2$ind$coord[, 1:2]
modele_pca2 <- glm(y_train ~ ., data = as.data.frame(pca_premier_plan_individus), family = binomial)
coord_test_proj <- predict(pca_partie2, newdata = X_test)$coord[, 1:2]
prob_pca2 <- predict(modele_pca2, newdata = as.data.frame(coord_test_proj), type = "response")

### Sélection par AIC

modele_AIC <- stepAIC(modele_complet, direction = "both", trace = FALSE)
prob_aic <- predict(modele_AIC, newdata = as.data.frame(X_test), type = "response")

### Régression lasso

cv_lasso <- cv.glmnet(X_train, y_train, family = "binomial")
modele_lasso <- glmnet(X_train, y_train, family = "binomial", lambda = cv_lasso$lambda.min)
prob_lasso <- predict(modele_lasso, newx = X_test, type = "response")

## SVM

### SVM linéaire

svm_lin <- svm(X_train, as.factor(y_train), kernel = "linear", probability = TRUE)
pred_lin <- predict(svm_lin, X_test, probability = TRUE)
prob_svm_lin <- attr(pred_lin, "probabilities")[, 2]

### SVM polynomial

svm_poly <- svm(X_train, as.factor(y_train), kernel = "polynomial", degree = 3, probability = TRUE)
pred_poly <- predict(svm_poly, X_test, probability = TRUE)
prob_svm_poly <- attr(pred_poly, "probabilities")[, 2]

## ROC & AUC

preds <- list(
  Complet = prediction(prob_complet, y_test),
  PCA2    = prediction(prob_pca2,    y_test),
  AIC     = prediction(prob_aic,     y_test),
  Lasso   = prediction(prob_lasso,   y_test),
  SVM_L   = prediction(prob_svm_lin, y_test),
  SVM_P   = prediction(prob_svm_poly, y_test)
)
cols <- seq_along(preds)

#png("roc_comparaison.png")
perf0 <- performance(preds[[1]], "tpr", "fpr")
plot(perf0, col = cols[1], main = "ROC sur test")
for(i in 2:length(preds)) {
  plot(performance(preds[[i]], "tpr", "fpr"), col = cols[i], add = TRUE)
}
abline(0,1, lty = 2, col = "grey") # Base aléatoire
aucs <- numeric(length(preds))
names(aucs) <- names(preds)
for (i in seq_along(preds)) {
  perf_auc <- performance(preds[[i]], "auc")
  auc_value <- perf_auc@y.values[[1]]
  aucs[i] <- auc_value
}
legend("bottomright",
       legend = paste(names(aucs), " (AUC=", sprintf("%.2f", aucs), ")"),
       col = cols) # Légende avec AUC
#dev.off()

## Erreurs train & test

models_probs <- list(
  Complet = list(train = predict(modele_complet, type="response"), test = prob_complet),
  PCA2    = list(train = predict(modele_pca2, newdata=as.data.frame(pca_premier_plan_individus), type="response"), test  = prob_pca2),
  AIC     = list(train = predict(modele_AIC, type="response"), test = prob_aic),
  Lasso   = list(train = as.vector(predict(modele_lasso, newx = X_train, type="response")), test  = prob_lasso),
  SVM_L   = list(train = attr(predict(svm_lin, X_train, probability=TRUE), "probabilities")[,2], test  = prob_svm_lin),
  SVM_P   = list(train = attr(predict(svm_poly, X_train, probability=TRUE), "probabilities")[,2], test  = prob_svm_poly)
)
errs <- sapply(models_probs, function(mp) {
  c(train = mean((mp$train>0.5) != y_train),
    test  = mean((mp$test >0.5) != y_test))
}) # seuil à 0.5
errs_df <- as.data.frame(t(errs))
print(errs_df)

## Barplot des erreurs test

df_err <- data.frame(model = rownames(errs_df), test_error = errs_df$test)
barplot_erreurs <- ggplot(df_err, aes(x = model, y = test_error)) +
  geom_col(fill = "blue") +
  labs(title = "Erreur test par modèle", y = "Erreur test")
#ggsave("barplot_erreurs.png", barplot_erreurs)