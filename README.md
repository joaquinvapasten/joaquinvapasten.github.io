# Sitio personal — Joaquín Valenzuela Pastén

Sitio hecho con **Quarto** + **GitHub Pages**, publicado automáticamente con GitHub Actions.
Tema oscuro propio (`custom.scss`). En línea: <https://joaquinvapasten.github.io/>

## Estructura

| Archivo / carpeta | Qué es |
|---|---|
| `index.qmd` | Portada (sobre mí, líneas de interés) |
| `cv.qmd` | CV embebido y descargable |
| `explorador.qmd` | Explorador interactivo (ENUSC / CASEN / Cruce), Observable JS |
| `data/` | CSV agregados que alimentan el explorador + `regiones.json` |
| `prep/` | Scripts R que generan los CSV desde los microdatos |
| `custom.scss`, `styles.css` | Tema y estilos |
| `.github/workflows/publish.yml` | CI que renderiza y publica |

> Los microdatos pesados **no** están en el repo. Los scripts de `prep/` los leen desde
> rutas locales y dejan en `data/` solo los agregados livianos.

## Publicar cambios

Editar texto: modificar el `.qmd` correspondiente y `git push` (Actions publica solo, 3–5 min).

Actualizar datos: correr el script de `prep/` que toque (regenera los CSV de `data/`) y
`git push`.

Previsualizar local (requiere R con `dplyr`, `survey`, etc.):

```bash
quarto preview
```

## Pendiente / ideas

- **Datos de delitos en vivo:** integrar CEAD (Min. Seguridad) y Carabineros para consultar
  estadísticas por comuna desde la propia página (requiere un paso de scraping/ETL, ya que
  GitHub Pages es estático — ver notas del proyecto).
- Indicadores nuevos: basta agregar filas al catálogo `data/explorador.csv` (vía
  `prep/05_explorador.R`) y aparecen solos en el explorador.
- Dominio propio vía `CNAME`; analítica respetuosa (Plausible/GoatCounter).
