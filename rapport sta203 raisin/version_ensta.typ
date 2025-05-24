#import "@preview/typographix-polytechnique-reports:0.1.6" as template

#let translate_month(month) = {
  // Construction mapping for months
  let t = (:)
  let fr-month-s = ("Janv.", "Févr.", "Mars", "Avr.", "Mai", "Juin",
    "Juill.", "Août", "Sept.", "Oct.", "Nov.", "Déc.")
  let fr-months-l = ("Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
    "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre")
  for i in range(12) {
    let idate = datetime(year: 0, month: i + 1, day: 1)
    let ml = idate.display("[month repr:long]")
    let ms = idate.display("[month repr:short]")
    t.insert(ml, fr-months-l.at(i))
    t.insert(ms, fr-month-s.at(i))
  }

  // Translating month
  let fr_month = t.at(month)
  fr_month
}

#let display-date(date, short-month) = {
  context {
    // Getting adapted month string
    let repr = if short-month { "short" } else { "long" }
    let month = date.display("[month repr:" + repr + "]")

    // Translate if necessary
    if text.lang == "fr" {
      month = translate_month(month)
    }

  // Returns month and year
  [#month #str(date.year())]
  }
}


#let cover(title, author, date-start, subtitle: none, logo: none, short-month: false, logo-horizontal: true) = {
  set text(font: "New Computer Modern Sans", hyphenate: false, fill: rgb("#3343fe"))
  set align(center)

  v(1.8fr)

  set text(size: 24pt, weight: "bold")
  upper(title)

  v(1.5fr)

  if subtitle != none {
    set text(size: 20pt)
    subtitle
  }
  image("raisin.jpg", width:50%)

  
  set text(size: 18pt, weight: "regular")
  display-date(date-start, short-month)

  image("filet-court.svg")

  set text(size: 16pt)
  smallcaps(author)

  v(1fr)

  let logo-height = if (logo-horizontal) { 20mm } else { 30mm }
  let path-logo-x = if (logo-horizontal) { "logos/logo_ensta_horizontal.jpg" } else { "logos_ensta_vertical.png" }

  set image(height: logo-height)

  if (logo != none) {
    grid(
      columns: (1fr, 1fr), align: center + horizon,
      logo, image(path-logo-x)
    )
  } else {
    grid(
      columns: (1fr), align: center + horizon,
      image(path-logo-x)
    )
  }

}

#let apply-header-footer(doc, short-title: none) = {
  set page(header: { 
    grid(columns: (1fr, 1fr),
      align(horizon, smallcaps(text(fill: rgb("3343fe"), size: 14pt, font: "New Computer Modern Sans", weight: "bold")[#short-title])),
      align(right, image("logos/logo_ensta_vertical.png", height: 20mm)))
  }, numbering: "1 / 1")
  counter(page).update(1)

  doc
}




#let appendix(body, title: "Appendix") = {
  counter(heading).update(0)
  // From https://github.com/typst/typst/discussions/3630
  set heading(
    numbering: (..nums) => {
      let vals = nums.pos()
      let s = ""
      if vals.len() == 1 {
        s += title + " "
      }
      s += numbering("A.1 -", ..vals)
      s
    },
  )

  body
}


  

#set text(lang: "fr")

#cover(
  [étude statistique d'un mélange de raisins],
  "Josselin De Féligonde - Gabriel Vignon",
  datetime.today(),
  subtitle: "STA03 - Apprentissage statistique",
  logo-horizontal: true,
)

// Defining variables for the cover page and PDF metadata
// Main title on cover page
#let title = [Le raisin]
// Subtitle on cover page
#let subtitle = "Le raisin"
// Logo on cover page
#let logo = "logos/logo_ensta_horizontal.jpg" // instead of none set to image("path/to/my-logo.png")
#let logo-horizontal = true // set to true if the logo is squared or horizontal, set to false if not
// Short title on headers
#let short-title = "Le raisin"
#let author = "Josselin De Féligonde - Gabriel Vignon"
#let date-start = datetime(year: 2024, month: 06, day: 05)
#let date-end = datetime(year: 2024, month: 09, day: 05)
// Set to true for bigger margins and so on (good luck with your report)
#let despair-mode = false

#set text(lang: "fr")

// Set document metadata
#set document(title: title, author: author, date: datetime.today())
#show: template.apply.with(despair-mode: despair-mode)

// Acknowledgements
//#heading(level: 1, numbering: none, outlined: false)[Remerciements]

// Table of contents
#outline(title: [Table des matières], indent: 1em, depth: 2)

// Defining header and page numbering (will pagebreak)
#show: apply-header-footer.with(short-title: short-title)

// Introduction
#heading(level: 1, numbering: none)[Introduction]
#pagebreak()

#include("report.typ")