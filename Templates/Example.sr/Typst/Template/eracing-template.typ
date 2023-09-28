#let eracing-template(title: "", authors: (), date: none, lang: "it", accent: blue, light-ratio: 60%, small-titles: false, body) = {

  let light-accent = accent.lighten(light-ratio)

  // Utilities.
  let zstack(..args) = style(styles => {
    let width = 0pt
    let height = 0pt
    for item in args.pos() {
        let size = measure(item, styles)
        width = calc.max(width, size.width)
        height = calc.max(height, size.height)
    }
    block(width: width, height: height, {
        for item in args.pos() {
            place(item)
        }
    })
  })

  // Set the document's basic properties.
  set document(author: authors, title: title)
  
  set page(
    background: locate(loc => if loc.page() == 1 {
      place(
        top, 
        stack(
          dir: ttb,
          rect(fill: luma(97%), width: 100%, height: 3cm),
          rect(fill: accent, width: 100%, height: 2mm)
        )
      )
    }),
    header: [
      #locate(loc => if loc.page() == 1 {
        // Header
        stack(
          dir: ltr,
          spacing: 1fr,
          stack(
            dir: ltr,
            image("eracing.svg", height: 2cm),
            align(horizon)[
              #set text(size: 18pt, weight: 300)
              #set par(leading: 7pt)
              UNIUD\ E-Racing Team
            ]
          ),
          image("uniud.svg", height: 2cm),
        )
      })
    ],
    header-ascent: 0%,
    margin: (left: 1.5cm, right: 1.5cm, top: 2.5cm, bottom: 1.5cm)
  )
  
  set text(font: "IBM Plex Sans", lang: lang, size: 9.25pt)

  show raw: it => [#text(font: "IBM Plex Mono", size: 9.25pt, it)]

  // Set paragraph spacing.
  show par: set block(above: 1.5em, below: 0.75em)
  set par(leading: 0.58em)

  // Titles.
  show heading: it => {
    if small-titles {
      set text(size: 11pt, fill: accent)
      [#it.body - ]
    } else {
      underline(it)
    }
  }

  // Underline.
  set underline(stroke: (paint: light-accent, thickness: 0.1em), offset: 1pt)

  // Highlight.
  set highlight(fill: light-accent, extent: 2pt, top-edge: 4pt, bottom-edge: -3pt)

  // Figure.
  show figure: it => {
    block(
      stack(
        dir: ttb,
        spacing: 3mm,
        it.body,
        [
          #set text(size: 9pt, weight: 500)
          #highlight(it.caption)
        ]
      )
    )
  }

  // Space for the first page.
  v(1.5cm)

  // Main body.
  set par(justify: true)
  show: columns.with(2, gutter: 2em)

  // Title block.
  block(text(weight: 700, 1.75em, title))
  v(0.8em, weak: true)
  date

  // Author information.
  stack(
    spacing: 0.3cm,
    dir: ttb,
    ..authors.map(author => align(left, strong(author))),
  )

  body
}