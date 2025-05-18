  # Importation des bibliothèques
  library(ggplot2)
  library(readxl)
  library(corrplot)
  library(FactoMineR) # pour le PCA automatique
  library(ggdendro) # pour le dendrogramme version ggplot
  library(GGally) # pour ggpairs
  library(factoextra)
  library(cowplot)
  # Partie 1 : analyse non supervisée


  ## Analyse descriptive


  ### Lecture du dataset :
  data <- read_excel("Raisin.xlsx")
  dimension <- dim(data)
  n <- dimension[1]
  p <- dimension[2]
  entete <- head(data)
  description <- summary(data)
  ### Quelques graphiques pour comprendre le dataset :
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
  png("t.png")
  plot(1:5, erreurs_k, type = "b", pch = 19,
      xlab = "Nombre de composantes principales (k)",
      ylab = "Erreur de classification",
      main = "Erreur de classification selon k")
  dev.off()

  cat("Erreur 2 groupes sans ACP :", erreur, ". Erreur 2 groupes avec ACP : ", erreurs_k[2])
  meilleur_k <- which.min(erreurs_k)
  cat("\nk optimal =", meilleur_k, "avec une erreur de", round(erreurs_k[meilleur_k], 3))