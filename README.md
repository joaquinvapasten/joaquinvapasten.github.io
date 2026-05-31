# Sitio personal — Joaquín

Sitio web hecho con **Quarto** + **GitHub Pages**. Incluye: portada (sobre mí), CV descargable, galería de visualizadores interactivos en R, y una página de lecturas. Tema oscuro con paleta negro / azul oscuro / rojo / rojo oscuro.

---

## 1. Personaliza (5 minutos)

Busca y reemplaza estos marcadores en el proyecto:

| Marcador | Dónde | Qué poner |
|---|---|---|
| `TU_USUARIO` | `_quarto.yml`, `index.qmd` | tu usuario de GitHub / LinkedIn |
| `TUCORREO@gmail.com` | `_quarto.yml`, `index.qmd` | tu correo |
| `Joaquín` | `_quarto.yml`, `index.qmd`, footer | tu nombre completo (agrega apellido) |
| `img/perfil.jpg` | carpeta `img/` | tu foto real (mismo nombre) |
| `files/cv.pdf` | carpeta `files/` | tu CV real en PDF (mismo nombre) |
| `ID_DE_TU_CARPETA` | `lecturas.qmd` | ID de tu carpeta de Drive (opcional) |
| `site-url` | `_quarto.yml` | `https://TU_USUARIO.github.io` |

> Para actualizar el CV en el futuro: solo reemplaza `files/cv.pdf` y vuelve a publicar.

## 2. Requisitos

- [Quarto](https://quarto.org) (ya lo tienes ✅)
- **R** con estos paquetes para el visualizador de ejemplo:

```r
install.packages(c("dplyr", "ggplot2", "plotly", "DT", "leaflet"))
```

## 3. Previsualiza en local

Desde la carpeta del proyecto:

```bash
quarto preview
```

Se abre en el navegador y se recarga solo al guardar cambios.

## 4. Publica en GitHub Pages

**Opción A — la más fácil (recomendada):**

```bash
# 1. Crea un repo vacío en GitHub (sin README)
# 2. En la carpeta del proyecto:
git init
git add .
git commit -m "Mi sitio"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git push -u origin main

# 3. Publica (renderiza y sube a la rama gh-pages):
quarto publish gh-pages
```

Luego, en GitHub: **Settings → Pages → Source: rama `gh-pages`**. Tu sitio queda en
`https://TU_USUARIO.github.io/TU_REPO/`.

> Si quieres que la URL sea `https://TU_USUARIO.github.io` (sin sufijo), nombra el repo exactamente `TU_USUARIO.github.io`.

**Opción B — GitHub Actions (publica solo al hacer push):** ver `.github/workflows/publish.yml` (incluido). Útil si no quieres correr `quarto publish` a mano, aunque requiere configurar R en el CI.

## 5. Agregar un visualizador nuevo

1. Copia `proyectos/ejemplo-desigualdad.qmd` → `proyectos/mi-analisis.qmd`.
2. Reemplaza el bloque de datos simulados por tu base real (CASEN, WVS, ENVIF, etc.).
3. Agrega una tarjeta en `visualizadores.qmd` apuntando a `proyectos/mi-analisis.html`.
4. `quarto publish gh-pages`.

---

## Ideas para más adelante

- **Apps interactivas sin servidor (Shinylive):** corre apps Shiny dentro del sitio estático, sin pagar hosting. Ideal para filtros y sliders sobre tus bases.
- **Observable / OJS:** celdas `{ojs}` para visualizaciones interactivas en JS directo en Quarto.
- **Blog / bitácora:** un `blog.qmd` tipo *listing* para reseñas de papers o notas metodológicas (genera RSS automático).
- **Sección Publicaciones/Ponencias:** lista con tu `.bib`, enlaces a PDF y DOI.
- **Sección Docencia:** materiales de ayudantías, slides, guías de R.
- **Listado bibliográfico automático:** archivo `referencias.bib` + `nocite: '@*'` para una biblioteca citada con formato.
- **Toggle claro/oscuro:** Quarto lo soporta con `theme: {light: ..., dark: custom.scss}`.
- **Dominio propio:** apunta un dominio (ej. `joaquin.cl`) al sitio vía `CNAME`.
- **Analítica respetuosa:** Plausible o GoatCounter para ver visitas sin trackear personas.
- **Descargas de datos:** ofrece los `.rds`/`.csv` limpios de cada visualizador para que otros repliquen.
